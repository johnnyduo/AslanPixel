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
    "Nexus: HCS Topic #0.0.1234 — sequence #4,193 missing. Gap confirmed. Flagging consensus timestamp skew to Drax.",
    "Nexus: Mirror node A and B diverge at slot 4,192,441. 340ms lag on node B. Anomaly logged.",
    "Nexus: Ingesting HCS topic #0.0.5678 — 1,204 msgs/min. Sequence integrity: CLEAN. No gaps detected.",
    "Nexus: Cross-referencing HCS timestamps with SaucerSwap TX slots. Correlation: 0.91. Strong signal.",
    "Nexus: New HCS subscription opened — topic #0.0.9901. Starting from sequence #0. Monitoring live.",
    "Nexus: Consensus event #4,195 carries anomalous payload size — 2.4KB vs 0.3KB baseline. FLAGGED.",
    "Nexus: HCS topic #0.0.1234 throughput dropped 38% — 527 msgs/min. Network condition shift detected.",
  ],
  strategist: [
    "Oryn: EVM strategy branch A — contract 0x00…4f89a2 at 87% confidence. Branch B fallback at 0x00…7c31d1.",
    "Oryn: Three-branch model complete. Expected value: +4.2% over 72h. Recommending branch A. Confidence: 91%.",
    "Oryn: SaucerSwap route via 0x00…4f89a2 beats Pangolin by 0.09% slippage at this size. Branch A confirmed.",
    "Oryn: Volatility window optimal — entry in next 8-12 minutes. EVM calldata prepared. 92% confidence.",
    "Oryn: HTS token #0.0.887432 overweight at 61% — rebalance threshold triggered. Dispatching to Drax for review.",
    "Oryn: Scenario model — bull +6.1%, base +2.8%, bear -1.2%. Expected value positive. Strategy APPROVED.",
    "Oryn: Fallback activated — if slippage exceeds 0.25%, reduce contract call value by 40% and retry.",
  ],
  sentinel: [
    "Drax: Slippage cap 0.25% enforced. Route 0x00…4f89a2 clears at 0.12%. APPROVED for Vex.",
    "Drax: Audit hash 0xf3a1…verified via Quantstamp registry. Contract 0x00…4f89a2 — no critical issues. CLEARED.",
    "Drax: HTS token #0.0.887432 at 61% portfolio — approaching 65% alert threshold. WATCHING.",
    "Drax: EVM gas spike +340% above baseline at slot 4,192,500. Network congestion. HOLD ORDERS.",
    "Drax: Policy override attempt rejected. Max allocation 5% per HTS token. Rule is non-negotiable.",
    "Drax: Sandwich risk on TX 0.0.1234@1711234567 — probability 2.1%. Proceeding with standard submission.",
    "Drax: Three consecutive EVM simulation failures on 0x00…7c31d1. Contract flagged HIGH RISK. Blocking.",
  ],
  treasurer: [
    "Lyss: HTS treasury — 12,847.50 HBAR (1,284,750,000,000,000 tinyhbar). Gas reserve: 500 HBAR locked. Available: 12,347.50 HBAR.",
    "Lyss: Committing exactly 250 HBAR (25,000,000,000,000 tinyhbar). Post-execution projection: 12,597.50 HBAR.",
    "Lyss: Daily spend — 342 HBAR (34,200,000,000,000 tinyhbar). Within 400 HBAR budget. Runway: 37 days.",
    "Lyss: HTS token #0.0.731861 APR updated — 14.2% annualized. Compounding allocation approved: 2,000 HBAR.",
    "Lyss: Gas costs this epoch — 84,700,000,000 tinyhbar across 12 TXs. Avg: 7,058,333,333 tinyhbar/TX.",
    "Lyss: HTS stablecoin #0.0.456789 buffer: $3,204 USDC — below 25% target. Recommending rebalance to Oryn.",
    "Lyss: Monthly report — inflows 8,400 HBAR, outflows 5,912 HBAR, net +2,488 HBAR. Treasury healthy.",
  ],
  executor: [
    "Vex: TX 0.0.1234@1711234567.000000000 — 250 HBAR → 31.05 USDC — Gas: 199,233,000,000 tinyhbar — Slot: 4,192,441 CONFIRMED.",
    "Vex: EVM simulation — gasEstimate 94,200 units @ 2,115 tinyhbar/unit = 199,233,000 tinyhbar total. SAFE.",
    "Vex: Nonce 1847 locked. Sequential batch of 3 TXs queued. Mirror node ETA: 42 seconds.",
    "Vex: Retry 2/3 — TX reverted at slot 4,192,300. EVM gas multiplier adjusted 1.0x → 1.2x. Resubmitting.",
    "Vex: SaucerSwap route executed — HBAR → SAUCE via 0x00…4f89a2 — actual slippage 0.09% vs 0.12% estimate.",
    "Vex: Batch TX 0.0.1234@1711234600.000000000 — 3 EVM calls, 1 HTS transfer — total gas: 2,712,330,000 tinyhbar.",
    "Vex: Drax halt received. TX paused at EVM simulation stage. Awaiting policy clearance before resubmit.",
  ],
  archivist: [
    "Kael: Receipt #2042 → mirror.hedera.com/api/v1/transactions/0.0.1234-1711234567 — inputHash: 0xef56…, outputHash: 0xab78… 5 agents logged.",
    "Kael: Consensus timestamp 2024-03-23T14:32:25.000Z — slot 4,192,847. Entry immutable. Mirror: CONFIRMED.",
    "Kael: SHA-256 bundle hash for HCS msg #4,192 reasoning chain: 0x1a2b3c4d…e5f6. Verifiable on-chain.",
    "Kael: Retrieving receipt #2039 — mirror.hedera.com/api/v1/transactions/0.0.1234-1711230000. All fields intact.",
    "Kael: QuestReceipt contract — 2,042 total receipts. HCS storage cost: 210,000,000 tinyhbar per record.",
    "Kael: Cross-referencing receipt #2041 with Lyss treasury ledger TL-1847. Tinyhbar values match. CONSISTENT.",
    "Kael: Archival complete — full agent session hashed, HCS topic #0.0.1234 msg submitted. IMMUTABLE.",
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
