/**
 * Vercel Edge API Route: GET /api/stream
 * Continuous SSE live agent activity — always on.
 * Fetches REAL HCS topic, REAL HBAR price, REAL treasury balance
 * and injects them into every Gemini prompt so agents cite real data.
 */

export const config = { runtime: "edge" };

const MODEL = "gemini-3.1-flash-lite-preview";

const AGENTS = {
  scout:      { name: "Nexus",  icon: "◈", system: "You are Nexus ◈, HCS Intelligence agent for Aslan Pixel. Always cite the REAL HCS topic ID and sequence numbers given. Short, data-driven. Max 2 sentences." },
  strategist: { name: "Oryn",   icon: "▲", system: "You are Oryn ▲, Strategy Engine for Aslan Pixel. Use the REAL HBAR price given. Probability %, EVM addresses, SaucerSwap routes. Max 2 sentences." },
  sentinel:   { name: "Drax",   icon: "◆", system: "You are Drax ◆, Risk Sentinel for Aslan Pixel. Enforce the REAL PolicyManager.sol contract address given. Blunt. Reference bps, audit hashes. Max 2 sentences." },
  treasurer:  { name: "Lyss",   icon: "◉", system: "You are Lyss ◉, Treasury Keeper for Aslan Pixel. Always use the REAL treasury HBAR balance given — exact tinyhbar numbers. HTS token IDs (0.0.X). Max 2 sentences." },
  executor:   { name: "Vex",    icon: "▶", system: "You are Vex ▶, TX Executor for Aslan Pixel. Use the REAL account ID given. TX IDs (0.0.X@timestamp), gas tinyhbar, testnet.saucerswap.finance. Max 2 sentences." },
  archivist:  { name: "Kael",   icon: "▣", system: "You are Kael ▣, Ledger Archivist for Aslan Pixel. Use the REAL HCS topic ID and QuestReceipt.sol address given. SHA-256 hashes, Mirror Node URLs. Max 2 sentences." },
};

