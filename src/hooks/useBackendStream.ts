/**
 * useBackendStream — connects to backend SSE for real-time agent activity
 * Falls back to Gemini direct (useLiveTimeline) if backend not available
 */
import { useState, useEffect, useCallback } from "react";
import type { TimelineMessage } from "@/lib/agentConversation";

const BACKEND_URL = import.meta.env.VITE_BACKEND_URL ?? "http://localhost:3001";

export interface QuestResult {
  questId: number;
  receiptId: number;
  status: "pending" | "running" | "completed" | "error";
}

interface UseBackendStreamReturn {
  messages: TimelineMessage[];
  isConnected: boolean;
  isBackendAvailable: boolean;
  submitQuest: (intent: string, walletAddress?: string) => Promise<QuestResult | null>;
  questStatus: QuestResult | null;
}

export function useBackendStream(): UseBackendStreamReturn {
  const [messages, setMessages] = useState<TimelineMessage[]>([]);
  const [isConnected, setIsConnected] = useState(false);
  const [isBackendAvailable, setIsBackendAvailable] = useState(false);
  const [questStatus, setQuestStatus] = useState<QuestResult | null>(null);

  // Check backend health
  useEffect(() => {
    fetch(`${BACKEND_URL}/health`, { signal: AbortSignal.timeout(2000) })
      .then((r) => r.ok && setIsBackendAvailable(true))
      .catch(() => setIsBackendAvailable(false));
  }, []);

  // Subscribe to live activity SSE stream
  useEffect(() => {
    if (!isBackendAvailable) return;

    const es = new EventSource(`${BACKEND_URL}/api/quest/stream`);

    es.addEventListener("message", (e) => {
      try {
        const msg: TimelineMessage = JSON.parse(e.data);
        setMessages((prev) => [msg, ...prev].slice(0, 50));
      } catch {}
    });

    es.addEventListener("ping", () => setIsConnected(true));
    es.onerror = () => setIsConnected(false);
    es.onopen = () => setIsConnected(true);

    return () => es.close();
  }, [isBackendAvailable]);

  // Submit quest — streams agent workflow via SSE
  const submitQuest = useCallback(async (
    intent: string,
    walletAddress?: string
  ): Promise<QuestResult | null> => {
    if (!isBackendAvailable) return null;

    const result: QuestResult = {
      questId: Date.now(),
      receiptId: 0,
      status: "running",
    };
    setQuestStatus(result);

    return new Promise((resolve) => {
      // POST triggers SSE stream
      fetch(`${BACKEND_URL}/api/quest`, {
        method: "POST",
        headers: { "Content-Type": "application/json" },
        body: JSON.stringify({ intent, walletAddress }),
      }).then(async (res) => {
        if (!res.ok || !res.body) {
          setQuestStatus((p) => p ? { ...p, status: "error" } : null);
          resolve(null);
          return;
        }

        const reader = res.body.getReader();
        const decoder = new TextDecoder();
        let buffer = "";

        while (true) {
          const { done, value } = await reader.read();
          if (done) break;

          buffer += decoder.decode(value, { stream: true });
          const parts = buffer.split("\n\n");
          buffer = parts.pop() ?? "";

          for (const part of parts) {
            const lines = part.split("\n");
            let event = "message";
            let data = "";
            for (const line of lines) {
              if (line.startsWith("event: ")) event = line.slice(7);
              if (line.startsWith("data: ")) data = line.slice(6);
            }
            if (!data) continue;

            try {
              const parsed = JSON.parse(data);
              if (event === "message") {
                setMessages((prev) => [parsed as TimelineMessage, ...prev].slice(0, 50));
              } else if (event === "done") {
                const final: QuestResult = {
                  questId: result.questId,
                  receiptId: parsed.receiptId ?? 0,
                  status: "completed",
                };
                setQuestStatus(final);
                resolve(final);
              } else if (event === "error") {
                setQuestStatus((p) => p ? { ...p, status: "error" } : null);
                resolve(null);
              }
            } catch {}
          }
        }
      }).catch(() => {
        setQuestStatus((p) => p ? { ...p, status: "error" } : null);
        resolve(null);
      });
    });
  }, [isBackendAvailable]);

  return { messages, isConnected, isBackendAvailable, submitQuest, questStatus };
}
