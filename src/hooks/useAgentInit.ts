/**
 * useAgentInit — registers agents onchain on first app load (once per session)
 */
import { useEffect, useRef } from "react";

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
        if (d.registeredAgents?.length > 0) {
          console.log("[AgentInit] Registered:", d.registeredAgents, "| HCS topic:", d.topicId);
        } else if (d.skippedAgents?.length > 0) {
          console.log("[AgentInit] Agents already registered | HCS topic:", d.topicId);
        }
      })
      .catch(() => { /* silent — non-critical */ });
  }, []);
}
