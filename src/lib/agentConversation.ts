// Agent conversation generator using Gemini 2.0 Flash Lite
// Generates live, in-character messages for each agent based on their personality

export type MessageType =
  | "conversation"
  | "tool_call"
  | "decision"
  | "transaction"
  | "alert"
  | "policy"
  | "receipt";

export interface ConversationContext {
  trigger: string;
  agentId: string;
  previousMessages?: TimelineMessage[];
}

export interface TimelineMessage {
  time: string;
  type: MessageType;
  agentId: string;
  content: string;
  id: string;
}

const AGENT_PERSONALITIES: Record<string, string> = {
  scout:
    "Nexus — HCS Intelligence. Reads Hedera Consensus Service topic streams in real-time. Speaks in HCS topic IDs (0.0.xxxx), consensus timestamps, sequence numbers, and message hashes. Short punchy sentences. Loves flagging anomalies.",
  strategist:
    "Oryn — Strategy Engine. Calculates EVM contract strategy branches. Speaks in contract addresses (0x00…format), confidence percentages, and multi-path decision trees. Structured, mentions risk-adjusted outcomes.",
  sentinel:
    "Drax — Risk Sentinel. Enforces policy on every TX before it touches the network. Blunt, zero-tolerance. References slippage limits (0.25% cap), audit hashes, contract review status. Never lets anything slide.",
  treasurer:
    "Lyss — Treasury Keeper. Owns HTS token balances and speaks in exact tinyhbar values. Always references HBAR totals, HTS token IDs (0.0.xxxx), and gas reserves. Immovable on budget limits.",
  executor:
    "Vex — TX Executor. Simulate, sign, submit — in that order. Uses Hedera TX IDs (0.0.xxx@timestamp format), EVM gas in tinyhbar, mirror node confirmation slots. Fast, methodical, never skips steps.",
  archivist:
    "Kael — Ledger Archivist. Writes and retrieves receipts via mirror.hedera.com. References receipt numbers, Mirror node URLs, HCS message hashes, and consensus timestamps. Speaks about immutability as doctrine.",
};

const AGENT_TYPES: Record<string, MessageType[]> = {
  scout: ["conversation", "tool_call", "alert"],
  strategist: ["conversation", "decision"],
  sentinel: ["policy", "alert", "conversation"],
  treasurer: ["conversation", "tool_call"],
  executor: ["tool_call", "transaction", "conversation"],
  archivist: ["receipt", "conversation"],
};

