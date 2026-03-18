/**
 * grantBadge
 *
 * Firestore trigger: onWrite on various collections.
 * Also callable for explicit badge checks.
 *
 * Badge definitions — checked server-side, never client-controllable.
 * Badges are idempotent: once granted, cannot be granted again.
 *
 * Badge paths: users/{uid}/badges/{badgeId}
 * Feed post: created on grant for social visibility
 */

import { onDocumentWritten } from "firebase-functions/v2/firestore";
import { onCall } from "firebase-functions/v2/https";
import { FieldValue } from "firebase-admin/firestore";
import { db } from "./admin";
import { logger } from "firebase-functions";

export interface BadgeDefinition {
  badgeId: string;
  name: string;
  nameTh: string;
  description: string;
  descriptionTh: string;
  iconKey: string;
  rarity: "common" | "rare" | "epic" | "legendary";
  bonusCoins: number;
  bonusXp: number;
}

export const BADGES: BadgeDefinition[] = [
  {
    badgeId: "first_agent_task",
    name: "First Mission",
    nameTh: "ภารกิจแรก",
    description: "Complete your first agent task",
    descriptionTh: "ทำภารกิจตัวแทนครั้งแรก",
    iconKey: "badge_mission",
    rarity: "common",
    bonusCoins: 50,
    bonusXp: 25,
  },
  {
    badgeId: "first_prediction",
    name: "Oracle Initiate",
    nameTh: "นักทำนายมือใหม่",
    description: "Enter your first market prediction",
    descriptionTh: "เข้าร่วมทำนายตลาดครั้งแรก",
    iconKey: "badge_oracle",
    rarity: "common",
    bonusCoins: 30,
    bonusXp: 20,
  },
  {
    badgeId: "first_win",
    name: "First Win",
    nameTh: "ชนะครั้งแรก",
    description: "Win your first market prediction",
    descriptionTh: "ชนะการทำนายตลาดครั้งแรก",
    iconKey: "badge_win",
    rarity: "rare",
    bonusCoins: 100,
    bonusXp: 50,
  },
  {
    badgeId: "agent_level_5",
    name: "Veteran Analyst",
    nameTh: "นักวิเคราะห์ผู้ช่ำชอง",
    description: "Reach agent level 5",
    descriptionTh: "ยกระดับตัวแทนถึงระดับ 5",
    iconKey: "badge_veteran",
    rarity: "rare",
    bonusCoins: 200,
    bonusXp: 100,
  },
  {
    badgeId: "economy_level_10",
    name: "Market Master",
    nameTh: "เจ้าแห่งตลาด",
    description: "Reach economy level 10",
    descriptionTh: "ยกระดับเศรษฐกิจถึงระดับ 10",
    iconKey: "badge_master",
    rarity: "epic",
    bonusCoins: 500,
    bonusXp: 250,
  },
  {
    badgeId: "top_rank_weekly",
    name: "Top Rank Weekly",
    nameTh: "อันดับ 1 รายสัปดาห์",
    description: "Reach #1 on the weekly leaderboard",
    descriptionTh: "ติดอันดับ 1 ในลีดเดอร์บอร์ดประจำสัปดาห์",
    iconKey: "badge_top",
    rarity: "legendary",
    bonusCoins: 1000,
    bonusXp: 500,
  },
  {
    badgeId: "broker_connected",
    name: "Market Link",
    nameTh: "เชื่อมต่อตลาด",
    description: "Connect a real broker account",
    descriptionTh: "เชื่อมต่อบัญชีโบรกเกอร์จริง",
    iconKey: "badge_broker",
    rarity: "rare",
    bonusCoins: 150,
    bonusXp: 75,
  },
];

const BADGE_MAP = new Map(BADGES.map((b) => [b.badgeId, b]));