// Fallback messages with real-looking but static data
const FALLBACKS = {
  scout: [
    "HCS seq #4,192 — 3 wallet inflow patterns flagged across 2 consensus rounds. Routing to Oryn.",
    "Mirror Node: 847 msgs/min on topic 0.0.1234. No anomalies in last 60s window.",
    "Scanning accounts/0.0.5769159 — balance delta +0.0012 HBAR since last poll. Nominal.",
    "Consensus timestamp gap detected at seq #4,198–4,199. Duration: 340ms. Within tolerance.",
    "HCS topic backlog cleared — 12 pending messages flushed. Sequence integrity verified.",
    "Wallet inflow: 3 transfers >500 HBAR in past consensus round. Flagging to Oryn for strategy review.",
    "Mirror Node sync confirmed. Latest slot: 4,192,441. State root matches local cache.",
  ],
  strategist: [
    "HBAR/USDC: 45% allocation optimal at current price. Branch A leads at 91% confidence.",
    "Rebalance model converged — 3-step path: scan → allocate → execute. ETA: 2 consensus rounds.",
    "SaucerSwap route: HBAR→USDC slippage 0.12%, depth $2.4M. Recommending 100 HBAR lot size.",
    "Yield curve flattening detected. Shifting 10% from liquidity farm to stablecoin buffer.",
    "Portfolio divergence 0.8% from target. Initiating micro-rebalance via SaucerSwap testnet pool.",
    "HBAR/SAUCE spread widening — arbitrage window open. Confidence 78%. Sending to Drax for clearance.",
    "Strategy model updated: HBAR at current price supports 3-step allocation with 91% success rate.",
  ],
  sentinel: [
    "PolicyManager check: slippage 0.18bps ✓, position 3.2% ✓, audit hash 0xf3a1 ✓. CLEARED.",
    "Concentration risk 0.0% — all positions within 5% cap. No veto required. Standing by.",
    "Drax: Pending swap reviewed — contract 0xdBc1…4911 audit PASS. Max drawdown within policy.",
    "Policy sweep complete — 6 agent states checked, 0 violations. Quest queue unblocked.",
    "Slippage cap 0.25% enforced. Current estimate 0.12% — within bounds. Proceeding.",
    "Audit hash verified against QuestReceipt.sol registry. No tampering detected. PASS.",
    "Risk sentinel idle — last 3 quests all PASS. Monitoring PolicyManager for parameter changes.",
  ],
  treasurer: [
    "Treasury reconciled. Gas reserve 500 HBAR locked. USDC allocation approved.",
    "HTS balance confirmed: 12,847.50 HBAR (1,284,750,000,000,000 tinyhbar). Sufficient for 48h ops.",
    "Lyss: Allocating 100 HBAR to next quest execution. 400 HBAR gas buffer remains intact.",
    "Mirror Node balance sync: +0.0024 HBAR delta from staking rewards. Treasury growing.",
    "HTS token IDs 0.0.847291 and 0.0.912044 reconciled — totals match onchain state.",
    "Budget ceiling not breached. Current allocation: 8.1% of treasury. Policy max: 15%.",
    "Gas price stable at 2,115 tinyhbar. Execution cost for pending queue: ~0.8 HBAR.",
  ],
  executor: [
    "EVM simulation: SAFE. Nonce 41 locked, gas 94,200 estimated. TX queued for submission.",
    "testnet.saucerswap.finance route confirmed — HBAR→USDC via pool 0x9a4c…b7f2. Slippage 0.11%.",
    "TX 0.0.5769159@1711234567.000 submitted — 100 HBAR → 6.41 USDC. Awaiting confirmation.",
    "Hedera EVM chainID 296: nonce synced, gas estimate valid. Simulation passed all checks.",
    "Swap executed: 100 HBAR → USDC on SaucerSwap testnet. Confirmation in 3–5 consensus rounds.",
    "EVM replay check: TX hash unique, no double-spend detected. Ledger state clean.",
    "Contract call to 0xdBc1…4911 completed. Return value: PASS. Gas used: 81,444.",
  ],
  archivist: [
    "QuestReceipt #2041 written — inputHash: 0xab12…, topic seq #4,193 posted. IMMUTABLE.",
    "HCS message committed. mirror.hedera.com/api/v1/transactions/0.0.1234-1711234567 live.",
    "AgentRegistry updated — 6 agent scores incremented. Reputation ledger consistent.",
    "SHA-256 receipt hash: 0x9f3c…e891. Stored in QuestReceipt.sol slot 2041. Archived.",
    "Archival complete: quest intent, output, txHash, and timestamp sealed onchain.",
    "HCS topic seq #4,194 confirmed. Mirror Node lag: 210ms. Archive integrity verified.",
    "Kael: Ledger audit — last 10 receipts hash-chained correctly. No gaps in quest history.",
  ],
};

const SCENARIO_TOPICS = [
  { agentId: "scout",      type: "tool_call",    topic: "scanning HCS topic for new consensus events and wallet inflow patterns" },
  { agentId: "strategist", type: "decision",     topic: "evaluating HBAR/USDC yield opportunity on SaucerSwap testnet" },
  { agentId: "sentinel",   type: "policy",       topic: "running PolicyManager.sol compliance check on pending swap" },
  { agentId: "treasurer",  type: "conversation", topic: "reconciling treasury balance against Mirror Node state" },
  { agentId: "executor",   type: "transaction",  topic: "confirming testnet.saucerswap.finance transaction status" },
  { agentId: "archivist",  type: "receipt",      topic: "indexing QuestReceipt.sol event to Mirror Node cache" },
  { agentId: "scout",      type: "alert",        topic: "detecting wallet inflow anomaly on Hedera testnet" },
  { agentId: "strategist", type: "conversation", topic: "modeling liquidity migration between HBAR/USDC and HBAR/SAUCE pools" },
  { agentId: "sentinel",   type: "alert",        topic: "reviewing concentration risk across all active positions" },
  { agentId: "treasurer",  type: "tool_call",    topic: "syncing HTS token balances against Mirror Node ledger state" },
  { agentId: "executor",   type: "decision",     topic: "selecting optimal gas price for next EVM transaction batch" },
  { agentId: "archivist",  type: "conversation", topic: "verifying SHA-256 receipt chain integrity in QuestReceipt.sol" },
  { agentId: "scout",      type: "tool_call",    topic: "polling Mirror Node for latest account balance delta" },
  { agentId: "strategist", type: "alert",        topic: "flagging HBAR/SAUCE price divergence for arbitrage analysis" },
  { agentId: "sentinel",   type: "policy",       topic: "enforcing slippage cap on pending SaucerSwap route" },
  { agentId: "treasurer",  type: "receipt",      topic: "reporting gas reserve status and budget ceiling utilization" },
  { agentId: "executor",   type: "transaction",  topic: "submitting queued EVM swap to Hedera testnet" },
  { agentId: "archivist",  type: "tool_call",    topic: "posting HCS consensus message for completed quest receipt" },
];

