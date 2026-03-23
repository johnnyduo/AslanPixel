/**
 * AslanGuild Backend — Multi-Agent Orchestrator
 * Stack: Express + Hedera SDK + Gemini 2.0 Flash Lite + SaucerSwap Testnet
 * Streams real-time agent activity via SSE
 */
import express from "express";
import cors from "cors";
import { config } from "dotenv";
import { runAgentWorkflow } from "./agents/orchestrator.js";
import { saucerswapRouter } from "./routes/saucerswap.js";
import { hederaRouter } from "./routes/hedera.js";

config();

const app = express();
app.use(cors({ origin: "*" }));
app.use(express.json());

// Health check
app.get("/health", (_, res) => res.json({ status: "ok", time: Date.now() }));

// SaucerSwap testnet routes
app.use("/api/saucerswap", saucerswapRouter);

// Hedera network routes (mirror node, HCS, HTS)
app.use("/api/hedera", hederaRouter);

/**
 * POST /api/quest
 * Triggers the full multi-agent workflow
 * Body: { intent: string, walletAddress?: string }
 * Response: SSE stream of agent events
 */
app.post("/api/quest", async (req, res) => {
  const { intent, walletAddress } = req.body;
  if (!intent) return res.status(400).json({ error: "intent required" });

  // Server-Sent Events setup
  res.setHeader("Content-Type", "text/event-stream");
  res.setHeader("Cache-Control", "no-cache");
  res.setHeader("Connection", "keep-alive");
  res.setHeader("X-Accel-Buffering", "no");
  res.flushHeaders();

  const emit = (event, data) => {
    res.write(`event: ${event}\ndata: ${JSON.stringify(data)}\n\n`);
  };

  try {
    await runAgentWorkflow({ intent, walletAddress, emit });
    emit("done", { status: "completed" });
  } catch (err) {
    emit("error", { message: err.message });
  } finally {
    res.end();
  }
});

/**
 * GET /api/quest/stream
 * Long-running SSE: auto-generates agent activity every 10s
 * Frontend subscribes to this for live timeline
 */
app.get("/api/quest/stream", async (req, res) => {
  res.setHeader("Content-Type", "text/event-stream");
  res.setHeader("Cache-Control", "no-cache");
  res.setHeader("Connection", "keep-alive");
  res.setHeader("X-Accel-Buffering", "no");
  res.flushHeaders();

  const { generateLiveActivity } = await import("./agents/liveActivity.js");

  const emit = (event, data) => {
    if (!res.writableEnded) {
      res.write(`event: ${event}\ndata: ${JSON.stringify(data)}\n\n`);
    }
  };

  // Emit initial ping
  emit("ping", { time: Date.now() });

  // Generate live activity on interval
  const interval = setInterval(async () => {
    try {
      const messages = await generateLiveActivity();
      messages.forEach((msg) => emit("message", msg));
    } catch (e) {
      emit("error", { message: e.message });
    }
  }, 8000 + Math.random() * 4000);

  req.on("close", () => clearInterval(interval));
});

const PORT = process.env.PORT || 3001;
app.listen(PORT, () => console.log(`AslanGuild backend on :${PORT}`));
