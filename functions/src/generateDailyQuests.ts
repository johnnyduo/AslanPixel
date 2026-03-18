/**
 * generateDailyQuests
 *
 * Scheduled: daily at 00:01 Asia/Bangkok (UTC+7).
 * For every user with onboardingComplete=true, generates 3 daily quests
 * and 1 weekly quest (on Mondays).
 *
 * Deterministic per uid+date — same quests regenerated if called multiple times.
 * Idempotent: checks lastQuestDate before writing.
 *
 * Quest paths:
 *   quests/{uid}/active/{questId}
 *   users/{uid}/settings/quests → {lastQuestDate}
 */

import { onSchedule } from "firebase-functions/v2/scheduler";
import { FieldValue, Timestamp } from "firebase-admin/firestore";
import { db } from "./admin";
import { logger } from "firebase-functions";

// ── Quest templates ────────────────────────────────────────────────────────────

interface QuestTemplate {
  id: string;
  objective: string;
  objectiveTh: string;
  target: number;
  reward: { coins: number; xp: number };
  type: "daily" | "weekly";
}

const DAILY_TEMPLATES: QuestTemplate[] = [
  {
    id: "send_agent",
    objective: "Send an agent on a mission",
    objectiveTh: "ส่งตัวแทนไปทำภารกิจ",
    target: 1,
    reward: { coins: 20, xp: 10 },
    type: "daily",
  },
  {
    id: "read_market",
    objective: "Read a market insight",
    objectiveTh: "อ่านข้อมูลตลาด",
    target: 1,
    reward: { coins: 15, xp: 8 },
    type: "daily",
  },
  {
    id: "post_feed",
    objective: "Post to the social feed",
    objectiveTh: "โพสต์ในฟีดโซเชียล",
    target: 1,
    reward: { coins: 25, xp: 15 },
    type: "daily",
  },
  {
    id: "enter_prediction",
    objective: "Enter a market prediction",
    objectiveTh: "เข้าร่วมการทำนายตลาด",
    target: 1,
    reward: { coins: 30, xp: 20 },
    type: "daily",
  },
  {
    id: "visit_plaza",
    objective: "Visit the public plaza",
    objectiveTh: "เยี่ยมชม Public Plaza",
    target: 1,
    reward: { coins: 10, xp: 5 },
    type: "daily",
  },
  {
    id: "check_portfolio",
    objective: "Check your portfolio",
    objectiveTh: "ดูพอร์ตโฟลิโอของคุณ",
    target: 1,
    reward: { coins: 12, xp: 6 },
    type: "daily",
  },
  {
    id: "complete_task",
    objective: "Complete an agent task",
    objectiveTh: "ทำภารกิจตัวแทนให้เสร็จ",
    target: 1,
    reward: { coins: 35, xp: 25 },
    type: "daily",
  },
];

const WEEKLY_TEMPLATES: QuestTemplate[] = [
  {
    id: "weekly_predictions",
    objective: "Enter 5 market predictions this week",
    objectiveTh: "เข้าร่วมทำนายตลาด 5 ครั้งในสัปดาห์นี้",
    target: 5,
    reward: { coins: 200, xp: 100 },
    type: "weekly",
  },
  {
    id: "weekly_agent_tasks",
    objective: "Complete 10 agent tasks this week",
    objectiveTh: "ทำภารกิจตัวแทนให้ครบ 10 ครั้งในสัปดาห์นี้",
    target: 10,
    reward: { coins: 300, xp: 150 },
    type: "weekly",
  },
  {
    id: "weekly_feed_posts",
    objective: "Post to the feed 3 times this week",
    objectiveTh: "โพสต์ในฟีด 3 ครั้งในสัปดาห์นี้",
    target: 3,
    reward: { coins: 150, xp: 80 },
    type: "weekly",
  },
  {
    id: "weekly_plaza_visits",
    objective: "Visit the plaza 5 times this week",
    objectiveTh: "เยี่ยมชม Plaza 5 ครั้งในสัปดาห์นี้",
    target: 5,
    reward: { coins: 100, xp: 60 },
    type: "weekly",
  },
];

// ── Seeded pseudo-random (same uid+dateStr = same picks) ──────────────────────
function seededRandom(seed: string): () => number {
  let h = 0;
  for (let i = 0; i < seed.length; i++) {
    h = (Math.imul(31, h) + seed.charCodeAt(i)) | 0;
  }
  return () => {
    h ^= h << 13;
    h ^= h >> 17;
    h ^= h << 5;
    return ((h >>> 0) / 0xffffffff);
  };
}