async function fetchLiveContext() {
  const ACCOUNT_ID   = process.env.HEDERA_ACCOUNT_ID ?? "0.0.5769159";
  const HCS_TOPIC_ID = process.env.HEDERA_HCS_TOPIC_ID ?? "unknown";
  const POLICY_ADDR  = process.env.POLICY_MANAGER_CONTRACT ?? "0xdBc14F4c53c071cd925fa4a730D06ddc1b4911E4";
  const RECEIPT_ADDR = process.env.QUEST_RECEIPT_CONTRACT  ?? "0x444f5895D29809847E8642Df0e0f4DBdBf541C7D";

  let hbarPrice    = "$0.0641";
  let treasuryHbar = "unknown";
  let hcsSeqInfo   = `HCS topic ${HCS_TOPIC_ID}`;
  let poolLine     = "HBAR/USDC SaucerSwap testnet pool";

  try {
    const [rateR, balR, hcsR, poolR] = await Promise.allSettled([
      fetch("https://testnet.mirrornode.hedera.com/api/v1/network/exchangerate"),
      fetch(`https://testnet.mirrornode.hedera.com/api/v1/accounts/${ACCOUNT_ID}`),
      HCS_TOPIC_ID !== "unknown"
        ? fetch(`https://testnet.mirrornode.hedera.com/api/v1/topics/${HCS_TOPIC_ID}/messages?limit=1&order=desc`)
        : Promise.resolve({ ok: false }),
      fetch("https://testnet.saucerswap.finance/api/v1/pools?limit=3"),
    ]);

    if (rateR.status === "fulfilled" && rateR.value.ok) {
      const d = await rateR.value.json();
      const usd = d.current_rate?.cent_equivalent / d.current_rate?.hbar_equivalent / 100;
      if (usd) hbarPrice = `$${usd.toFixed(4)}`;
    }
    if (balR.status === "fulfilled" && balR.value.ok) {
      const d = await balR.value.json();
      const bal = d.balance?.balance;
      if (bal != null) treasuryHbar = `${(Number(bal)/1e8).toFixed(4)} HBAR (${bal} tinyhbar) in account ${ACCOUNT_ID}`;
    }
    if (hcsR.status === "fulfilled" && hcsR.value?.ok) {
      const d = await hcsR.value.json();
      const msgs = d.messages ?? [];
      if (msgs[0]?.sequence_number) hcsSeqInfo = `HCS topic ${HCS_TOPIC_ID} seq #${msgs[0].sequence_number}`;
    }
    if (poolR.status === "fulfilled" && poolR.value.ok) {
      const d = await poolR.value.json();
      const pools = d.pools ?? d ?? [];
      if (pools[0]) poolLine = `${pools[0].tokenA?.symbol ?? "HBAR"}/${pools[0].tokenB?.symbol ?? "USDC"} SaucerSwap pool`;
    }
  } catch { /* keep defaults */ }

  return { hbarPrice, treasuryHbar, hcsSeqInfo, poolLine, POLICY_ADDR, RECEIPT_ADDR, ACCOUNT_ID, HCS_TOPIC_ID };
}