const LOCAL_MESSAGES: Record<string, string[]> = {
  scout: [
    "Nexus: HCS Topic #0.0.1234 — seq #4,193 missing. Gap confirmed. Flagging timestamp skew to Drax.",
    "Nexus: Mirror node A and B diverge at slot 4,192,441. 340ms lag on node B. Anomaly logged.",
    "Nexus: Ingesting HCS topic #0.0.5678 — 1,204 msgs/min. Sequence integrity: CLEAN.",
    "Nexus: Cross-referencing HCS timestamps with SaucerSwap TX slots. Correlation: 0.91. Strong signal.",
    "Nexus: New HCS subscription opened — topic #0.0.9901. Starting from sequence #0. Monitoring.",
    "Nexus: Consensus event #4,195 — anomalous payload 2.4KB vs 0.3KB baseline. FLAGGED.",
    "Nexus: HCS topic #0.0.1234 throughput dropped 38% — 527 msgs/min. Condition shift detected.",
    "Nexus: Hedera mainnet block 62,841,004 finalized — 0.7s consensus. Latency nominal.",
    "Nexus: HCS seq #4,201 delivered with 2 attestors vs expected 3. Threshold met, logging discrepancy.",
    "Nexus: SaucerSwap pool event detected — 0x00…a8f2 — 147 HBAR movement. Relaying to Oryn.",
    "Nexus: Mirror node catch-up complete. 13 missed events replayed. Timeline consistent.",
    "Nexus: Topic #0.0.1234 message rate back to 841 msgs/min. Congestion window passed. CLEAR.",
    "Nexus: HCS attestor quorum restored at seq #4,209. Three nodes back online. Confidence: HIGH.",
    "Nexus: Polling interval adjusted 500ms → 250ms — high-frequency event window active.",
    "Nexus: EVM block 62,841,100 — 47 TXs, avg gas 94k units. Pool depth stable at $2.4M.",
  ],
  strategist: [
    "Oryn: EVM strategy branch A — contract 0x00…4f89a2 at 87% confidence. Branch B at 0x00…7c31d1.",
    "Oryn: Three-branch model complete. Expected value: +4.2% over 72h. Branch A recommended.",
    "Oryn: SaucerSwap route via 0x00…4f89a2 beats Pangolin by 0.09% slippage. Branch A confirmed.",
    "Oryn: Volatility window optimal — entry in 8-12 min. EVM calldata prepared. 92% confidence.",
    "Oryn: HTS token #0.0.887432 overweight at 61% — rebalance threshold hit. Sending to Drax.",
    "Oryn: Scenario model — bull +6.1%, base +2.8%, bear -1.2%. Expected value positive. APPROVED.",
    "Oryn: Fallback active — if slippage > 0.25%, reduce value 40% and retry.",
    "Oryn: HBAR/USDC 30-day correlation: 0.82. Position sizing adjusted down 12% for risk parity.",
    "Oryn: Liquidity depth at 0x00…4f89a2 — $2.41M. Acceptable for 500 HBAR order. Proceeding.",
    "Oryn: Arbitrage window — 0.31% spread between SaucerSwap and Pangolin. Lifetime: ~4 blocks.",
    "Oryn: Confidence decay model — branch A drops below 70% at T+6h. Recommend execution < T+2h.",
    "Oryn: HTS token #0.0.456789 yield curve inflecting. Reallocating 15% from HBAR pairs.",
    "Oryn: Monte Carlo sim — 10,000 runs, median +3.1%, 5th pct -0.4%. Risk-reward acceptable.",
    "Oryn: EVM fork delta detected — mainnet vs shadow fork diverges at block 62,840,900. Recalculating.",
    "Oryn: Strategy locked in. Sending calldata to Vex. Window closes in ~3 minutes.",
  ],
  sentinel: [
    "Drax: Slippage cap 0.25% enforced. Route 0x00…4f89a2 clears at 0.12%. APPROVED for Vex.",
    "Drax: Audit hash 0xf3a1…verified via Quantstamp registry. Contract cleared. No critical issues.",
    "Drax: HTS token #0.0.887432 at 61% — approaching 65% alert threshold. WATCHING.",
    "Drax: EVM gas spike +340% above baseline at slot 4,192,500. Congestion. HOLD ORDERS.",
    "Drax: Policy override rejected. Max 5% per HTS token. Non-negotiable.",
    "Drax: Sandwich risk TX 0.0.1234@1711234567 — probability 2.1%. Proceeding standard path.",
    "Drax: Three consecutive EVM simulation failures on 0x00…7c31d1. HIGH RISK — blocked.",
    "Drax: Reentrancy pattern scan on 0x00…4f89a2 — CLEAN. No recursive call vectors found.",
    "Drax: Oracle price feed deviation 0.18% vs Chainlink reference. Within tolerance. PASSED.",
    "Drax: Whale wallet 0x00…a9c4 moved 44,000 HBAR in last 2 blocks. Monitoring for wash patterns.",
    "Drax: MEV protection active — private mempool route selected. Front-run risk: LOW.",
    "Drax: Smart contract upgrade detected at 0x00…7c31d1. Halting all pending TXs pending re-audit.",
    "Drax: Portfolio VaR (95%, 24h): 1.8% of total. Within 3% policy limit. GREEN.",
    "Drax: Liquidity drawdown scenario — if pool drops 40%, max loss capped at 180 HBAR. Acceptable.",
    "Drax: All pre-flight checks passed. Releasing TX to Vex. Policy signature: 0xd4a8….",
  ],
  treasurer: [
    "Lyss: HTS treasury — 12,847.50 HBAR (1,284,750,000,000,000 tinyhbar). Gas reserve: 500 HBAR locked.",
    "Lyss: Committing 250 HBAR (25,000,000,000,000 tinyhbar). Post-exec projection: 12,597.50 HBAR.",
    "Lyss: Daily spend — 342 HBAR. Within 400 HBAR budget. Runway: 37 days.",
    "Lyss: HTS token #0.0.731861 APR 14.2% annualized. Compounding allocation: 2,000 HBAR approved.",
    "Lyss: Gas this epoch — 84,700,000,000 tinyhbar across 12 TXs. Avg 7.06B tinyhbar/TX.",
    "Lyss: USDC buffer #0.0.456789 — $3,204 — below 25% target. Recommending rebalance to Oryn.",
    "Lyss: Monthly — inflows 8,400 HBAR, outflows 5,912 HBAR, net +2,488 HBAR. Healthy.",
    "Lyss: Emergency reserve at 1,200 HBAR — untouched. Minimum floor 800 HBAR. Holding.",
    "Lyss: Batch fee estimate for 5 pending TXs: 412,500,000,000 tinyhbar. Approved.",
    "Lyss: Yield from HTS pool #0.0.887432 — +147.3 HBAR this week. Auto-compounding enabled.",
    "Lyss: Treasury utilization rate: 62.4%. Optimal band: 55–70%. Efficiency: GOOD.",
    "Lyss: Gas price trending up 18% this hour. Delaying non-critical TXs by 30 min window.",
    "Lyss: HTS token #0.0.456789 — USDC peg deviation 0.003%. Stablecoin risk: NEGLIGIBLE.",
    "Lyss: Quarterly projection — if current yield holds, +12,400 HBAR annualized. Target: 15,000.",
    "Lyss: Reserve ratio post-TX: 9.1% — above 8% floor. Budget integrity intact.",
  ],
  executor: [
    "Vex: TX 0.0.1234@1711234567 — 250 HBAR → 31.05 USDC — Gas: 199B tinyhbar — Slot: 4,192,441 CONFIRMED.",
    "Vex: EVM sim — gasEstimate 94,200 units @ 2,115 tinyhbar/unit = 199,233,000 tinyhbar. SAFE.",
    "Vex: Nonce 1847 locked. 3-TX batch queued. Mirror ETA: 42 seconds.",
    "Vex: Retry 2/3 — reverted at slot 4,192,300. Gas multiplier 1.0x → 1.2x. Resubmitting.",
    "Vex: SaucerSwap HBAR → SAUCE via 0x00…4f89a2 — actual slippage 0.09% vs 0.12% estimate.",
    "Vex: Batch TX 0.0.1234@1711234600 — 3 EVM calls + 1 HTS transfer. Total gas: 2.71B tinyhbar.",
    "Vex: Drax halt received. Paused at simulation stage. Awaiting policy clearance.",
    "Vex: Pre-flight sim complete — no revert paths detected across 3 execution branches. PROCEED.",
    "Vex: Mirror node confirmation received at slot 4,192,502. Finality: ABSOLUTE.",
    "Vex: Calldata encoding verified — ABI signature 0x38ed1739 (swapExactTokensForTokens). Correct.",
    "Vex: Gas oracle suggests 2,050 tinyhbar/unit — 3% below Lyss estimate. Using conservative figure.",
    "Vex: TX 0.0.1234@1711235001 — 100 HBAR → 12.47 USDC — Confirmed in 1 block. Latency: 0.71s.",
    "Vex: Parallel sim across 2 routes — route A wins by 0.06% net. Submitting route A.",
    "Vex: Nonce gap detected at 1851. Filling nonce hole with no-op TX before batch. Standard procedure.",
    "Vex: All 3 TXs in batch confirmed. Total execution time: 4.3s. Receipts forwarded to Kael.",
  ],
  archivist: [
    "Kael: Receipt #2042 → mirror.hedera.com/api/v1/transactions/0.0.1234-1711234567 — 5 agents logged.",
    "Kael: Consensus timestamp 2024-03-23T14:32:25Z — slot 4,192,847. Entry immutable. CONFIRMED.",
    "Kael: SHA-256 bundle hash HCS msg #4,192 reasoning chain: 0x1a2b3c4d…e5f6. On-chain verifiable.",
    "Kael: Retrieving receipt #2039 — all fields intact. No tampering detected.",
    "Kael: QuestReceipt contract — 2,042 total receipts. HCS storage: 210M tinyhbar/record.",
    "Kael: Cross-referencing receipt #2041 with Lyss ledger TL-1847. Tinyhbar values match. CONSISTENT.",
    "Kael: Archival complete — session hashed, HCS msg submitted to #0.0.1234. IMMUTABLE.",
    "Kael: Receipt index rebuilt — 2,042 entries re-verified. Zero integrity violations. CLEAN.",
    "Kael: Merkle root for quest batch #847 — 0x9f3a…c2b1. Stored on HCS topic #0.0.1234.",
    "Kael: Mirror API response time 84ms — within SLA. Retrieval performance: OPTIMAL.",
    "Kael: Receipt #2043 written — quest intent hash: 0xabcd…, all 6 agent signatures present.",
    "Kael: Audit trail for TX 0.0.1234@1711234567 — 4 policy checks, 2 simulations, 1 execution. COMPLETE.",
    "Kael: Long-term archive compression ratio: 4.2:1. 2,042 receipts in 1.8MB on-chain storage.",
    "Kael: Spot-checking receipt #1,991 — consensus timestamp drift vs local clock: 12ms. Acceptable.",
    "Kael: HCS topic #0.0.1234 — last 24h: 1,847 msgs, zero corruption events. Ledger integrity: 100%.",
  ],
};

