import { useState } from "react";
import { Send, Sparkles, Target, Zap, Scroll, TrendingUp } from "lucide-react";
import { Button } from "@/components/ui/button";
import { AGENTS } from "@/data/agents";

const suggestedPrompts = [
  { icon: Target,      text: "Allocate low-risk portfolio across HBAR pairs" },
  { icon: Zap,         text: "Rebalance with 30% liquidity buffer on Hedera" },
  { icon: TrendingUp,  text: "Analyze my wallet risk and suggest mitigation" },
  { icon: Scroll,      text: "Execute 100 HBAR → USDC at best route + receipt" },
];

interface Mission {
  id: number;
  title: string;
  status: "executing" | "complete" | "pending";
  agentIds: string[];
  progress: number;
}

const activeMissions: Mission[] = [
  { id: 1, title: "DeFi Yield Optimization",   status: "executing", agentIds: ["scout", "strategist", "executor"], progress: 65 },
  { id: 2, title: "Market Sentiment Scan",      status: "complete",  agentIds: ["scout", "archivist"],              progress: 100 },
  { id: 3, title: "Governance Vote Analysis",   status: "pending",   agentIds: ["strategist"],                      progress: 15 },
  { id: 4, title: "Treasury Rebalance",         status: "executing", agentIds: ["treasurer", "sentinel", "executor"], progress: 42 },
];

const STATUS_STYLES: Record<string, { bar: string; dot: string; label: string }> = {
  executing: { bar: "gradient-gold", dot: "bg-gold animate-pulse-glow", label: "Executing" },
  complete:  { bar: "bg-success",    dot: "bg-success",                  label: "Complete" },
  pending:   { bar: "bg-secondary",  dot: "bg-muted-foreground",         label: "Pending" },
};

const LeftPanel = () => {
  const [query, setQuery] = useState("");

  return (
    <aside className="w-72 xl:w-80 glass-panel flex flex-col gap-3 p-4 overflow-hidden">
      {/* Header */}
      <div className="flex items-center gap-2">
        <Sparkles className="w-4 h-4 text-gold" />
        <h2 className="font-pixel text-[10px] text-gold tracking-wider">QUEST INPUT</h2>
      </div>

      {/* Input */}
      <div className="relative">
        <textarea
          value={query}
          onChange={(e) => setQuery(e.target.value)}
          placeholder="Describe your goal in natural language..."
          className="w-full h-[72px] bg-secondary/40 border border-border/40 rounded-lg px-3 py-2.5 text-xs text-foreground placeholder:text-muted-foreground resize-none focus:outline-none focus:border-gold/40 focus:ring-1 focus:ring-primary/20 font-mono leading-relaxed"
        />
        <Button
          size="sm"
          className="absolute bottom-2 right-2 h-6 px-2 gap-1 text-[10px] font-pixel"
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

      {/* Active agents — status strip */}
      <div>
        <p className="text-[9px] text-muted-foreground uppercase tracking-wider font-mono mb-1.5">Guild Agents</p>
        <div className="grid grid-cols-3 gap-1">
          {AGENTS.map((a) => (
            <div
              key={a.id}
              className="flex items-center gap-1 px-1.5 py-1 rounded-md"
              style={{
                background: a.color + "12",
                border: `1px solid ${a.color}25`,
              }}
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
            const st = STATUS_STYLES[m.status];
            const missionAgents = AGENTS.filter((a) => m.agentIds.includes(a.id));
            return (
              <div
                key={m.id}
                className="rounded-xl p-3 space-y-2 cursor-pointer transition-all duration-200 group"
                style={{
                  background: "hsl(225 22% 11%)",
                  border: "1px solid hsl(225 15% 18%)",
                }}
                onMouseEnter={(e) => (e.currentTarget.style.borderColor = "hsl(43 90% 55% / 0.2)")}
                onMouseLeave={(e) => (e.currentTarget.style.borderColor = "hsl(225 15% 18%)")}
              >
                {/* Title + status */}
                <div className="flex items-start justify-between gap-2">
                  <p className="text-[11px] font-medium text-foreground leading-tight">{m.title}</p>
                  <div className="flex items-center gap-1 shrink-0">
                    <div className={`w-1.5 h-1.5 rounded-full ${st.dot}`} />
                    <span className="text-[8px] font-pixel text-muted-foreground">{st.label}</span>
                  </div>
                </div>

                {/* Progress bar */}
                <div className="space-y-1">
                  <div className="h-1.5 bg-secondary rounded-full overflow-hidden">
                    <div
                      className={`h-full rounded-full transition-all duration-700 ${st.bar}`}
                      style={{ width: `${m.progress}%` }}
                    />
                  </div>
                  <div className="flex justify-between">
                    <span className="text-[8px] font-mono text-muted-foreground">{m.progress}%</span>
                  </div>
                </div>

                {/* Agent avatars */}
                <div className="flex items-center gap-1">
                  {missionAgents.map((a) => (
                    <div
                      key={a.id}
                      title={`${a.name} — ${a.role}`}
                      className="w-5 h-5 rounded-md flex items-center justify-center text-[9px] font-pixel"
                      style={{
                        background: a.color + "20",
                        border: `1px solid ${a.color}45`,
                        color: a.color,
                      }}
                    >
                      {a.icon}
                    </div>
                  ))}
                  <span className="text-[8px] text-muted-foreground font-mono ml-1">
                    {missionAgents.length} agent{missionAgents.length > 1 ? "s" : ""}
                  </span>
                </div>
              </div>
            );
          })}
        </div>
      </div>
    </aside>
  );
};

export default LeftPanel;
