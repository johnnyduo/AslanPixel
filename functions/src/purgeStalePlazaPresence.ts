/**
 * purgeStalePlazaPresence
 *
 * Scheduled: every 2 minutes.
 * Removes plaza presence entries older than 3 minutes (user left/disconnected).
 *
 * Plaza presence path: plazaPresence/{uid}
 * Fields: uid, displayName, avatarId, x, y, lastSeen: Timestamp
 */

import { onSchedule } from "firebase-functions/v2/scheduler";
import { Timestamp } from "firebase-admin/firestore";
import { db } from "./admin";
import { logger } from "firebase-functions";

const STALE_THRESHOLD_MS = 3 * 60 * 1000; // 3 minutes

export const purgeStalePlazaPresence = onSchedule(
  {
    schedule: "every 2 minutes",
    timeZone: "Asia/Bangkok",
    region: "asia-southeast1",
    memory: "256MiB",
  },
  async () => {
    const cutoff = Timestamp.fromMillis(Date.now() - STALE_THRESHOLD_MS);

    const staleSnap = await db
      .collection("plazaPresence")
      .where("lastSeen", "<", cutoff)
      .limit(200)
      .get();

    if (staleSnap.empty) {
      logger.debug("[purgeStalePlazaPresence] Nothing to purge");
      return;
    }

    // Batch delete
    const batches: FirebaseFirestore.WriteBatch[] = [];
    let current = db.batch();
    let count = 0;

    for (const doc of staleSnap.docs) {
      current.delete(doc.ref);
      count++;
      if (count % 500 === 0) {
        batches.push(current);
        current = db.batch();
      }
    }
    batches.push(current);

    await Promise.all(batches.map((b) => b.commit()));
    logger.info(`[purgeStalePlazaPresence] Purged ${staleSnap.size} stale presence entries`);
  }
);
