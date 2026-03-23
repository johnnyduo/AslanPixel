/**
 * useContracts.ts
 * Browser-side hooks that read live data from deployed Hedera testnet contracts.
 * Uses BrowserProvider (window.ethereum) when available, falls back to JsonRpcProvider.
 */

import { useState, useEffect, useCallback } from "react";
import { JsonRpcProvider, BrowserProvider, Contract } from "ethers";

// ---------------------------------------------------------------------------
// Contract addresses
// ---------------------------------------------------------------------------
const ADDRESSES = {
  QuestReceipt:  "0x444f5895D29809847E8642Df0e0f4DBdBf541C7D",
  AgentRegistry: "0x8B90AA6D1A12111C8F08C8B9Af4cca9f90336CC4",
  MockUSDC:      "0x152Bf42A48677b678c658E452788ea2687525BF7",
  USDCFaucet:    "0xCA0558Fa81166C5939335282973Aa2F3A00B3953",
  PolicyManager: "0xdBc14F4c53c071cd925fa4a730D06ddc1b4911E4",
} as const;

const RPC_URL = "https://testnet.hashio.io/api";

// ---------------------------------------------------------------------------
// ABIs — extracted directly from artifacts/contracts/*.sol/*.json
// ---------------------------------------------------------------------------
const QUEST_RECEIPT_ABI = [
  "function questCount() view returns (uint256)",
  "function getReceipt(uint256 questId) view returns (tuple(bytes32 inputHash, bytes32 outputHash, bytes32 txHash, uint256 timestamp, uint256 questId, bool success, string intent))",
  "function getRecentReceipts(uint256 limit) view returns (tuple(bytes32 inputHash, bytes32 outputHash, bytes32 txHash, uint256 timestamp, uint256 questId, bool success, string intent)[])",
  "function getLatestReceipt() view returns (tuple(bytes32 inputHash, bytes32 outputHash, bytes32 txHash, uint256 timestamp, uint256 questId, bool success, string intent))",
  "function storeReceipt(bytes32 inputHash, bytes32 outputHash, bytes32 txHash, string intent, bool success) returns (uint256 questId)",
  "event ReceiptStored(uint256 indexed questId, bytes32 inputHash, bytes32 outputHash, bool success, uint256 timestamp)",
];

const AGENT_REGISTRY_ABI = [
  "function getAgentCount() view returns (uint256)",
  "function getAgent(string agentId) view returns (tuple(string agentId, string name, uint256 reputation, uint256 completedQuests, uint256 successCount, uint256 registeredAt, bool active))",
  "function agentKeys(uint256) view returns (bytes32)",
  "function registerAgent(string agentId, string name, string, address) nonpayable",
  "function recordQuestResult(string agentId, uint256 questId, bool success) nonpayable",
  "function deactivateAgent(string agentId) nonpayable",
  "event AgentRegistered(bytes32 indexed key, string agentId, string name)",
  "event QuestCompleted(bytes32 indexed key, uint256 questId, bool success)",
  "event ReputationUpdated(bytes32 indexed key, uint256 newRep)",
];

const MOCK_USDC_ABI = [
  "function balanceOf(address) view returns (uint256)",
  "function decimals() view returns (uint8)",
  "function symbol() view returns (string)",
  "function name() view returns (string)",
  "function totalSupply() view returns (uint256)",
  "function transfer(address to, uint256 amount) returns (bool)",
  "function approve(address spender, uint256 amount) returns (bool)",
  "function allowance(address, address) view returns (uint256)",
];

const USDC_FAUCET_ABI = [
  "function drip() nonpayable",
  "function dripTo(address to) nonpayable",
  "function lastClaim(address) view returns (uint256)",
  "function nextClaimTime(address user) view returns (uint256)",
  "function COOLDOWN() view returns (uint256)",
  "function DRIP_AMOUNT() view returns (uint256)",
  "event Dripped(address indexed to, uint256 amount, uint256 nextClaimAt)",
];


// ---------------------------------------------------------------------------
// Provider helpers
// ---------------------------------------------------------------------------
function getReadProvider(): JsonRpcProvider {
  return new JsonRpcProvider(RPC_URL);
}

async function getWriteProvider(): Promise<BrowserProvider> {
  if (typeof window === "undefined" || !window.ethereum) {
    throw new Error("No injected wallet found (window.ethereum is undefined)");
  }
  const provider = new BrowserProvider(window.ethereum);
  await provider.send("eth_requestAccounts", []);
  return provider;
}