function getCurrentTime(): string {
  const now = new Date();
  return now.toTimeString().slice(0, 8);
}

function generateId(): string {
  return `msg_${Date.now()}_${Math.random().toString(36).slice(2, 7)}`;
}

function pickRandom<T>(arr: T[]): T {
  return arr[Math.floor(Math.random() * arr.length)];
}

export function generateLocalMessage(agentId: string, _type: string): string {
  const messages = LOCAL_MESSAGES[agentId];
  if (!messages || messages.length === 0) {
    return `Agent ${agentId} processing Hedera DeFi operation...`;
  }
  return pickRandom(messages);
}

// Gemini is called server-side only via /api/stream and /api/quest (Vercel Edge).
// Frontend never holds the API key — no VITE_GEMINI_API_KEY needed.
export async function generateAgentMessage(
  agentId: string,
  _context: ConversationContext
): Promise<string> {
  // Always use local fallback — real AI comes through SSE from server
  return generateLocalMessage(agentId, "conversation");
}

const WORKFLOW_STEPS: Array<{ agentId: string; type: MessageType }> = [
  { agentId: "scout", type: "tool_call" },
  { agentId: "scout", type: "conversation" },
  { agentId: "strategist", type: "decision" },
  { agentId: "sentinel", type: "policy" },
  { agentId: "treasurer", type: "conversation" },
  { agentId: "executor", type: "tool_call" },
  { agentId: "executor", type: "transaction" },
  { agentId: "sentinel", type: "alert" },
  { agentId: "archivist", type: "receipt" },
];

