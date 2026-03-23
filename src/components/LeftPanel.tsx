import { useState, useEffect } from "react";
import { Send, Sparkles, Target, Zap, Scroll, TrendingUp, ChevronRight, Droplets } from "lucide-react";
import { Button } from "@/components/ui/button";
import { AGENTS } from "@/data/agents";
import { useLiveTimeline } from "@/hooks/useLiveTimeline";
import { useQuestInput } from "@/hooks/useQuestInput";
import { useWallet } from "@/hooks/useWallet";
import { useAppKitProvider } from "@reown/appkit/react";
import { BrowserProvider, Contract, JsonRpcProvider } from "ethers";

const FAUCET_ADDRESS = "0xCA0558Fa81166C5939335282973Aa2F3A00B3953";
const FAUCET_ABI = [
  "function drip() external",
  "function nextClaimTime(address) view returns (uint256)",
];
const HEDERA_TESTNET_RPC = "https://testnet.hashio.io/api";

const suggestedPrompts = [
  { icon: Target,      text: "Allocate low-risk portfolio across HBAR pairs" },
  { icon: Zap,         text: "Rebalance with 30% liquidity buffer on Hedera" },
  { icon: TrendingUp,  text: "Analyze my wallet risk and suggest mitigation" },
  { icon: Scroll,      text: "Execute 100 HBAR → USDC at best route + receipt" },
];