// ---------------------------------------------------------------------------
// Types
// ---------------------------------------------------------------------------
export interface Receipt {
  inputHash: string;
  outputHash: string;
  txHash: string;
  timestamp: number;
  questId: number;
  success: boolean;
  intent: string;
}

export interface AgentStat {
  agentId: string;
  name: string;
  reputation: number;
  completedQuests: number;
  successCount: number;
  registeredAt: number;
  active: boolean;
}

// The 6 canonical agent IDs — used as fallback when contract is unreachable
const CANONICAL_AGENT_IDS = ["scout", "strategist", "sentinel", "treasurer", "executor", "archivist"];

// ---------------------------------------------------------------------------
// Hook: useQuestReceipts — polls every 30 s
// ---------------------------------------------------------------------------
export function useQuestReceipts(): { receipts: Receipt[]; count: number; loading: boolean } {
  const [receipts, setReceipts] = useState<Receipt[]>([]);
  const [count, setCount] = useState(0);
  const [loading, setLoading] = useState(true);

  const fetchData = useCallback(async () => {
    try {
      const provider = getReadProvider();
      const contract = new Contract(ADDRESSES.QuestReceipt, QUEST_RECEIPT_ABI, provider);

      const rawCount: bigint = await contract.questCount();
      const n = Number(rawCount);
      setCount(n);

      if (n === 0) {
        setReceipts([]);
        setLoading(false);
        return;
      }

      const limit = Math.min(n, 20);
      const raw = await contract.getRecentReceipts(limit) as Record<string, unknown>[];

      const parsed: Receipt[] = raw.map((r) => ({
        inputHash:  r.inputHash,
        outputHash: r.outputHash,
        txHash:     r.txHash,
        timestamp:  Number(r.timestamp),
        questId:    Number(r.questId),
        success:    r.success,
        intent:     r.intent,
      }));

      setReceipts(parsed);
    } catch (err) {
      console.warn("[useQuestReceipts] fetch error:", err);
    } finally {
      setLoading(false);
    }
  }, []);

  useEffect(() => {
    fetchData();
    const id = setInterval(fetchData, 30_000);
    return () => clearInterval(id);
  }, [fetchData]);

  return { receipts, count, loading };
}

// ---------------------------------------------------------------------------
// Hook: useAgentStats — polls every 60 s, fetches ALL registered agents dynamically
// ---------------------------------------------------------------------------
export function useAgentStats(): { agents: AgentStat[]; loading: boolean } {
  const [agents, setAgents] = useState<AgentStat[]>([]);
  const [loading, setLoading] = useState(true);

  const fetchData = useCallback(async () => {
    try {
      const provider = getReadProvider();
      const contract = new Contract(ADDRESSES.AgentRegistry, AGENT_REGISTRY_ABI, provider);

      // First get count of registered agents
      let agentCount = CANONICAL_AGENT_IDS.length;
      try {
        const rawCount: bigint = await contract.getAgentCount();
        agentCount = Math.max(Number(rawCount), CANONICAL_AGENT_IDS.length);
      } catch { /* fall back to canonical 6 */ }

      // Collect all agent IDs: canonical 6 + any custom ones from localStorage
      const storedCustom: string[] = (() => {
        try {
          return JSON.parse(localStorage.getItem("aslan_custom_agent_ids") || "[]");
        } catch { return []; }
      })();
      const allIds = Array.from(new Set([...CANONICAL_AGENT_IDS, ...storedCustom]));

      const results = await Promise.allSettled(
        allIds.map((id) => contract.getAgent(id))
      );

      const parsed: AgentStat[] = results
        .map((r, i) => {
          if (r.status === "rejected") {
            return {
              agentId:        allIds[i],
              name:           allIds[i],
              reputation:     0,
              completedQuests: 0,
              successCount:   0,
              registeredAt:   0,
              active:         false,
            } as AgentStat;
          }
          const a = r.value;
          return {
            agentId:        a.agentId,
            name:           a.name,
            reputation:     Number(a.reputation),
            completedQuests: Number(a.completedQuests),
            successCount:   Number(a.successCount),
            registeredAt:   Number(a.registeredAt),
            active:         a.active,
          } as AgentStat;
        });

      setAgents(parsed);
    } catch (err) {
      console.warn("[useAgentStats] fetch error:", err);
    } finally {
      setLoading(false);
    }
  }, []);

  useEffect(() => {
    fetchData();
    const id = setInterval(fetchData, 60_000);
    return () => clearInterval(id);
  }, [fetchData]);

  return { agents, loading };
}

