/**
 * PaymentGate — x402-style agent wage payment modal
 * Shown before vote panel. Requires 1 USDC to activate agents.
 * If wallet connected on Hedera testnet (MetaMask/EVM) → real ERC-20 USDC transfer
 * Otherwise → demo mode bypass (shows payment simulation)
 */
import { useState } from "react";
import { createPortal } from "react-dom";
import { Zap, CheckCircle, Loader2, AlertTriangle, ExternalLink } from "lucide-react";
import { useAppKitAccount, useAppKitState, useAppKitProvider } from "@reown/appkit/react";
import { BrowserProvider, Contract } from "ethers";
import { useHbarPrice } from "@/hooks/useHbarPrice";

// MockUSDC EVM address on Hedera testnet (6 decimals)
const MOCK_USDC_EVM = "0x152Bf42A48677b678c658E452788ea2687525BF7";
// Treasury EVM address (AgentRegistry deployer / receives wages)
const TREASURY_EVM  = "0x8B90AA6D1A12111C8F08C8B9Af4cca9f90336CC4";
const WAGE_USDC = "1.00";
const WAGE_RAW  = 1_000_000n; // 1 USDC · 6 decimals

const ERC20_ABI = [
  "function transfer(address to, uint256 amount) returns (bool)",
  "function balanceOf(address) view returns (uint256)",
];

interface PaymentGateProps {
  intent: string;
  onPaid: () => void;
  onDismiss: () => void;
}

const AGENT_SHARES = [
  { id: "scout",      name: "Nexus", icon: "◈", role: "HCS Intel",    share: "0.20", color: "hsl(195 100% 55%)" },
  { id: "strategist", name: "Oryn",  icon: "▲", role: "Strategy",     share: "0.20", color: "hsl(43 90% 60%)" },
  { id: "sentinel",   name: "Drax",  icon: "◆", role: "Risk Guard",   share: "0.15", color: "hsl(0 72% 60%)" },
  { id: "treasurer",  name: "Lyss",  icon: "◉", role: "Treasury",     share: "0.15", color: "hsl(280 65% 68%)" },
  { id: "executor",   name: "Vex",   icon: "▶", role: "TX Exec",      share: "0.20", color: "hsl(142 70% 50%)" },
  { id: "archivist",  name: "Kael",  icon: "▣", role: "Archivist",    share: "0.10", color: "hsl(38 92% 55%)" },
];

type PayState = "idle" | "signing" | "broadcasting" | "confirmed" | "demo";

