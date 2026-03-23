export interface Agent {
  id: string;
  name: string;
  fullName: string;
  role: string;
  trait: string;
  color: string;
  glowColor: string;
  icon: string;
  initials: string;
  gradientClass: string;
  quote: string;
  philosophy: string;
  confidence: number;
  reputation: number;
  completedQuests: number;
  successRate: number;
  specialization: string;
  status: "active" | "idle" | "executing" | "standby";
  animIndex: number;
  homeRoom: string;
  recentActions: { action: string; time: string; type: string }[];
}

export const AGENTS: Agent[] = [
  {
    id: "scout",
    name: "Nexus",
    fullName: "Nexus",
    role: "HCS Intelligence",
    trait: "Relentless · Signal-First",
    color: "hsl(195 100% 55%)",
    glowColor: "hsl(195 100% 55% / 0.2)",
    icon: "◈",
    initials: "NX",
    gradientClass: "from-cyan-500 to-blue-600",
    quote: "Every consensus event is a clue. I read the ledger in real-time.",
    philosophy: "Data is never noise — only unread signal. I cross-reference HCS topic streams, consensus timestamps, and sequence numbers before any conclusion.",
    confidence: 91,
    reputation: 5,
    completedQuests: 318,
    successRate: 97,
    specialization: "Hedera Consensus Service",
    status: "executing",
    animIndex: 1,
    homeRoom: "tokenforge",
    recentActions: [
      { action: "Subscribed HCS Topic #0.0.1234 — 847 msgs/min ingested", time: "1m ago", type: "tool_call" },
      { action: "Detected sequence gap at msg #4,192 — anomaly flagged", time: "4m ago", type: "alert" },
      { action: "Mapped consensus timestamp skew across 3 mirror nodes", time: "9m ago", type: "analysis" },
    ],
  },
  {
    id: "strategist",
    name: "Oryn",
    fullName: "Oryn",
    role: "Strategy Engine",
    trait: "Calculated · Multi-path",
    color: "hsl(43 90% 60%)",
    glowColor: "hsl(43 90% 60% / 0.2)",
    icon: "▲",
    initials: "OR",
    gradientClass: "from-yellow-400 to-amber-600",
    quote: "I model every outcome before the first byte hits the network.",
    philosophy: "I build structured multi-step plans with probability weights on each branch. No EVM call without a fallback. No goal without measurable criteria on-chain.",
    confidence: 88,
    reputation: 5,
    completedQuests: 241,
    successRate: 95,
    specialization: "Smart Contract Strategy",
    status: "active",
    animIndex: 2,
    homeRoom: "smartspire",
    recentActions: [
      { action: "Modeled 3-branch EVM strategy — confidence: 87%", time: "2m ago", type: "proposal" },
      { action: "Evaluated contract 0x00000000000000000000000000000000004f89a2", time: "6m ago", type: "analysis" },
      { action: "Proposed HTS yield split: 40% stake / 35% LP / 25% reserve", time: "14m ago", type: "proposal" },
    ],
  },
  {
    id: "sentinel",
    name: "Drax",
    fullName: "Drax",
    role: "Risk Sentinel",
    trait: "Vigilant · Zero-Tolerance",
    color: "hsl(142 70% 50%)",
    glowColor: "hsl(142 70% 50% / 0.2)",
    icon: "◆",
    initials: "DX",
    gradientClass: "from-green-500 to-emerald-700",
    quote: "Nothing passes without passing me first. That's the policy.",
    philosophy: "Every transaction passes my criteria: max drawdown, concentration limits, smart contract audit hash. If it fails any — it doesn't go through.",
    confidence: 96,
    reputation: 5,
    completedQuests: 509,
    successRate: 99,
    specialization: "Policy Enforcement",
    status: "active",
    animIndex: 3,
    homeRoom: "consensushub",
    recentActions: [
      { action: "Slippage cap enforced: 0.25% max — route cleared at 0.12%", time: "30s ago", type: "alert" },
      { action: "Audit hash 0xf3a1…verified via Quantstamp registry", time: "3m ago", type: "verification" },
      { action: "Policy: 5% max position limit enforced on HTS token #0.0.887432", time: "7m ago", type: "policy" },
    ],
  },
  {
    id: "treasurer",
    name: "Lyss",
    fullName: "Lyss",
    role: "Treasury Keeper",
    trait: "Precise · Immovable",
    color: "hsl(280 65% 68%)",
    glowColor: "hsl(280 65% 68% / 0.2)",
    icon: "◉",
    initials: "LY",
    gradientClass: "from-purple-500 to-violet-700",
    quote: "Every tinyhbar accounted for. The treasury never lies.",
    philosophy: "I own the HTS treasury state at all times. Every HBAR, every token, every pending TX is accounted for in tinyhbar. I never commit more than the risk-adjusted budget allows.",
    confidence: 94,
    reputation: 4,
    completedQuests: 187,
    successRate: 98,
    specialization: "HTS Token Management",
    status: "standby",
    animIndex: 4,
    homeRoom: "mirrorvault",
    recentActions: [
      { action: "Reserved 500 HBAR (50,000,000,000 tinyhbar) for gas buffer", time: "5m ago", type: "allocation" },
      { action: "Reconciled HTS portfolio: 12,847.50 HBAR across 4 token IDs", time: "11m ago", type: "analysis" },
      { action: "Blocked over-allocation — HTS token #0.0.731861 at cap", time: "18m ago", type: "policy" },
    ],
  },
  {
    id: "executor",
    name: "Vex",
    fullName: "Vex",
    role: "TX Executor",
    trait: "Fast · Methodical",
    color: "hsl(38 92% 55%)",
    glowColor: "hsl(38 92% 55% / 0.2)",
    icon: "▶",
    initials: "VX",
    gradientClass: "from-orange-400 to-red-600",
    quote: "Simulate, sign, submit. In that order. Every time.",
    philosophy: "Once approved, I execute with precision: simulate on Hedera EVM, check gas in tinyhbar, confirm nonce, submit, monitor via mirror node. I never skip steps.",
    confidence: 99,
    reputation: 4,
    completedQuests: 412,
    successRate: 96,
    specialization: "EVM Execution",
    status: "idle",
    animIndex: 5,
    homeRoom: "dexgate",
    recentActions: [
      { action: "TX 0.0.1234@1711234567.000000000 — 100 HBAR swap — CONFIRMED slot 4,192,441", time: "2m ago", type: "transaction" },
      { action: "EVM gas simulation: 94,200 units @ 2,115 tinyhbar/unit — SAFE", time: "3m ago", type: "tool_call" },
      { action: "Sequential batch of 3 TXs queued — nonce locked at 1847", time: "5m ago", type: "analysis" },
    ],
  },
  {
    id: "archivist",
    name: "Kael",
    fullName: "Kael",
    role: "Ledger Archivist",
    trait: "Meticulous · Immutable",
    color: "hsl(0 72% 62%)",
    glowColor: "hsl(0 72% 62% / 0.2)",
    icon: "▣",
    initials: "KL",
    gradientClass: "from-red-500 to-rose-700",
    quote: "The ledger is the only truth. I write it and I keep it.",
    philosophy: "I write receipts to the QuestReceipt contract: input hash, output hash, agent list, consensus timestamp. The mirror node confirms. The ledger never lies and neither do I.",
    confidence: 100,
    reputation: 5,
    completedQuests: 509,
    successRate: 100,
    specialization: "Mirror Node & Receipts",
    status: "active",
    animIndex: 6,
    homeRoom: "ledgerarchive",
    recentActions: [
      { action: "Receipt #2041 stored — mirror.hedera.com/api/v1/transactions/0.0.1234-1711234567", time: "2m ago", type: "transaction" },
      { action: "SHA-256 bundle hash for HCS msg #4,192: 0x1a2b3c4d…e5f6", time: "4m ago", type: "tool_call" },
      { action: "Retrieved receipt #2038 — Mirror: CONFIRMED, state: IMMUTABLE", time: "9m ago", type: "analysis" },
    ],
  },
];

export const STATUS_COLORS: Record<string, string> = {
  active: "hsl(142 70% 50%)",
  executing: "hsl(43 90% 60%)",
  standby: "hsl(195 100% 55%)",
  idle: "hsl(215 12% 50%)",
};

export const ACTION_TYPE_COLORS: Record<string, string> = {
  tool_call: "hsl(43 90% 60%)",
  analysis: "hsl(195 100% 55%)",
  proposal: "hsl(280 65% 68%)",
  alert: "hsl(38 92% 55%)",
  verification: "hsl(142 70% 50%)",
  transaction: "hsl(142 70% 50%)",
  policy: "hsl(0 72% 62%)",
  allocation: "hsl(280 65% 68%)",
};
