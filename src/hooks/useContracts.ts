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
  // ERC-8004 Trustless Agents — Hedera Testnet (chainId 296)
  ERC8004Identity:    "0x8004A818BFB912233c491871b3d84c89A494BD9e",
  ERC8004Reputation:  "0x8004B663056A597Dffe9eCcC1965A193B7388713",
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

// ERC-8004 IdentityRegistry ABI (UUPS proxy, extends ERC-721)
const ERC8004_IDENTITY_ABI = [
  "function register() external returns (uint256 agentId)",
  "function register(string agentURI) external returns (uint256 agentId)",
  "function register(string agentURI, tuple(string metadataKey, bytes metadataValue)[] metadata) external returns (uint256 agentId)",
  "function setAgentURI(uint256 agentId, string newURI) external",
  "function getMetadata(uint256 agentId, string metadataKey) external view returns (bytes)",
  "function setMetadata(uint256 agentId, string metadataKey, bytes metadataValue) external",
  "function getAgentWallet(uint256 agentId) external view returns (address)",
  "function ownerOf(uint256 tokenId) external view returns (address)",
  "function tokenURI(uint256 tokenId) external view returns (string)",
  "function isAuthorizedOrOwner(address spender, uint256 agentId) external view returns (bool)",
  "function balanceOf(address owner) external view returns (uint256)",
  "event Registered(uint256 indexed agentId, string agentURI, address indexed owner)",
  "event MetadataSet(uint256 indexed agentId, string indexed indexedMetadataKey, string metadataKey, bytes metadataValue)",
];

// ERC-8004 ReputationRegistry ABI
const ERC8004_REPUTATION_ABI = [
  "function giveFeedback(uint256 agentId, int128 value, uint8 valueDecimals, string tag1, string tag2, string endpoint, string feedbackURI, bytes32 feedbackHash) external",
  "function getSummary(uint256 agentId, address[] clientAddresses, string tag1, string tag2) external view returns (uint64 count, int128 summaryValue, uint8 summaryValueDecimals)",
  "function readFeedback(uint256 agentId, address clientAddress, uint64 feedbackIndex) external view returns (int128 value, uint8 valueDecimals, string tag1, string tag2, bool isRevoked)",
  "function getClients(uint256 agentId) external view returns (address[])",
  "function getLastIndex(uint256 agentId, address clientAddress) external view returns (uint64)",
  "event NewFeedback(uint256 indexed agentId, address indexed clientAddress, uint64 feedbackIndex, int128 value, uint8 valueDecimals, string indexed indexedTag1, string tag1, string tag2, string endpoint, string feedbackURI, bytes32 feedbackHash)",
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
// Function: registerAgentERC8004 — registers a new agent via ERC-8004 IdentityRegistry
// The user signs a tx via MetaMask; returns { txHash, erc8004AgentId }
// ---------------------------------------------------------------------------
export async function registerAgentERC8004(
  agentId: string,
  agentName: string,
  role: string
): Promise<{ txHash: string; erc8004AgentId: number | null }> {
  const provider = await getWriteProvider();
  const signer = await provider.getSigner();
  const contract = new Contract(ADDRESSES.ERC8004Identity, ERC8004_IDENTITY_ABI, signer);

  // Build minimal registration URI
  const registrationFile = {
    type: "https://eips.ethereum.org/EIPS/eip-8004#registration-v1",
    name: agentName,
    description: `${agentName} — ${role}. AslanPixel guild agent on Hedera.`,
    image: `https://aslanpixel.vercel.app/assets/npcs/npc-${agentId}-s.png`,
    services: [{ name: "A2A", endpoint: "https://aslanpixel.vercel.app/.well-known/agent-card.json", version: "0.3.0" }],
    x402Support: true,
    active: true,
    supportedTrust: ["reputation"],
  };
  const agentURI = "data:application/json;base64," + btoa(JSON.stringify(registrationFile));

  const encoder = new TextEncoder();
  const toHex = (s: string) => "0x" + Array.from(encoder.encode(s)).map(b => b.toString(16).padStart(2,"0")).join("");

  const metadata = [
    { metadataKey: "agentId",   metadataValue: toHex(agentId) },
    { metadataKey: "agentName", metadataValue: toHex(agentName) },
    { metadataKey: "agentRole", metadataValue: toHex(role) },
  ];

  const tx = await contract["register(string,(string,bytes)[])"](agentURI, metadata);
  const receipt = await tx.wait();

  // Parse Registered event to get agentId (tokenId)
  let erc8004AgentId: number | null = null;
  try {
    const iface = contract.interface;
    for (const log of (receipt.logs ?? [])) {
      try {
        const parsed = iface.parseLog(log);
        if (parsed?.name === "Registered") {
          erc8004AgentId = Number(parsed.args[0]);
          break;
        }
      } catch { /* skip */ }
    }
  } catch { /* best-effort */ }

  return { txHash: tx.hash as string, erc8004AgentId };
}

// ---------------------------------------------------------------------------
// Hook: useERC8004AgentOwner — looks up owner of an ERC-8004 agent NFT by tokenId
// ---------------------------------------------------------------------------
export function useERC8004AgentOwner(tokenId: number | null): {
  owner: string | null;
  loading: boolean;
} {
  const [owner, setOwner] = useState<string | null>(null);
  const [loading, setLoading] = useState(false);

  useEffect(() => {
    if (!tokenId || tokenId <= 0) { setOwner(null); return; }
    setLoading(true);
    const provider = getReadProvider();
    const contract = new Contract(ADDRESSES.ERC8004Identity, ERC8004_IDENTITY_ABI, provider);
    contract.ownerOf(tokenId)
      .then((o: string) => setOwner(o))
      .catch(() => setOwner(null))
      .finally(() => setLoading(false));
  }, [tokenId]);

  return { owner, loading };
}

// ---------------------------------------------------------------------------
// Hook: useERC8004Balance — how many agent NFTs does an address own
// ---------------------------------------------------------------------------
export function useERC8004Balance(address: string | null | undefined): number {
  const [count, setCount] = useState(0);

  useEffect(() => {
    if (!address) { setCount(0); return; }
    const provider = getReadProvider();
    const contract = new Contract(ADDRESSES.ERC8004Identity, ERC8004_IDENTITY_ABI, provider);
    contract.balanceOf(address)
      .then((n: bigint) => setCount(Number(n)))
      .catch(() => setCount(0));
  }, [address]);

  return count;
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