// ---------------------------------------------------------------------------
// Function: deactivateAgent — calls deactivateAgent on AgentRegistry via MetaMask
// ---------------------------------------------------------------------------
export async function deactivateAgentOnchain(agentId: string): Promise<string> {
  const provider = await getWriteProvider();
  const signer = await provider.getSigner();
  const contract = new Contract(ADDRESSES.AgentRegistry, AGENT_REGISTRY_ABI, signer);
  const tx = await contract.deactivateAgent(agentId);
  await tx.wait();
  return tx.hash as string;
}

// ---------------------------------------------------------------------------
// Hook: useUSDCBalance — polls every 15 s
// ---------------------------------------------------------------------------
export function useUSDCBalance(address: string | null | undefined): {
  balance: number;
  formatted: string;
  loading: boolean;
} {
  const [balance, setBalance] = useState(0);
  const [formatted, setFormatted] = useState("0.00");
  const [loading, setLoading] = useState(true);

  const fetchData = useCallback(async () => {
    if (!address) {
      setBalance(0);
      setFormatted("0.00");
      setLoading(false);
      return;
    }
    try {
      const provider = getReadProvider();
      const contract = new Contract(ADDRESSES.MockUSDC, MOCK_USDC_ABI, provider);
      const raw: bigint = await contract.balanceOf(address);
      // MockUSDC uses 6 decimals
      const num = Number(raw) / 1_000_000;
      setBalance(num);
      setFormatted(
        new Intl.NumberFormat("en-US", { minimumFractionDigits: 2, maximumFractionDigits: 6 }).format(num)
      );
    } catch (err) {
      console.warn("[useUSDCBalance] fetch error:", err);
    } finally {
      setLoading(false);
    }
  }, [address]);

  useEffect(() => {
    fetchData();
    const id = setInterval(fetchData, 15_000);
    return () => clearInterval(id);
  }, [fetchData]);

  return { balance, formatted, loading };
}

// ---------------------------------------------------------------------------
// Hook: useCanClaimFaucet
// ---------------------------------------------------------------------------
export function useCanClaimFaucet(address: string | null | undefined): {
  canClaim: boolean;
  nextClaimAt: Date | null;
  loading: boolean;
} {
  const [canClaim, setCanClaim] = useState(false);
  const [nextClaimAt, setNextClaimAt] = useState<Date | null>(null);
  const [loading, setLoading] = useState(true);

  const fetchData = useCallback(async () => {
    if (!address) {
      setCanClaim(false);
      setNextClaimAt(null);
      setLoading(false);
      return;
    }
    try {
      const provider = getReadProvider();
      const contract = new Contract(ADDRESSES.USDCFaucet, USDC_FAUCET_ABI, provider);
      const nextTs: bigint = await contract.nextClaimTime(address);
      const nextSec = Number(nextTs);
      const nowSec = Math.floor(Date.now() / 1000);
      if (nextSec === 0 || nowSec >= nextSec) {
        setCanClaim(true);
        setNextClaimAt(null);
      } else {
        setCanClaim(false);
        setNextClaimAt(new Date(nextSec * 1000));
      }
    } catch (err) {
      console.warn("[useCanClaimFaucet] fetch error:", err);
      setCanClaim(false);
    } finally {
      setLoading(false);
    }
  }, [address]);

  useEffect(() => {
    fetchData();
    const id = setInterval(fetchData, 15_000);
    return () => clearInterval(id);
  }, [fetchData]);

  return { canClaim, nextClaimAt, loading };
}

// ---------------------------------------------------------------------------
// Function: useClaimFaucet — returns an async function that calls drip()
// ---------------------------------------------------------------------------
export function useClaimFaucet(): {
  claim: () => Promise<string>;
  claiming: boolean;
  error: string | null;
} {
  const [claiming, setClaiming] = useState(false);
  const [error, setError] = useState<string | null>(null);

  const claim = useCallback(async (): Promise<string> => {
    setError(null);
    setClaiming(true);
    try {
      const provider = await getWriteProvider();
      const signer = await provider.getSigner();
      const contract = new Contract(ADDRESSES.USDCFaucet, USDC_FAUCET_ABI, signer);
      const tx = await contract.drip();
      await tx.wait();
      return tx.hash as string;
    } catch (err) {
      const e = err as { reason?: string; message?: string };
      const msg: string = e?.reason ?? e?.message ?? "Claim failed";
      setError(msg);
      throw err;
    } finally {
      setClaiming(false);
    }
  }, []);

  return { claim, claiming, error };
}
