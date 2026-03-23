/**
 * Live Activity Generator
 * Continuously generates realistic agent chatter using Gemini 2.0 Flash Lite
 * Called every 8-12 seconds to feed the frontend timeline
 */
import { GoogleGenerativeAI } from "@google/generative-ai";
import { getHbarPrice, getLatestHCSMessages } from "../hedera/mirror.js";
import { getSaucerSwapPools } from "../hedera/saucerswap.js";

const genai = new GoogleGenerativeAI(process.env.GEMINI_API_KEY);
const MODEL = "gemini-2.0-flash-lite-preview-02-05";

// Rotating scenarios — agents talk about different things each cycle
const SCENARIOS = [
  { lead: "scout",      type: "tool_call",    topic: "HCS topic stream monitoring and sequence number tracking" },
  { lead: "strategist", type: "decision",     topic: "rebalancing HBAR/SAUCE allocation based on yield opportunities" },
  { lead: "sentinel",   type: "policy",       topic: "enforcing slippage cap and position limit checks" },
  { lead: "treasurer",  type: "conversation", topic: "reconciling HBAR treasury balance against Mirror Node state" },
  { lead: "executor",   type: "transaction",  topic: "submitting SaucerSwap testnet swap and confirming consensus" },
  { lead: "archivist",  type: "receipt",      topic: "indexing QuestReceipt.sol events and updating Mirror Node cache" },
  { lead: "scout",      type: "alert",        topic: "anomalous wallet inflow detected on Hedera testnet" },
  { lead: "strategist", type: "conversation", topic: "modeling liquidity pool migration from HBAR/USDC to HBAR/SAUCE" },
];

let scenarioIndex = 0;

const AGENT_PERSONAS = {
  scout:      { name: "Nexus",  icon: "◈", color: "hsl(195 100% 55%)", system: "You are Nexus, HCS intelligence agent. Short, data-driven. Mention HCS topic IDs, sequence numbers, SaucerSwap pool addresses." },
  strategist: { name: "Oryn",   icon: "▲", color: "hsl(43 90% 60%)",  system: "You are Oryn, strategy engine. Use probability percentages, EVM addresses, contract calldata references." },
  sentinel:   { name: "Drax",   icon: "◆", color: "hsl(142 70% 50%)", system: "You are Drax, risk sentinel. Blunt, policy-focused. Reference PolicyManager.sol rules, slippage bps, audit hashes." },
  treasurer:  { name: "Lyss",   icon: "◉", color: "hsl(280 65% 68%)", system: "You are Lyss, treasury keeper. Exact numbers always. tinyhbar precision, HTS token IDs (0.0.XXXXX), Mirror Node slots." },
  executor:   { name: "Vex",    icon: "▶", color: "hsl(38 92% 55%)",  system: "You are Vex, TX executor. Always mention TX ID format (0.0.X@timestamp), gas tinyhbar, SaucerSwap testnet confirmations." },
  archivist:  { name: "Kael",   icon: "▣", color: "hsl(0 72% 62%)",   system: "You are Kael, ledger archivist. SHA-256 hashes, receipt IDs, QuestReceipt.sol, Mirror Node URLs." },
};

async function generateMessage(agentId, topic, liveData) {
  const persona = AGENT_PERSONAS[agentId];
  const model = genai.getGenerativeModel({
    model: MODEL,
    systemInstruction: `${persona.system} Max 1-2 sentences. Stay completely in character.`,
    generationConfig: { temperature: 0.92, maxOutputTokens: 120 },
  });

  const context = liveData
    ? `Live data: HBAR price $${liveData.hbarPrice ?? "0.064"}, top pool: ${liveData.topPool ?? "HBAR/USDC"}. `
    : "";

  const result = await model.generateContent(
    `${context}Current activity: ${topic}. Generate one in-character status update about what you're doing right now.`
  );
  return result.response.text().trim();
}

export async function generateLiveActivity() {
  const scenario = SCENARIOS[scenarioIndex % SCENARIOS.length];
  scenarioIndex++;

  const timestamp = () => {
    const d = new Date();
    return `${String(d.getHours()).padStart(2,"0")}:${String(d.getMinutes()).padStart(2,"0")}:${String(d.getSeconds()).padStart(2,"0")}`;
  };

  // Fetch live data for context (best effort)
  let liveData = {};
  try {
    const [price, pools] = await Promise.allSettled([getHbarPrice(), getSaucerSwapPools()]);
    liveData = {
      hbarPrice: price.status === "fulfilled" ? price.value : null,
      topPool: pools.status === "fulfilled" && pools.value?.[0] ? pools.value[0].pairName ?? "HBAR/USDC" : null,
    };
  } catch (_) {}

  // Generate lead agent message
  let content;
  try {
    content = await generateMessage(scenario.lead, scenario.topic, liveData);
  } catch (_) {
    // Fallback — rich local messages per agent
    const fallbacks = {
      scout:      ["HCS topic 0.0.1234: seq #47,821 received — inflow signal from 3 wallets converging on SAUCE.", "Mirror Node shows 0.0.847291 accumulated 48,000 HBAR in the last 4 consensus rounds."],
      strategist: ["Path A: HBAR→USDC→SAUCE yields 8.3% APR at 91% confidence. Initiating plan.", "Rebalance model converged: 45% HBAR liquidity, 30% SAUCE farm, 25% stablecoin buffer."],
      sentinel:   ["PolicyManager check: slippage 0.18bps ✓, position 3.2% ✓, audit hash 0xf3a1 ✓. PASS.", "Concentration limit 5% enforced — blocking 0.0.99341 from exceeding threshold."],
      treasurer:  ["Treasury: 12,847.50 HBAR (1,284,750,000,000 tinyhbar). Gas reserve: 500 HBAR locked.", "HTS token 0.0.731861 (SAUCE): 4,200 units. Current value: 268.80 HBAR equivalent."],
      executor:   ["TX 0.0.4819204@1742733201.000 submitted to testnet.saucerswap.finance — awaiting consensus.", "simulateTx result: SAFE. Gas: 91,200 units @ 92 tinyhbar/unit. Submitting now."],
      archivist:  ["Receipt #2,041 → QuestReceipt.sol. inputHash: 0xab12…cd34. Mirror: CONFIRMED.", "HCS topic 0.0.1235 seq #3,091: quest bundle hashed and posted. Immutable from this block."],
    };
    const msgs = fallbacks[scenario.lead] ?? ["Monitoring Hedera network activity."];
    content = msgs[Math.floor(Math.random() * msgs.length)];
  }

  const messages = [
    {
      id: `live-${Date.now()}-1`,
      time: timestamp(),
      type: scenario.type,
      agentId: scenario.lead,
      content,
    },
  ];

  // 40% chance of a follow-up response from another agent
  if (Math.random() < 0.4) {
    const responders = Object.keys(AGENT_PERSONAS).filter((id) => id !== scenario.lead);
    const responder = responders[Math.floor(Math.random() * responders.length)];
    try {
      await new Promise((r) => setTimeout(r, 400));
      const followUp = await generateMessage(
        responder,
        `responding to ${AGENT_PERSONAS[scenario.lead].name}'s update about ${scenario.topic}`,
        liveData
      );
      messages.push({
        id: `live-${Date.now()}-2`,
        time: timestamp(),
        type: "conversation",
        agentId: responder,
        content: followUp,
      });
    } catch (_) {}
  }

  return messages;
}
