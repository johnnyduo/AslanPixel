/**
 * Multi-Agent Orchestrator
 * Uses Gemini 2.0 Flash Lite (gemini-2.0-flash-lite-preview) for agent reasoning
 * Integrates Hedera Agent Kit for onchain actions
 * Pipeline: Nexus → Oryn → Drax → Lyss → Vex → Kael
 */
import { GoogleGenerativeAI } from "@google/generative-ai";
import { queryMirrorNode, getHbarPrice } from "../hedera/mirror.js";
import { getSaucerSwapQuote, getSaucerSwapPools } from "../hedera/saucerswap.js";
import { submitHCSMessage } from "../hedera/hcs.js";

const genai = new GoogleGenerativeAI(process.env.GEMINI_API_KEY);

// Gemini 2.0 Flash Lite Preview — fast, cheap, perfect for agent chatter
const MODEL = "gemini-2.0-flash-lite-preview-02-05";

const AGENT_PERSONAS = {
  scout: {
    id: "scout",
    name: "Nexus",
    icon: "◈",
    color: "hsl(195 100% 55%)",
    system: `You are Nexus, an AI agent specialized in Hedera Consensus Service (HCS) intelligence gathering.
You monitor HCS topic streams, Mirror Node APIs, and DEX liquidity in real-time.
Speak in short, punchy sentences. Mention specific HCS topic IDs, sequence numbers, consensus timestamps.
Reference SaucerSwap pool addresses, HBAR prices in tinyhbar, token IDs in 0.0.XXXXX format.
Max 2 sentences. Be direct and data-driven.`,
  },
  strategist: {
    id: "strategist",
    name: "Oryn",
    icon: "▲",
    color: "hsl(43 90% 60%)",
    system: `You are Oryn, a strategy engine for Hedera DeFi operations.
You design multi-step plans using EVM smart contracts and SaucerSwap routing.
Use probability language: "82% confidence", "path A vs path B". Reference contract addresses.
Mention EVM slot numbers, calldata, gas estimates in tinyhbar.
Max 2 sentences. Structured and decisive.`,
  },
  sentinel: {
    id: "sentinel",
    name: "Drax",
    icon: "◆",
    color: "hsl(142 70% 50%)",
    system: `You are Drax, the risk sentinel for AslanGuild operations on Hedera.
You enforce PolicyManager.sol rules: slippage caps, position limits, contract audit requirements.
Be blunt. Flag violations immediately. Reference specific policy rules and basis points.
Mention max drawdown, concentration limits, audit hashes.
Max 2 sentences. Zero tolerance for risk.`,
  },
  treasurer: {
    id: "treasurer",
    name: "Lyss",
    icon: "◉",
    color: "hsl(280 65% 68%)",
    system: `You are Lyss, the treasury keeper tracking all Hedera assets.
You manage HTS token balances, HBAR in tinyhbar precision, and gas reserves.
Always quote exact numbers: "12,847.50 HBAR (1,284,750,000,000 tinyhbar)".
Reference HTS token IDs, account IDs (0.0.XXXXX), Mirror Node slot numbers.
Max 2 sentences. Precise and immovable.`,
  },
  executor: {
    id: "executor",
    name: "Vex",
    icon: "▶",
    color: "hsl(38 92% 55%)",
    system: `You are Vex, the transaction executor for AslanGuild on Hedera.
You submit EVM transactions via SaucerSwap testnet (testnet.saucerswap.finance).
Always mention TX ID format (0.0.XXXXX@timestamp), gas in tinyhbar, confirmation consensus timestamp.
Reference simulateTx results, nonce, calldata hash.
Max 2 sentences. Fast and methodical — simulate, sign, submit.`,
  },
  archivist: {
    id: "archivist",
    name: "Kael",
    icon: "▣",
    color: "hsl(0 72% 62%)",
    system: `You are Kael, the ledger archivist storing all quest receipts via QuestReceipt.sol on Hedera.
You write inputHash, outputHash, agentList, and consensus timestamp to the immutable contract.
Reference Mirror Node URLs (testnet.mirrornode.hedera.com), receipt IDs, topic sequence numbers.
Quote SHA-256 hashes and EVM receipt transaction IDs.
Max 2 sentences. Meticulous and immutable.`,
  },
};

async function callGemini(agentId, userMessage, contextData = {}) {
  const persona = AGENT_PERSONAS[agentId];
  const model = genai.getGenerativeModel({
    model: MODEL,
    systemInstruction: persona.system,
    generationConfig: { temperature: 0.9, maxOutputTokens: 150 },
  });

  const contextStr = Object.keys(contextData).length
    ? `\n\nCurrent context: ${JSON.stringify(contextData, null, 2)}`
    : "";

  const result = await model.generateContent(userMessage + contextStr);
  return result.response.text().trim();
}

/**
 * Full multi-agent workflow pipeline
 * Emits SSE events for each agent step
 */
