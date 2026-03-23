/**
 * useAgentInit — registers agents onchain on first app load (once per session).
 * Persists per-agent registration TX hashes to localStorage so the UI can link to HashScan.
 */
import { useEffect, useRef } from "react";

export const AGENT_TX_STORAGE_KEY = "aslan_agent_reg_txhashes";

// Onchain registration TX hashes (AgentRegistry.sol on Hedera testnet)
const HARDCODED_TX_HASHES: Record<string, string> = {
  scout:      "0x83d275944fe351c12f2d446abed14db241e5cdca4a9dc906f4650e626d6fc36d",
  strategist: "0xe137dbba0276fe96d29bd0bb1b1b122f9dc65d2bef99fc2931f7bfdd6e6c843f",
  sentinel:   "0x84dcb11da739ca8ac96394f875ce51e3b01de2b741dbdefce9606721466916b4",
  treasurer:  "0x675e25bf7d351082768f6d370a500c9fd8921000b8fce52a70837ad009f2585b",
  executor:   "0x468bdc0128a753d1e2191bfe32592141643896e2a52f1a9693ca0d018be20a34",
  archivist:  "0x2f1204418d375692eaad888bd4fc9a1d664b9cb4966000b8b2d3fe8ca38da1c0",
};

/** Returns a map of agentId -> EVM tx hash (hardcoded onchain + any localStorage overrides) */
export function getStoredAgentTxHashes(): Record<string, string> {
  try {
    const raw = localStorage.getItem(AGENT_TX_STORAGE_KEY);
    const stored = raw ? JSON.parse(raw) : {};
    // Merge: localStorage overrides hardcoded (for re-registrations)
    return { ...HARDCODED_TX_HASHES, ...stored };
  } catch {
    return { ...HARDCODED_TX_HASHES };
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
