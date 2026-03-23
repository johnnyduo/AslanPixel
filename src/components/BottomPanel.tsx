import { useEffect, useRef } from "react";
import { MessageSquare, Terminal, ArrowRightLeft, Cpu, AlertTriangle, Shield, BookOpen, Zap } from "lucide-react";
import { AGENTS } from "@/data/agents";
import { useLiveTimeline } from "@/hooks/useLiveTimeline";

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
  const { messages, isLive, error: _error } = useLiveTimeline();
  const scrollRef = useRef<HTMLDivElement>(null);

  // Auto-scroll to top when new messages arrive (newest first)
  useEffect(() => {
    if (scrollRef.current) {
      scrollRef.current.scrollTop = 0;
    }
  }, [messages.length]);

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
            {/* AI badge — shows when Gemini is responding */}
            {isLive && (
              <div className="flex items-center gap-1 px-1 py-0.5 rounded" style={{ background: "hsl(280 65% 68% / 0.15)", border: "1px solid hsl(280 65% 68% / 0.4)" }}>
                <Zap className="w-2.5 h-2.5 animate-pulse" style={{ color: "hsl(280 65% 68%)" }} />
                <span className="text-[7px] font-pixel" style={{ color: "hsl(280 65% 68%)" }}>AI</span>
              </div>
            )}
            <span className="text-[9px] text-muted-foreground font-mono">LIVE</span>
            <div className="w-2 h-2 rounded-full bg-success animate-pulse-glow" />
          </div>
        </div>
      </div>

      {/* Timeline */}
      <div ref={scrollRef} className="flex-1 overflow-y-auto scrollbar-thin px-3 py-1.5 space-y-0.5">
        {messages.map((item, i) => {
          const meta = TYPE_META[item.type] ?? TYPE_META.conversation;
          const agent = AGENTS.find((a) => a.id === item.agentId);
          const Icon = meta.Icon;
          return (
            <div
              key={item.id}
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
