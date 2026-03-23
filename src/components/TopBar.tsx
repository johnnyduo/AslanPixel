import { useEffect, useState } from "react";
import { Bell, Wallet, TrendingUp, TrendingDown } from "lucide-react";
import { Button } from "@/components/ui/button";

const STATIC_PRICE = 0.0641;

interface HbarPrice {
  value: number;
  change: "up" | "down" | "flat";
}

const TopBar = () => {
  const [hbarPrice, setHbarPrice] = useState<HbarPrice>({ value: STATIC_PRICE, change: "up" });

  useEffect(() => {
    let prevPrice = STATIC_PRICE;

    const fetchPrice = async () => {
      try {
        const res = await fetch("/api/hedera?path=/api/v1/network/exchangerate");
        if (!res.ok) throw new Error("non-ok");
        const json = await res.json();
        // Hedera exchange rate: current_rate.cent_equivalent / current_rate.hbar_equivalent * 0.01
        const rate = json?.current_rate;
        if (rate && rate.hbar_equivalent && rate.cent_equivalent) {
          const price = (rate.cent_equivalent / rate.hbar_equivalent) * 0.01;
          const change: "up" | "down" | "flat" = price > prevPrice ? "up" : price < prevPrice ? "down" : "flat";
          prevPrice = price;
          setHbarPrice({ value: price, change });
        }
      } catch {
        // Backend unavailable — keep static fallback
        setHbarPrice((prev) => prev);
      }
    };

    fetchPrice();
    const interval = setInterval(fetchPrice, 30000);
    return () => clearInterval(interval);
  }, []);

  const priceStr = hbarPrice.value.toFixed(4);
  const TrendIcon = hbarPrice.change === "up" ? TrendingUp : hbarPrice.change === "down" ? TrendingDown : null;
  const trendColor = hbarPrice.change === "up" ? "hsl(142 70% 50%)" : hbarPrice.change === "down" ? "hsl(0 72% 60%)" : "hsl(195 100% 55%)";

  return (
    <header className="h-14 glass-panel-strong flex items-center justify-between px-5 rounded-none border-x-0 border-t-0">
      <div className="flex items-center gap-3">
        <div className="flex items-center gap-2">
          <div className="w-8 h-8 gradient-gold rounded-lg flex items-center justify-center">
            <span className="font-pixel text-xs text-primary-foreground">AP</span>
          </div>
          <div>
            <h1 className="font-pixel text-sm text-gold leading-none">ASLAN PIXEL</h1>
            <p className="text-[10px] text-muted-foreground font-mono">PROJECT v1.0</p>
          </div>
        </div>
      </div>

      <div className="flex items-center gap-2">
        {/* HBAR live price ticker */}
        <div className="flex items-center gap-1.5 px-3 py-1.5 glass-panel text-xs font-mono">
          {TrendIcon && <TrendIcon className="w-3 h-3" style={{ color: trendColor }} />}
          <span className="text-gold font-mono font-medium">HBAR ${priceStr}</span>
        </div>

        <div className="flex items-center gap-1.5 px-3 py-1.5 glass-panel text-xs font-mono">
          <div className="w-2 h-2 rounded-full bg-success animate-pulse-glow" />
          <span className="text-success">Mainnet</span>
        </div>

        <div className="flex items-center gap-1.5 px-3 py-1.5 glass-panel text-xs font-mono">
          <span className="text-gold">ℏ</span>
          <span className="text-foreground">12,847.50</span>
          <span className="text-muted-foreground">HBAR</span>
        </div>

        <Button variant="ghost" size="icon" className="relative">
          <Bell className="w-4 h-4 text-muted-foreground" />
          <span className="absolute top-1.5 right-1.5 w-2 h-2 bg-gold rounded-full" />
        </Button>

        <Button variant="gold" size="sm" className="gap-2">
          <Wallet className="w-3.5 h-3.5" />
          <span className="hidden sm:inline">0x4a...8f2c</span>
          <span className="sm:hidden">Wallet</span>
        </Button>
      </div>
    </header>
  );
};

export default TopBar;
