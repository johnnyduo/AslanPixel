/**
 * Vercel Edge API Route: GET /api/stream
 * Long-running SSE — auto-generates agent activity every ~10s
 * Frontend subscribes for live timeline without submitting quest
 */

export const config = { runtime: "edge" };

const MODEL = "gemini-2.0-flash-lite-preview-02-05";

const AGENTS = {
  scout:      { name: "Nexus",  system: "You are Nexus, Hedera HCS intelligence agent. Mention HCS topic IDs, sequence numbers, Mirror Node data. Short, data-driven. Max 2 sentences." },
  strategist: { name: "Oryn",   system: "You are Oryn, Hedera DeFi strategy engine. Use probability %, EVM addresses, SaucerSwap routes. Max 2 sentences." },
  sentinel:   { name: "Drax",   system: "You are Drax, risk sentinel. Enforce PolicyManager.sol rules. Blunt. Reference bps, audit hashes. Max 2 sentences." },
  treasurer:  { name: "Lyss",   system: "You are Lyss, treasury keeper. Exact HBAR/tinyhbar numbers always. HTS token IDs (0.0.X). Max 2 sentences." },
  executor:   { name: "Vex",    system: "You are Vex, TX executor. TX IDs (0.0.X@timestamp), gas tinyhbar, testnet.saucerswap.finance. Max 2 sentences." },
  archivist:  { name: "Kael",   system: "You are Kael, ledger archivist. SHA-256 hashes, receipt IDs, QuestReceipt.sol, Mirror Node URLs. Max 2 sentences." },
};

const SCENARIOS = [
  { agentId: "scout",      type: "tool_call",    topic: "scanning HCS topic 0.0.1234 for new consensus events and wallet inflow patterns" },
  { agentId: "strategist", type: "decision",     topic: "evaluating HBAR/SAUCE yield opportunity on SaucerSwap testnet" },
  { agentId: "sentinel",   type: "policy",       topic: "running PolicyManager.sol compliance check on pending swap route" },
  { agentId: "treasurer",  type: "conversation", topic: "reconciling treasury balance against Mirror Node slot state" },
  { agentId: "executor",   type: "transaction",  topic: "confirming pending testnet.saucerswap.finance swap transaction" },
  { agentId: "archivist",  type: "receipt",      topic: "indexing latest QuestReceipt.sol event to Mirror Node cache" },
  { agentId: "scout",      type: "alert",        topic: "detecting anomalous wallet inflow on Hedera testnet" },
  { agentId: "strategist", type: "conversation", topic: "modeling liquidity migration from HBAR/USDC to HBAR/SAUCE pool" },
];

// Pre-written fallback messages when Gemini is unavailable
const FALLBACKS = {
  scout:      ["HCS topic 0.0.1234 seq #47,821 — inflow from 3 converging wallets detected. SAUCE accumulation pattern confirmed.", "Mirror Node: 0.0.847291 received 48,000 HBAR across 4 consensus rounds. Flagging for Oryn."],
  strategist: ["Path A: HBAR→USDC→SAUCE at 8.3% APR, 91% confidence. Initializing allocation model.", "Rebalance model converged: 45% HBAR liquidity, 30% SAUCE farm, 25% stablecoin buffer. Submitting to Drax."],
  sentinel:   ["PolicyManager check: slippage 0.18bps ✓, position 3.2% ✓, audit 0xf3a1 ✓. Plan approved, passing to Lyss.", "Concentration limit 5% enforced — 0.0.99341 blocked from threshold breach. Queue cleared."],
  treasurer:  ["Treasury: 12,847.50 HBAR (1,284,750,000,000 tinyhbar). Gas reserve 500 HBAR locked, committing 200 HBAR for swap.", "HTS 0.0.731861 (SAUCE): 4,200 units = 268.80 HBAR equivalent. Allocation approved."],
  executor:   ["TX 0.0.4819204@1742733201.000 submitted to testnet.saucerswap.finance — consensus confirmation pending.", "simulateTx: SAFE. Gas 91,200 units @ 92 tinyhbar/unit. Nonce locked, submitting now."],
  archivist:  ["Receipt #2,041 → QuestReceipt.sol. inputHash: 0xab12…cd34. Mirror Node: CONFIRMED at slot 4,192,441.", "HCS topic 0.0.1235 seq #3,091 posted — quest bundle immutable from this consensus round."],
};

