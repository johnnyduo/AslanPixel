import { useState, useEffect, useRef, useCallback } from "react";
import {
  type TimelineMessage,
  makeLocalGroupConversation,
} from "@/lib/agentConversation";

const STORAGE_KEY = "aslan_chat_history";
const MAX_MESSAGES = 50;
const LOAD_FROM_STORAGE = 20;

// Seed messages — Hedera-native content with new agent names
const SEED_MESSAGES: TimelineMessage[] = [
  {
    id: "seed_1",
    time: "14:32:01",
    type: "conversation",
    agentId: "scout",
    content:
      "Nexus: Subscribing HCS Topic #0.0.1234 — ingesting consensus events at 847 msgs/min. Sequence #4,190 onward.",
  },
  {
    id: "seed_2",
    time: "14:32:04",
    type: "tool_call",
    agentId: "scout",
    content:
      "HCS.getTopicMessages({ topicId:'0.0.1234', limit:500, order:'desc' }) → 847 events, last seq #4,192",
  },
  {
    id: "seed_3",
    time: "14:32:07",
    type: "conversation",
    agentId: "strategist",
    content:
      "Oryn: Generating EVM strategy model — 40% HTS liquidity, 35% stablecoin buffer, 25% yield farm. Confidence: 91%.",
  },
  {
    id: "seed_4",
    time: "14:32:09",
    type: "decision",
    agentId: "strategist",
    content:
      "SaucerSwap route selected — slippage 0.12%, liquidity depth $2.4M. Contract 0x00…4f89a2 audited. PROCEED.",
  },
  {
    id: "seed_5",
    time: "14:32:11",
    type: "policy",
    agentId: "sentinel",
    content:
      "Drax: Policy enforced — max position 5%, slippage cap 0.25%, audit hash 0xf3a1…verified. All checks PASS.",
  },
  {
    id: "seed_6",
    time: "14:32:14",
    type: "conversation",
    agentId: "treasurer",
    content:
      "Lyss: HTS treasury confirmed — 12,847.50 HBAR (1,284,750,000,000 tinyhbar). Reserving 500 HBAR gas buffer.",
  },
  {
    id: "seed_7",
    time: "14:32:17",
    type: "tool_call",
    agentId: "executor",
    content:
      "Vex: EVM.simulateTx({ to: SaucerSwap, value: 100ℏ, gasLimit: 94200, gasPrice: 2115 tinyhbar }) → SAFE",
  },
  {
    id: "seed_8",
    time: "14:32:19",
    type: "transaction",
    agentId: "executor",
    content:
      "TX 0.0.1234@1711234567.000000000 — 100 HBAR → 12.47 USDC — Gas: 199,233,000 tinyhbar — Slot: 4,192,441 CONFIRMED",
  },
  {
    id: "seed_9",
    time: "14:32:22",
    type: "alert",
    agentId: "sentinel",
    content:
      "Drax: Mirror node lag +340ms detected post-TX. HCS sequence gap at #4,193. Holding sequential ops. MONITORING.",
  },
  {
    id: "seed_10",
    time: "14:32:25",
    type: "receipt",
    agentId: "archivist",
    content:
      "Kael: Receipt #2041 → mirror.hedera.com/api/v1/transactions/0.0.1234-1711234567 — inputHash: 0xab12… IMMUTABLE",
  },
];


function loadFromStorage(): TimelineMessage[] {
  try {
    const raw = localStorage.getItem(STORAGE_KEY);
    if (!raw) return [];
    const lines = raw.trim().split("\n").filter(Boolean);
    const parsed = lines
      .map((line) => {
        try {
          return JSON.parse(line) as TimelineMessage;
        } catch {
          return null;
        }
      })
      .filter((m): m is TimelineMessage => m !== null);
    // Return last N messages
    return parsed.slice(-LOAD_FROM_STORAGE);
  } catch {
    return [];
  }
}

const STORAGE_MAX_LINES = 30; // hard cap — prevents QuotaExceededError crash

