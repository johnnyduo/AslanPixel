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
    name: "Scout",
    fullName: "Scout Veyra",
    role: "Data Discovery",
    trait: "Curious · Relentless",
    color: "hsl(195 100% 55%)",
    glowColor: "hsl(195 100% 55% / 0.2)",
    icon: "◈",
    initials: "SV",
    gradientClass: "from-cyan-500 to-blue-600",
    quote: "Every signal matters. I find what others miss.",
    philosophy: "Data is never noise — only unread signal. I cross-reference on-chain flows, DEX depth, and off-chain sentiment before any conclusion.",
    confidence: 91,
    reputation: 5,
    completedQuests: 318,
    successRate: 97,
    specialization: "On-chain Intelligence",
    status: "executing",
    animIndex: 1,
    homeRoom: "guild",
    recentActions: [
      { action: "Pulled HBAR/USDC depth from 4 DEXs", time: "1m ago", type: "tool_call" },
      { action: "Detected anomalous wallet inflow", time: "4m ago", type: "alert" },
      { action: "Mapped token holder concentration", time: "9m ago", type: "analysis" },
    ],
  },
  {
    id: "strategist",
    name: "Strategist",
    fullName: "Strategist Oryn",
    role: "Planning & Reasoning",
    trait: "Calculated · Decisive",
    color: "hsl(43 90% 60%)",
    glowColor: "hsl(43 90% 60% / 0.2)",
    icon: "▲",
    initials: "SO",
    gradientClass: "from-yellow-400 to-amber-600",
    quote: "A plan without risk assessment is just a wish.",
    philosophy: "I build structured multi-step plans with probability weights on each branch. No action without a fallback. No goal without measurable criteria.",
    confidence: 88,
    reputation: 5,
    completedQuests: 241,
    successRate: 95,
    specialization: "Strategy & Portfolio",
    status: "active",
    animIndex: 2,
    homeRoom: "strategy",
    recentActions: [
      { action: "Generated 3-step rebalance plan", time: "2m ago", type: "proposal" },
      { action: "Weighted risk/reward on HBAR/ETH", time: "6m ago", type: "analysis" },
      { action: "Proposed yield allocation 40/30/30", time: "14m ago", type: "proposal" },
    ],
  },
  {
    id: "sentinel",
    name: "Sentinel",
    fullName: "Sentinel Drax",
    role: "Risk & Policy Guard",
    trait: "Vigilant · Uncompromising",
    color: "hsl(142 70% 50%)",
    glowColor: "hsl(142 70% 50% / 0.2)",
    icon: "◆",
    initials: "SD",
    gradientClass: "from-green-500 to-emerald-700",
    quote: "I stand between the plan and what could go wrong.",
    philosophy: "Every transaction passes my criteria: max drawdown, concentration limits, smart contract audit status. If it fails any — it doesn't go through.",
    confidence: 96,
    reputation: 5,
    completedQuests: 509,
    successRate: 99,
    specialization: "Risk Management",
    status: "active",
    animIndex: 3,
    homeRoom: "hub",
    recentActions: [
      { action: "Flagged high slippage on swap route", time: "30s ago", type: "alert" },
      { action: "Approved contract 0xf3a1 audit", time: "3m ago", type: "verification" },
      { action: "Enforced 5% max position limit", time: "7m ago", type: "policy" },
    ],
  },
  {
    id: "treasurer",
    name: "Treasurer",
    fullName: "Treasurer Lyss",
    role: "Budget & Allocation",
    trait: "Precise · Conservative",
    color: "hsl(280 65% 68%)",
    glowColor: "hsl(280 65% 68% / 0.2)",
    icon: "◉",
    initials: "TL",
    gradientClass: "from-purple-500 to-violet-700",
    quote: "Capital allocation is not a guess — it's science.",
    philosophy: "I own the treasury state at all times. Every HBAR, every token, every pending TX is accounted for. I never commit more than the risk-adjusted budget allows.",
    confidence: 94,
    reputation: 4,
    completedQuests: 187,
    successRate: 98,
    specialization: "Treasury & Liquidity",
    status: "standby",
    animIndex: 4,
    homeRoom: "vault",
    recentActions: [
      { action: "Reserved 500 HBAR for gas buffer", time: "5m ago", type: "allocation" },
      { action: "Reconciled portfolio to 12,847 HBAR", time: "11m ago", type: "analysis" },
      { action: "Blocked over-allocation attempt", time: "18m ago", type: "policy" },
    ],
  },
  {
    id: "executor",
    name: "Executor",
    fullName: "Executor Nexis",
    role: "Transaction Execution",
    trait: "Fast · Methodical",
    color: "hsl(38 92% 55%)",
    glowColor: "hsl(38 92% 55% / 0.2)",
    icon: "▶",
    initials: "EN",
    gradientClass: "from-orange-400 to-red-600",
    quote: "Approved plans don't execute themselves. I do.",
    philosophy: "Once approved, I execute with precision: simulate first, check gas, confirm nonce, submit, monitor. I never skip steps and always produce a receipt.",
    confidence: 99,
    reputation: 4,
    completedQuests: 412,
    successRate: 96,
    specialization: "On-chain Execution",
    status: "idle",
    animIndex: 5,
    homeRoom: "market",
    recentActions: [
      { action: "TX 0x7a3f...2e1c — 100 HBAR → USDC CONFIRMED", time: "2m ago", type: "transaction" },
      { action: "Gas simulation: 92,400 units @ 0.0001 HBAR", time: "3m ago", type: "tool_call" },
      { action: "Nonce locked for sequential TX batch", time: "5m ago", type: "analysis" },
    ],
  },
  {
    id: "archivist",
    name: "Archivist",
    fullName: "Archivist Kael",
    role: "Onchain Logging",
    trait: "Meticulous · Immutable",
    color: "hsl(0 72% 62%)",
    glowColor: "hsl(0 72% 62% / 0.2)",
    icon: "▣",
    initials: "AK",
    gradientClass: "from-red-500 to-rose-700",
    quote: "Truth lives onchain. Everything else is rumor.",
    philosophy: "I write receipts to the QuestReceipt contract: input hash, output hash, agent list, timestamp. The ledger never lies and neither do I.",
    confidence: 100,
    reputation: 5,
    completedQuests: 509,
    successRate: 100,
    specialization: "Onchain Records",
    status: "active",
    animIndex: 6,
    homeRoom: "archive",
    recentActions: [
      { action: "Receipt #2041 stored — QuestReceipt.sol", time: "2m ago", type: "transaction" },
      { action: "Hashed agent reasoning bundle (SHA-256)", time: "4m ago", type: "tool_call" },
      { action: "Retrieved receipt #2038 for audit", time: "9m ago", type: "analysis" },
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
