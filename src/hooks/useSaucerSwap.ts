/**
 * useSaucerSwap — live pool data from SaucerSwap testnet
 */
import { useState, useEffect } from "react";

export interface SaucerPool {
  id: string;
  tokenA: { symbol: string; priceUsd?: number };
  tokenB: { symbol: string; priceUsd?: number };
  tvlUsd: number;
  volume24h: number;
  fee: number;
}

const FALLBACK_POOLS: SaucerPool[] = [
  { id: "1", tokenA: { symbol: "HBAR" }, tokenB: { symbol: "USDC" }, tvlUsd: 48291, volume24h: 12847, fee: 0.3 },
  { id: "2", tokenA: { symbol: "HBAR" }, tokenB: { symbol: "SAUCE" }, tvlUsd: 31200, volume24h: 8420, fee: 0.3 },
  { id: "3", tokenA: { symbol: "USDC" }, tokenB: { symbol: "SAUCE" }, tvlUsd: 19800, volume24h: 4200, fee: 0.3 },
];

export function useSaucerSwap() {
  const [pools, setPools] = useState<SaucerPool[]>(FALLBACK_POOLS);
  const [loading, setLoading] = useState(true);

  useEffect(() => {
    const fetch_ = async () => {
      try {
        const res = await fetch("/api/saucerswap?path=/pools&limit=5");
        if (!res.ok) throw new Error("non-ok");
        const data = await res.json();
        const raw = data?.pools ?? data ?? [];
        if (!Array.isArray(raw) || raw.length === 0) throw new Error("empty");
        const mapped: SaucerPool[] = raw.slice(0, 5).map((p: any, i: number) => ({
          id: p.id ?? String(i),
          tokenA: { symbol: p.tokenA?.symbol ?? "HBAR", priceUsd: p.tokenA?.priceUsd },
          tokenB: { symbol: p.tokenB?.symbol ?? "USDC", priceUsd: p.tokenB?.priceUsd },
          tvlUsd: Number(p.tvlUsd ?? p.liquidity ?? 0),
          volume24h: Number(p.volume24h ?? p.volume ?? 0),
          fee: Number(p.fee ?? 0.3),
        }));
        setPools(mapped);
      } catch {
        setPools(FALLBACK_POOLS);
      } finally {
        setLoading(false);
      }
    };
    fetch_();
    const id = setInterval(fetch_, 60_000);
    return () => clearInterval(id);
  }, []);

  return { pools, loading };
}