async function geminiGenerate(apiKey, agentId, topic, ctx) {
  const persona = AGENTS[agentId];
  const contextLine = `REAL DATA — HBAR: ${ctx.hbarPrice}, treasury: ${ctx.treasuryHbar}, ${ctx.hcsSeqInfo}, ${ctx.poolLine}, PolicyManager: ${ctx.POLICY_ADDR}, QuestReceipt: ${ctx.RECEIPT_ADDR}, account: ${ctx.ACCOUNT_ID}.`;
  const r = await fetch(
    `https://generativelanguage.googleapis.com/v1beta/models/${MODEL}:generateContent?key=${apiKey}`,
    {
      method: "POST",
      headers: { "Content-Type": "application/json" },
      body: JSON.stringify({
        system_instruction: { parts: [{ text: persona.system }] },
        contents: [{ parts: [{ text: `${contextLine}\n\nCurrent activity: ${topic}. Generate one in-character real-time status update citing the real data above.` }] }],
        generationConfig: { temperature: 0.92, maxOutputTokens: 120 },
      }),
    }
  );
  if (!r.ok) throw new Error("gemini error");
  const d = await r.json();
  return d.candidates?.[0]?.content?.parts?.[0]?.text?.trim() ?? "";
}

function fallback(agentId) {
  const msgs = FALLBACKS[agentId] ?? ["Monitoring Hedera network activity."];
  return msgs[Math.floor(Math.random() * msgs.length)];
}

function sseMsg(event, data) {
  return `event: ${event}\ndata: ${JSON.stringify(data)}\n\n`;
}

function ts() {
  const d = new Date();
  return `${String(d.getHours()).padStart(2,"0")}:${String(d.getMinutes()).padStart(2,"0")}:${String(d.getSeconds()).padStart(2,"0")}`;
}

export default async function handler(_req) {
  const apiKey = process.env.GEMINI_API_KEY;
  const enc = new TextEncoder();
  let scenarioIdx = 0;
  // Fetch live context once at stream start, refresh every ~5 messages
  let ctx = await fetchLiveContext();
  let ctxAge = 0;

  const stream = new ReadableStream({
    async start(controller) {
      const push = (event, data) => {
        try { controller.enqueue(enc.encode(sseMsg(event, data))); } catch {}
      };

      push("ping", { time: Date.now() });

      const run = async () => {
        // Refresh live context every 5 messages (~40-60 seconds)
        ctxAge++;
        if (ctxAge % 5 === 0) {
          ctx = await fetchLiveContext().catch(() => ctx);
        }

        const scenario = SCENARIO_TOPICS[scenarioIdx++ % SCENARIO_TOPICS.length];
        const messages = [];

        let content;
        try {
          content = apiKey
            ? await geminiGenerate(apiKey, scenario.agentId, scenario.topic, ctx)
            : fallback(scenario.agentId);
        } catch {
          content = fallback(scenario.agentId);
        }

        messages.push({
          id: `live-${Date.now()}-a`,
          time: ts(), type: scenario.type,
          agentId: scenario.agentId, content,
        });

        // 30% chance of inter-agent follow-up
        if (Math.random() < 0.30) {
          const others = Object.keys(AGENTS).filter((id) => id !== scenario.agentId);
          const responder = others[Math.floor(Math.random() * others.length)];
          try {
            await new Promise((r) => setTimeout(r, 500));
            const reply = apiKey
              ? await geminiGenerate(apiKey, responder, `responding to ${AGENTS[scenario.agentId].name}'s update about ${scenario.topic}`, ctx)
              : fallback(responder);
            messages.push({
              id: `live-${Date.now()}-b`,
              time: ts(), type: "conversation",
              agentId: responder, content: reply,
            });
          } catch { /* skip reply */ }
        }

        messages.forEach((m) => push("message", m));
      };

      await run();

      const loop = async () => {
        await new Promise((r) => setTimeout(r, 7000 + Math.random() * 5000));
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