const LeftPanel = () => {
  const [query, setQuery] = useState("");
  const [canClaim, setCanClaim] = useState(false);
  const [claiming, setClaiming] = useState(false);
  const [claimError, setClaimError] = useState<string | null>(null);
  const { messages, isLive } = useLiveTimeline();
  const { setPendingIntent } = useQuestInput();
  const { isConnected, address } = useWallet();
  const { walletProvider } = useAppKitProvider("eip155");

  // Check if user can claim from faucet (read-only, no wallet needed)
  useEffect(() => {
    if (!isConnected || !address) {
      setCanClaim(false);
      return;
    }

    const checkClaim = async () => {
      try {
        const provider = new JsonRpcProvider(HEDERA_TESTNET_RPC);
        const faucet = new Contract(FAUCET_ADDRESS, FAUCET_ABI, provider);
        const nextTime: bigint = await faucet.nextClaimTime(address);
        const nowSec = BigInt(Math.floor(Date.now() / 1000));
        setCanClaim(nextTime === 0n || nowSec >= nextTime);
      } catch {
        setCanClaim(false);
      }
    };

    checkClaim();
    const interval = setInterval(checkClaim, 30000);
    return () => clearInterval(interval);
  }, [isConnected, address]);

  const handleClaim = async () => {
    if (!walletProvider) return;
    setClaiming(true);
    setClaimError(null);
    try {
      const ethersProvider = new BrowserProvider(walletProvider as Parameters<typeof BrowserProvider>[0]);
      const signer = await ethersProvider.getSigner();
      const faucet = new Contract(FAUCET_ADDRESS, FAUCET_ABI, signer);
      const tx = await faucet.drip();
      await tx.wait();
      setCanClaim(false);
    } catch (err: unknown) {
      const msg = err instanceof Error ? err.message : String(err);
      setClaimError(msg.length > 60 ? msg.slice(0, 60) + "…" : msg);
    } finally {
      setClaiming(false);
    }
  };

  // Dynamic missions from live messages
  const questMessages = messages.filter((m) => m.type === "quest").slice(0, 4);
  const activeMissions = questMessages.length > 0
    ? questMessages.map((m, i) => ({
        id: m.id,
        title: m.content.slice(0, 42) + (m.content.length > 42 ? "…" : ""),
        status: "executing" as const,
        agentId: m.agentId,
        progress: Math.min(100, 30 + i * 20),
      }))
    : [
        { id: "m1", title: "DeFi Yield Optimization",  status: "executing" as const, agentId: "scout",      progress: 65 },
        { id: "m2", title: "Market Sentiment Scan",     status: "complete" as const,  agentId: "archivist",  progress: 100 },
        { id: "m3", title: "Governance Vote Analysis",  status: "pending" as const,   agentId: "strategist", progress: 15 },
        { id: "m4", title: "Treasury Rebalance",        status: "executing" as const, agentId: "treasurer",  progress: 42 },
      ];

  const STATUS_STYLES = {
    executing: { bar: "gradient-gold", dot: "bg-gold animate-pulse-glow", label: "Executing" },
    complete:  { bar: "bg-success",    dot: "bg-success",                  label: "Complete" },
    pending:   { bar: "bg-secondary",  dot: "bg-muted-foreground",         label: "Pending" },
  };

  const handleDeploy = () => {
    const trimmed = query.trim();
    if (!trimmed) return;
    setPendingIntent(trimmed);
    setQuery("");
  };

  return (
    <aside className="w-72 xl:w-80 glass-panel flex flex-col gap-3 p-4 overflow-hidden">
      {/* Header */}
      <div className="flex items-center justify-between">
        <div className="flex items-center gap-2">
          <Sparkles className="w-4 h-4 text-gold" />
          <h2 className="font-pixel text-[10px] text-gold tracking-wider">QUEST INPUT</h2>
        </div>
        {isLive && (
          <div className="flex items-center gap-1 px-1.5 py-0.5 rounded" style={{ background: "hsl(142 70% 50% / 0.1)", border: "1px solid hsl(142 70% 50% / 0.3)" }}>
            <div className="w-1.5 h-1.5 rounded-full bg-success animate-pulse" />
            <span className="text-[7px] font-pixel text-success">LIVE</span>
          </div>
        )}
      </div>

      {/* Input */}
      <div className="relative">
        <textarea
          value={query}
          onChange={(e) => setQuery(e.target.value)}
          onKeyDown={(e) => { if (e.key === "Enter" && !e.shiftKey) { e.preventDefault(); handleDeploy(); } }}
          placeholder="Describe your goal in natural language..."
          className="w-full h-[72px] bg-secondary/40 border border-border/40 rounded-lg px-3 py-2.5 text-xs text-foreground placeholder:text-muted-foreground resize-none focus:outline-none focus:border-gold/40 focus:ring-1 focus:ring-primary/20 font-mono leading-relaxed"
        />
        <Button
          size="sm"
          disabled={!query.trim()}
          onClick={handleDeploy}
          className="absolute bottom-2 right-2 h-6 px-2 gap-1 text-[10px] font-pixel disabled:opacity-40"
          style={{
            background: "linear-gradient(135deg, hsl(43 90% 50%), hsl(38 85% 40%))",
            border: "1px solid hsl(43 90% 60% / 0.5)",
            color: "hsl(225 30% 6%)",
          }}
        >
          <Send className="w-3 h-3" />
          Deploy
        </Button>
      </div>

      {/* Suggested prompts */}
      <div className="space-y-1">
        <p className="text-[9px] text-muted-foreground uppercase tracking-wider font-mono">Suggested Quests</p>
        {suggestedPrompts.map((p, i) => (
          <button
            key={i}
            onClick={() => setQuery(p.text)}
            className="w-full flex items-start gap-2 px-2.5 py-1.5 rounded-lg border border-transparent transition-all text-left group"
            style={{ background: "hsl(225 20% 11%)" }}
            onMouseEnter={(e) => (e.currentTarget.style.borderColor = "hsl(43 90% 55% / 0.2)")}
            onMouseLeave={(e) => (e.currentTarget.style.borderColor = "transparent")}
          >
            <p.icon className="w-3 h-3 text-cyan mt-0.5 shrink-0" />
            <span className="text-[10px] text-muted-foreground group-hover:text-foreground transition-colors leading-relaxed font-mono">
              {p.text}
            </span>
          </button>
        ))}
      </div>

      {/* Active agents */}
      <div>
        <p className="text-[9px] text-muted-foreground uppercase tracking-wider font-mono mb-1.5">Guild Agents</p>
        <div className="grid grid-cols-3 gap-1">
          {AGENTS.map((a) => (
            <div
              key={a.id}
              className="flex items-center gap-1 px-1.5 py-1 rounded-md"
              style={{ background: a.color + "12", border: `1px solid ${a.color}25` }}
            >
              <div
                className="w-1.5 h-1.5 rounded-full shrink-0"
                style={{
                  background: a.status === "executing" || a.status === "active" ? a.color : a.color + "50",
                  animation: a.status === "executing" ? "pulse-glow 1.5s ease-in-out infinite" : undefined,
                }}
              />
              <span className="text-[8px] font-pixel truncate" style={{ color: a.color + "bb" }}>
                {a.name}
              </span>
            </div>
          ))}
        </div>
      </div>

      {/* Active missions */}
      <div className="flex-1 overflow-hidden flex flex-col">
        <div className="flex items-center justify-between mb-1.5">
          <p className="text-[9px] text-muted-foreground uppercase tracking-wider font-mono">Active Missions</p>
          <span className="text-[9px] text-gold font-mono">{activeMissions.length}</span>
        </div>
        <div className="space-y-2 overflow-y-auto scrollbar-thin flex-1">
          {activeMissions.map((m) => {
            const st = STATUS_STYLES[m.status] ?? STATUS_STYLES.pending;
            const agent = AGENTS.find((a) => a.id === m.agentId);
            return (
              <div
                key={m.id}
                className="rounded-xl p-3 space-y-2 cursor-pointer transition-all duration-200"
                style={{ background: "hsl(225 22% 11%)", border: "1px solid hsl(225 15% 18%)" }}
                onMouseEnter={(e) => (e.currentTarget.style.borderColor = "hsl(43 90% 55% / 0.2)")}
                onMouseLeave={(e) => (e.currentTarget.style.borderColor = "hsl(225 15% 18%)")}
              >
                <div className="flex items-start justify-between gap-2">
                  <p className="text-[10px] font-medium text-foreground leading-tight">{m.title}</p>
                  <div className="flex items-center gap-1 shrink-0">
                    <div className={`w-1.5 h-1.5 rounded-full ${st.dot}`} />
                    <span className="text-[8px] font-pixel text-muted-foreground">{st.label}</span>
                  </div>
                </div>
                <div className="h-1.5 bg-secondary rounded-full overflow-hidden">
                  <div className={`h-full rounded-full transition-all duration-700 ${st.bar}`} style={{ width: `${m.progress}%` }} />
                </div>
                {agent && (
                  <div className="flex items-center gap-1.5">
                    <div
                      className="w-5 h-5 rounded-md flex items-center justify-center text-[9px] font-pixel"
                      style={{ background: agent.color + "20", border: `1px solid ${agent.color}45`, color: agent.color }}
                    >
                      {agent.icon}
                    </div>
                    <span className="text-[8px] text-muted-foreground font-mono">{agent.name}</span>
                    <ChevronRight className="w-2.5 h-2.5 text-muted-foreground ml-auto" />
                  </div>
                )}
              </div>
            );
          })}
        </div>
      </div>

      {/* Faucet claim button — shown only when connected and canClaim */}
      {isConnected && canClaim && (
        <div className="pt-1 border-t border-border/20">
          <Button
            size="sm"
            className="w-full gap-2 text-[10px] font-pixel h-8"
            onClick={handleClaim}
            disabled={claiming}
            style={{
              background: claiming
                ? "hsl(195 100% 50% / 0.1)"
                : "linear-gradient(135deg, hsl(195 100% 40%), hsl(195 100% 28%))",
              border: "1px solid hsl(195 100% 55% / 0.4)",
              color: claiming ? "hsl(195 100% 55%)" : "hsl(225 30% 6%)",
            }}
          >
            <Droplets className="w-3 h-3" />
            {claiming ? "Claiming…" : "Claim 1000 USDC"}
          </Button>
          {claimError && (
            <p className="text-[8px] text-red-400 font-mono mt-1 text-center leading-tight">{claimError}</p>
          )}
        </div>
      )}
    </aside>
  );
};

export default LeftPanel;
