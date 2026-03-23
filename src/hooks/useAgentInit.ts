/**
 * useAgentInit — registers agents onchain on first app load (once per session).
 * Persists per-agent registration TX hashes to localStorage so the UI can link to HashScan.
 */
import { useEffect, useRef } from "react";

export const AGENT_TX_STORAGE_KEY = "aslan_agent_reg_txhashes";

/** Returns a map of agentId -> EVM tx hash from localStorage */
export function getStoredAgentTxHashes(): Record<string, string> {
  try {
    const raw = localStorage.getItem(AGENT_TX_STORAGE_KEY);
    return raw ? JSON.parse(raw) : {};
  } catch {
    return {};
  }
}

export function useAgentInit() {
  const fired = useRef(false);

  useEffect(() => {
    if (fired.current) return;
    fired.current = true;

    // Fire-and-forget — don't block UI
    fetch("/api/agent-register", {
      method: "POST",
      headers: { "Content-Type": "application/json" },
      body: JSON.stringify({ mode: "register" }),
    })
      .then((r) => r.json())
      .then((d) => {
        // Persist any newly returned TX hashes (merge with existing)
        if (d.txHashes && Object.keys(d.txHashes).length > 0) {
          const existing = getStoredAgentTxHashes();
          const merged = { ...existing, ...d.txHashes };
          localStorage.setItem(AGENT_TX_STORAGE_KEY, JSON.stringify(merged));
          console.log("[AgentInit] Registered:", d.registeredAgents, "| TX hashes stored:", d.txHashes);
        } else if (d.skippedAgents?.length > 0) {
          console.log("[AgentInit] Agents already registered | HCS topic:", d.topicId);
        }
      })
      .catch(() => { /* silent — non-critical */ });
  }, []);
}