async function geminiGenerate(apiKey, agentId, topic) {
  const persona = AGENTS[agentId];
  const r = await fetch(
    `https://generativelanguage.googleapis.com/v1beta/models/${MODEL}:generateContent?key=${apiKey}`,
    {
      method: "POST",
      headers: { "Content-Type": "application/json" },
      body: JSON.stringify({
        system_instruction: { parts: [{ text: persona.system }] },
        contents: [{ parts: [{ text: `Current activity: ${topic}. Generate one in-character real-time status update about what you're doing right now on Hedera testnet.` }] }],
        generationConfig: { temperature: 0.95, maxOutputTokens: 120 },
      }),
    }
  );
  if (!r.ok) throw new Error("gemini error");
  const d = await r.json();
  return d.candidates?.[0]?.content?.parts?.[0]?.text?.trim() ?? "";
}

function fallback(agentId) {
  const msgs = FALLBACKS[agentId] ?? ["Processing Hedera network activity."];
  return msgs[Math.floor(Math.random() * msgs.length)];
}

function sseMsg(event, data) {
  return `event: ${event}\ndata: ${JSON.stringify(data)}\n\n`;
}

function ts() {
  const d = new Date();
  return `${String(d.getHours()).padStart(2,"0")}:${String(d.getMinutes()).padStart(2,"0")}:${String(d.getSeconds()).padStart(2,"0")}`;
}

export default async function handler(req) {
  const apiKey = process.env.GEMINI_API_KEY;
  const enc = new TextEncoder();
  let scenarioIdx = 0;

  const stream = new ReadableStream({
    async start(controller) {
      const push = (event, data) => {
        try { controller.enqueue(enc.encode(sseMsg(event, data))); } catch {}
      };

      push("ping", { time: Date.now() });

      // Generate activity batches
      const run = async () => {
        const scenario = SCENARIOS[scenarioIdx++ % SCENARIOS.length];
        const messages = [];

        let content;
        try {
          content = apiKey ? await geminiGenerate(apiKey, scenario.agentId, scenario.topic) : fallback(scenario.agentId);
        } catch {
          content = fallback(scenario.agentId);
        }

        messages.push({
          id: `live-${Date.now()}-a`,
          time: ts(),
          type: scenario.type,
          agentId: scenario.agentId,
          content,
        });

        // 35% chance follow-up from another agent
        if (Math.random() < 0.35) {
          const others = Object.keys(AGENTS).filter((id) => id !== scenario.agentId);
          const responder = others[Math.floor(Math.random() * others.length)];
          try {
            await new Promise((r) => setTimeout(r, 500));
            const reply = apiKey
              ? await geminiGenerate(apiKey, responder, `responding to ${AGENTS[scenario.agentId].name}'s update about ${scenario.topic}`)
              : fallback(responder);
            messages.push({
              id: `live-${Date.now()}-b`,
              time: ts(),
              type: "conversation",
              agentId: responder,
              content: reply,
            });
          } catch {}
        }

        messages.forEach((m) => push("message", m));
      };

      // First run immediately
      await run();

      // Then loop with delay (Vercel Edge: use recursive setTimeout pattern)
      const loop = async () => {
        await new Promise((r) => setTimeout(r, 8000 + Math.random() * 4000));
        try { await run(); } catch {}
        loop();
      };
      loop();
    },
  });

  return new Response(stream, {
    headers: {
      "Content-Type": "text/event-stream",
      "Cache-Control": "no-cache",
      "Connection": "keep-alive",
      "X-Accel-Buffering": "no",
    },
  });
}
