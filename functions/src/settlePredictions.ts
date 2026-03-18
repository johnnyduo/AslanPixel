/**
 * settlePredictions
 *
 * Triggered: Firestore onWrite on predictionEvents/{eventId}
 *   when status changes to "settled" and correctOptionId is set.
 *
 * Also exposed as a callable for admin manual settlement.
 *
 * Logic:
 *   1. Query all entries for this event
 *   2. Determine winners (selectedOptionId == correctOptionId)
 *   3. Calculate reward = coinStaked × WIN_MULTIPLIER (losers refund 0)
 *   4. For each winner: transaction — update entry, credit economy, write feed post
 *   5. Post a system feed post announcing results
 *   6. Idempotent: skip entries where result is already set
 */

import { onDocumentWritten } from "firebase-functions/v2/firestore";
import { onCall, HttpsError } from "firebase-functions/v2/https";
import { FieldValue } from "firebase-admin/firestore";
import { db } from "./admin";
import { PredictionEvent, PredictionEntry } from "./types";
import { logger } from "firebase-functions";

const WIN_MULTIPLIER = 2.0; // Winner gets 2× their stake back

// ── Firestore trigger ─────────────────────────────────────────────────────────
export const settlePredictionsOnWrite = onDocumentWritten(
  {
    document: "predictionEvents/{eventId}",
    region: "asia-southeast1",
    memory: "512MiB",
  },
  async (event) => {
    const after = event.data?.after.data() as PredictionEvent | undefined;
    const before = event.data?.before.data() as PredictionEvent | undefined;

    // Only process when status changes TO "settled"
    if (
      !after ||
      after.status !== "settled" ||
      before?.status === "settled" ||
      !after.correctOptionId
    ) {
      return;
    }

    logger.info(`[settlePredictions] Settling event ${after.eventId}`);
    await _settleEvent(after.eventId, after);
  }
);

// ── Admin callable ────────────────────────────────────────────────────────────
export const settlePredictionCallable = onCall(
  { region: "asia-southeast1" },
  async (request) => {
    // Admin only
    const uid = request.auth?.uid;
    if (!uid) throw new HttpsError("unauthenticated", "Must be authenticated");

    const userDoc = await db.collection("users").doc(uid).get();
    if (userDoc.data()?.role !== "ADMIN") {
      throw new HttpsError("permission-denied", "Admin only");
    }

    const { eventId, correctOptionId } = request.data as {
      eventId: string;
      correctOptionId: string;
    };
    if (!eventId || !correctOptionId) {
      throw new HttpsError("invalid-argument", "eventId and correctOptionId required");
    }

    const eventRef = db.collection("predictionEvents").doc(eventId);
    const eventSnap = await eventRef.get();
    if (!eventSnap.exists) throw new HttpsError("not-found", "Event not found");

    const eventData = eventSnap.data() as PredictionEvent;
    if (eventData.status === "settled") {
      throw new HttpsError("already-exists", "Event already settled");
    }

    // Mark settled — will trigger the Firestore onWrite above
    await eventRef.update({
      status: "settled",
      correctOptionId,
      settledAt: FieldValue.serverTimestamp(),
    });

    return { success: true };
  }
);

// ── Core settlement logic ─────────────────────────────────────────────────────
async function _settleEvent(eventId: string, event: PredictionEvent) {
  // Collect all entries via collection group
  const entriesSnap = await db
    .collectionGroup("entries")
    .where("eventId", "==", eventId)
    .where("result", "==", null)
    .get();

  if (entriesSnap.empty) {
    logger.info(`[settlePredictions] No entries for event ${eventId}`);
    return;
  }

  logger.info(`[settlePredictions] Processing ${entriesSnap.size} entries`);

  let winners = 0;
  let totalRewardPaid = 0;

  for (const entryDoc of entriesSnap.docs) {
    const entry = entryDoc.data() as PredictionEntry;
    if (entry.result) continue; // Already settled

    const isWinner = entry.selectedOptionId === event.correctOptionId;
    const rewardGranted = isWinner
      ? Math.round(entry.coinStaked * WIN_MULTIPLIER)
      : 0;

    const economyRef = db
      .collection("users")
      .doc(entry.uid)
      .collection("economy")
      .doc("balance");
    const txLogRef = db
      .collection("users")
      .doc(entry.uid)
      .collection("economy")
      .doc("balance")
      .collection("transactions")
      .doc();

    try {
      await db.runTransaction(async (txn) => {
        const snap = await txn.get(entryDoc.ref);
        if (!snap.exists || snap.data()?.result) return; // Already done

        // Update entry result
        txn.update(entryDoc.ref, {
          result: isWinner ? "win" : "loss",
          rewardGranted,
          settledAt: FieldValue.serverTimestamp(),
        });

        if (isWinner && rewardGranted > 0) {
          // Credit winner
          txn.set(
            economyRef,
            {
              coins: FieldValue.increment(rewardGranted),
              lastUpdated: FieldValue.serverTimestamp(),
            },
            { merge: true }
          );

          txn.set(txLogRef, {
            type: "credit",
            amount: rewardGranted,
            reason: "prediction_win",
            eventId,
            entryId: entry.entryId,
            timestamp: FieldValue.serverTimestamp(),
          });
        }
      });

      if (isWinner) {
        winners++;
        totalRewardPaid += rewardGranted;
      }
    } catch (err) {
      logger.error(`[settlePredictions] Failed entry ${entry.entryId}:`, err);
    }
  }

  // Post system feed announcement
  await _postSettlementFeed(event, winners, totalRewardPaid);

  logger.info(
    `[settlePredictions] Event ${eventId} settled — winners: ${winners}, paid: ${totalRewardPaid} coins`
  );
}

async function _postSettlementFeed(
  event: PredictionEvent,
  winners: number,
  totalPaid: number
) {
  const correctOption = event.options.find(
    (o) => o.optionId === event.correctOptionId
  );

  await db.collection("feedPosts").add({
    type: "prediction",
    authorUid: null,
    content: `🎯 Prediction settled: ${event.title} — ${winners} winner(s) shared ${totalPaid} coins`,
    contentTh: `🎯 ผลการทำนาย: ${event.titleTh} — ผู้ชนะ ${winners} คน รับ ${totalPaid} เหรียญ`,
    metadata: {
      eventId: event.eventId,
      correctOptionId: event.correctOptionId,
      correctOptionLabel: correctOption?.label ?? "",
      correctOptionLabelTh: correctOption?.labelTh ?? "",
      winners,
      totalPaid,
    },
    createdAt: FieldValue.serverTimestamp(),
    reactions: {},
  });
}
