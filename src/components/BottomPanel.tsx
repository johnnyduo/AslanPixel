import { useEffect, useRef, useState } from "react";
import { MessageSquare, Terminal, ArrowRightLeft, Cpu, AlertTriangle, Shield, BookOpen, Zap, Send } from "lucide-react";
import { AGENTS } from "@/data/agents";
import { useLiveTimeline } from "@/hooks/useLiveTimeline";
import { useQuestInput } from "@/hooks/useQuestInput";
import type { TimelineMessage } from "@/lib/agentConversation";

const TYPE_META: Record<string, { label: string; Icon: React.ElementType; color: string; bg: string }> = {
  conversation: { label: "CHAT",   Icon: MessageSquare, color: "hsl(195 100% 55%)", bg: "hsl(195 100% 55% / 0.05)" },
  tool_call:    { label: "TOOL",   Icon: Terminal,      color: "hsl(43 90% 60%)",   bg: "hsl(43 90% 60% / 0.05)" },
  decision:     { label: "DECIDE", Icon: Cpu,           color: "hsl(195 100% 55%)", bg: "hsl(195 100% 55% / 0.06)" },
  transaction:  { label: "TX",     Icon: ArrowRightLeft,color: "hsl(142 70% 50%)",  bg: "hsl(142 70% 50% / 0.07)" },
  alert:        { label: "ALERT",  Icon: AlertTriangle, color: "hsl(38 92% 55%)",   bg: "hsl(38 92% 55% / 0.06)" },
  policy:       { label: "POLICY", Icon: Shield,        color: "hsl(142 70% 50%)",  bg: "hsl(142 70% 50% / 0.05)" },
  receipt:      { label: "RCPT",   Icon: BookOpen,      color: "hsl(0 72% 62%)",    bg: "hsl(0 72% 62% / 0.06)" },
  quest:        { label: "QUEST",  Icon: Zap,           color: "hsl(43 90% 60%)",   bg: "hsl(43 90% 60% / 0.08)" },
};

type QuestStatus = "idle" | "running" | "complete" | "error";

