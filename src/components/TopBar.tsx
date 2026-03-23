import { useEffect, useState } from "react";
import { useNavigate } from "react-router-dom";
import { Bell, Wallet, TrendingUp, TrendingDown, BarChart2 } from "lucide-react";
import { JsonRpcProvider, Contract } from "ethers";
import { Button } from "@/components/ui/button";
import { useWallet } from "@/hooks/useWallet";
import { useHbarPrice } from "@/hooks/useHbarPrice";

// MockUSDC EVM address on Hedera testnet (6 decimals)
const MOCK_USDC_EVM = "0x152Bf42A48677b678c658E452788ea2687525BF7";
const ERC20_BALANCE_ABI = ["function balanceOf(address) view returns (uint256)"];
const HEDERA_TESTNET_RPC = "https://testnet.hashio.io/api";

interface TopBarProps {
  onDashboardToggle?: () => void;
}

const TopBar = ({ onDashboardToggle }: TopBarProps) => {
  const [hbarBalance, setHbarBalance] = useState<number | null>(null);
  const [usdcBalance, setUsdcBalance] = useState<number | null>(null);
  const { shortAddress, isConnected, address, openModal } = useWallet();
  const navigate = useNavigate();
  const { price: hbarPriceValue, change: hbarChange } = useHbarPrice();

  // Fetch HBAR + USDC balance when wallet is connected
  useEffect(() => {
    if (!isConnected || !address) {
      setHbarBalance(null);
      setUsdcBalance(null);
      return;
    }

    const fetchBalances = async () => {
      const provider = new JsonRpcProvider(HEDERA_TESTNET_RPC);

      // HBAR balance via eth_getBalance (in wei = tinybar on Hedera)
      try {
        const weiBalance = await provider.getBalance(address);
        // Hedera: 1 HBAR = 1e8 tinybar, but eth_getBalance returns tinybar as wei-equivalent
        setHbarBalance(Number(weiBalance) / 1e8);
      } catch {
        // fallback to mirror node
        try {
          const res = await fetch(`/api/hedera?path=/api/v1/accounts/${address}`);
          if (res.ok) {
            const json = await res.json();
            if (json?.balance?.balance != null) setHbarBalance(json.balance.balance / 1e8);
          }
        } catch { /* ignore */ }
      }

      // USDC balance via ERC-20 balanceOf (always correct regardless of token association)
      try {
        const usdc = new Contract(MOCK_USDC_EVM, ERC20_BALANCE_ABI, provider);
        const raw: bigint = await usdc.balanceOf(address);
        setUsdcBalance(Number(raw) / 1e6);
      } catch {
        // ignore
      }
    };

    fetchBalances();
    const interval = setInterval(fetchBalances, 30000);
    return () => clearInterval(interval);
  }, [isConnected, address]);

  const priceStr = hbarPriceValue.toFixed(4);
  const TrendIcon = hbarChange === "up" ? TrendingUp : hbarChange === "down" ? TrendingDown : null;
  const trendColor = hbarChange === "up" ? "hsl(142 70% 50%)" : hbarChange === "down" ? "hsl(0 72% 60%)" : "hsl(195 100% 55%)";

  const hbarBalanceStr = hbarBalance != null
    ? hbarBalance >= 1000
      ? hbarBalance.toLocaleString("en-US", { minimumFractionDigits: 2, maximumFractionDigits: 2 })
      : hbarBalance.toFixed(4)
    : null;

  const usdcBalanceStr = usdcBalance != null
    ? usdcBalance >= 1000
      ? usdcBalance.toLocaleString("en-US", { minimumFractionDigits: 0, maximumFractionDigits: 0 })
      : usdcBalance.toFixed(2)
    : null;

  return (
    <header className="h-14 glass-panel-strong flex items-center justify-between px-5 rounded-none border-x-0 border-t-0">
      <div className="flex items-center gap-3">
        <button
          onClick={() => navigate("/")}
          className="flex items-center gap-2 hover:opacity-80 transition-opacity cursor-pointer"
        >
          <div className="w-8 h-8 gradient-gold rounded-lg flex items-center justify-center">
            <span className="font-pixel text-xs text-primary-foreground">AP</span>
          </div>
          <div>
            <h1 className="font-pixel text-sm text-gold leading-none">ASLAN PIXEL</h1>
            <p className="text-[10px] text-muted-foreground font-mono">PROJECT v1.0</p>
          </div>
        </button>
      </div>

      <div className="flex items-center gap-2">
        {/* HBAR live price ticker */}
        <div className="flex items-center gap-1.5 px-3 py-1.5 glass-panel text-xs font-mono">
          {TrendIcon && <TrendIcon className="w-3 h-3" style={{ color: trendColor }} />}
          <span className="text-gold font-mono font-medium">HBAR ${priceStr}</span>
        </div>

        {/* Wallet HBAR balance — shown when connected */}
        {isConnected && hbarBalanceStr != null && (
          <div className="flex items-center gap-1.5 px-3 py-1.5 glass-panel text-xs font-mono">
            <span className="text-muted-foreground">⬡</span>
            <span className="text-foreground font-mono">{hbarBalanceStr}</span>
            <span className="text-muted-foreground text-[10px]">HBAR</span>
            {usdcBalanceStr != null && (
              <>
                <span className="text-border mx-0.5">|</span>
                <span className="text-cyan font-mono">{usdcBalanceStr}</span>
                <span className="text-muted-foreground text-[10px]">USDC</span>
              </>
            )}
          </div>
        )}

        <div className="flex items-center gap-1.5 px-3 py-1.5 glass-panel text-xs font-mono">
          <div className="w-2 h-2 rounded-full bg-success animate-pulse-glow" />
          <span className="text-success">Testnet</span>
        </div>

        {/* Dashboard toggle */}
        {onDashboardToggle && (
          <Button
            variant="ghost"
            size="icon"
            className="relative"
            onClick={onDashboardToggle}
            title="Pixel Dashboard"
          >
            <BarChart2 className="w-4 h-4 text-muted-foreground hover:text-gold transition-colors" />
          </Button>
        )}

        <Button variant="ghost" size="icon" className="relative">
          <Bell className="w-4 h-4 text-muted-foreground" />
          <span className="absolute top-1.5 right-1.5 w-2 h-2 bg-gold rounded-full" />
        </Button>

        {/* Wallet connect button — real Reown AppKit */}
        <Button
          variant="gold"
          size="sm"
          className="gap-2"
          onClick={() => openModal()}
        >
          {isConnected ? (
            <>
              <div className="w-2 h-2 rounded-full bg-success animate-pulse" />
              <span className="hidden sm:inline font-mono">{shortAddress}</span>
              <span className="sm:hidden">Connected</span>
            </>
          ) : (
            <>
              <Wallet className="w-3.5 h-3.5" />
              <span className="hidden sm:inline">Connect Wallet</span>
              <span className="sm:hidden">Wallet</span>
            </>
          )}
        </Button>
      </div>
    </header>
  );
};

export default TopBar;
