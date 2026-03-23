import { MessageSquare, Terminal, ArrowRightLeft, Cpu, CheckCircle2, AlertTriangle } from "lucide-react";

const timelineItems = [
  { time: "14:32:01", type: "conversation", agent: "Kael", content: "Initiating LP analysis for HBAR/USDC pair across 3 DEXs", icon: MessageSquare, color: "text-cyan" },
  { time: "14:32:04", type: "tool_call", agent: "System", content: "API.fetchPoolData({ pairs: ['HBAR/USDC'], dexes: ['SaucerSwap', 'Pangolin', 'HeliSwap'] })", icon: Terminal, color: "text-gold" },
  { time: "14:32:08", type: "decision", agent: "Kael", content: "SaucerSwap selected — lowest slippage (0.12%), deepest liquidity ($2.4M)", icon: Cpu, color: "text-cyan" },
  { time: "14:32:11", type: "transaction", agent: "Vault", content: "TX 0x7a3f...2e1c — Swap 100 HBAR → 12.47 USDC — Status: CONFIRMED", icon: ArrowRightLeft, color: "text-success" },
  { time: "14:32:15", type: "conversation", agent: "Sentinel", content: "Monitoring swap execution. Price impact within acceptable bounds (0.03%)", icon: MessageSquare, color: "text-cyan" },
  { time: "14:32:18", type: "alert", agent: "Oracle", content: "Market volatility spike detected — recommending hold on further swaps", icon: AlertTriangle, color: "text-gold" },
  { time: "14:32:22", type: "decision", agent: "Kael", content: "Acknowledged. Pausing remaining swap sequence. Awaiting user confirmation.", icon: CheckCircle2, color: "text-success" },
];

const typeLabels: Record<string, string> = {
  conversation: "CHAT",
  tool_call: "TOOL",
  decision: "DECIDE",
  transaction: "TX",
  alert: "ALERT",
};

const typeBg: Record<string, string> = {
  conversation: "bg-secondary/60",
  tool_call: "bg-secondary/60 border-l-2 border-gold/40",
  decision: "bg-secondary/40 border-l-2 border-cyan/40",
  transaction: "bg-secondary/40 border-l-2 border-success/40",
  alert: "bg-secondary/60 border-l-2 border-gold/60",
};

const BottomPanel = () => {
  return (
    <div className="h-48 xl:h-56 glass-panel flex flex-col overflow-hidden">
      <div className="flex items-center justify-between px-4 py-2 border-b border-border/30">
        <div className="flex items-center gap-2">
          <Terminal className="w-3.5 h-3.5 text-gold" />
          <h2 className="font-pixel text-[10px] text-gold tracking-wider">ACTIVITY TIMELINE</h2>
        </div>
        <div className="flex items-center gap-3">
          <span className="text-[10px] text-muted-foreground font-mono">LIVE</span>
          <div className="w-2 h-2 rounded-full bg-success animate-pulse-glow" />
        </div>
      </div>

      <div className="flex-1 overflow-y-auto scrollbar-thin px-4 py-2 space-y-1">
        {timelineItems.map((item, i) => {
          const Icon = item.icon;
          return (
            <div
              key={i}
              className={`flex items-start gap-3 px-3 py-1.5 rounded-md ${typeBg[item.type]} animate-timeline-enter`}
              style={{ animationDelay: `${i * 50}ms` }}
            >
              <span className="text-[10px] text-muted-foreground font-mono w-16 shrink-0 pt-0.5">{item.time}</span>
              <Icon className={`w-3.5 h-3.5 ${item.color} shrink-0 mt-0.5`} />
              <span className={`text-[9px] font-mono uppercase tracking-wider ${item.color} w-12 shrink-0 pt-0.5`}>
                {typeLabels[item.type]}
              </span>
              <span className="text-[10px] font-mono text-muted-foreground w-14 shrink-0 pt-0.5">{item.agent}</span>
              <span className="text-xs font-mono text-secondary-foreground leading-relaxed">{item.content}</span>
            </div>
          );
        })}
      </div>
    </div>
  );
};

export default BottomPanel;