export async function generateGroupConversation(
  trigger: string
): Promise<TimelineMessage[]> {
  const apiKey = import.meta.env.VITE_GEMINI_API_KEY as string | undefined;

  // Pick 4-8 steps from the workflow
  const count = 4 + Math.floor(Math.random() * 5);
  const shuffledSteps = [...WORKFLOW_STEPS]
    .sort(() => Math.random() - 0.5)
    .slice(0, count)
    .sort((a, b) => {
      // Re-sort roughly by workflow order: Nexus → Oryn → Drax → Lyss → Vex → Kael
      const order = ["scout", "strategist", "sentinel", "treasurer", "executor", "archivist"];
      return order.indexOf(a.agentId) - order.indexOf(b.agentId);
    });

  const now = Date.now();
  const messages: TimelineMessage[] = [];

  for (let i = 0; i < shuffledSteps.length; i++) {
    const step = shuffledSteps[i];
    const stepTime = new Date(now + i * 3000);
    const timeStr = stepTime.toTimeString().slice(0, 8);

    let content: string;

    if (apiKey) {
      try {
        const context: ConversationContext = {
          trigger,
          agentId: step.agentId,
          previousMessages: messages,
        };
        content = await generateAgentMessage(step.agentId, context);
      } catch {
        content = generateLocalMessage(step.agentId, step.type);
      }
    } else {
      content = generateLocalMessage(step.agentId, step.type);
    }

    messages.push({
      id: generateId(),
      time: timeStr,
      type: step.type,
      agentId: step.agentId,
      content,
    });
  }

  return messages;
}

export function makeLocalGroupConversation(): TimelineMessage[] {
  const count = 2 + Math.floor(Math.random() * 3);
  const stepIndices = Array.from({ length: WORKFLOW_STEPS.length }, (_, i) => i)
    .sort(() => Math.random() - 0.5)
    .slice(0, count)
    .sort((a, b) => a - b);

  const now = Date.now();
  return stepIndices.map((stepIdx, i) => {
    const step = WORKFLOW_STEPS[stepIdx];
    const stepTime = new Date(now + i * 3000);
    return {
      id: generateId(),
      time: stepTime.toTimeString().slice(0, 8),
      type: step.type,
      agentId: step.agentId,
      content: generateLocalMessage(step.agentId, step.type),
    };
  });
}

// Re-export getCurrentTime for use in hooks
export { getCurrentTime };
