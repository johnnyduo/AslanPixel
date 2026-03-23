import { Shield, Brain, Star, CheckCircle, XCircle, Play, ChevronRight } from "lucide-react";
import { Button } from "@/components/ui/button";

const selectedAgent = {
  name: "Archivist Kael",
  role: "Strategy Analyst",
  status: "active",
  confidence: 87,
  reasoning: "Cross-referencing DeFi pool depths with historical volatility to optimize entry. Factoring gas costs and slippage tolerance.",
  reputation: 4,
  completedQuests: 142,
  successRate: 94,
  specialization: "DeFi & Yield",
};

const recentActions = [
  { action: "Analyzed LP positions", time: "2m ago", type: "analysis" },
  { action: "Proposed swap route", time: "5m ago", type: "proposal" },
  { action: "Verified contract", time: "12m ago", type: "verification" },
];

const RightPanel = () => {
  return (
    <aside className="w-72 xl:w-80 glass-panel flex flex-col gap-3 p-4 overflow-hidden">
      <div className="flex items-center gap-2 mb-1">
        <Shield className="w-4 h-4 text-cyan" />
        <h2 className="font-pixel text-xs text-cyan tracking-wider">AGENT DETAIL</h2>
      </div>

      {/* Agent Profile */}
      <div className="glass-panel p-4 space-y-3">
        <div className="flex items-center gap-3">
          <div className="w-12 h-12 rounded-lg gradient-cyan flex items-center justify-center glow-cyan">
            <span className="font-pixel text-lg text-primary-foreground">AK</span>
          </div>
          <div className="flex-1">
            <h3 className="text-sm font-semibold text-foreground">{selectedAgent.name}</h3>
            <p className="text-[11px] text-cyan font-mono">{selectedAgent.role}</p>
            <div className="flex items-center gap-1 mt-0.5">
              {Array.from({ length: 5 }).map((_, i) => (
                <Star
                  key={i}
                  className={`w-3 h-3 ${i < selectedAgent.reputation ? 'text-gold fill-current' : 'text-muted-foreground/30'}`}
                />
              ))}
            </div>
          </div>
          <div className="w-2 h-2 rounded-full bg-success animate-pulse-glow" />
        </div>

        <div className="grid grid-cols-3 gap-2">
          <StatBox label="Quests" value={selectedAgent.completedQuests.toString()} />
          <StatBox label="Success" value={`${selectedAgent.successRate}%`} accent />
          <StatBox label="Focus" value={selectedAgent.specialization} small />
        </div>
      </div>

      {/* Confidence Meter */}
      <div className="glass-panel p-3 space-y-2">
        <div className="flex items-center justify-between">
          <span className="text-[10px] text-muted-foreground uppercase tracking-wider font-mono">Confidence</span>
          <span className="text-sm font-mono text-gold font-semibold">{selectedAgent.confidence}%</span>
        </div>
        <div className="h-2 bg-secondary rounded-full overflow-hidden">
          <div
            className="h-full gradient-gold rounded-full transition-all duration-1000"
            style={{ width: `${selectedAgent.confidence}%` }}
          />
        </div>
      </div>

      {/* Reasoning */}
      <div className="glass-panel p-3 space-y-2">
        <div className="flex items-center gap-1.5">
          <Brain className="w-3.5 h-3.5 text-cyan" />
          <span className="text-[10px] text-muted-foreground uppercase tracking-wider font-mono">Reasoning</span>
        </div>
        <p className="text-xs text-secondary-foreground leading-relaxed font-mono">{selectedAgent.reasoning}</p>
      </div>

      {/* Action Buttons */}
      <div className="flex gap-2">
        <Button variant="approve" size="sm" className="flex-1 gap-1.5">
          <CheckCircle className="w-3.5 h-3.5" />
          Approve
        </Button>
        <Button variant="destructive" size="sm" className="flex-1 gap-1.5">
          <XCircle className="w-3.5 h-3.5" />
          Reject
        </Button>
        <Button variant="outline" size="sm" className="gap-1.5">
          <Play className="w-3.5 h-3.5" />
          Sim
        </Button>
      </div>

      {/* Recent Actions */}
      <div className="flex-1 overflow-hidden flex flex-col">
        <p className="text-[10px] text-muted-foreground uppercase tracking-wider font-mono mb-2">Recent Actions</p>
        <div className="space-y-1 overflow-y-auto scrollbar-thin flex-1">
          {recentActions.map((item, i) => (
            <div key={i} className="flex items-center gap-2 px-2 py-1.5 rounded-md hover:bg-secondary/30 transition-colors group cursor-pointer">
              <ChevronRight className="w-3 h-3 text-muted-foreground group-hover:text-cyan transition-colors" />
              <span className="text-xs text-foreground flex-1">{item.action}</span>
              <span className="text-[10px] text-muted-foreground font-mono">{item.time}</span>
            </div>
          ))}
        </div>
      </div>
    </aside>
  );
};

const StatBox = ({ label, value, accent, small }: { label: string; value: string; accent?: boolean; small?: boolean }) => (
  <div className="bg-secondary/40 rounded-lg p-2 text-center">
    <p className={`font-mono font-semibold ${small ? 'text-[10px]' : 'text-xs'} ${accent ? 'text-success' : 'text-foreground'}`}>{value}</p>
    <p className="text-[9px] text-muted-foreground uppercase tracking-wider">{label}</p>
  </div>
);

export default RightPanel;