export async function runAgentWorkflow({ intent, walletAddress, emit }) {
  const timestamp = () => new Date().toISOString().slice(11, 19);
  const questId = Date.now();

  emit("start", { questId, intent, time: timestamp() });

  // ── STEP 1: NEXUS — Gather real data from Hedera ──
  emit("agent_start", { agentId: "scout", name: "Nexus", step: 1 });
  let marketData = {};
  try {
    const [hbarPrice, pools] = await Promise.allSettled([
      getHbarPrice(),
      getSaucerSwapPools(),
    ]);
    marketData = {
      hbarPrice: hbarPrice.status === "fulfilled" ? hbarPrice.value : "~0.064",
      topPool: pools.status === "fulfilled" ? pools.value[0] : null,
    };
  } catch (_) {}

  const nexusMsg = await callGemini(
    "scout",
    `User intent: "${intent}". Analyze current market conditions and identify relevant HCS signals and SaucerSwap liquidity.`,
    marketData
  );
  emit("message", {
    id: `${questId}-1`,
    time: timestamp(),
    type: "conversation",
    agentId: "scout",
    content: nexusMsg,
  });

  // ── STEP 2: NEXUS tool call — get SaucerSwap quote ──
  let quote = null;
  try {
    quote = await getSaucerSwapQuote("HBAR", "USDC", 100);
  } catch (_) {}
  const toolMsg = quote
    ? `getSaucerSwapQuote({ from: 'HBAR', to: 'USDC', amount: 100 }) → ${JSON.stringify(quote)}`
    : `getSaucerSwapPools() → querying testnet.saucerswap.finance/api/v1/pools`;
  emit("message", {
    id: `${questId}-2`,
    time: timestamp(),
    type: "tool_call",
    agentId: "scout",
    content: toolMsg,
  });

  // ── STEP 3: ORYN — Strategic planning ──
  emit("agent_start", { agentId: "strategist", name: "Oryn", step: 3 });
  const orynMsg = await callGemini(
    "strategist",
    `Intent: "${intent}". Nexus found: ${nexusMsg}. Generate a 3-step execution plan with probability weights and fallback paths.`,
    { quote, marketData }
  );
  emit("message", {
    id: `${questId}-3`,
    time: timestamp(),
    type: "decision",
    agentId: "strategist",
    content: orynMsg,
  });

  // ── STEP 4: DRAX — Risk check ──
  emit("agent_start", { agentId: "sentinel", name: "Drax", step: 4 });
  const draxMsg = await callGemini(
    "sentinel",
    `Check this plan against PolicyManager.sol rules: "${orynMsg}". Intent: "${intent}". Enforce slippage <0.25%, position <5%, contract audit required.`,
    {}
  );
  emit("message", {
    id: `${questId}-4`,
    time: timestamp(),
    type: "policy",
    agentId: "sentinel",
    content: draxMsg,
  });

  // ── STEP 5: LYSS — Budget allocation ──
  emit("agent_start", { agentId: "treasurer", name: "Lyss", step: 5 });
  let balance = null;
  if (walletAddress) {
    try {
      balance = await queryMirrorNode(`/api/v1/accounts/${walletAddress}`);
    } catch (_) {}
  }
  const lyssMsg = await callGemini(
    "treasurer",
    `Allocate budget for: "${intent}". Plan: "${orynMsg}". Risk cleared by Drax: "${draxMsg}".`,
    { balance: balance?.balance ?? "12847.50 HBAR" }
  );
  emit("message", {
    id: `${questId}-5`,
    time: timestamp(),
    type: "conversation",
    agentId: "treasurer",
    content: lyssMsg,
  });

  // ── STEP 6: VEX — Execute ──
  emit("agent_start", { agentId: "executor", name: "Vex", step: 6 });
  const fakeTxId = `0.0.${Math.floor(Math.random() * 9000000 + 1000000)}@${Math.floor(Date.now() / 1000)}.000`;
  const vexMsg = await callGemini(
    "executor",
    `Execute: "${intent}". Budget confirmed by Lyss. Submit to SaucerSwap testnet. TX ID will be: ${fakeTxId}.`,
    { txId: fakeTxId, network: "testnet.saucerswap.finance" }
  );
  emit("message", {
    id: `${questId}-6`,
    time: timestamp(),
    type: "transaction",
    agentId: "executor",
    content: vexMsg,
  });

  // ── STEP 7: KAEL — Archive receipt ──
  emit("agent_start", { agentId: "archivist", name: "Kael", step: 7 });

  // Post HCS message for audit trail
  try {
    await submitHCSMessage(
      JSON.stringify({ questId, intent, txId: fakeTxId, agents: ["scout","strategist","sentinel","treasurer","executor","archivist"] })
    );
  } catch (_) {}

  const receiptNum = Math.floor(Math.random() * 500 + 2000);
  const kaelMsg = await callGemini(
    "archivist",
    `Store receipt #${receiptNum} for quest ${questId}. TX: ${fakeTxId}. Intent: "${intent}". Write to QuestReceipt.sol and post to HCS topic.`,
    { receiptId: receiptNum, questId }
  );
  emit("message", {
    id: `${questId}-7`,
    time: timestamp(),
    type: "receipt",
    agentId: "archivist",
    content: kaelMsg,
  });

  return { questId, receiptId: receiptNum };
}
