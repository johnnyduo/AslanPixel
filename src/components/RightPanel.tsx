import { useState, useEffect, useRef } from "react";
import { createPortal } from "react-dom";
import { Shield, Brain, Star, CheckCircle, XCircle, Play, ChevronRight, Zap, ExternalLink, UserPlus, Loader2, X, Shuffle, CreditCard, Trash2 } from "lucide-react";
import { Button } from "@/components/ui/button";
import { AGENTS, STATUS_COLORS, ACTION_TYPE_COLORS, type Agent } from "@/data/agents";
import { useLiveTimeline } from "@/hooks/useLiveTimeline";
import { useQuestInput } from "@/hooks/useQuestInput";
import { useAgentStats, deactivateAgentOnchain } from "@/hooks/useContracts";
import { getStoredAgentTxHashes, AGENT_TX_STORAGE_KEY } from "@/hooks/useAgentInit";
import PaymentGate from "@/components/PaymentGate";

// micro-USDC cost per message type (6 decimals, so 1_000_000 = 1.00 USDC)
const MSG_COST_USDC: Record<string, number> = {
  transaction:   50_000,   // 0.05 USDC
  tool_call:     10_000,   // 0.01 USDC
  receipt:       20_000,   // 0.02 USDC
  decision:       5_000,   // 0.005 USDC
  policy:         3_000,   // 0.003 USDC
  conversation:   1_000,   // 0.001 USDC
  alert:          1_000,   // 0.001 USDC
};

function formatUsdc(microUsdc: number): string {
  return (microUsdc / 1_000_000).toFixed(4);
}

type RegState = "idle" | "calling" | "done" | "error";
type DeactivateState = "idle" | "calling" | "done" | "error";

const TRAITS = [
  { id: "analyst",   label: "Analyst",   desc: "Data-driven · precise",   icon: "◈" },
  { id: "guardian",  label: "Guardian",  desc: "Risk-averse · vigilant",  icon: "◆" },
  { id: "executor",  label: "Executor",  desc: "Fast · action-oriented",  icon: "▶" },
];

const NAME_PREFIXES = ["Nexus","Oryn","Vex","Kael","Drax","Lyss","Zara","Mira","Axon","Flux","Vera","Crix"];
const NAME_SUFFIXES = ["-7","X","Prime","-9","Alpha","Zero","-Ω","Max","Nova","Core"];

function autogenName() {
  const p = NAME_PREFIXES[Math.floor(Math.random() * NAME_PREFIXES.length)];
  const s = NAME_SUFFIXES[Math.floor(Math.random() * NAME_SUFFIXES.length)];
  return p + s;
}