// ── Agent task trigger ────────────────────────────────────────────────────────
export const checkBadgesOnTaskSettle = onDocumentWritten(
  {
    document: "agentTasks/{uid}/tasks/{taskId}",
    region: "asia-southeast1",
  },
  async (event) => {
    const after = event.data?.after.data();
    const before = event.data?.before.data();
    if (!after?.isSettled || before?.isSettled) return;

    const uid = event.params.uid;
    await _checkAndGrant(uid, "first_agent_task");
  }
);

// ── Prediction win trigger ────────────────────────────────────────────────────
export const checkBadgesOnPredictionSettle = onDocumentWritten(
  {
    document: "userEntries/{uid}/entries/{entryId}",
    region: "asia-southeast1",
  },
  async (event) => {
    const after = event.data?.after.data();
    const before = event.data?.before.data();
    if (!after?.result || before?.result) return;

    const uid = event.params.uid;
    await _checkAndGrant(uid, "first_prediction");
    if (after.result === "win") {
      await _checkAndGrant(uid, "first_win");
    }
  }
);

// ── Broker connected trigger ──────────────────────────────────────────────────
export const checkBadgesOnBrokerConnect = onDocumentWritten(
  {
    document: "brokerConnections/{uid}",
    region: "asia-southeast1",
  },
  async (event) => {
    const after = event.data?.after.data();
    if (!after?.isActive) return;

    const uid = event.params.uid;
    await _checkAndGrant(uid, "broker_connected");
  }
);

// ── Callable for manual check ─────────────────────────────────────────────────
export const checkAndGrantBadgeCallable = onCall(
  { region: "asia-southeast1" },
  async (request) => {
    const uid = request.auth?.uid;
    if (!uid) return;

    const { badgeId } = request.data as { badgeId: string };
    if (!badgeId) return;

    await _checkAndGrant(uid, badgeId);
    return { success: true };
  }
);

// ── Core grant logic ──────────────────────────────────────────────────────────
async function _checkAndGrant(uid: string, badgeId: string): Promise<void> {
  const def = BADGE_MAP.get(badgeId);
  if (!def) return;

  const badgeRef = db
    .collection("users")
    .doc(uid)
    .collection("badges")
    .doc(badgeId);

  await db.runTransaction(async (txn) => {
    const snap = await txn.get(badgeRef);
    if (snap.exists) return; // Already granted

    const economyRef = db
      .collection("users")
      .doc(uid)
      .collection("economy")
      .doc("balance");
    const txLogRef = db
      .collection("users")
      .doc(uid)
      .collection("economy")
      .doc("balance")
      .collection("transactions")
      .doc();

    // Grant badge
    txn.set(badgeRef, {
      badgeId,
      name: def.name,
      nameTh: def.nameTh,
      iconKey: def.iconKey,
      rarity: def.rarity,
      grantedAt: FieldValue.serverTimestamp(),
    });

    // Bonus rewards
    if (def.bonusCoins > 0 || def.bonusXp > 0) {
      txn.set(
        economyRef,
        {
          coins: FieldValue.increment(def.bonusCoins),
          xp: FieldValue.increment(def.bonusXp),
          lastUpdated: FieldValue.serverTimestamp(),
        },
        { merge: true }
      );

      txn.set(txLogRef, {
        type: "credit",
        amount: def.bonusCoins,
        xp: def.bonusXp,
        reason: "badge_reward",
        badgeId,
        timestamp: FieldValue.serverTimestamp(),
      });
    }
  });

  // Post to feed (outside transaction — non-critical)
  try {
    await db.collection("feedPosts").add({
      type: "achievement",
      authorUid: uid,
      content: `🏆 Earned badge: ${def.name}`,
      contentTh: `🏆 ได้รับตรา: ${def.nameTh}`,
      metadata: { badgeId, rarity: def.rarity, bonusCoins: def.bonusCoins },
      createdAt: FieldValue.serverTimestamp(),
      reactions: {},
    });
    logger.info(`[grantBadge] Granted ${badgeId} to uid=${uid}`);
  } catch (err) {
    logger.warn(`[grantBadge] Feed post failed for ${badgeId}:`, err);
  }
}