function appendToStorage(messages: TimelineMessage[]): void {
  try {
    const existing = localStorage.getItem(STORAGE_KEY) ?? "";
    const existingLines = existing ? existing.trim().split("\n").filter(Boolean) : [];
    const newLines = messages.map((m) => JSON.stringify(m));
    // Keep only last STORAGE_MAX_LINES lines total
    const combined = [...existingLines, ...newLines].slice(-STORAGE_MAX_LINES);
    localStorage.setItem(STORAGE_KEY, combined.join("\n"));
  } catch {
    // Storage full — clear and start fresh rather than crashing
    try { localStorage.removeItem(STORAGE_KEY); } catch { /* ignore */ }
  }
}

export interface UseLiveTimelineReturn {
  messages: TimelineMessage[];
  isLive: boolean;
  error: string | null;
}

export function useLiveTimeline(): UseLiveTimelineReturn {
  const [messages, setMessages] = useState<TimelineMessage[]>([]);
  const [isLive, setIsLive] = useState(false);
  const timerRef = useRef<ReturnType<typeof setTimeout> | null>(null);
  const isMounted = useRef(true);
  const esRef = useRef<EventSource | null>(null);
  const backendConnected = useRef(false);
  const retryCountRef = useRef(0);

  // On mount: load from storage, fall back to seeds
  useEffect(() => {
    const stored = loadFromStorage();
    if (stored.length > 0) {
      // Merge stored with seeds, deduplicate by id, newest first
      const all = [...stored, ...SEED_MESSAGES];
      const seen = new Set<string>();
      const deduped = all.filter((m) => {
        if (seen.has(m.id)) return false;
        seen.add(m.id);
        return true;
      });
      setMessages(deduped.slice(0, MAX_MESSAGES));
    } else {
      setMessages([...SEED_MESSAGES]);
    }
  }, []);

  // Local fallback ticker — only fires when SSE is NOT connected
  const scheduleNext = useCallback(() => {
    if (!isMounted.current) return;
    const delay = 8000 + Math.random() * 4000;
    timerRef.current = setTimeout(() => {
      if (!isMounted.current) return;
      if (backendConnected.current) { scheduleNext(); return; }

      const batch = makeLocalGroupConversation();
      appendToStorage(batch);
      setMessages((prev) => [...batch, ...prev].slice(0, MAX_MESSAGES));
      scheduleNext();
    }, delay);
  }, []);

  // Always connect to /api/stream SSE — works on Vercel Edge (all envs)
  // Key stays server-side, browser never sees GEMINI_API_KEY
  useEffect(() => {
    if (typeof window === "undefined") return;

    let es: EventSource;
    let retryTimeout: ReturnType<typeof setTimeout>;

    const connect = () => {
      es = new EventSource("/api/stream");
      esRef.current = es;

      es.addEventListener("ping", () => {
        backendConnected.current = true;
        retryCountRef.current = 0;
        setIsLive(true);
      });

      es.addEventListener("message", (event) => {
        if (!isMounted.current) return;
        try {
          const data = JSON.parse(event.data) as TimelineMessage;
          if (!data.id || !data.content) return;
          backendConnected.current = true;
          retryCountRef.current = 0;
          setIsLive(true);
          appendToStorage([data]);
          setMessages((prev) => [data, ...prev].slice(0, MAX_MESSAGES));
        } catch { /* ignore */ }
      });

      es.onerror = () => {
        backendConnected.current = false;
        setIsLive(false);
        es.close();
        // Exponential backoff: 15s, 30s, 60s, cap at 120s
        const delay = Math.min(15000 * Math.pow(2, retryCountRef.current), 120000);
        retryCountRef.current = Math.min(retryCountRef.current + 1, 3);
        retryTimeout = setTimeout(connect, delay);
      };
    };

    connect();

    return () => {
      clearTimeout(retryTimeout);
      es?.close();
      backendConnected.current = false;
      setIsLive(false);
    };
  }, []);

  useEffect(() => {
    isMounted.current = true;
    scheduleNext();
    return () => {
      isMounted.current = false;
      if (timerRef.current) {
        clearTimeout(timerRef.current);
      }
    };
  }, [scheduleNext]);

  return { messages, isLive, error: null };
}
