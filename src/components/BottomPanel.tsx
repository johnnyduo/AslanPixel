import { MessageSquare, Terminal, ArrowRightLeft, Cpu, CheckCircle2, AlertTriangle, Shield, Database, BookOpen, Zap } from "lucide-react";
import { AGENTS } from "@/data/agents";

interface TimelineItem {
  time: string;
  type: "conversation" | "tool_call" | "decision" | "transaction" | "alert" | "policy" | "receipt";
  agentId: string;
  content: string;
}

const timelineItems: TimelineItem[] = [
  { time: "14:32:01", type: "conversation", agentId: "scout",      content: "Scanning HBAR/USDC depth across SaucerSwap, Pangolin, HeliSwap — pulling 24h volume + slippage data." },
  { time: "14:32:04", type: "tool_call",    agentId: "scout",      content: "API.fetchPoolData({ pairs: ['HBAR/USDC'], dexes: 3, resolution: '1m' }) → 847 data points" },
  { time: "14:32:07", type: "conversation", agentId: "strategist", content: "Generating weighted allocation model: 40% HBAR liquidity, 35% stablecoin buffer, 25% yield farm." },
  { time: "14:32:09", type: "decision",     agentId: "strategist", content: "SaucerSwap selected — lowest slippage 0.12%, deepest liquidity $2.4M. Plan confidence: 91%." },
  { time: "14:32:11", type: "policy",       agentId: "sentinel",   content: "Enforcing: max position 5%, slippage cap 0.25%, contract audit required. All checks PASS." },
  { time: "14:32:14", type: "conversation", agentId: "treasurer",  content: "Treasury balance confirmed: 12,847.50 HBAR. Reserving 500 HBAR gas buffer. Committing 100 HBAR for swap." },
  { time: "14:32:17", type: "tool_call",    agentId: "executor",   content: "simulateTx({ from: wallet, to: SaucerSwap, amount: 100, gasEstimate: 92400 }) → SAFE" },
  { time: "14:32:19", type: "transaction",  agentId: "executor",   content: "TX 0x7a3f…2e1c submitted — 100 HBAR → 12.47 USDC — Gas: 0.0092 HBAR — Status: CONFIRMED ✓" },
  { time: "14:32:22", type: "alert",        agentId: "sentinel",   content: "Volatility spike +2.4% detected post-swap. Recommending hold on sequential swaps. Monitoring." },
  { time: "14:32:25", type: "receipt",      agentId: "archivist",  content: "Receipt #2041 stored → QuestReceipt.sol — inputHash: 0xab12…, outputHash: 0xcd34…, agents: 5" },
];

const TYPE_META: Record<string, { label: string; Icon: React.ElementType; color: string; bg: string }> = {
  conversation: { label: "CHAT",   Icon: MessageSquare, color: "hsl(195 100% 55%)", bg: "hsl(195 100% 55% / 0.05)" },
  tool_call:    { label: "TOOL",   Icon: Terminal,      color: "hsl(43 90% 60%)",   bg: "hsl(43 90% 60% / 0.05)" },
  decision:     { label: "DECIDE", Icon: Cpu,           color: "hsl(195 100% 55%)", bg: "hsl(195 100% 55% / 0.06)" },
  transaction:  { label: "TX",     Icon: ArrowRightLeft,color: "hsl(142 70% 50%)",  bg: "hsl(142 70% 50% / 0.07)" },
  alert:        { label: "ALERT",  Icon: AlertTriangle, color: "hsl(38 92% 55%)",   bg: "hsl(38 92% 55% / 0.06)" },
  policy:       { label: "POLICY", Icon: Shield,        color: "hsl(142 70% 50%)",  bg: "hsl(142 70% 50% / 0.05)" },
  receipt:      { label: "RCPT",   Icon: BookOpen,      color: "hsl(0 72% 62%)",    bg: "hsl(0 72% 62% / 0.06)" },
};

const BottomPanel = () => {
  return (
    <div className="h-52 xl:h-60 glass-panel flex flex-col overflow-hidden">
      {/* Header */}
      <div className="flex items-center justify-between px-4 py-2 border-b border-border/30 shrink-0">
        <div className="flex items-center gap-2">
          <Terminal className="w-3.5 h-3.5 text-gold" />
          <h2 className="font-pixel text-[10px] text-gold tracking-wider">ACTIVITY TIMELINE</h2>
        </div>
        <div className="flex items-center gap-4">
          {/* Agent color legend — compact */}
          <div className="hidden xl:flex items-center gap-2">
            {AGENTS.map((a) => (
              <div key={a.id} className="flex items-center gap-1">
                <div className="w-1.5 h-1.5 rounded-full" style={{ background: a.color }} />
                <span className="text-[8px] font-pixel" style={{ color: a.color + "99" }}>{a.name}</span>
              </div>
            ))}
          </div>
          <div className="flex items-center gap-1.5">
            <span className="text-[9px] text-muted-foreground font-mono">LIVE</span>
            <div className="w-2 h-2 rounded-full bg-success animate-pulse-glow" />
          </div>
        </div>
      </div>

      {/* Timeline */}
      <div className="flex-1 overflow-y-auto scrollbar-thin px-3 py-1.5 space-y-0.5">
        {timelineItems.map((item, i) => {
          const meta = TYPE_META[item.type];
          const agent = AGENTS.find((a) => a.id === item.agentId);
          const Icon = meta.Icon;
          return (
            <div
              key={i}
              className="flex items-start gap-2 px-2.5 py-1.5 rounded-md transition-colors hover:bg-secondary/20 animate-timeline-enter group"
              style={{
                background: meta.bg,
                borderLeft: `2px solid ${agent?.color ?? meta.color}40`,
                animationDelay: `${i * 40}ms`,
              }}
            >
              {/* Time */}
              <span className="text-[9px] text-muted-foreground font-mono w-14 shrink-0 pt-[1px]">{item.time}</span>

              {/* Type icon */}
              <Icon className="w-3 h-3 shrink-0 mt-[2px]" style={{ color: meta.color }} />

              {/* Type label */}
              <span
                className="text-[8px] font-pixel uppercase w-11 shrink-0 pt-[2px]"
                style={{ color: meta.color }}
              >
                {meta.label}
              </span>

              {/* Agent name pill */}
              {agent && (
                <span
                  className="text-[8px] font-pixel px-1 py-0.5 rounded shrink-0"
                  style={{
                    background: agent.color + "18",
                    color: agent.color,
                    border: `1px solid ${agent.color}35`,
                  }}
                >
                  {agent.icon} {agent.name}
                </span>
              )}

              {/* Content */}
              <span className="text-[10px] font-mono text-secondary-foreground leading-snug">{item.content}</span>
            </div>
          );
        })}
      </div>
    </div>
  );
};

export default BottomPanel;
