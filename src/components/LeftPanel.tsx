import { useState } from "react";
import { Send, Sparkles, Target, Zap, Scroll } from "lucide-react";
import { Button } from "@/components/ui/button";

const suggestedPrompts = [
  { icon: Target, text: "Swap 100 HBAR for USDC at best rate" },
  { icon: Zap, text: "Stake tokens to maximize yield" },
  { icon: Scroll, text: "Analyze top NFT collections" },
];

const activeMissions = [
  { id: 1, title: "DeFi Yield Optimization", status: "executing", agents: 3, progress: 65 },
  { id: 2, title: "Market Sentiment Scan", status: "complete", agents: 2, progress: 100 },
  { id: 3, title: "Governance Vote Analysis", status: "pending", agents: 1, progress: 15 },
];

const LeftPanel = () => {
  const [query, setQuery] = useState("");

  return (
    <aside className="w-72 xl:w-80 glass-panel flex flex-col gap-3 p-4 overflow-hidden">
      <div className="flex items-center gap-2 mb-1">
        <Sparkles className="w-4 h-4 text-gold" />
        <h2 className="font-pixel text-xs text-gold tracking-wider">QUEST INPUT</h2>
      </div>

      <div className="relative">
        <textarea
          value={query}
          onChange={(e) => setQuery(e.target.value)}
          placeholder="Describe your quest..."
          className="w-full h-20 bg-secondary/50 border border-border/50 rounded-lg px-3 py-2.5 text-sm text-foreground placeholder:text-muted-foreground resize-none focus:outline-none focus:border-gold/40 focus:ring-1 focus:ring-primary/20 font-mono text-xs"
        />
        <Button variant="gold" size="xs" className="absolute bottom-2 right-2 gap-1">
          <Send className="w-3 h-3" />
          Deploy
        </Button>
      </div>

      <div className="space-y-1.5">
        <p className="text-[10px] text-muted-foreground uppercase tracking-wider font-mono">Suggested</p>
        {suggestedPrompts.map((prompt, i) => (
          <button
            key={i}
            onClick={() => setQuery(prompt.text)}
            className="w-full flex items-start gap-2 px-2.5 py-2 rounded-lg bg-secondary/30 hover:bg-secondary/60 border border-transparent hover:border-border/30 transition-all text-left group"
          >
            <prompt.icon className="w-3.5 h-3.5 text-cyan mt-0.5 shrink-0" />
            <span className="text-xs text-muted-foreground group-hover:text-foreground transition-colors leading-relaxed">{prompt.text}</span>
          </button>
        ))}
      </div>

      <div className="flex-1 overflow-hidden flex flex-col mt-2">
        <div className="flex items-center justify-between mb-2">
          <p className="text-[10px] text-muted-foreground uppercase tracking-wider font-mono">Active Missions</p>
          <span className="text-[10px] text-gold font-mono">{activeMissions.length}</span>
        </div>
        <div className="space-y-2 overflow-y-auto scrollbar-thin flex-1">
          {activeMissions.map((mission) => (
            <div key={mission.id} className="glass-panel p-3 space-y-2 hover:border-gold/20 transition-colors cursor-pointer">
              <div className="flex items-start justify-between">
                <p className="text-xs font-medium text-foreground leading-tight">{mission.title}</p>
                <StatusDot status={mission.status} />
              </div>
              <div className="flex items-center gap-2">
                <div className="flex-1 h-1 bg-secondary rounded-full overflow-hidden">
                  <div
                    className={`h-full rounded-full transition-all ${mission.status === 'complete' ? 'bg-success' : 'gradient-gold'}`}
                    style={{ width: `${mission.progress}%` }}
                  />
                </div>
                <span className="text-[10px] text-muted-foreground font-mono">{mission.progress}%</span>
              </div>
              <div className="flex items-center gap-1">
                <span className="text-[10px] text-muted-foreground font-mono">{mission.agents} agents</span>
              </div>
            </div>
          ))}
        </div>
      </div>
    </aside>
  );
};

const StatusDot = ({ status }: { status: string }) => {
  const colors: Record<string, string> = {
    executing: "bg-gold animate-pulse-glow",
    complete: "bg-success",
    pending: "bg-muted-foreground",
  };
  return <div className={`w-2 h-2 rounded-full ${colors[status] || 'bg-muted-foreground'}`} />;
};

export default LeftPanel;
