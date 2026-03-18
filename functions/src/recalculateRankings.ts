/**
 * recalculateRankings
 *
 * Scheduled: every hour.
 * Reads all users, computes scores, writes to leaderboards/{type}/entries (ordered array).
 *
 * Ranking types:
 *   overall  — composite: level×100 + coins×0.1 + xp×0.05
 *   coins    — total coins
 *   level    — economy level (xp/1000 + 1)
 *   prediction_accuracy — wins / total entries (min 5 entries)
 *
 * Writes:
 *   leaderboards/{type} → { updatedAt, entries: [{rank, uid, displayName, avatarId, score}] }
 *   users/{uid} → { rank_{type}: number } (denormalized for quick display)
 */

import { onSchedule } from "firebase-functions/v2/scheduler";
import { FieldValue } from "firebase-admin/firestore";
import { db } from "./admin";
import { logger } from "firebase-functions";

interface LeaderboardEntry {
  rank: number;
  uid: string;
  displayName: string;
  avatarId: string;
  score: number;
  level?: number;
  coins?: number;
}

export const recalculateRankings = onSchedule(
  {
    schedule: "0 * * * *", // top of every hour
    timeZone: "Asia/Bangkok",
    region: "asia-southeast1",
    memory: "1GiB",
    timeoutSeconds: 540,
  },
  async () => {
    logger.info("[recalculateRankings] Starting");

    // Query users collection, then batch-fetch economy balances
    const usersSnap = await db
      .collection("users")
      .where("onboardingComplete", "==", true)
      .select("uid", "displayName", "avatarId")
      .get();

    if (usersSnap.empty) {
      logger.info("[recalculateRankings] No users");
      return;
    }

    logger.info(`[recalculateRankings] Processing ${usersSnap.size} users`);

    // Batch-fetch economy balances
    const BATCH = 20;
    const userEntries: Array<{
      uid: string;
      displayName: string;
      avatarId: string;
      coins: number;
      xp: number;
      level: number;
    }> = [];

    for (let i = 0; i < usersSnap.docs.length; i += BATCH) {
      const batch = usersSnap.docs.slice(i, i + BATCH);
      const balanceRefs = batch.map((d) =>
        db.collection("users").doc(d.id).collection("economy").doc("balance")
      );
      const balanceSnaps = await db.getAll(...balanceRefs);

      for (let j = 0; j < batch.length; j++) {
        const userDoc = batch[j];
        const balSnap = balanceSnaps[j];
        const bal = balSnap.data() ?? { coins: 0, xp: 0 };
        const coins = (bal.coins as number) ?? 0;
        const xp = (bal.xp as number) ?? 0;
        const level = Math.floor(xp / 1000) + 1;

        userEntries.push({
          uid: userDoc.id,
          displayName: (userDoc.data().displayName as string) ?? "Player",
          avatarId: (userDoc.data().avatarId as string) ?? "A1",
          coins,
          xp,
          level,
        });
      }
    }

    // ── Compute and write each ranking type ───────────────────────────────────

    // 1. Overall
    const overall = [...userEntries]
      .map((u) => ({
        ...u,
        score: u.level * 100 + u.coins * 0.1 + u.xp * 0.05,
      }))
      .sort((a, b) => b.score - a.score)
      .slice(0, 100);

    await _writeLeaderboard("overall", overall);

    // 2. Coins
    const coinsRanking = [...userEntries]
      .map((u) => ({ ...u, score: u.coins }))
      .sort((a, b) => b.score - a.score)
      .slice(0, 100);

    await _writeLeaderboard("coins", coinsRanking);

    // 3. Level
    const levelRanking = [...userEntries]
      .map((u) => ({ ...u, score: u.level * 1000 + u.xp }))
      .sort((a, b) => b.score - a.score)
      .slice(0, 100);

    await _writeLeaderboard("level", levelRanking);

    // 4. Prediction accuracy (async — query entries)
    await _computePredictionRanking(usersSnap.docs.map((d) => ({
      uid: d.id,
      displayName: (d.data().displayName as string) ?? "Player",
      avatarId: (d.data().avatarId as string) ?? "A1",
    })));

    // Write rank back to user docs (top 100 only)
    await _denormalizeRanks("overall", overall);

    logger.info("[recalculateRankings] Done");
  }
);

async function _writeLeaderboard(
  type: string,
  sorted: Array<{ uid: string; displayName: string; avatarId: string; score: number; level?: number; coins?: number }>
) {
  const entries: LeaderboardEntry[] = sorted.map((u, i) => ({
    rank: i + 1,
    uid: u.uid,
    displayName: u.displayName,
    avatarId: u.avatarId,
    score: Math.round(u.score),
    level: u.level,
    coins: u.coins,
  }));

  await db.collection("leaderboards").doc(type).set({
    type,
    entries,
    totalEntries: entries.length,
    updatedAt: FieldValue.serverTimestamp(),
  });

  logger.debug(`[recalculateRankings] Wrote ${type} leaderboard (${entries.length} entries)`);
}

async function _denormalizeRanks(
  type: string,
  sorted: Array<{ uid: string }>
) {
  const writeBatch = db.batch();
  sorted.forEach((u, i) => {
    const ref = db.collection("users").doc(u.uid);
    writeBatch.set(ref, { [`rank_${type}`]: i + 1 }, { merge: true });
  });
  await writeBatch.commit();
}

async function _computePredictionRanking(
  users: Array<{ uid: string; displayName: string; avatarId: string }>
) {
  const MIN_ENTRIES = 5;

  const scored: Array<{
    uid: string; displayName: string; avatarId: string; score: number; accuracy: number; total: number
  }> = [];

  for (const user of users) {
    const entriesSnap = await db
      .collection("userEntries")
      .doc(user.uid)
      .collection("entries")
      .where("result", "in", ["win", "loss"])
      .select("result")
      .get();

    if (entriesSnap.size < MIN_ENTRIES) continue;

    const wins = entriesSnap.docs.filter((d) => d.data().result === "win").length;
    const accuracy = wins / entriesSnap.size;

    scored.push({
      ...user,
      score: Math.round(accuracy * 1000),
      accuracy,
      total: entriesSnap.size,
    });
  }

  scored.sort((a, b) => b.score - a.score);
  const top100 = scored.slice(0, 100);

  if (top100.length > 0) {
    await _writeLeaderboard("prediction_accuracy", top100);
  }
}