export default function PaymentGate({ intent, onPaid, onDismiss }: PaymentGateProps) {
  const [payState, setPayState] = useState<PayState>("idle");
  const [txHash, setTxHash] = useState<string | null>(null);
  const [errMsg, setErrMsg] = useState<string | null>(null);
  const { isConnected, address } = useAppKitAccount();
  const { selectedNetworkId } = useAppKitState();
  const { walletProvider } = useAppKitProvider("eip155");
  const { price } = useHbarPrice();
  const isHedera = selectedNetworkId === "eip155:296";
  const usdcInHbar = price > 0 ? (1 / price).toFixed(1) : "~15";

  const handlePay = async () => {
    setErrMsg(null);

    if (!isConnected || !isHedera || !walletProvider) {
      // Demo mode — simulate payment
      setPayState("demo");
      setTimeout(() => {
        setTxHash(`0x${Array.from({length:64},()=>Math.floor(Math.random()*16).toString(16)).join("")}`);
        setTimeout(() => onPaid(), 1400);
      }, 1200);
      return;
    }

    try {
      setPayState("signing");
      const provider  = new BrowserProvider(walletProvider as Parameters<typeof BrowserProvider>[0]);
      const signer    = await provider.getSigner();
      const usdc      = new Contract(MOCK_USDC_EVM, ERC20_ABI, signer);

      // Check balance first
      const bal: bigint = await usdc.balanceOf(address);
      if (bal < WAGE_RAW) {
        setErrMsg(`Insufficient USDC — you have ${(Number(bal) / 1e6).toFixed(2)}, need 1.00`);
        setPayState("idle");
        return;
      }

      setPayState("broadcasting");
      const tx = await usdc.transfer(TREASURY_EVM, WAGE_RAW);
      setTxHash(tx.hash);
      await tx.wait();
      setPayState("confirmed");
      setTimeout(() => onPaid(), 1200);
    } catch (e: unknown) {
      const msg = e instanceof Error ? e.message : String(e);
      if (msg.includes("user rejected") || msg.includes("ACTION_REJECTED")) {
        setErrMsg("Transaction rejected by user");
      } else {
        setErrMsg(msg.slice(0, 80));
      }
      setPayState("idle");
    }
  };

  const isProcessing = payState === "signing" || payState === "broadcasting";
  const isDone = payState === "confirmed" || payState === "demo";

  if (typeof document === "undefined" || !document.body) return null;

  return createPortal(
    <div
      className="fixed inset-0 z-[9998] flex items-center justify-center p-4"
      style={{ background: "hsl(225 30% 4% / 0.92)", backdropFilter: "blur(6px)" }}
    >
      <div
        className="w-full max-w-sm glass-panel p-4 space-y-3 animate-timeline-enter"
        style={{ border: "1px solid hsl(195 100% 55% / 0.35)", boxShadow: "0 0 40px hsl(195 100% 55% / 0.08)" }}
      >
        {/* Header */}
        <div className="flex items-center gap-2.5">
          <div className="w-8 h-8 rounded-lg flex items-center justify-center shrink-0"
            style={{ background: "hsl(195 100% 55% / 0.12)", border: "1px solid hsl(195 100% 55% / 0.35)" }}>
            <Zap className="w-4 h-4" style={{ color: "hsl(195 100% 55%)" }} />
          </div>
          <div>
            <p className="font-pixel text-[10px] text-cyan tracking-wider">AGENT WAGE — x402</p>
            <p className="text-[9px] font-mono text-muted-foreground mt-0.5">
              HTTP 402 · Payment Required to Execute
            </p>
          </div>
          <div className="ml-auto shrink-0 px-1.5 py-0.5 rounded text-[7px] font-pixel"
            style={{ background: "hsl(195 100% 55% / 0.1)", color: "hsl(195 100% 55%)", border: "1px solid hsl(195 100% 55% / 0.3)" }}>
            HEDERA TESTNET
          </div>
        </div>

        {/* Divider */}
        <div className="h-px" style={{ background: "linear-gradient(90deg, transparent, hsl(195 100% 55% / 0.3), transparent)" }} />

        {/* Quest preview */}
        <div className="px-2 py-1.5 rounded-md"
          style={{ background: "hsl(225 20% 9%)", border: "1px solid hsl(225 15% 18%)" }}>
          <p className="text-[8px] font-pixel text-muted-foreground tracking-wider mb-1">QUEST INTENT</p>
          <p className="text-[10px] font-mono text-secondary-foreground leading-snug truncate">
            {intent.replace(/^\[AUTO\] /, "")}
          </p>
        </div>

        {/* Payment breakdown */}
        <div className="space-y-1.5">
          <p className="text-[8px] font-pixel text-muted-foreground tracking-wider">WAGE DISTRIBUTION</p>
          <div className="grid grid-cols-3 gap-1">
            {AGENT_SHARES.map((a) => (
              <div key={a.id} className="flex items-center gap-1 px-1.5 py-1 rounded"
                style={{ background: a.color + "0a", border: `1px solid ${a.color}20` }}>
                <span className="font-pixel text-[9px]" style={{ color: a.color }}>{a.icon}</span>
                <div className="min-w-0">
                  <p className="text-[7px] font-pixel leading-none" style={{ color: a.color + "cc" }}>{a.name}</p>
                  <p className="text-[7px] font-mono text-muted-foreground leading-none mt-0.5">{a.share} USDC</p>
                </div>
              </div>
            ))}
          </div>
        </div>

        {/* Total */}
        <div className="flex items-center justify-between px-3 py-2 rounded-lg"
          style={{ background: "hsl(195 100% 55% / 0.06)", border: "1px solid hsl(195 100% 55% / 0.25)" }}>
          <div>
            <p className="text-[8px] font-pixel text-muted-foreground">TOTAL WAGE</p>
            <p className="text-[9px] font-mono text-muted-foreground mt-0.5">≈ {usdcInHbar} HBAR · 0.0.5769177</p>
          </div>
          <div className="text-right">
            <p className="text-lg font-mono font-bold text-cyan leading-none">{WAGE_USDC}</p>
            <p className="text-[9px] font-mono text-muted-foreground">USDC</p>
          </div>
        </div>

        {/* Status / TX confirmed */}
        {isDone && txHash && (
          <div className="flex items-center gap-2 px-2 py-1.5 rounded"
            style={{ background: "hsl(142 70% 50% / 0.08)", border: "1px solid hsl(142 70% 50% / 0.3)" }}>
            <CheckCircle className="w-3 h-3 text-success shrink-0" />
            <div className="min-w-0 flex-1">
              <p className="text-[8px] font-pixel text-success">PAYMENT CONFIRMED</p>
              <p className="text-[8px] font-mono text-muted-foreground truncate mt-0.5">
                {txHash.slice(0,10)}…{txHash.slice(-8)}
              </p>
            </div>
            {txHash.startsWith("0x") && txHash.length === 66 && (
              <a href={`https://hashscan.io/testnet/transaction/${txHash}`}
                target="_blank" rel="noopener noreferrer">
                <ExternalLink className="w-3 h-3 text-cyan" />
              </a>
            )}
          </div>
        )}

        {/* Error */}
        {errMsg && (
          <div className="flex items-center gap-1.5 px-2 py-1 rounded"
            style={{ background: "hsl(0 72% 55% / 0.08)", border: "1px solid hsl(0 72% 55% / 0.3)" }}>
            <AlertTriangle className="w-3 h-3 shrink-0 text-destructive" />
            <p className="text-[8px] font-mono text-destructive leading-snug">{errMsg}</p>
          </div>
        )}

        {/* Wallet status hints */}
        {!isConnected && payState === "idle" && (
          <div className="flex items-center gap-1.5 px-2 py-1 rounded"
            style={{ background: "hsl(38 92% 55% / 0.08)", border: "1px solid hsl(38 92% 55% / 0.25)" }}>
            <AlertTriangle className="w-3 h-3 shrink-0" style={{ color: "hsl(38 92% 55%)" }} />
            <p className="text-[8px] font-mono" style={{ color: "hsl(38 92% 55%)" }}>
              No wallet connected — will run in demo mode
            </p>
          </div>
        )}
        {isConnected && !isHedera && payState === "idle" && (
          <div className="flex items-center gap-1.5 px-2 py-1 rounded"
            style={{ background: "hsl(38 92% 55% / 0.08)", border: "1px solid hsl(38 92% 55% / 0.25)" }}>
            <AlertTriangle className="w-3 h-3 shrink-0" style={{ color: "hsl(38 92% 55%)" }} />
            <p className="text-[8px] font-mono" style={{ color: "hsl(38 92% 55%)" }}>
              Switch to Hedera Testnet for real USDC payment
            </p>
          </div>
        )}

        {/* Action buttons */}
        <div className="flex gap-2">
          <button onClick={onDismiss} disabled={isProcessing || isDone}
            className="flex-1 h-8 rounded font-pixel text-[8px] transition-all duration-200 disabled:opacity-30"
            style={{ background: "hsl(225 20% 12%)", border: "1px solid hsl(225 15% 22%)", color: "hsl(215 12% 50%)" }}>
            CANCEL
          </button>
          <button
            onClick={handlePay}
            disabled={isProcessing || isDone}
            className="flex-1 h-8 rounded font-pixel text-[8px] flex items-center justify-center gap-1.5 transition-all duration-200 disabled:opacity-60"
            style={{
              background: isDone
                ? "linear-gradient(135deg, hsl(142 70% 35%), hsl(142 70% 28%))"
                : isProcessing
                ? "linear-gradient(135deg, hsl(195 100% 35%), hsl(195 100% 28%))"
                : "linear-gradient(135deg, hsl(195 100% 45%), hsl(195 100% 35%))",
              border: `1px solid ${isDone ? "hsl(142 70% 50% / 0.5)" : "hsl(195 100% 55% / 0.5)"}`,
              color: "#fff",
              boxShadow: !isProcessing && !isDone ? "0 0 16px hsl(195 100% 55% / 0.2)" : undefined,
            }}
          >
            {isProcessing && <Loader2 className="w-3 h-3 animate-spin" />}
            {isDone && <CheckCircle className="w-3 h-3" />}
            {!isProcessing && !isDone && <Zap className="w-3 h-3" />}
            {payState === "idle" && (isConnected && isHedera ? "PAY 1 USDC" : "DEMO — ACTIVATE")}
            {payState === "signing" && "SIGNING..."}
            {payState === "broadcasting" && "BROADCASTING..."}
            {payState === "confirmed" && "PAID ✓"}
            {payState === "demo" && "ACTIVATING..."}
          </button>
        </div>

        {/* Footer */}
        <p className="text-[7px] font-mono text-muted-foreground/50 text-center">
          x402 · HTTP Payment Standard · Hedera Testnet · USDC 0.0.5769177
        </p>
      </div>
    </div>,
    document.body
  );
}