const RightPanel = () => {
  const [selectedId, setSelectedId] = useState<string>("scout");
  const [actionFeedback, setActionFeedback] = useState<{ type: "approve" | "reject" | "sim"; ts: number } | null>(null);
  const [showRegModal, setShowRegModal] = useState(false);
  const [regState, setRegState] = useState<RegState>("idle");
  const [regResult, setRegResult] = useState<{ txHash?: string; topicId?: string; msg?: string } | null>(null);
  const [regName, setRegName] = useState("");
  const [regTrait, setRegTrait] = useState("analyst");
  const [deactivateState, setDeactivateState] = useState<DeactivateState>("idle");
  const [deactivateMsg, setDeactivateMsg] = useState<string | null>(null);
  const [sessionCost, setSessionCost] = useState(0);       // tinyhbar
  const [showPayWage, setShowPayWage] = useState(false);
  const seenMsgIds = useRef(new Set<string>());
  const { agents: onchainAgents } = useAgentStats();
  const { messages } = useLiveTimeline();
  const { setPendingIntent } = useQuestInput();
  const agent = AGENTS.find((a) => a.id === selectedId) ?? AGENTS[0];
  const [agentTxHashes, setAgentTxHashes] = useState<Record<string, string>>({});

  useEffect(() => {
    setAgentTxHashes(getStoredAgentTxHashes());
    const handler = () => setAgentTxHashes(getStoredAgentTxHashes());
    window.addEventListener("storage", handler);
    return () => window.removeEventListener("storage", handler);
  }, []);

  // Accumulate session cost from live timeline messages (micro-USDC)
  useEffect(() => {
    let added = 0;
    for (const m of messages) {
      if (seenMsgIds.current.has(m.id)) continue;
      seenMsgIds.current.add(m.id);
      added += MSG_COST_USDC[m.type] ?? 0;
    }
    if (added > 0) setSessionCost((prev) => prev + added);
  }, [messages]);

  // Merge onchain data
  const onchain = onchainAgents.find((a) => a.agentId === selectedId);
  const isOnchain = onchain && onchain.registeredAt > 0;
  // Reputation: contract stores 0-1000, display as 0-5 stars
  const displayRep = isOnchain ? Math.round(onchain.reputation / 200) : agent.reputation;
  const displayQuests = isOnchain ? onchain.completedQuests : agent.completedQuests;
  const displaySuccessRate = isOnchain && onchain.completedQuests > 0
    ? Math.round((onchain.successCount / onchain.completedQuests) * 100)
    : agent.successRate;

  // Live recent actions from timeline for selected agent
  const liveActions = messages
    .filter((m) => m.agentId === selectedId)
    .slice(0, 5)
    .map((m) => ({ action: m.content.slice(0, 72), time: m.time, type: m.type }));

  const recentActions = liveActions.length > 0 ? liveActions : agent.recentActions;

  const handleApprove = () => {
    setActionFeedback({ type: "approve", ts: Date.now() });
    setPendingIntent(`Approve and execute ${agent.name}'s latest recommended action on Hedera`);
    setTimeout(() => setActionFeedback(null), 3000);
  };

  const handleReject = () => {
    setActionFeedback({ type: "reject", ts: Date.now() });
    setTimeout(() => setActionFeedback(null), 2000);
  };

  const handleSim = () => {
    setActionFeedback({ type: "sim", ts: Date.now() });
    setPendingIntent(`Simulate ${agent.name}'s strategy without executing — show projected outcome`);
    setTimeout(() => setActionFeedback(null), 3000);
  };

  const handleRegister = async () => {
    setRegState("calling");
    setRegResult(null);
    try {
      const res = await fetch("/api/agent-register", {
        method: "POST",
        headers: { "Content-Type": "application/json" },
        body: JSON.stringify({ mode: "register", agentId: selectedId, name: regName.trim() || agent.name, trait: regTrait }),
      });
      const d = await res.json();
      if (d.txHashes && Object.keys(d.txHashes).length > 0) {
        // Persist newly returned TX hashes
        const existing = getStoredAgentTxHashes();
        const merged = { ...existing, ...d.txHashes };
        localStorage.setItem(AGENT_TX_STORAGE_KEY, JSON.stringify(merged));
        setAgentTxHashes(merged);
      }
      const txHash = d.txHashes?.[selectedId] ?? agentTxHashes[selectedId] ?? null;
      const wasRegistered = d.registeredAgents?.includes(selectedId);
      // Persist custom agent ID so PixelMap/useAgentStats can show it in the map
      if (wasRegistered) {
        const canonical = ["scout","strategist","sentinel","treasurer","executor","archivist"];
        if (!canonical.includes(selectedId)) {
          const stored: string[] = (() => { try { return JSON.parse(localStorage.getItem("aslan_custom_agent_ids") || "[]"); } catch { return []; } })();
          if (!stored.includes(selectedId)) {
            localStorage.setItem("aslan_custom_agent_ids", JSON.stringify([...stored, selectedId]));
          }
        }
      }
      setRegResult({
        txHash: txHash ?? undefined,
        topicId: d.topicId,
        msg: d.skippedAgents?.includes(selectedId)
          ? "Agent already registered onchain"
          : wasRegistered
          ? "Agent registered successfully"
          : d.error ?? "Registration attempted",
      });
      setRegState("done");
    } catch (e) {
      setRegResult({ msg: e instanceof Error ? e.message : "Network error" });
      setRegState("error");
    }
  };

  const handleDeactivate = async () => {
    if (!window.confirm(`Deactivate agent ${agent.name} onchain? This requires a MetaMask transaction.`)) return;
    setDeactivateState("calling");
    setDeactivateMsg(null);
    try {
      const txHash = await deactivateAgentOnchain(selectedId);
      setDeactivateMsg(`Deactivated · TX: ${txHash.slice(0,10)}…${txHash.slice(-6)}`);
      setDeactivateState("done");
    } catch (e) {
      const msg = e instanceof Error ? e.message : String(e);
      setDeactivateMsg(msg.includes("user rejected") ? "Transaction rejected" : msg.slice(0, 60));
      setDeactivateState("error");
    }
  };

  return (
    <>
    <aside className="w-72 xl:w-80 glass-panel flex flex-col gap-0 overflow-hidden">
      {/* Agent selector tabs */}
      <div className="px-3 pt-3 pb-0">
        <div className="flex items-center gap-1.5 mb-2">
          <Shield className="w-3.5 h-3.5 text-cyan" />
          <h2 className="font-pixel text-[10px] text-cyan tracking-wider">AGENT DETAIL</h2>
          <button
            onClick={() => { setShowRegModal(true); setRegState("idle"); setRegResult(null); setRegName(agent.name); setRegTrait("analyst"); }}
            className="ml-auto flex items-center gap-1 px-1.5 py-0.5 rounded text-[7px] font-pixel transition-all duration-200 hover:opacity-90"
            style={{ background: "hsl(43 90% 55% / 0.12)", border: "1px solid hsl(43 90% 55% / 0.35)", color: "hsl(43 90% 65%)" }}
            title="Register agent onchain"
          >
            <UserPlus className="w-2.5 h-2.5" />
            REGISTER
          </button>
        </div>
        <div className="grid grid-cols-3 gap-1 mb-3">
          {AGENTS.map((a) => (
            <button
              key={a.id}
              onClick={() => setSelectedId(a.id)}
              className="relative flex flex-col items-center gap-0.5 px-1 py-1.5 rounded-md transition-all duration-200 group"
              style={{
                background: selectedId === a.id ? `${a.color}18` : "transparent",
                border: `1px solid ${selectedId === a.id ? a.color + "60" : "hsl(225 15% 20%)"}`,
              }}
            >
              {/* Status dot */}
              <div
                className="absolute top-1 right-1 w-1.5 h-1.5 rounded-full"
                style={{
                  background: STATUS_COLORS[a.status],
                  boxShadow: `0 0 4px ${STATUS_COLORS[a.status]}`,
                  animation: a.status === "executing" || a.status === "active" ? "pulse-glow 1.5s ease-in-out infinite" : undefined,
                }}
              />
              <span className="font-pixel text-base" style={{ color: selectedId === a.id ? a.color : a.color + "70" }}>
                {a.icon}
              </span>
              <span
                className="font-pixel text-[7px] leading-none text-center"
                style={{ color: selectedId === a.id ? a.color : "hsl(215 12% 45%)" }}
              >
                {a.name}
              </span>
            </button>
          ))}
        </div>
      </div>

      {/* Divider */}
      <div className="h-px mx-3 mb-3" style={{ background: `linear-gradient(90deg, transparent, ${agent.color}40, transparent)` }} />

      <div className="flex flex-col gap-2.5 px-3 pb-3 overflow-y-auto scrollbar-thin flex-1">
        {/* Profile card */}
        <div className="glass-panel p-3 space-y-2.5">
          <div className="flex items-center gap-3">
            {/* Avatar */}
            <div
              className="w-11 h-11 rounded-lg flex items-center justify-center shrink-0 relative"
              style={{
                background: `linear-gradient(135deg, ${agent.color}30, ${agent.color}10)`,
                border: `2px solid ${agent.color}60`,
                boxShadow: `0 0 16px ${agent.glowColor}`,
              }}
            >
              <span className="font-pixel text-base" style={{ color: agent.color }}>{agent.icon}</span>
              {/* Corner accent */}
              <div className="absolute top-0.5 right-0.5 w-1.5 h-1.5 rounded-[1px]" style={{ background: agent.color + "80" }} />
            </div>

            <div className="flex-1 min-w-0">
              <h3 className="text-sm font-semibold text-foreground truncate">{agent.fullName}</h3>
              <p className="text-[10px] font-mono mt-0.5" style={{ color: agent.color }}>{agent.role}</p>
              <p className="text-[9px] text-muted-foreground font-mono mt-0.5">{agent.trait}</p>
            </div>

            {/* Status badge */}
            <div
              className="shrink-0 px-1.5 py-0.5 rounded text-[8px] font-pixel uppercase"
              style={{
                background: STATUS_COLORS[agent.status] + "20",
                border: `1px solid ${STATUS_COLORS[agent.status]}50`,
                color: STATUS_COLORS[agent.status],
              }}
            >
              {agent.status}
            </div>
          </div>

          {/* Stars + onchain badge */}
          <div className="flex items-center gap-1 flex-wrap">
            {Array.from({ length: 5 }).map((_, i) => (
              <Star
                key={i}
                className="w-3 h-3"
                style={{
                  color: i < displayRep ? "hsl(43 90% 60%)" : "hsl(225 15% 25%)",
                  fill: i < displayRep ? "hsl(43 90% 60%)" : "transparent",
                }}
              />
            ))}
            <span className="text-[9px] text-muted-foreground font-mono ml-1">
              {isOnchain ? `${onchain!.reputation}/1000` : `${displayRep}.0 rep`}
            </span>
            {isOnchain && (() => {
              const txHash = agentTxHashes[selectedId];
              const href = txHash
                ? `https://hashscan.io/testnet/transaction/${txHash}`
                : `https://hashscan.io/testnet/contract/0x8B90AA6D1A12111C8F08C8B9Af4cca9f90336CC4`;
              return (
                <a
                  href={href}
                  target="_blank"
                  rel="noopener noreferrer"
                  className="flex items-center gap-0.5 text-[7px] font-pixel px-1 py-0.5 rounded ml-1"
                  style={{ background: "hsl(195 100% 55% / 0.1)", color: "hsl(195 100% 55%)", border: "1px solid hsl(195 100% 55% / 0.3)" }}
                  title={txHash ? `TX: ${txHash}` : "View AgentRegistry contract"}
                >
                  ONCHAIN <ExternalLink className="w-2 h-2" />
                </a>
              );
            })()}
          </div>

          {/* Stats grid */}
          <div className="grid grid-cols-3 gap-1.5">
            <StatBox label="Quests" value={displayQuests.toString()} color={agent.color} />
            <StatBox label="Success" value={`${displaySuccessRate}%`} color="hsl(142 70% 50%)" />
            <StatBox label="Focus" value={agent.specialization} color={agent.color} small />
          </div>

          {/* Session cost meter + pay button */}
          <div className="rounded-lg px-2.5 py-2 flex items-center gap-2"
            style={{ background: "hsl(43 90% 55% / 0.06)", border: "1px solid hsl(43 90% 55% / 0.2)" }}>
            <div className="flex-1 min-w-0">
              <p className="text-[7px] font-pixel text-muted-foreground tracking-wider">SESSION COST</p>
              <div className="flex items-baseline gap-1 mt-0.5">
                <span className="text-[11px] font-mono font-bold text-gold leading-none">
                  {formatUsdc(sessionCost)}
                </span>
                <span className="text-[7px] font-mono text-muted-foreground">USDC</span>
              </div>
              <p className="text-[7px] font-mono text-muted-foreground/60 mt-0.5 truncate">
                {messages.length} ops · 0.0.5769177
              </p>
            </div>
            <button
              onClick={() => setShowPayWage(true)}
              className="shrink-0 flex items-center gap-1 px-2 py-1.5 rounded-md font-pixel text-[7px] transition-all hover:opacity-90 active:scale-95"
              style={{
                background: "linear-gradient(135deg, hsl(43 90% 45%), hsl(38 85% 35%))",
                border: "1px solid hsl(43 90% 55% / 0.6)",
                color: "hsl(225 30% 6%)",
                boxShadow: "0 0 12px hsl(43 90% 55% / 0.2)",
              }}
            >
              <CreditCard className="w-2.5 h-2.5" />
              PAY WAGE
            </button>
          </div>
        </div>

        {/* Confidence meter */}
        <div className="glass-panel p-3 space-y-2">
          <div className="flex items-center justify-between">
            <div className="flex items-center gap-1.5">
              <Zap className="w-3 h-3" style={{ color: agent.color }} />
              <span className="text-[10px] text-muted-foreground uppercase tracking-wider font-mono">Confidence</span>
            </div>
            <span className="text-sm font-mono font-semibold" style={{ color: agent.color }}>{agent.confidence}%</span>
          </div>
          <div className="h-2 bg-secondary rounded-full overflow-hidden">
            <div
              className="h-full rounded-full transition-all duration-700"
              style={{
                width: `${agent.confidence}%`,
                background: `linear-gradient(90deg, ${agent.color}80, ${agent.color})`,
                boxShadow: `0 0 8px ${agent.color}60`,
              }}
            />
          </div>
          {/* Tick marks */}
          <div className="flex justify-between">
            {[25, 50, 75, 100].map((v) => (
              <span key={v} className="text-[8px] font-mono text-muted-foreground/50">{v}</span>
            ))}
          </div>
        </div>

        {/* Philosophy / reasoning */}
        <div className="glass-panel p-3 space-y-1.5">
          <div className="flex items-center gap-1.5">
            <Brain className="w-3 h-3" style={{ color: agent.color }} />
            <span className="text-[10px] text-muted-foreground uppercase tracking-wider font-mono">Philosophy</span>
          </div>
          {/* Quote */}
          <p
            className="text-[10px] font-mono italic border-l-2 pl-2"
            style={{ color: agent.color + "cc", borderColor: agent.color + "50" }}
          >
            "{agent.quote}"
          </p>
          <p className="text-[10px] text-secondary-foreground leading-relaxed font-mono">{agent.philosophy}</p>
        </div>

        {/* Action buttons */}
        <div className="space-y-1.5">
          <div className="flex gap-1.5">
            <Button
              size="sm"
              onClick={handleApprove}
              className="flex-1 gap-1 text-xs h-8 transition-all duration-200"
              style={{
                background: actionFeedback?.type === "approve"
                  ? "linear-gradient(135deg, hsl(142 70% 50%), hsl(142 70% 40%))"
                  : "linear-gradient(135deg, hsl(142 70% 40%), hsl(142 70% 30%))",
                border: "1px solid hsl(142 70% 50% / 0.4)",
                color: "hsl(142 70% 90%)",
                boxShadow: actionFeedback?.type === "approve" ? "0 0 12px hsl(142 70% 50% / 0.4)" : undefined,
              }}
            >
              <CheckCircle className="w-3 h-3" />
              {actionFeedback?.type === "approve" ? "Approved!" : "Approve"}
            </Button>
            <Button
              size="sm"
              onClick={handleReject}
              className="flex-1 gap-1 text-xs h-8"
              style={{
                background: actionFeedback?.type === "reject"
                  ? "linear-gradient(135deg, hsl(0 72% 50%), hsl(0 72% 40%))"
                  : "linear-gradient(135deg, hsl(0 72% 40%), hsl(0 72% 30%))",
                border: "1px solid hsl(0 72% 55% / 0.4)",
                color: "hsl(0 72% 90%)",
              }}
            >
              <XCircle className="w-3 h-3" />
              {actionFeedback?.type === "reject" ? "Rejected" : "Reject"}
            </Button>
            <Button
              size="sm"
              onClick={handleSim}
              className="gap-1 text-xs h-8 px-2.5"
              style={{
                background: actionFeedback?.type === "sim" ? `${agent.color}30` : `${agent.color}15`,
                border: `1px solid ${agent.color}40`,
                color: agent.color,
              }}
            >
              <Play className="w-3 h-3" />
              Sim
            </Button>
          </div>
          {actionFeedback?.type === "approve" && (
            <p className="text-[8px] font-pixel text-success text-center animate-pulse">
              ◈ Quest dispatched to {agent.name}...
            </p>
          )}
          {actionFeedback?.type === "sim" && (
            <p className="text-[8px] font-pixel text-cyan text-center animate-pulse">
              ▲ Simulation running...
            </p>
          )}
        </div>

        {/* Recent actions — live from timeline, fallback to static */}
        <div>
          <div className="flex items-center justify-between mb-1.5">
            <p className="text-[10px] text-muted-foreground uppercase tracking-wider font-mono">Recent Actions</p>
            {liveActions.length > 0 && (
              <span className="text-[7px] font-pixel px-1 py-0.5 rounded" style={{ background: "hsl(195 100% 55% / 0.1)", color: "hsl(195 100% 55%)", border: "1px solid hsl(195 100% 55% / 0.3)" }}>LIVE</span>
            )}
          </div>
          <div className="space-y-1">
            {recentActions.map((item, i) => (
              <div
                key={i}
                className="flex items-center gap-2 px-2 py-1.5 rounded-md transition-colors cursor-pointer group"
                style={{ background: "hsl(225 20% 11%)", border: "1px solid hsl(225 15% 18%)" }}
                onMouseEnter={(e) => (e.currentTarget.style.borderColor = `${agent.color}30`)}
                onMouseLeave={(e) => (e.currentTarget.style.borderColor = "hsl(225 15% 18%)")}
              >
                <div
                  className="w-1.5 h-1.5 rounded-full shrink-0"
                  style={{ background: ACTION_TYPE_COLORS[item.type] || agent.color }}
                />
                <ChevronRight className="w-3 h-3 text-muted-foreground group-hover:text-foreground transition-colors shrink-0" />
                <span className="text-[10px] text-secondary-foreground flex-1 leading-snug">{item.action}</span>
                <span className="text-[9px] text-muted-foreground font-mono shrink-0">{item.time}</span>
              </div>
            ))}
          </div>
        </div>
      </div>

    </aside>

      {/* Register Agent Modal — full-screen portal */}
      {/* Pay Wage — reuse PaymentGate portal */}
      {showPayWage && (
        <PaymentGate
          intent={`Session wage — ${sessionCost > 0 ? formatUsdc(sessionCost) + " USDC across " + messages.length + " agent ops" : "agent activity this session"}`}
          onPaid={() => { setShowPayWage(false); setSessionCost(0); seenMsgIds.current.clear(); }}
          onDismiss={() => setShowPayWage(false)}
        />
      )}

      {showRegModal && typeof document !== "undefined" && document.body && createPortal(
        <div
          className="fixed inset-0 z-[9999] flex items-center justify-center p-4"
          style={{ background: "hsl(225 30% 4% / 0.92)", backdropFilter: "blur(6px)" }}
          onClick={(e) => { if (e.target === e.currentTarget && regState !== "calling") setShowRegModal(false); }}
        >
          <div
            className="w-full max-w-sm glass-panel p-5 space-y-4 animate-timeline-enter"
            style={{ border: `1px solid ${agent.color}55`, boxShadow: `0 0 60px ${agent.color}18, 0 0 120px hsl(225 30% 4% / 0.8)` }}
          >
            {/* Header */}
            <div className="flex items-center gap-2.5">
              <div className="w-8 h-8 rounded-lg flex items-center justify-center shrink-0"
                style={{ background: agent.color + "18", border: `1px solid ${agent.color}45` }}>
                <UserPlus className="w-4 h-4" style={{ color: agent.color }} />
              </div>
              <div className="flex-1 min-w-0">
                <p className="font-pixel text-[11px] tracking-wider" style={{ color: agent.color }}>REGISTER AGENT ONCHAIN</p>
                <p className="text-[8px] font-mono text-muted-foreground mt-0.5">AgentRegistry.sol · Hedera Testnet EVM</p>
              </div>
              <button onClick={() => setShowRegModal(false)} disabled={regState === "calling"}
                className="shrink-0 w-6 h-6 flex items-center justify-center rounded hover:bg-white/5 transition-colors disabled:opacity-30">
                <X className="w-3.5 h-3.5 text-muted-foreground" />
              </button>
            </div>

            <div className="h-px" style={{ background: `linear-gradient(90deg, transparent, ${agent.color}35, transparent)` }} />

            {/* Agent chip */}
            <div className="flex items-center gap-2.5 px-3 py-2 rounded-lg"
              style={{ background: agent.color + "0c", border: `1px solid ${agent.color}25` }}>
              <span className="font-pixel text-2xl leading-none" style={{ color: agent.color }}>{agent.icon}</span>
              <div className="flex-1 min-w-0">
                <p className="text-xs font-semibold text-foreground">{agent.fullName}</p>
                <p className="text-[9px] font-mono" style={{ color: agent.color + "bb" }}>{agent.role}</p>
              </div>
              {isOnchain && (
                <span className="text-[7px] font-pixel px-1.5 py-0.5 rounded"
                  style={{ background: "hsl(142 70% 50% / 0.1)", color: "hsl(142 70% 55%)", border: "1px solid hsl(142 70% 50% / 0.3)" }}>
                  ✓ REGISTERED
                </span>
              )}
            </div>

            {/* Name input */}
            <div className="space-y-1.5">
              <div className="flex items-center justify-between">
                <p className="text-[8px] font-pixel text-muted-foreground tracking-wider">AGENT NAME</p>
                <button
                  onClick={() => { setRegName(autogenName()); setRegTrait(TRAITS[Math.floor(Math.random()*TRAITS.length)].id); }}
                  className="flex items-center gap-1 px-1.5 py-0.5 rounded text-[7px] font-pixel transition-all hover:opacity-80"
                  style={{ background: "hsl(280 65% 60% / 0.12)", border: "1px solid hsl(280 65% 60% / 0.3)", color: "hsl(280 65% 70%)" }}
                >
                  <Shuffle className="w-2.5 h-2.5" /> AUTOGEN
                </button>
              </div>
              <input
                type="text"
                value={regName}
                onChange={(e) => setRegName(e.target.value)}
                maxLength={24}
                placeholder="Enter agent name…"
                disabled={regState === "calling"}
                className="w-full h-9 px-3 rounded-lg text-sm font-mono bg-transparent outline-none transition-all disabled:opacity-40"
                style={{
                  background: "hsl(225 20% 9%)",
                  border: `1px solid ${regName.trim() ? agent.color + "50" : "hsl(225 15% 20%)"}`,
                  color: "hsl(215 20% 85%)",
                }}
              />
            </div>

            {/* Trait selector */}
            <div className="space-y-1.5">
              <p className="text-[8px] font-pixel text-muted-foreground tracking-wider">CHARACTERISTIC</p>
              <div className="grid grid-cols-3 gap-1.5">
                {TRAITS.map((t) => (
                  <button
                    key={t.id}
                    onClick={() => setRegTrait(t.id)}
                    disabled={regState === "calling"}
                    className="flex flex-col items-center gap-1 px-2 py-2 rounded-lg transition-all duration-150 disabled:opacity-40"
                    style={{
                      background: regTrait === t.id ? agent.color + "18" : "hsl(225 20% 9%)",
                      border: `1px solid ${regTrait === t.id ? agent.color + "60" : "hsl(225 15% 18%)"}`,
                      boxShadow: regTrait === t.id ? `0 0 12px ${agent.color}18` : undefined,
                    }}
                  >
                    <span className="font-pixel text-base leading-none" style={{ color: regTrait === t.id ? agent.color : "hsl(215 12% 45%)" }}>
                      {t.icon}
                    </span>
                    <p className="text-[8px] font-pixel leading-none" style={{ color: regTrait === t.id ? agent.color : "hsl(215 12% 50%)" }}>
                      {t.label}
                    </p>
                    <p className="text-[7px] font-mono text-muted-foreground text-center leading-tight">{t.desc}</p>
                  </button>
                ))}
              </div>
            </div>

            {/* Contract row + cap */}
            <div className="space-y-1 text-[8px] font-mono text-muted-foreground px-1">
              <div className="flex items-center justify-between">
                <span>Contract</span>
                <a href="https://hashscan.io/testnet/contract/0x8B90AA6D1A12111C8F08C8B9Af4cca9f90336CC4"
                  target="_blank" rel="noopener noreferrer"
                  className="flex items-center gap-0.5 text-cyan hover:underline">
                  0x8B90…CC4 <ExternalLink className="w-2 h-2" />
                </a>
              </div>
              <div className="flex items-center justify-between">
                <span>Registry slots</span>
                <span style={{ color: (regResult as {agentCount?:number}|null)?.agentCount != null && ((regResult as {agentCount?:number}).agentCount ?? 0) >= 18 ? "hsl(38 92% 55%)" : "hsl(215 12% 55%)" }}>
                  {(regResult as {agentCount?:number}|null)?.agentCount != null ? `${(regResult as {agentCount?:number}).agentCount}/20` : "?/20"}
                </span>
              </div>
            </div>

            {/* Result */}
            {regResult && (
              <div className="flex items-start gap-2 px-2.5 py-2 rounded-lg"
                style={{
                  background: regState === "error" ? "hsl(0 72% 55% / 0.08)" : "hsl(142 70% 50% / 0.08)",
                  border: `1px solid ${regState === "error" ? "hsl(0 72% 55% / 0.3)" : "hsl(142 70% 50% / 0.3)"}`,
                }}>
                {regState === "done"
                  ? <CheckCircle className="w-3.5 h-3.5 text-success shrink-0 mt-0.5" />
                  : <Shield className="w-3.5 h-3.5 text-destructive shrink-0 mt-0.5" />}
                <div className="min-w-0 space-y-0.5">
                  <p className="text-[8px] font-pixel" style={{ color: regState === "error" ? "hsl(0 72% 65%)" : "hsl(142 70% 60%)" }}>
                    {regResult.msg}
                  </p>
                  {regResult.txHash && (
                    <a href={`https://hashscan.io/testnet/transaction/${regResult.txHash}`}
                      target="_blank" rel="noopener noreferrer"
                      className="flex items-center gap-0.5 text-[8px] font-mono text-cyan hover:underline">
                      TX: {regResult.txHash.slice(0,10)}…{regResult.txHash.slice(-6)} <ExternalLink className="w-2 h-2" />
                    </a>
                  )}
                  {regResult.topicId && (
                    <p className="text-[8px] font-mono text-muted-foreground">HCS Topic: {regResult.topicId}</p>
                  )}
                </div>
              </div>
            )}

            {/* Deactivate feedback */}
            {deactivateMsg && (
              <div className="flex items-center gap-1.5 px-2 py-1.5 rounded"
                style={{
                  background: deactivateState === "error" ? "hsl(0 72% 55% / 0.08)" : "hsl(142 70% 50% / 0.08)",
                  border: `1px solid ${deactivateState === "error" ? "hsl(0 72% 55% / 0.3)" : "hsl(142 70% 50% / 0.3)"}`,
                }}>
                <p className="text-[8px] font-mono" style={{ color: deactivateState === "error" ? "hsl(0 72% 65%)" : "hsl(142 70% 60%)" }}>
                  {deactivateMsg}
                </p>
              </div>
            )}

            {/* Buttons */}
            <div className="flex gap-2 pt-1">
              <button onClick={() => setShowRegModal(false)} disabled={regState === "calling"}
                className="flex-1 h-9 rounded-lg font-pixel text-[8px] transition-all disabled:opacity-30"
                style={{ background: "hsl(225 20% 11%)", border: "1px solid hsl(225 15% 20%)", color: "hsl(215 12% 50%)" }}>
                {regState === "done" ? "CLOSE" : "CANCEL"}
              </button>
              {isOnchain && (
                <button
                  onClick={handleDeactivate}
                  disabled={deactivateState === "calling" || regState === "calling"}
                  className="h-9 px-3 rounded-lg font-pixel text-[8px] flex items-center justify-center gap-1 transition-all disabled:opacity-40"
                  style={{ background: "hsl(0 72% 40% / 0.15)", border: "1px solid hsl(0 72% 55% / 0.4)", color: "hsl(0 72% 65%)" }}
                  title="Deactivate agent onchain (requires MetaMask)"
                >
                  {deactivateState === "calling" ? <Loader2 className="w-3 h-3 animate-spin" /> : <Trash2 className="w-3 h-3" />}
                  REMOVE
                </button>
              )}
              {regState !== "done" && (
                <button
                  onClick={handleRegister}
                  disabled={regState === "calling" || !regName.trim()}
                  className="flex-2 h-9 px-5 rounded-lg font-pixel text-[8px] flex items-center justify-center gap-1.5 transition-all disabled:opacity-50"
                  style={{
                    background: `linear-gradient(135deg, ${agent.color}cc, ${agent.color}88)`,
                    border: `1px solid ${agent.color}70`,
                    color: "#fff",
                    boxShadow: regState === "idle" ? `0 0 20px ${agent.color}25` : undefined,
                  }}
                >
                  {regState === "calling" ? (
                    <><Loader2 className="w-3 h-3 animate-spin" />REGISTERING…</>
                  ) : (
                    <><UserPlus className="w-3 h-3" />REGISTER ONCHAIN</>
                  )}
                </button>
              )}
            </div>
          </div>
        </div>,
        document.body
      )}
    </>
  );
};

const StatBox = ({
  label, value, color, small,
}: {
  label: string; value: string; color: string; small?: boolean;
}) => (
  <div
    className="rounded-lg p-2 text-center"
    style={{ background: color + "10", border: `1px solid ${color}20` }}
  >
    <p
      className={`font-mono font-semibold ${small ? "text-[9px]" : "text-xs"} leading-tight`}
      style={{ color }}
    >
      {value}
    </p>
    <p className="text-[8px] text-muted-foreground uppercase tracking-wider mt-0.5">{label}</p>
  </div>
);

export default RightPanel;
