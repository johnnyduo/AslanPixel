/**
 * Vercel API Route: POST /api/quest
 * Runs multi-agent workflow, streams via SSE
 * Compatible with Vercel Edge Runtime for streaming
 */

export const config = { runtime: "edge" };

const MODEL = "gemini-2.0-flash-lite-preview-02-05";

const PERSONAS = {
  scout: {
    name: "Nexus", icon: "◈", color: "hsl(195 100% 55%)",
    system: "You are Nexus, HCS intelligence agent on Hedera. Short, data-driven sentences. Mention HCS topic IDs (0.0.XXXXX), sequence numbers, SaucerSwap testnet pool addresses. Max 2 sentences.",
  },
  strategist: {
    name: "Oryn", icon: "▲", color: "hsl(43 90% 60%)",
    system: "You are Oryn, strategy engine for Hedera DeFi. Use probability percentages, EVM contract addresses, tinyhbar amounts. Reference SaucerSwap routing paths. Max 2 sentences.",
  },
  sentinel: {
    name: "Drax", icon: "◆", color: "hsl(142 70% 50%)",
    system: "You are Drax, risk sentinel. Enforce PolicyManager.sol rules. Blunt and uncompromising. Reference slippage bps, position limits, audit hashes. Max 2 sentences.",
  },
  treasurer: {
    name: "Lyss", icon: "◉", color: "hsl(280 65% 68%)",
    system: "You are Lyss, treasury keeper. Always exact numbers: HBAR in tinyhbar precision, HTS token IDs (0.0.XXXXX), Mirror Node slot numbers. Max 2 sentences.",
  },
  executor: {
    name: "Vex", icon: "▶", color: "hsl(38 92% 55%)",
    system: "You are Vex, TX executor. Always mention TX ID (0.0.X@timestamp format), gas in tinyhbar, testnet.saucerswap.finance confirmations. Max 2 sentences.",
  },
  archivist: {
    name: "Kael", icon: "▣", color: "hsl(0 72% 62%)",
    system: "You are Kael, ledger archivist. SHA-256 hashes, receipt IDs, QuestReceipt.sol, Mirror Node URLs. Write what you archived. Max 2 sentences.",
  },
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
  if (req.method !== "POST") {
    return new Response("Method not allowed", { status: 405 });
  }

  const { intent, walletAddress } = await req.json();
  if (!intent) return new Response(JSON.stringify({ error: "intent required" }), { status: 400 });

  const apiKey = process.env.GEMINI_API_KEY;
  const questId = Date.now();
  const ts = () => new Date().toISOString().slice(11, 19);

  const stream = new ReadableStream({
    async start(controller) {
      const enc = new TextEncoder();
      const push = (event, data) => controller.enqueue(enc.encode(sseMsg(event, data)));

      push("start", { questId, intent, time: ts() });

      // Fetch live SaucerSwap data
      let poolInfo = "HBAR/USDC testnet pool";
      try {
        const r = await fetch("https://testnet.saucerswap.finance/api/v1/pools?limit=3");
        if (r.ok) {
          const d = await r.json();
          const pools = d.pools ?? d ?? [];
          poolInfo = pools[0] ? `${pools[0].tokenA?.symbol}/${pools[0].tokenB?.symbol} pool (${pools[0].contractId ?? pools[0].id})` : poolInfo;
        }
      } catch {}

      // Fetch HBAR price from Mirror Node
      let hbarPrice = "$0.0641";
      try {
        const r = await fetch("https://testnet.mirrornode.hedera.com/api/v1/network/exchangerate");
        if (r.ok) {
          const d = await r.json();
          const usd = d.current_rate?.cent_equivalent / d.current_rate?.hbar_equivalent / 100;
          if (usd) hbarPrice = `$${usd.toFixed(4)}`;
        }
      } catch {}

      const STEPS = [
        { agentId: "scout",      type: "conversation", prompt: `User intent: "${intent}". SaucerSwap testnet shows: ${poolInfo}. HBAR price: ${hbarPrice}. You're scanning HCS and DEX data — report what you find.` },
        { agentId: "scout",      type: "tool_call",    prompt: `Report the specific tool call you're making to gather data for: "${intent}". Include API endpoint, parameters, and result summary.` },
        { agentId: "strategist", type: "decision",     prompt: `Nexus found market data for: "${intent}". HBAR at ${hbarPrice}, top pool: ${poolInfo}. Build a 3-step execution plan with probability weights.` },
        { agentId: "sentinel",   type: "policy",       prompt: `Checking Oryn's plan for "${intent}" against PolicyManager.sol. Verify: slippage <0.25%, position <5%, audit status. State PASS or specific violation.` },
        { agentId: "treasurer",  type: "conversation", prompt: `Budget allocation for: "${intent}". Drax cleared the policy check. State exact HBAR amounts reserved, including gas buffer. Use tinyhbar precision.` },
        { agentId: "executor",   type: "transaction",  prompt: `Executing: "${intent}" on testnet.saucerswap.finance. All approvals received. Generate realistic TX ID and confirmation details.` },
        { agentId: "archivist",  type: "receipt",      prompt: `Store QuestReceipt for quest ${questId}: "${intent}". Generate receipt number, inputHash, outputHash, HCS topic sequence number.` },
      ];

      for (const step of STEPS) {
        try {
          await new Promise((r) => setTimeout(r, 300));
          const content = await gemini(apiKey, step.agentId, step.prompt);
          push("message", {
            id: `${questId}-${step.agentId}-${Date.now()}`,
            time: ts(),
            type: step.type,
            agentId: step.agentId,
            content,
          });
        } catch (e) {
          // Fallback
          push("message", {
            id: `${questId}-${step.agentId}-${Date.now()}`,
            time: ts(),
            type: step.type,
            agentId: step.agentId,
            content: `[${PERSONAS[step.agentId].name}] Processing ${step.type} for quest ${questId}...`,
          });
        }
      }

      const receiptId = Math.floor(Math.random() * 500 + 2000);
      push("done", { questId, receiptId, status: "completed" });
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
