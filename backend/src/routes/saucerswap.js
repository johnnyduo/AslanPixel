/**
 * SaucerSwap Testnet routes
 * Exposes pool data, quotes, and prices to frontend
 */
import { Router } from "express";
import { getSaucerSwapPools, getSaucerSwapQuote, getSaucerSwapTokenPrice, getSaucerSwapTVL } from "../hedera/saucerswap.js";

export const saucerswapRouter = Router();

// GET /api/saucerswap/pools
saucerswapRouter.get("/pools", async (_, res) => {
  try {
    const pools = await getSaucerSwapPools();
    res.json({ pools, source: "testnet.saucerswap.finance", time: Date.now() });
  } catch (e) {
    res.status(500).json({ error: e.message });
  }
});

// GET /api/saucerswap/quote?from=HBAR&to=USDC&amount=100
saucerswapRouter.get("/quote", async (req, res) => {
  const { from = "HBAR", to = "USDC", amount = "100" } = req.query;
  try {
    const quote = await getSaucerSwapQuote(from, to, parseFloat(amount));
    res.json(quote);
  } catch (e) {
    res.status(500).json({ error: e.message });
  }
});

// GET /api/saucerswap/price/:tokenId
saucerswapRouter.get("/price/:tokenId", async (req, res) => {
  try {
    const price = await getSaucerSwapTokenPrice(req.params.tokenId);
    res.json({ tokenId: req.params.tokenId, price });
  } catch (e) {
    res.status(500).json({ error: e.message });
  }
});

// GET /api/saucerswap/tvl
saucerswapRouter.get("/tvl", async (_, res) => {
  try {
    const tvl = await getSaucerSwapTVL();
    res.json({ tvl });
  } catch (e) {
    res.status(500).json({ error: e.message });
  }
});