const BottomPanel = () => {
  const { messages: liveMessages, isLive, error: _error } = useLiveTimeline();
  const [questInput, setQuestInput] = useState("");
  const [questStatus, setQuestStatus] = useState<QuestStatus>("idle");
  const [questMessages, setQuestMessages] = useState<TimelineMessage[]>([]);
  const [lastReceiptId, setLastReceiptId] = useState<string | null>(null);
  const scrollRef = useRef<HTMLDivElement>(null);
  const eventSourceRef = useRef<EventSource | null>(null);
  const { pendingIntent, clearPendingIntent } = useQuestInput();

  // Listen for intents dispatched from LeftPanel "Deploy" button
  useEffect(() => {
    if (!pendingIntent) return;
    setQuestInput(pendingIntent);
    clearPendingIntent();
    // Slight delay so input is visible before running
    const t = setTimeout(() => {
      runQuestWithIntent(pendingIntent);
    }, 150);
    return () => clearTimeout(t);
  }, [pendingIntent]); // eslint-disable-line react-hooks/exhaustive-deps

  // Merge quest messages on top of live messages, newest first
  const allMessages: TimelineMessage[] = [...questMessages, ...liveMessages].slice(0, 60);

  // Auto-scroll to top when new messages arrive (newest first)
  useEffect(() => {
    if (scrollRef.current) {
      scrollRef.current.scrollTop = 0;
    }
  }, [allMessages.length]);

  const runQuestWithIntent = (intent: string) => {
    if (!intent.trim() || questStatus === "running") return;

    setQuestStatus("running");
    setQuestMessages([]);
    setLastReceiptId(null);

    if (eventSourceRef.current) {
      eventSourceRef.current.close();
    }

    const url = `/api/quest?intent=${encodeURIComponent(intent.trim())}`;
    const es = new EventSource(url);
    eventSourceRef.current = es;

    es.onmessage = (event) => {
      try {
        const data = JSON.parse(event.data) as Partial<TimelineMessage> & { receiptId?: string; done?: boolean };
        if (data.done) {
          if (data.receiptId) setLastReceiptId(data.receiptId);
          setQuestStatus("complete");
          es.close();
          return;
        }
        const msg: TimelineMessage = {
          id: data.id ?? `quest_${Date.now()}_${Math.random()}`,
          time: data.time ?? new Date().toLocaleTimeString("en-GB", { hour: "2-digit", minute: "2-digit", second: "2-digit" }),
          type: data.type ?? "quest",
          agentId: data.agentId ?? "scout",
          content: data.content ?? String(event.data),
        };
        setQuestMessages((prev) => [msg, ...prev].slice(0, 30));
      } catch {
        const msg: TimelineMessage = {
          id: `quest_${Date.now()}_${Math.random()}`,
          time: new Date().toLocaleTimeString("en-GB", { hour: "2-digit", minute: "2-digit", second: "2-digit" }),
          type: "quest",
          agentId: "scout",
          content: event.data,
        };
        setQuestMessages((prev) => [msg, ...prev].slice(0, 30));
      }
    };

    es.onerror = () => {
      setQuestStatus("error");
      es.close();
    };
  };

  const runQuest = () => {
    runQuestWithIntent(questInput.trim());
  };

  const handleKeyDown = (e: React.KeyboardEvent<HTMLInputElement>) => {
    if (e.key === "Enter") runQuest();
  };

  return (
    <div className="h-64 xl:h-72 glass-panel flex flex-col overflow-hidden">

      {/* ── Quest Input Bar ── */}
      <div className="shrink-0 px-3 pt-2.5 pb-2 border-b border-gold/20"
        style={{ background: "hsl(225 28% 6% / 0.8)" }}>
        <div className="flex items-center gap-2">
          {/* Label */}
          <span className="font-pixel text-[8px] text-gold shrink-0 tracking-wider">QUEST:</span>

          {/* Input */}
          <input
            type="text"
            value={questInput}
            onChange={(e) => setQuestInput(e.target.value)}
            onKeyDown={handleKeyDown}
            placeholder="Describe your intent..."
            disabled={questStatus === "running"}
            className="flex-1 h-7 bg-transparent border border-gold/25 rounded px-2 text-[10px] font-mono text-foreground placeholder:text-muted-foreground focus:outline-none focus:border-gold/50 disabled:opacity-50"
          />

          {/* Run Quest button */}
          <button
            onClick={runQuest}
            disabled={questStatus === "running" || !questInput.trim()}
            className="shrink-0 flex items-center gap-1.5 px-3 h-7 rounded font-pixel text-[8px] disabled:opacity-40 transition-all duration-200"
            style={{
              background: "linear-gradient(135deg, hsl(43 90% 45%), hsl(38 85% 35%))",
              border: "1px solid hsl(43 90% 55% / 0.6)",
              color: "hsl(225 30% 6%)",
              textShadow: "none",
            }}
          >
            <Send className="w-2.5 h-2.5" />
            RUN QUEST
          </button>
        </div>

        {/* Status line */}
        {questStatus === "running" && (
          <div className="flex items-center gap-1.5 mt-1.5">
            <div className="w-1.5 h-1.5 rounded-full bg-gold animate-pulse" />
            <span className="text-[8px] font-pixel text-gold tracking-widest animate-pulse">AGENTS MOBILIZING...</span>
          </div>
        )}
        {questStatus === "complete" && (
          <div className="flex items-center gap-1.5 mt-1.5">
            <div className="w-1.5 h-1.5 rounded-full bg-success" />
            <span className="text-[8px] font-pixel text-success">
              QUEST COMPLETE{lastReceiptId ? ` — Receipt #${lastReceiptId} stored` : ""}
            </span>
          </div>
        )}
        {questStatus === "error" && (
          <div className="flex items-center gap-1.5 mt-1.5">
            <div className="w-1.5 h-1.5 rounded-full bg-destructive" />
            <span className="text-[8px] font-pixel text-destructive">QUEST FAILED — check connection</span>
          </div>
        )}
      </div>

      {/* Header */}
      <div className="flex items-center justify-between px-4 py-1.5 border-b border-border/30 shrink-0">
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
        {allMessages.map((item, i) => {
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
