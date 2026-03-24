import React, { useEffect, useRef, useState } from "react";
import { MessageSquare, Terminal, ArrowRightLeft, Cpu, AlertTriangle, Shield, BookOpen, Zap, Send, Bot, Wallet, Lock } from "lucide-react";
import { AGENTS } from "@/data/agents";
import { useLiveTimeline } from "@/hooks/useLiveTimeline";
import { useQuestInput } from "@/hooks/useQuestInput";
import { useAutoQuest } from "@/hooks/useAutoQuest";
import { useWallet } from "@/hooks/useWallet";
import VotePanel from "@/components/VotePanel";
import PaymentGate from "@/components/PaymentGate";
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

type QuestStatus = "idle" | "paying" | "voting" | "running" | "complete" | "error";

// Parse content and make TX hashes / HashScan URLs clickable
function renderContent(content: string) {
  // Split on TX hashes and hashscan URLs, making them links
  const parts: React.ReactNode[] = [];
  let last = 0;
  const combined = new RegExp(`(0x[0-9a-fA-F]{40,}|hashscan\.io\/testnet\/(?:tx|transaction|contract)\/[^\s·]+)`, "g");
  let match: RegExpExecArray | null;
  while ((match = combined.exec(content)) !== null) {
    if (match.index > last) parts.push(content.slice(last, match.index));
    const raw = match[1];
    const href = raw.startsWith("0x")
      ? `https://hashscan.io/testnet/transaction/${raw}`
      : `https://${raw}`;
    const label = raw.startsWith("0x")
      ? `${raw.slice(0, 10)}…${raw.slice(-6)}`
      : "hashscan ↗";
    parts.push(
      <a key={match.index} href={href} target="_blank" rel="noopener noreferrer"
        className="text-cyan hover:underline cursor-pointer"
        onClick={(e) => e.stopPropagation()}
      >
        {label}
      </a>
    );
    last = match.index + raw.length;
  }
  if (last < content.length) parts.push(content.slice(last));
  return parts.length > 0 ? parts : content;
}

const TABS = [
  { id: "all",          label: "ALL" },
  { id: "conversation", label: "CHAT" },
  { id: "tool_call",    label: "TOOL" },
  { id: "transaction",  label: "TX" },
  { id: "alert",        label: "ALERT" },
] as const;
type TabId = typeof TABS[number]["id"];

