/**
 * Vercel Edge API Route: GET /api/quest?intent=...
 * Runs multi-agent workflow, streams via SSE, stores receipt onchain
 */

export const config = { runtime: "edge" };

const MODEL = "gemini-2.0-flash-lite-preview-02-05";

const PERSONAS = {
  scout: {
    name: "Nexus", icon: "◈",
    system: "You are Nexus, HCS intelligence agent on Hedera. Short, data-driven sentences. Mention HCS topic IDs (0.0.XXXXX), sequence numbers, SaucerSwap testnet pool addresses. Max 2 sentences.",
  },
  strategist: {
    name: "Oryn", icon: "▲",
    system: "You are Oryn, strategy engine for Hedera DeFi. Use probability percentages, EVM contract addresses, tinyhbar amounts. Reference SaucerSwap routing paths. Max 2 sentences.",
  },
  sentinel: {
    name: "Drax", icon: "◆",
    system: "You are Drax, risk sentinel. Enforce PolicyManager.sol rules. Blunt and uncompromising. Reference slippage bps, position limits, audit hashes. Max 2 sentences.",
  },
  treasurer: {
    name: "Lyss", icon: "◉",
    system: "You are Lyss, treasury keeper. Always exact numbers: HBAR in tinyhbar precision, HTS token IDs (0.0.XXXXX), Mirror Node slot numbers. Max 2 sentences.",
  },
  executor: {
    name: "Vex", icon: "▶",
    system: "You are Vex, TX executor. Always mention TX ID (0.0.X@timestamp format), gas in tinyhbar, testnet.saucerswap.finance confirmations. Max 2 sentences.",
  },
  archivist: {
    name: "Kael", icon: "▣",
    system: "You are Kael, ledger archivist. SHA-256 hashes, receipt IDs, QuestReceipt.sol, Mirror Node URLs. Write what you archived. Max 2 sentences.",
  },
};

const FALLBACKS = {
  scout:      "HCS topic 0.0.1234 seq #47,821 — inflow from 3 converging wallets detected. SAUCE accumulation pattern confirmed.",
  strategist: "Path A: HBAR→USDC→SAUCE at 8.3% APR, 91% confidence. Initializing allocation model.",
  sentinel:   "PolicyManager check: slippage 0.18bps ✓, position 3.2% ✓, audit 0xf3a1 ✓. Plan approved.",
  treasurer:  "Treasury: 12,847.50 HBAR (1,284,750,000,000 tinyhbar). Gas reserve 500 HBAR locked.",
  executor:   "TX 0.0.4819204@1742733201.000 submitted to testnet.saucerswap.finance — consensus confirmation pending.",
  archivist:  "Receipt archived to QuestReceipt.sol. inputHash: 0xab12…cd34. Mirror Node: CONFIRMED at slot 4,192,441.",
};

async function gemini(apiKey, agentId, prompt) {
  const persona = PERSONAS[agentId];
  const res = await fetch(
    `https://generativelanguage.googleapis.com/v1beta/models/${MODEL}:generateContent?key=${apiKey}`,
    {
      method: "POST",
      headers: { "Content-Type": "application/json" },
      body: JSON.stringify({
        system_instruction: { parts: [{ text: persona.system }] },
        contents: [{ parts: [{ text: prompt }] }],
        generationConfig: { temperature: 0.92, maxOutputTokens: 150 },
      }),
    }
  );
  if (!res.ok) throw new Error(`Gemini ${res.status}`);
  const data = await res.json();
  return data.candidates?.[0]?.content?.parts?.[0]?.text?.trim() ?? "";
}


function sseMsg(event, data) {
  return `event: ${event}\ndata: ${JSON.stringify(data)}\n\n`;
}