function pickN<T>(arr: T[], n: number, rng: () => number): T[] {
  const copy = [...arr];
  const result: T[] = [];
  while (result.length < n && copy.length > 0) {
    const idx = Math.floor(rng() * copy.length);
    result.push(copy.splice(idx, 1)[0]);
  }
  return result;
}

// ── Scheduled function ────────────────────────────────────────────────────────
export const generateDailyQuestsScheduled = onSchedule(
  {
    schedule: "1 0 * * *", // 00:01 every day
    timeZone: "Asia/Bangkok",
    region: "asia-southeast1",
    memory: "512MiB",
    timeoutSeconds: 540,
  },
  async () => {
    const now = new Date();
    const dateStr = now.toISOString().slice(0, 10); // "YYYY-MM-DD"
    const isMonday = now.getDay() === 1; // Monday = weekly reset

    logger.info(`[generateDailyQuests] date=${dateStr} isMonday=${isMonday}`);

    // Get all onboarded users
    const usersSnap = await db
      .collection("users")
      .where("onboardingComplete", "==", true)
      .select("uid") // Projection — fetch uid only
      .get();

    logger.info(`[generateDailyQuests] ${usersSnap.size} users to process`);

    let generated = 0;
    let skipped = 0;

    // Process in batches of 20
    const BATCH_SIZE = 20;
    const userDocs = usersSnap.docs;
    for (let i = 0; i < userDocs.length; i += BATCH_SIZE) {
      const batch = userDocs.slice(i, i + BATCH_SIZE);
      await Promise.all(
        batch.map(async (userDoc) => {
          const uid = userDoc.id;
          try {
            const didGenerate = await _generateForUser(uid, dateStr, isMonday);
            if (didGenerate) generated++;
            else skipped++;
          } catch (err) {
            logger.error(`[generateDailyQuests] Failed uid=${uid}:`, err);
          }
        })
      );
    }

    logger.info(
      `[generateDailyQuests] Done — generated: ${generated}, skipped: ${skipped}`
    );
  }
);

async function _generateForUser(
  uid: string,
  dateStr: string,
  isMonday: boolean
): Promise<boolean> {
  const settingsRef = db
    .collection("users")
    .doc(uid)
    .collection("settings")
    .doc("quests");

  const settingsSnap = await settingsRef.get();
  const lastDate = settingsSnap.data()?.lastQuestDate as string | undefined;

  // Already generated today
  if (lastDate === dateStr) return false;

  const rng = seededRandom(`${uid}:${dateStr}`);
  const picked = pickN(DAILY_TEMPLATES, 3, rng);

  // Expiry: end of today Bangkok time
  const expiry = new Date();
  expiry.setHours(23, 59, 59, 999);
  const expiryTs = Timestamp.fromDate(expiry);

  const writeBatch = db.batch();

  // Write 3 daily quests
  for (const template of picked) {
    const questRef = db
      .collection("quests")
      .doc(uid)
      .collection("active")
      .doc(`daily_${template.id}_${dateStr}`);
    writeBatch.set(questRef, {
      questId: `daily_${template.id}_${dateStr}`,
      type: "daily",
      objective: template.objective,
      objectiveTh: template.objectiveTh,
      reward: template.reward,
      progress: 0,
      target: template.target,
      completed: false,
      expiresAt: expiryTs,
      createdAt: FieldValue.serverTimestamp(),
    });
  }

  // Weekly quest on Mondays
  if (isMonday) {
    const weekRng = seededRandom(`${uid}:weekly:${dateStr}`);
    const weeklyPicked = pickN(WEEKLY_TEMPLATES, 1, weekRng)[0];
    const weekExpiry = new Date();
    weekExpiry.setDate(weekExpiry.getDate() + (7 - weekExpiry.getDay()));
    weekExpiry.setHours(23, 59, 59, 999);

    const weeklyRef = db
      .collection("quests")
      .doc(uid)
      .collection("active")
      .doc(`weekly_${weeklyPicked.id}_${dateStr}`);
    writeBatch.set(weeklyRef, {
      questId: `weekly_${weeklyPicked.id}_${dateStr}`,
      type: "weekly",
      objective: weeklyPicked.objective,
      objectiveTh: weeklyPicked.objectiveTh,
      reward: weeklyPicked.reward,
      progress: 0,
      target: weeklyPicked.target,
      completed: false,
      expiresAt: Timestamp.fromDate(weekExpiry),
      createdAt: FieldValue.serverTimestamp(),
    });
  }

  // Update settings
  writeBatch.set(settingsRef, { lastQuestDate: dateStr }, { merge: true });

  await writeBatch.commit();
  return true;
}
