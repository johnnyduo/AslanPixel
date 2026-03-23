/**
 * SaucerSwap Testnet API client
 * API: https://testnet.saucerswap.finance/api/v1
 * Docs: https://app.gitbook.com/o/hgFQuEAoGYJFLagqRyPn/s/WOuGHxUOjbqOmjvEOG8m
 */

const SAUCER_BASE = "https://testnet.saucerswap.finance/api/v1";

// Known testnet token IDs
export const TESTNET_TOKENS = {
  HBAR:  "HBAR",
  USDC:  "0.0.429274",  // testnet USDC
  SAUCE: "0.0.731861",  // testnet SAUCE
  HBARX: "0.0.887802",  // testnet HBARX
  WBTC:  "0.0.1183726", // testnet WBTC
};

async function saucerFetch(path) {
  const res = await fetch(`${SAUCER_BASE}${path}`, {
    headers: { "Accept": "application/json" },
  });
  if (!res.ok) throw new Error(`SaucerSwap API ${res.status}: ${path}`);
  return res.json();
}

export async function getSaucerSwapPools() {
  try {
    const data = await saucerFetch("/pools?limit=10");
    return (data.pools ?? data ?? []).map((p) => ({
      id: p.id ?? p.contractId,
      pairName: `${p.tokenA?.symbol ?? "?"} / ${p.tokenB?.symbol ?? "?"}`,
      liquidity: p.liquidity ?? p.tvl ?? "N/A",
      volume24h: p.volume24h ?? "N/A",
      fee: p.fee ?? "0.3%",
    }));
  } catch {
    // Return mock data for demo
    return [
      { id: "0.0.1062783", pairName: "HBAR / USDC", liquidity: "$2,441,820", volume24h: "$187,340", fee: "0.3%" },
      { id: "0.0.1061210", pairName: "HBAR / SAUCE", liquidity: "$1,203,440", volume24h: "$94,120",  fee: "0.3%" },
    ];
  }
}

export async function getSaucerSwapQuote(fromToken, toToken, amountIn) {
  try {
    const fromId = TESTNET_TOKENS[fromToken] ?? fromToken;
    const toId   = TESTNET_TOKENS[toToken]   ?? toToken;
    const data   = await saucerFetch(`/swap/quote?tokenIn=${fromId}&tokenOut=${toId}&amountIn=${amountIn * 1e8}`);
    return {
      amountIn,
      amountOut: ((data.amountOut ?? data.expectedOutput ?? 0) / 1e8).toFixed(6),
      slippage: data.priceImpact ?? data.slippage ?? "0.12%",
      route: data.route ?? [fromToken, toToken],
      fee: data.fee ?? "0.3%",
    };
  } catch {
    // Fallback mock quote
    const rates = { "HBAR-USDC": 0.0641, "HBAR-SAUCE": 0.312 };
    const key = `${fromToken}-${toToken}`;
    return {
      amountIn,
      amountOut: ((rates[key] ?? 1) * amountIn).toFixed(6),
      slippage: "0.12%",
      route: [fromToken, toToken],
      fee: "0.3%",
      mock: true,
    };
  }
}

export async function getSaucerSwapTokenPrice(tokenId) {
  try {
    const data = await saucerFetch(`/tokens/${tokenId}/price`);
    return data.priceUsd ?? data.price ?? null;
  } catch {
    return null;
  }
}

export async function getSaucerSwapTVL() {
  try {
    const data = await saucerFetch("/stats");
    return data.totalValueLockedUsd ?? data.tvl ?? null;
  } catch {
    return null;
  }
}
