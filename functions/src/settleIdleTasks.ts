/**
 * settleIdleTasks
 *
 * Scheduled: every 5 minutes via Cloud Scheduler.
 * Scans all agentTasks/{uid}/tasks where isSettled=false AND completesAt <= now.
 * Settles each task in a Firestore transaction:
 *   - Sets isSettled=true, actualReward, settledAt on the task doc
 *   - Credits coins + xp to users/{uid}/economy/balance
 *   - Updates agent status back to idle
 *   - Clears agent.activeTaskId
 *
 * Safety: idempotent — tasks already settled are skipped.
 */

import { onSchedule } from "firebase-functions/v2/scheduler";
import { FieldValue, Timestamp } from "firebase-admin/firestore";
import { db } from "./admin";
import { AgentTask, calcTaskReward, calcXpReward } from "./types";
import { logger } from "firebase-functions";

export const settleIdleTasks = onSchedule(
  {
    schedule: "every 5 minutes",
    timeZone: "Asia/Bangkok",
    region: "asia-southeast1",
    memory: "256MiB",
  },
  async () => {
    const now = Timestamp.now();
    logger.info("[settleIdleTasks] Running at", now.toDate().toISOString());

    // Collection group query — finds all tasks across all users
    const overdueTasks = await db
      .collectionGroup("tasks")
      .where("isSettled", "==", false)
      .where("completesAt", "<=", now)
      .limit(500)
      .get();

    if (overdueTasks.empty) {
      logger.info("[settleIdleTasks] No tasks to settle");
      return;
    }

    logger.info(`[settleIdleTasks] Settling ${overdueTasks.size} tasks`);
    let settled = 0;
    let failed = 0;

    // Batch settlements — parallel with concurrency cap
    const CONCURRENCY = 10;
    const docs = overdueTasks.docs;
    for (let i = 0; i < docs.length; i += CONCURRENCY) {
      const batch = docs.slice(i, i + CONCURRENCY);
      await Promise.all(batch.map((doc) => settleOne(doc)));
    }

    logger.info(`[settleIdleTasks] Done — settled: ${settled}, failed: ${failed}`);

    async function settleOne(doc: FirebaseFirestore.QueryDocumentSnapshot) {
      // Extract uid from path: agentTasks/{uid}/tasks/{taskId}
      const pathParts = doc.ref.path.split("/");
      const uid = pathParts[1];
      const task = doc.data() as AgentTask;

      if (task.isSettled) return; // Already settled (race condition guard)

      const actualReward = calcTaskReward(task.baseReward, task.agentLevel);
      const xpReward = calcXpReward(actualReward);
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
      const agentRef = db
        .collection("users")
        .doc(uid)
        .collection("agents")
        .doc(task.agentId);

      try {
        await db.runTransaction(async (txn) => {
          const taskSnap = await txn.get(doc.ref);
          if (!taskSnap.exists) return;
          const current = taskSnap.data() as AgentTask;
          if (current.isSettled) return; // Another instance beat us

          // 1. Mark task settled
          txn.update(doc.ref, {
            isSettled: true,
            actualReward,
            settledAt: FieldValue.serverTimestamp(),
          });

          // 2. Credit economy
          txn.set(
            economyRef,
            {
              coins: FieldValue.increment(actualReward),
              xp: FieldValue.increment(xpReward),
              lastUpdated: FieldValue.serverTimestamp(),
            },
            { merge: true }
          );

          // 3. Transaction log
          txn.set(txLogRef, {
            type: "credit",
            amount: actualReward,
            xp: xpReward,
            reason: "task_settlement",
            taskId: task.taskId,
            agentId: task.agentId,
            tier: task.tier,
            taskType: task.taskType,
            timestamp: FieldValue.serverTimestamp(),
          });

          // 4. Agent → celebrating → will revert to idle on next client sync
          txn.update(agentRef, {
            status: "celebrating",
            activeTaskId: null,
            taskCompletesAt: null,
          });
        });
        settled++;
        logger.debug(`[settleIdleTasks] Settled task ${task.taskId} (+${actualReward} coins, +${xpReward} xp) for uid=${uid}`);
      } catch (err) {
        failed++;
        logger.error(`[settleIdleTasks] Failed task ${task.taskId} uid=${uid}:`, err);
      }
    }
  }
);
