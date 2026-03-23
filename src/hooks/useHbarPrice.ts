/**
 * useHbarPrice — shared hook for live HBAR price from Hedera Mirror Node
 * Used by TopBar and DashboardPanel to avoid duplicate fetches
 */
import { useState, useEffect } from "react";
import { create } from "zustand";

interface HbarPriceStore {
  price: number;
  change: "up" | "down" | "flat";
  setPrice: (price: number, change: "up" | "down" | "flat") => void;
}

export const useHbarPriceStore = create<HbarPriceStore>((set) => ({
  price: 0.0641,
  change: "flat",
  setPrice: (price, change) => set({ price, change }),
}));

export function useHbarPrice() {
  const { price, change, setPrice } = useHbarPriceStore();
  const [prevPrice, setPrevPrice] = useState(0.0641);

  useEffect(() => {
    const fetchPrice = async () => {
      try {
        const res = await fetch("/api/hedera?path=/api/v1/network/exchangerate");
        if (!res.ok) return;
        const json = await res.json();
        const rate = json?.current_rate;
        if (rate?.hbar_equivalent && rate?.cent_equivalent) {
          const newPrice = (rate.cent_equivalent / rate.hbar_equivalent) * 0.01;
          const newChange: "up" | "down" | "flat" =
            newPrice > prevPrice ? "up" : newPrice < prevPrice ? "down" : "flat";
          setPrevPrice(newPrice);
          setPrice(newPrice, newChange);
        }
      } catch { /* ignore */ }
    };
    fetchPrice();
    const id = setInterval(fetchPrice, 30_000);
    return () => clearInterval(id);
  }, [setPrice, prevPrice]);

  return { price, change };
}