const BottomPanel = () => {
  const { messages: liveMessages, isLive, error: _error } = useLiveTimeline();
  const { isConnected, openModal } = useWallet();
  const [questInput, setQuestInput] = useState("");
  const [questStatus, setQuestStatus] = useState<QuestStatus>("idle");
  const [activeTab, setActiveTab] = useState<TabId>("all");
  const [questMessages, setQuestMessages] = useState<TimelineMessage[]>([]);
  const [lastReceiptId, setLastReceiptId] = useState<string | null>(null);
  const [lastTxHash, setLastTxHash] = useState<string | null>(null);
  const [pendingVoteIntent, setPendingVoteIntent] = useState<string | null>(null);
  const [isAutoQuest, setIsAutoQuest] = useState(false);
  const scrollRef = useRef<HTMLDivElement>(null);
  const eventSourceRef = useRef<EventSource | null>(null);
  const { pendingIntent, clearPendingIntent } = useQuestInput();

  // Activate auto quest scheduler
  useAutoQuest();

  // Listen for intents dispatched from LeftPanel / autoQuest
  useEffect(() => {
    if (!pendingIntent) return;
    const intent = pendingIntent;
    clearPendingIntent();
    setQuestInput(intent.replace(/^\[AUTO\] /, ""));
    setIsAutoQuest(intent.startsWith("[AUTO] "));
    // Show payment gate first, then vote panel
    setTimeout(() => {
      setPendingVoteIntent(intent);
      setQuestStatus("paying");
    }, 150);
  }, [pendingIntent]); // eslint-disable-line react-hooks/exhaustive-deps

  const allMessages: TimelineMessage[] = [...questMessages, ...liveMessages].slice(0, 60);
  const filteredMessages = activeTab === "all" ? allMessages : allMessages.filter((m) => m.type === activeTab);

  useEffect(() => {
    if (scrollRef.current) scrollRef.current.scrollTop = 0;
  }, [allMessages.length]);

  // Cleanup EventSource on unmount
  useEffect(() => {
    return () => { if (eventSourceRef.current) eventSourceRef.current.close(); };
  }, []);

  const runQuestWithIntent = (intent: string) => {
    const cleanIntent = intent.replace(/^\[AUTO\] /, "").trim();
    if (!cleanIntent || questStatus === "running") return;

    setQuestStatus("running");
    setQuestMessages([]);
    setLastReceiptId(null);
    setLastTxHash(null);

    if (eventSourceRef.current) eventSourceRef.current.close();

    const url = `/api/quest?intent=${encodeURIComponent(cleanIntent)}`;
    const es = new EventSource(url);
    eventSourceRef.current = es;

    es.onmessage = (event) => {
      try {
        const data = JSON.parse(event.data) as Partial<TimelineMessage> & { receiptId?: string; done?: boolean };
        if (data.done) return;
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

    es.addEventListener("done", (event) => {
      try {
        const data = JSON.parse((event as MessageEvent).data);
        if (data.receiptId) setLastReceiptId(String(data.receiptId));
        if (data.txHash) setLastTxHash(String(data.txHash));
      } catch {}
      setQuestStatus("complete");
      es.close();
    });

    es.onerror = () => {
      setQuestStatus((prev) => prev === "running" ? "error" : prev);
      es.close();
    };
  };

  const handlePaymentConfirmed = () => {
    setQuestStatus("voting");
  };

  const handlePaymentDismissed = () => {
    setPendingVoteIntent(null);
    setQuestStatus("idle");
  };

  const handleVoteApproved = () => {
    const intent = pendingVoteIntent;
    setPendingVoteIntent(null);
    if (intent) runQuestWithIntent(intent);
  };

  const handleVoteVetoed = (reason: string) => {
    setPendingVoteIntent(null);
    setQuestStatus("error");
    // Show veto reason as a timeline message
    const msg: TimelineMessage = {
      id: `veto_${Date.now()}`,
      time: new Date().toLocaleTimeString("en-GB", { hour: "2-digit", minute: "2-digit", second: "2-digit" }),
      type: "policy",
      agentId: "sentinel",
      content: `VETO: ${reason}`,
    };
    setQuestMessages((prev) => [msg, ...prev]);
  };

  const runQuest = () => {
    const trimmed = questInput.trim();
    if (!trimmed || questStatus === "running" || questStatus === "voting" || questStatus === "paying") return;
    if (!isConnected) { openModal(); return; }
    setIsAutoQuest(false);
    setPendingVoteIntent(trimmed);
    setQuestStatus("paying");
  };

  const handleKeyDown = (e: React.KeyboardEvent<HTMLInputElement>) => {
    if (e.key === "Enter") runQuest();
  };

  return (
    <div className="h-64 xl:h-72 glass-panel flex flex-col overflow-hidden relative">

      {/* Wallet connect gate — shown when not connected */}
      {!isConnected && (
        <div className="absolute inset-0 z-40 flex flex-col items-center justify-center gap-3"
          style={{ background: "hsl(225 28% 5% / 0.88)", backdropFilter: "blur(6px)" }}>
          <div className="flex flex-col items-center gap-2 mb-1">
            <div className="w-10 h-10 rounded-xl flex items-center justify-center"
              style={{ background: "hsl(43 90% 55% / 0.1)", border: "1px solid hsl(43 90% 55% / 0.3)" }}>
              <Lock className="w-4 h-4 text-gold" />
            </div>
            <span className="font-pixel text-[9px] text-gold tracking-widest">GUILD TERMINAL LOCKED</span>
          </div>
          <p className="text-[10px] font-mono text-muted-foreground text-center max-w-[240px] leading-relaxed">
            Connect your wallet to submit quests and view the live agent timeline.
          </p>
          <button
            onClick={openModal}
            className="flex items-center gap-2 px-4 h-8 rounded-lg font-pixel text-[9px] transition-all hover:opacity-90"
            style={{
              background: "linear-gradient(135deg, hsl(43 90% 45%), hsl(38 85% 35%))",
              border: "1px solid hsl(43 90% 55% / 0.6)",
              color: "hsl(225 30% 6%)",
              boxShadow: "0 0 20px hsl(43 90% 50% / 0.2)",
            }}
          >
            <Wallet className="w-3 h-3" />
            CONNECT WALLET
          </button>
        </div>
      )}

      {/* Payment Gate — x402 agent wage */}
      {questStatus === "paying" && pendingVoteIntent && (
        <PaymentGate
          intent={pendingVoteIntent}
          onPaid={handlePaymentConfirmed}
          onDismiss={handlePaymentDismissed}
        />
      )}

      {/* Vote Panel Overlay */}
      {questStatus === "voting" && pendingVoteIntent && (
        <VotePanel
          intent={pendingVoteIntent}
          onApproved={handleVoteApproved}
          onVetoed={handleVoteVetoed}
        />
      )}

      {/* ── Quest Input Bar ── */}
      <div className="shrink-0 px-3 pt-2.5 pb-2 border-b border-gold/20"
        style={{ background: "hsl(225 28% 6% / 0.8)" }}>
        <div className="flex items-center gap-2">
          <span className="font-pixel text-[8px] text-gold shrink-0 tracking-wider">QUEST:</span>

          <input
            type="text"
            value={questInput}
            onChange={(e) => setQuestInput(e.target.value)}
            onKeyDown={handleKeyDown}
            placeholder="Describe your intent..."
            disabled={questStatus === "running" || questStatus === "voting" || questStatus === "paying"}
            className="flex-1 h-7 bg-transparent border border-gold/25 rounded px-2 text-[10px] font-mono text-foreground placeholder:text-muted-foreground focus:outline-none focus:border-gold/50 disabled:opacity-50"
          />

          <button
            onClick={runQuest}
            disabled={questStatus === "running" || questStatus === "voting" || questStatus === "paying" || !questInput.trim()}
            className="shrink-0 flex items-center gap-1.5 px-3 h-7 rounded font-pixel text-[8px] disabled:opacity-40 transition-all duration-200"
            style={{
              background: "linear-gradient(135deg, hsl(43 90% 45%), hsl(38 85% 35%))",
              border: "1px solid hsl(43 90% 55% / 0.6)",
              color: "hsl(225 30% 6%)",
            }}
          >
            <Send className="w-2.5 h-2.5" />
            RUN QUEST
          </button>
        </div>

        {/* Status line */}
        {questStatus === "paying" && (
          <div className="flex items-center gap-1.5 mt-1.5">
            <div className="w-1.5 h-1.5 rounded-full bg-cyan animate-pulse" />
            <span className="text-[8px] font-pixel text-cyan tracking-widest animate-pulse">◈ x402 — AGENT WAGE REQUIRED...</span>
          </div>
        )}
        {questStatus === "voting" && (
          <div className="flex items-center gap-1.5 mt-1.5">
            <div className="w-1.5 h-1.5 rounded-full bg-cyan animate-pulse" />
            <span className="text-[8px] font-pixel text-cyan tracking-widest animate-pulse">PIXEL VOTE IN PROGRESS...</span>
          </div>
        )}
        {questStatus === "running" && (
          <div className="flex items-center gap-1.5 mt-1.5">
            {isAutoQuest && <Bot className="w-2.5 h-2.5 text-purple-400" />}
            <div className="w-1.5 h-1.5 rounded-full bg-gold animate-pulse" />
            <span className="text-[8px] font-pixel text-gold tracking-widest animate-pulse">
              {isAutoQuest ? "AUTO QUEST — AGENTS MOBILIZING..." : "AGENTS MOBILIZING..."}
            </span>
          </div>
        )}
        {questStatus === "complete" && (
          <div className="flex items-center gap-1.5 mt-1.5 flex-wrap">
            {isAutoQuest && <Bot className="w-2.5 h-2.5 text-purple-400 shrink-0" />}
            <div className="w-1.5 h-1.5 rounded-full bg-success shrink-0" />
            <span className="text-[8px] font-pixel text-success">
              QUEST COMPLETE{lastReceiptId ? ` — Receipt #${lastReceiptId}` : ""}
            </span>
            {lastTxHash && (
              <a
                href={`https://hashscan.io/testnet/tx/${lastTxHash}`}
                target="_blank"
                rel="noopener noreferrer"
                className="text-[8px] font-mono text-cyan underline hover:text-gold transition-colors"
              >
                {lastTxHash.slice(0, 10)}…{lastTxHash.slice(-6)} ↗
              </a>
            )}
          </div>
        )}
        {questStatus === "error" && (
          <div className="flex items-center gap-1.5 mt-1.5">
            <div className="w-1.5 h-1.5 rounded-full bg-destructive" />
            <span className="text-[8px] font-pixel text-destructive">QUEST FAILED — check connection</span>
          </div>
        )}
      </div>

      {/* Tab bar */}
      <div className="flex items-center gap-0 px-3 pt-1.5 border-b border-border/30 shrink-0 overflow-hidden">
        <Terminal className="w-3 h-3 text-gold shrink-0 mr-2" />
        <div className="flex items-center gap-0 flex-1 min-w-0 overflow-x-auto scrollbar-none">
          {TABS.map((tab) => {
            const count = tab.id === "all" ? allMessages.length : allMessages.filter((m) => m.type === tab.id).length;
            const isActive = activeTab === tab.id;
            return (
              <button
                key={tab.id}
                onClick={() => setActiveTab(tab.id)}
                className="shrink-0 flex items-center gap-1 px-2.5 py-1.5 text-[8px] font-pixel tracking-wider transition-all duration-150 border-b-2 whitespace-nowrap"
                style={{
                  borderBottomColor: isActive ? "hsl(43 90% 55%)" : "transparent",
                  color: isActive ? "hsl(43 90% 65%)" : "hsl(215 12% 40%)",
                  background: isActive ? "hsl(43 90% 55% / 0.06)" : "transparent",
                }}
              >
                {tab.label}
                {count > 0 && (
                  <span className="text-[7px] font-mono px-1 rounded-full leading-none py-0.5"
                    style={{
                      background: isActive ? "hsl(43 90% 55% / 0.2)" : "hsl(225 15% 20%)",
                      color: isActive ? "hsl(43 90% 65%)" : "hsl(215 12% 45%)",
                    }}>
                    {count}
                  </span>
                )}
              </button>
            );
          })}
        </div>
        {/* Live indicator — right side */}
        <div className="flex items-center gap-1.5 shrink-0 pl-2">
          {isLive && (
            <div className="flex items-center gap-1 px-1 py-0.5 rounded"
              style={{ background: "hsl(280 65% 68% / 0.15)", border: "1px solid hsl(280 65% 68% / 0.4)" }}>
              <Zap className="w-2 h-2 animate-pulse" style={{ color: "hsl(280 65% 68%)" }} />
              <span className="text-[7px] font-pixel" style={{ color: "hsl(280 65% 68%)" }}>AI</span>
            </div>
          )}
          <div className="w-1.5 h-1.5 rounded-full bg-success animate-pulse-glow" />
        </div>
      </div>

      {/* Timeline */}
      <div ref={scrollRef} className="flex-1 overflow-y-auto scrollbar-thin px-3 py-1.5 space-y-0.5">
        {filteredMessages.length === 0 && (
          <div className="flex items-center justify-center h-full">
            <p className="text-[8px] font-pixel text-muted-foreground/40 tracking-wider">NO {activeTab.toUpperCase()} EVENTS</p>
          </div>
        )}
        {filteredMessages.map((item, i) => {
          const meta = TYPE_META[item.type] ?? TYPE_META.conversation;
          const agentData = AGENTS.find((a) => a.id === item.agentId);
          const Icon = meta.Icon;
          const isAuto = item.content?.startsWith("[AUTO]") || false;
          return (
            <div
              key={item.id}
              className="flex items-start gap-2 px-2.5 py-1.5 rounded-md transition-colors hover:bg-secondary/20 animate-timeline-enter group"
              style={{
                background: meta.bg,
                borderLeft: `2px solid ${agentData?.color ?? meta.color}40`,
                animationDelay: `${i * 40}ms`,
              }}
            >
              <span className="text-[9px] text-muted-foreground font-mono w-14 shrink-0 pt-[1px]">{item.time}</span>
              <Icon className="w-3 h-3 shrink-0 mt-[2px]" style={{ color: meta.color }} />
              <span className="text-[8px] font-pixel uppercase w-11 shrink-0 pt-[2px]" style={{ color: meta.color }}>
                {meta.label}
              </span>
              {isAuto && (
                <span className="text-[7px] font-pixel px-1 py-0.5 rounded shrink-0" style={{ background: "hsl(280 65% 68% / 0.15)", color: "hsl(280 65% 68%)", border: "1px solid hsl(280 65% 68% / 0.3)" }}>AUTO</span>
              )}
              {agentData && (
                <span
                  className="text-[8px] font-pixel px-1 py-0.5 rounded shrink-0"
                  style={{ background: agentData.color + "18", color: agentData.color, border: `1px solid ${agentData.color}35` }}
                >
                  {agentData.icon} {agentData.name}
                </span>
              )}
              <span className="text-[10px] font-mono text-secondary-foreground leading-snug">{renderContent(item.content)}</span>
            </div>
          );
        })}
      </div>
    </div>
  );
};

export default BottomPanel;