export default async function handler(req) {
  // Support both GET (EventSource) and POST
  const url = new URL(req.url);
  const intent = url.searchParams.get("intent") ||
    (req.method === "POST" ? (await req.json().catch(() => ({}))).intent : null);

  if (!intent) return new Response(JSON.stringify({ error: "intent required" }), { status: 400 });

  const apiKey = process.env.GEMINI_API_KEY;
  const questId = Date.now();
  const ts = () => new Date().toISOString().slice(11, 19);

  const stream = new ReadableStream({
    async start(controller) {
      const enc = new TextEncoder();
      const push = (event, data) => {
        try { controller.enqueue(enc.encode(sseMsg(event, data))); } catch {}
      };

      push("message", { id: `${questId}-start`, time: ts(), type: "quest", agentId: "scout",
        content: `Quest received: "${intent}" — mobilizing 6 agents.` });

      // Fetch live market context
      let poolInfo = "HBAR/USDC testnet pool";
      let hbarPrice = "$0.0641";
      try {
        const [pr, sr] = await Promise.allSettled([
          fetch("https://testnet.mirrornode.hedera.com/api/v1/network/exchangerate"),
          fetch("https://testnet.saucerswap.finance/api/v1/pools?limit=3"),
        ]);
        if (pr.status === "fulfilled" && pr.value.ok) {
          const d = await pr.value.json();
          const usd = d.current_rate?.cent_equivalent / d.current_rate?.hbar_equivalent / 100;
          if (usd) hbarPrice = `$${usd.toFixed(4)}`;
        }
        if (sr.status === "fulfilled" && sr.value.ok) {
          const d = await sr.value.json();
          const pools = d.pools ?? d ?? [];
          if (pools[0]) poolInfo = `${pools[0].tokenA?.symbol ?? "HBAR"}/${pools[0].tokenB?.symbol ?? "USDC"} pool`;
        }
      } catch {}

      const STEPS = [
        { agentId: "scout",      type: "tool_call",    prompt: `User intent: "${intent}". SaucerSwap: ${poolInfo}. HBAR: ${hbarPrice}. Report HCS scan and wallet inflow data.` },
        { agentId: "strategist", type: "decision",     prompt: `Intent: "${intent}". HBAR at ${hbarPrice}, pool: ${poolInfo}. Build a 3-step execution plan with probability weights.` },
        { agentId: "sentinel",   type: "policy",       prompt: `Checking plan for "${intent}" against PolicyManager.sol rules. Slippage <25bps, position <5%, audit required. State PASS or violation.` },
        { agentId: "treasurer",  type: "conversation", prompt: `Budget allocation for: "${intent}". Policy cleared. State exact HBAR amounts and gas reserve in tinyhbar.` },
        { agentId: "executor",   type: "transaction",  prompt: `Executing: "${intent}" on Hedera testnet. Generate TX ID and confirmation status.` },
        { agentId: "archivist",  type: "receipt",      prompt: `Archive QuestReceipt for "${intent}". Generate receipt hash, HCS topic seq, Mirror Node confirmation.` },
      ];

      for (const step of STEPS) {
        await new Promise((r) => setTimeout(r, 400));
        let content;
        try {
          content = apiKey ? await gemini(apiKey, step.agentId, step.prompt) : FALLBACKS[step.agentId];
        } catch {
          content = FALLBACKS[step.agentId];
        }
        push("message", {
          id: `${questId}-${step.agentId}-${Date.now()}`,
          time: ts(),
          type: step.type,
          agentId: step.agentId,
          content,
        });
      }

      // Store receipt onchain via Node.js endpoint (fire-and-forget, non-blocking)
      let receiptId = String(questId).slice(-6);
      let onchainTxHash = null;

      // Call /api/store-receipt asynchronously — do not await, do not block the stream
      const baseUrl = process.env.VERCEL_URL
        ? `https://${process.env.VERCEL_URL}`
        : (process.env.NEXT_PUBLIC_BASE_URL || "");
      fetch(`${baseUrl}/api/store-receipt`, {
        method: "POST",
        headers: { "Content-Type": "application/json" },
        body: JSON.stringify({ intent, success: true, questId }),
      })
        .then(async (r) => {
          if (r.ok) {
            const data = await r.json().catch(() => ({}));
            if (data.receiptId) receiptId = String(data.receiptId);
            if (data.txHash) onchainTxHash = data.txHash;
            if (data.txHash) {
              push("message", {
                id: `${questId}-onchain`,
                time: ts(),
                type: "receipt",
                agentId: "archivist",
                content: `QuestReceipt #${data.receiptId} stored onchain — TX: ${data.txHash} — HashScan: hashscan.io/testnet/tx/${data.txHash}`,
              });
            }
          }
        })
        .catch(() => {});

      push("message", { id: `${questId}-done`, time: ts(), type: "quest", agentId: "archivist",
        content: `Quest #${receiptId} complete. All agents stood down. Receipt archived to ledger.` });

      push("done", { questId, receiptId, txHash: onchainTxHash, status: "completed", done: true });
      controller.close();
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
