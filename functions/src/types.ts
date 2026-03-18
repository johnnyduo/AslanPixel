// ── Shared types mirroring Flutter models ─────────────────────────────────────

export type AgentType = "analyst" | "scout" | "risk" | "social";
export type AgentStatus = "idle" | "working" | "returning" | "celebrating" | "fail";
export type TaskType = "research" | "scoutMission" | "analysis" | "socialScan";
export type TaskTier = "basic" | "standard" | "advanced" | "elite";

export interface AgentTask {
  taskId: string;
  agentId: string;
  agentType: AgentType;
  taskType: TaskType;
  tier: TaskTier;
  startedAt: FirebaseFirestore.Timestamp;
  completesAt: FirebaseFirestore.Timestamp;
  baseReward: number;
  xpReward: number;
  agentLevel: number;
  isSettled: boolean;
  actualReward?: number;
  settledAt?: FirebaseFirestore.Timestamp;
}

export interface EconomyBalance {
  coins: number;
  xp: number;
  unlockPoints: number;
  lastUpdated: FirebaseFirestore.Timestamp;
}

export interface PredictionEvent {
  eventId: string;
  symbol: string;
  title: string;
  titleTh: string;
  options: Array<{ optionId: string; label: string; labelTh: string }>;
  coinCost: number;
  settlementAt: FirebaseFirestore.Timestamp;
  settlementRule: "above" | "below" | "exact";
  status: "open" | "closed" | "settled";
  correctOptionId?: string;
  context?: string;
  createdAt: FirebaseFirestore.Timestamp;
}

export interface PredictionEntry {
  entryId: string;
  eventId: string;
  uid: string;
  selectedOptionId: string;
  coinStaked: number;
  enteredAt: FirebaseFirestore.Timestamp;
  result?: "win" | "loss";
  rewardGranted: number;
}

export interface QuestReward {
  coins: number;
  xp: number;
  itemId?: string;
}

export interface QuestModel {
  questId: string;
  type: "daily" | "weekly" | "achievement";
  objective: string;
  objectiveTh: string;
  reward: QuestReward;
  progress: number;
  target: number;
  completed: boolean;
  expiresAt?: FirebaseFirestore.Timestamp;
}

export interface FeedPost {
  postId: string;
  type: "system" | "user" | "achievement" | "prediction" | "ranking";
  authorUid?: string;
  content: string;
  contentTh?: string;
  metadata: Record<string, unknown>;
  createdAt: FirebaseFirestore.Timestamp;
  reactions: Record<string, number>;
}

// ── Reward constants matching IdleTaskEngine ─────────────────────────────────

export const TIER_BASE_REWARDS: Record<TaskTier, number> = {
  basic: 10,
  standard: 50,
  advanced: 200,
  elite: 800,
};

export const TIER_DURATIONS_MS: Record<TaskTier, number> = {
  basic: 5 * 60 * 1000,
  standard: 30 * 60 * 1000,
  advanced: 2 * 60 * 60 * 1000,
  elite: 8 * 60 * 60 * 1000,
};

export function calcTaskReward(baseReward: number, agentLevel: number): number {
  const multiplier = 1.0 + agentLevel * 0.05;
  return Math.round(baseReward * multiplier);
}

export function calcXpReward(finalReward: number): number {
  return Math.round(finalReward * 0.5);
}
