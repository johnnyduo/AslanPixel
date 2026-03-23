/**
 * Hedera network routes — Mirror Node, HCS, HTS
 */
import { Router } from "express";
import { queryMirrorNode, getHbarPrice, getAccountBalance, getLatestHCSMessages } from "../hedera/mirror.js";
import { submitHCSMessage } from "../hedera/hcs.js";
import { transferHBAR } from "../hedera/agentKit.js";

export const hederaRouter = Router();

// GET /api/hedera/price — HBAR price from Mirror Node
hederaRouter.get("/price", async (_, res) => {
  try {
    const price = await getHbarPrice();
    res.json({ hbarUsd: price, network: "testnet", time: Date.now() });
  } catch (e) {
    res.status(500).json({ error: e.message });
  }
});

// GET /api/hedera/account/:id — account balance
hederaRouter.get("/account/:id", async (req, res) => {
  try {
    const balance = await getAccountBalance(req.params.id);
    res.json(balance);
  } catch (e) {
    res.status(500).json({ error: e.message });
  }
});

// GET /api/hedera/hcs/:topicId/messages — latest HCS messages
hederaRouter.get("/hcs/:topicId/messages", async (req, res) => {
  try {
    const messages = await getLatestHCSMessages(req.params.topicId);
    res.json({ topicId: req.params.topicId, messages });
  } catch (e) {
    res.status(500).json({ error: e.message });
  }
});

// POST /api/hedera/hcs/submit — submit HCS message (for quest audit trail)
hederaRouter.post("/hcs/submit", async (req, res) => {
  const { message, topicId } = req.body;
  if (!message) return res.status(400).json({ error: "message required" });
  try {
    const result = await submitHCSMessage(message, topicId);
    res.json(result);
  } catch (e) {
    res.status(500).json({ error: e.message });
  }
});

// POST /api/hedera/transfer — HBAR transfer via Agent Kit
hederaRouter.post("/transfer", async (req, res) => {
  const { to, amount } = req.body;
  if (!to || !amount) return res.status(400).json({ error: "to and amount required" });
  try {
    const result = await transferHBAR(to, parseFloat(amount));
    res.json(result);
  } catch (e) {
    res.status(500).json({ error: e.message });
  }
});

// GET /api/hedera/mirror/* — raw mirror node proxy
hederaRouter.get("/mirror/*", async (req, res) => {
  const path = "/api/v1/" + req.params[0];
  try {
    const data = await queryMirrorNode(path);
    res.json(data);
  } catch (e) {
    res.status(500).json({ error: e.message });
  }
});
