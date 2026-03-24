/**
 * useAutoQuest — fires automated AI quests on interval
 * Makes the guild feel alive even when no user is interacting
 */
import { useEffect, useRef } from "react";
import { useQuestInput } from "@/hooks/useQuestInput";
import { useWallet } from "@/hooks/useWallet";

export const AUTO_QUESTS = [
  "Rebalance HBAR/USDC pool allocation for maximum yield on SaucerSwap testnet",
  "Scan HCS topics for anomalous wallet inflow patterns — generate risk report",
  "Yield optimize treasury: shift 15% from HBAR reserve to SAUCE liquidity farm",
  "Run full PolicyManager.sol compliance sweep on current portfolio positions",
  "Reconcile mirror node state across all HTS token IDs in treasury",
  "Analyze HBAR/SAUCE price divergence and recommend arbitrage entry point",
  "Execute sequential batch: scan → decide → execute → archive with full audit trail",
  "Monitor HCS topic sequence integrity and flag any consensus timestamp gaps",
];

export function useAutoQuest(intervalMs = 3 * 60 * 1000) {
  const { setPendingIntent, pendingIntent } = useQuestInput();
  const { isConnected } = useWallet();
  const idxRef = useRef(Math.floor(Math.random() * AUTO_QUESTS.length));
  const pendingRef = useRef(pendingIntent);
  const connectedRef = useRef(isConnected);

  // Keep refs in sync without re-creating interval
  useEffect(() => { pendingRef.current = pendingIntent; }, [pendingIntent]);
  useEffect(() => { connectedRef.current = isConnected; }, [isConnected]);

  useEffect(() => {
    const fire = () => {
      // Don't fire when wallet is disconnected or a quest is already pending
      if (!connectedRef.current) return;
      if (pendingRef.current) return;
      const intent = "[AUTO] " + AUTO_QUESTS[idxRef.current % AUTO_QUESTS.length];
      idxRef.current++;
      setPendingIntent(intent);
    };

    // First auto-quest fires after 90 seconds (give user time to interact first)
    const initialDelay = setTimeout(fire, 90 * 1000);
    const interval = setInterval(fire, intervalMs);

    return () => {
      clearTimeout(initialDelay);
      clearInterval(interval);
    };
  }, [setPendingIntent, intervalMs]);
}
