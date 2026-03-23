import { useState, useEffect, useRef, useCallback } from "react";
import {
  type TimelineMessage,
  generateGroupConversation,
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

const TRIGGERS = [
  "HCS Topic #0.0.1234 sequence gap detected — Nexus investigating",
  "HTS token #0.0.887432 mint threshold reached — Lyss reviewing allocation",
  "EVM contract 0x00000000000000000000000000000000004f89a2 upgrade detected — Drax re-auditing",
  "Mirror node slot 4,192,441 confirmed — Kael archiving receipt bundle",
  "SaucerSwap HBAR/USDC slippage spike to 0.31% — Drax enforcing cap",
  "Vex: batch of 3 EVM TXs queued — gas at 2,115 tinyhbar/unit optimal window",
  "Oryn: HTS yield strategy branch B activated — confidence 87%",
  "Mirror node lag +420ms — Nexus flagging consensus timestamp skew",
  "Treasury reconciliation cycle — Lyss verifying 12,847.50 HBAR balance",
  "New HCS topic subscription — Nexus tracking sequence numbers from #0",
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

function appendToStorage(messages: TimelineMessage[]): void {
  try {
    const existing = localStorage.getItem(STORAGE_KEY) ?? "";
    const newLines = messages.map((m) => JSON.stringify(m)).join("\n");
    const updated = existing ? `${existing}\n${newLines}` : newLines;
    localStorage.setItem(STORAGE_KEY, updated);
  } catch {
    // Storage full or unavailable — ignore
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
  const [error, setError] = useState<string | null>(null);
  const timerRef = useRef<ReturnType<typeof setTimeout> | null>(null);
  const isMounted = useRef(true);

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

  const scheduleNext = useCallback(() => {
    if (!isMounted.current) return;
    // Randomize between 8-12 seconds
    const delay = 8000 + Math.random() * 4000;
    timerRef.current = setTimeout(async () => {
      if (!isMounted.current) return;

      setIsLive(true);
      setError(null);

      const trigger = TRIGGERS[Math.floor(Math.random() * TRIGGERS.length)];
      let newMessages: TimelineMessage[];

      try {
        newMessages = await generateGroupConversation(trigger);
      } catch (err) {
        const errMsg = err instanceof Error ? err.message : "Unknown error";
        setError(errMsg);
        newMessages = makeLocalGroupConversation();
      }

      if (!isMounted.current) return;

      setIsLive(false);

      // Slice to 2-4 messages for the batch
      const batch = newMessages.slice(0, 2 + Math.floor(Math.random() * 3));

      appendToStorage(batch);

      setMessages((prev) => {
        const combined = [...batch, ...prev];
        return combined.slice(0, MAX_MESSAGES);
      });

      scheduleNext();
    }, delay);
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

  return { messages, isLive, error };
}
