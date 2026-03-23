import { useState } from "react";
import { Shield, Brain, Star, CheckCircle, XCircle, Play, ChevronRight, Zap, ExternalLink } from "lucide-react";
import { Button } from "@/components/ui/button";
import { AGENTS, STATUS_COLORS, ACTION_TYPE_COLORS, type Agent } from "@/data/agents";
import { useLiveTimeline } from "@/hooks/useLiveTimeline";
import { useQuestInput } from "@/hooks/useQuestInput";
import { useAgentStats } from "@/hooks/useContracts";

const RightPanel = () => {
  const [selectedId, setSelectedId] = useState<string>("scout");
  const [actionFeedback, setActionFeedback] = useState<{ type: "approve" | "reject" | "sim"; ts: number } | null>(null);
  const { agents: onchainAgents } = useAgentStats();
  const { messages } = useLiveTimeline();
  const { setPendingIntent } = useQuestInput();
  const agent = AGENTS.find((a) => a.id === selectedId)!;

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

  return (
    <aside className="w-72 xl:w-80 glass-panel flex flex-col gap-0 overflow-hidden">
      {/* Agent selector tabs */}
      <div className="px-3 pt-3 pb-0">
        <div className="flex items-center gap-1.5 mb-2">
          <Shield className="w-3.5 h-3.5 text-cyan" />
          <h2 className="font-pixel text-[10px] text-cyan tracking-wider">AGENT DETAIL</h2>
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
            {isOnchain && (
              <a
                href={`https://hashscan.io/testnet/account/0x8B90AA6D1A12111C8F08C8B9Af4cca9f90336CC4`}
                target="_blank"
                rel="noopener noreferrer"
                className="flex items-center gap-0.5 text-[7px] font-pixel px-1 py-0.5 rounded ml-1"
                style={{ background: "hsl(195 100% 55% / 0.1)", color: "hsl(195 100% 55%)", border: "1px solid hsl(195 100% 55% / 0.3)" }}
              >
                ONCHAIN <ExternalLink className="w-2 h-2" />
              </a>
            )}
          </div>

          {/* Stats grid */}
          <div className="grid grid-cols-3 gap-1.5">
            <StatBox label="Quests" value={displayQuests.toString()} color={agent.color} />
            <StatBox label="Success" value={`${displaySuccessRate}%`} color="hsl(142 70% 50%)" />
            <StatBox label="Focus" value={agent.specialization} color={agent.color} small />
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
