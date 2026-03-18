/**
 * Aslan Pixel — Cloud Functions Entry Point
 *
 * All functions deployed to region: asia-southeast1 (Singapore)
 * Runtime: Node.js 22
 *
 * Function inventory:
 * ── Scheduled ──────────────────────────────────────────────────────────────
 *   settleIdleTasks             every 5 minutes — settle completed agent tasks
 *   generateDailyQuestsScheduled daily 00:01 BKK — generate daily/weekly quests
 *   recalculateRankings         every hour — update leaderboards
 *   purgeStalePlazaPresence     every 2 minutes — clean up disconnected plaza users
 *
 * ── Firestore Triggers ──────────────────────────────────────────────────────
 *   settlePredictionsOnWrite    predictionEvents/{eventId} onWrite
 *   checkBadgesOnTaskSettle     agentTasks/{uid}/tasks/{taskId} onWrite
 *   checkBadgesOnPredictionSettle userEntries/{uid}/entries/{entryId} onWrite
 *   checkBadgesOnBrokerConnect  brokerConnections/{uid} onWrite
 *
 * ── Callable (HTTPS) ────────────────────────────────────────────────────────
 *   getAiInsight                Generate AI insight (cached, Gemini)
 *   composeFeedCaption          Generate feed caption text (Gemini)
 *   syncPortfolio               Fetch portfolio from broker (server-proxied)
 *   connectBroker               Connect broker account (stores encrypted token)
 *   submitOrder                 Submit buy/sell order via broker API
 *   settlePredictionCallable    Admin: manually settle a prediction event
 *   checkAndGrantBadgeCallable  Client: trigger badge check
 */

export { settleIdleTasks } from "./settleIdleTasks";

export { generateDailyQuestsScheduled } from "./generateDailyQuests";

export { recalculateRankings } from "./recalculateRankings";

export { purgeStalePlazaPresence } from "./purgeStalePlazaPresence";

export {
  settlePredictionsOnWrite,
  settlePredictionCallable,
} from "./settlePredictions";

export {
  checkBadgesOnTaskSettle,
  checkBadgesOnPredictionSettle,
  checkBadgesOnBrokerConnect,
  checkAndGrantBadgeCallable,
} from "./grantBadge";

export { getAiInsight } from "./getAiInsight";

export { composeFeedCaption } from "./composeFeedCaption";

export { syncPortfolio, connectBroker } from "./syncPortfolio";

export { submitOrder } from "./submitOrder";
