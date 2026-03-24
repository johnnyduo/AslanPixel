/**
 * Vercel API Route: POST /api/agent-register
 * Node.js runtime — registers agents via ERC-8004 IdentityRegistry on Hedera testnet
 * + records reputation via ERC-8004 ReputationRegistry
 * + posts HCS messages for every event
 *
 * ERC-8004 deployed on Hedera Testnet (chainId 296):
 *   IdentityRegistry:  0x8004A818BFB912233c491871b3d84c89A494BD9e
 *   ReputationRegistry:0x8004B663056A597Dffe9eCcC1965A193B7388713
 *
 * Returns: { topicId, registeredAgents, txHashes, agentIds, hcsSeq }
 */

import { JsonRpcProvider, Wallet, Contract, toUtf8Bytes, hexlify } from "ethers";
import {
  Client,
  PrivateKey,
  TopicCreateTransaction,
  TopicMessageSubmitTransaction,
  AccountId,
} from "@hashgraph/sdk";

const RPC_URL = "https://testnet.hashio.io/api";

// ERC-8004 contracts on Hedera Testnet (chainId 296)
const ERC8004_IDENTITY_REGISTRY   = "0x8004A818BFB912233c491871b3d84c89A494BD9e";
const ERC8004_REPUTATION_REGISTRY = "0x8004B663056A597Dffe9eCcC1965A193B7388713";

// Legacy AgentRegistry — kept for reputation read-back compatibility
const AGENT_REGISTRY_ADDRESS = "0x8B90AA6D1A12111C8F08C8B9Af4cca9f90336CC4";

// ERC-8004 IdentityRegistry ABI (UUPS proxy, extends ERC-721)
const IDENTITY_REGISTRY_ABI = [
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
  "event Registered(uint256 indexed agentId, string agentURI, address indexed owner)",
  "event MetadataSet(uint256 indexed agentId, string indexed indexedMetadataKey, string metadataKey, bytes metadataValue)",
];

// ERC-8004 ReputationRegistry ABI
const REPUTATION_REGISTRY_ABI = [
  "function giveFeedback(uint256 agentId, int128 value, uint8 valueDecimals, string tag1, string tag2, string endpoint, string feedbackURI, bytes32 feedbackHash) external",
  "function revokeFeedback(uint256 agentId, uint64 feedbackIndex) external",
  "function getSummary(uint256 agentId, address[] clientAddresses, string tag1, string tag2) external view returns (uint64 count, int128 summaryValue, uint8 summaryValueDecimals)",
  "function readFeedback(uint256 agentId, address clientAddress, uint64 feedbackIndex) external view returns (int128 value, uint8 valueDecimals, string tag1, string tag2, bool isRevoked)",
  "function getClients(uint256 agentId) external view returns (address[])",
  "function getLastIndex(uint256 agentId, address clientAddress) external view returns (uint64)",
  "event NewFeedback(uint256 indexed agentId, address indexed clientAddress, uint64 feedbackIndex, int128 value, uint8 valueDecimals, string indexed indexedTag1, string tag1, string tag2, string endpoint, string feedbackURI, bytes32 feedbackHash)",
];

// Legacy registry — for backwards compat read
const AGENT_REGISTRY_ABI = [
  "function registerAgent(string agentId, string name, string role, address wallet) nonpayable",
  "function recordQuestResult(string agentId, uint256 questId, bool success) nonpayable",
  "function getAgent(string agentId) view returns (tuple(string agentId, string name, uint256 reputation, uint256 completedQuests, uint256 successCount, uint256 registeredAt, bool active))",
  "function getAgentCount() view returns (uint256)",
];

// The 6 canonical guild agents
const AGENTS = [
  { id: "scout",      name: "Nexus", role: "HCS Intelligence",  symbol: "◈" },
  { id: "strategist", name: "Oryn",  role: "Strategy Engine",   symbol: "▲" },
  { id: "sentinel",   name: "Drax",  role: "Risk Sentinel",     symbol: "◆" },
  { id: "treasurer",  name: "Lyss",  role: "Treasury Keeper",   symbol: "◉" },
  { id: "executor",   name: "Vex",   role: "TX Executor",       symbol: "▶" },
  { id: "archivist",  name: "Kael",  role: "Ledger Archivist",  symbol: "▣" },
];

// Module-level cache
let _topicId = null;

// ---------------------------------------------------------------------------
// Hedera client helpers
// ---------------------------------------------------------------------------
function getHederaClient() {
  const accountId = process.env.HEDERA_ACCOUNT_ID;
  const privateKey = process.env.HEDERA_PRIVATE_KEY || process.env.DEPLOY_PRIVATE_KEY;
  if (!accountId || !privateKey) return null;
  try {
    const client = Client.forTestnet();
    const pk = privateKey.startsWith("0x") ? privateKey.slice(2) : privateKey;
    client.setOperator(AccountId.fromString(accountId), PrivateKey.fromStringECDSA(pk));
    return client;
  } catch {
    return null;
  }
}

async function ensureHCSTopic(client) {
  if (_topicId) return _topicId;
  if (process.env.HEDERA_HCS_TOPIC_ID) {
    _topicId = process.env.HEDERA_HCS_TOPIC_ID;
    return _topicId;
  }
  try {
    const tx = await new TopicCreateTransaction()
      .setTopicMemo("Aslan Pixel Agent Activity — ERC-8004 v1.0")
      .execute(client);
    const receipt = await tx.getReceipt(client);
    _topicId = receipt.topicId.toString();
    return _topicId;
  } catch {
    return null;
  }
}

async function postHCSMessage(client, topicId, payload) {
  if (!client || !topicId) return null;
  try {
    const tx = await new TopicMessageSubmitTransaction()
      .setTopicId(topicId)
      .setMessage(JSON.stringify(payload))
      .execute(client);
    const receipt = await tx.getReceipt(client);
    return receipt.topicSequenceNumber?.toString() ?? null;
  } catch {
    return null;
  }
}

// ---------------------------------------------------------------------------
// ERC-8004 agent registration file (JSON stored in agentURI metadata)
// Conforms to https://eips.ethereum.org/EIPS/eip-8004#registration-v1
// ---------------------------------------------------------------------------
function buildAgentRegistrationURI(agent) {
  const registrationFile = {
    type: "https://eips.ethereum.org/EIPS/eip-8004#registration-v1",
    name: agent.name,
    description: `${agent.symbol} ${agent.name} — ${agent.role}. AslanPixel guild agent on Hedera.`,
    image: `https://aslanpixel.vercel.app/assets/npcs/npc-${agent.id}-s.png`,
    services: [
      {
        name: "A2A",
        endpoint: "https://aslanpixel.vercel.app/.well-known/agent-card.json",
        version: "0.3.0",
      },
    ],
    x402Support: true,
    active: true,
    supportedTrust: ["reputation"],
    chainId: 296,
    hedera: {
      hcsTopicId: process.env.HEDERA_HCS_TOPIC_ID || "0.0.5178025",
      accountId: process.env.HEDERA_ACCOUNT_ID || "0.0.5769159",
    },
  };
  // Encode as data URI (no IPFS needed for testnet/hackathon)
  return "data:application/json;base64," + Buffer.from(JSON.stringify(registrationFile)).toString("base64");
}

// ---------------------------------------------------------------------------
// ERC-8004 register agent
// ---------------------------------------------------------------------------
async function erc8004RegisterAgents(wallet, customAgentId, customName, customTrait) {
  const identityRegistry = new Contract(ERC8004_IDENTITY_REGISTRY, IDENTITY_REGISTRY_ABI, wallet);
  // Also register in legacy AgentRegistry for reputation read-back
  const legacyRegistry = new Contract(AGENT_REGISTRY_ADDRESS, AGENT_REGISTRY_ABI, wallet);

  const registered = [];
  const skipped = [];
  const txHashes = {};
  const erc8004AgentIds = {}; // agentId string => ERC-8004 tokenId (uint256)

  const agentsToRegister = customAgentId
    ? [{ id: customAgentId, name: customName || customAgentId, role: customTrait || "Custom Agent", symbol: "✦" }]
    : AGENTS;

  for (const agent of agentsToRegister) {
    try {
      // Build ERC-8004 registration URI
      const agentURI = buildAgentRegistrationURI(agent);

      // Encode agentId as metadata key "agentId" -> bytes
      const metadata = [
        { metadataKey: "agentId",   metadataValue: hexlify(toUtf8Bytes(agent.id)) },
        { metadataKey: "agentName", metadataValue: hexlify(toUtf8Bytes(agent.name)) },
        { metadataKey: "agentRole", metadataValue: hexlify(toUtf8Bytes(agent.role)) },
      ];

      // Call ERC-8004 register(string, MetadataEntry[])
      const tx = await identityRegistry["register(string,(string,bytes)[])"](agentURI, metadata);
      const receipt = await tx.wait();

      // Extract agentId (tokenId) from Registered event
      let erc8004Id = null;
      try {
        const iface = identityRegistry.interface;
        for (const log of receipt.logs ?? []) {
          try {
            const parsed = iface.parseLog(log);
            if (parsed?.name === "Registered") {
              erc8004Id = Number(parsed.args[0]);
              break;
            }
          } catch { /* skip */ }
        }
      } catch { /* best effort */ }

      registered.push(agent.id);
      txHashes[agent.id] = receipt?.hash ?? tx.hash;
      if (erc8004Id !== null) erc8004AgentIds[agent.id] = erc8004Id;

      // Also register in legacy registry (best-effort, may already exist)
      try {
        const legacyTx = await legacyRegistry.registerAgent(agent.id, agent.name, agent.role, wallet.address);
        await legacyTx.wait();
      } catch { /* agent may already exist in legacy registry — ignore */ }

    } catch (err) {
      // If already registered (token exists), treat as skipped not error
      const msg = err?.message ?? "";
      if (msg.includes("exists") || msg.includes("already") || msg.includes("ERC721")) {
        skipped.push(agent.id);
      } else {
        skipped.push(agent.id);
        console.warn(`[agent-register] ERC-8004 registration failed for ${agent.id}:`, msg.slice(0, 120));
      }
    }
  }

  return { registered, skipped, txHashes, erc8004AgentIds };
}

// ---------------------------------------------------------------------------
// ERC-8004 reputation feedback — called after quest completion
// ---------------------------------------------------------------------------
async function erc8004RecordQuestResults(wallet, questId, success) {
  const repRegistry = new Contract(ERC8004_REPUTATION_REGISTRY, REPUTATION_REGISTRY_ABI, wallet);
  const identityRegistry = new Contract(ERC8004_IDENTITY_REGISTRY, IDENTITY_REGISTRY_ABI, wallet);

  // score: 80 success (value=8000, decimals=2) | 30 failure (value=3000, decimals=2)
  const score = success ? 8000 : 3000;
  const tag1 = success ? "successRate" : "successRate";
  const tag2 = success ? "success" : "failed";

  let successCount = 0;
  await Promise.allSettled(
    AGENTS.map(async (agent) => {
      try {
        // Get the ERC-8004 tokenId for this agent by reading agentId metadata
        // We brute-force token IDs 1-6 for canonical agents (minted in order at deploy)
        // In production this would be indexed
        const agentIndex = AGENTS.findIndex(a => a.id === agent.id);
        const tokenId = agentIndex + 1; // tokenIds 1-6 for canonical agents

        const feedbackHash = "0x" + Buffer.from(`quest-${questId}-${agent.id}`).toString("hex").padEnd(64, "0").slice(0, 64);
        const tx = await repRegistry.giveFeedback(
          tokenId,
          score,
          2, // valueDecimals
          tag1,
          tag2,
          "https://aslanpixel.vercel.app/api/quest",
          "", // feedbackURI
          feedbackHash,
        );
        await tx.wait();
        successCount++;
      } catch { /* non-blocking */ }
    })
  );

  // Also update legacy registry
  try {
    const legacyRegistry = new Contract(AGENT_REGISTRY_ADDRESS, AGENT_REGISTRY_ABI, wallet);
    await Promise.allSettled(
      AGENTS.map((agent) =>
        legacyRegistry.recordQuestResult(agent.id, questId, success).then((tx) => tx.wait())
      )
    );
  } catch { /* best-effort */ }

  return successCount;
}

// ---------------------------------------------------------------------------
// Main run
// ---------------------------------------------------------------------------
async function run(mode, questId, success, customAgentId, customName, customTrait) {
  const pk = process.env.HEDERA_PRIVATE_KEY || process.env.DEPLOY_PRIVATE_KEY;
  if (!pk) throw new Error("HEDERA_PRIVATE_KEY not configured");

  const provider = new JsonRpcProvider(RPC_URL);
  const wallet = new Wallet(pk.startsWith("0x") ? pk : "0x" + pk, provider);
  const hederaClient = getHederaClient();
  const topicId = hederaClient
    ? await ensureHCSTopic(hederaClient)
    : (process.env.HEDERA_HCS_TOPIC_ID ?? null);

  if (mode === "record" && questId != null) {
    const count = await erc8004RecordQuestResults(wallet, questId, success ?? true);

    const seqNum = await postHCSMessage(hederaClient, topicId, {
      event: "quest_complete",
      questId,
      success: success ?? true,
      agents: AGENTS.map((a) => a.id),
      timestamp: new Date().toISOString(),
      protocol: "erc-8004",
    });

    return { recorded: count, topicId, hcsSeq: seqNum };
  }

  // Default: register agents
  const { registered, skipped, txHashes, erc8004AgentIds } =
    await erc8004RegisterAgents(wallet, customAgentId, customName, customTrait);

  const seqNum = await postHCSMessage(hederaClient, topicId, {
    event: "agents_registered",
    registered,
    skipped,
    txHashes,
    erc8004AgentIds,
    timestamp: new Date().toISOString(),
    project: "Aslan Pixel",
    protocol: "erc-8004",
    identityRegistry: ERC8004_IDENTITY_REGISTRY,
    reputationRegistry: ERC8004_REPUTATION_REGISTRY,
  });

  return {
    topicId,
    registeredAgents: registered,
    skippedAgents: skipped,
    txHashes,
    erc8004AgentIds,
    hcsSeq: seqNum,
    identityRegistry: ERC8004_IDENTITY_REGISTRY,
    reputationRegistry: ERC8004_REPUTATION_REGISTRY,
  };
}

export default async function handler(req, res) {
  // Web API Request style (dev server / Edge)
  if (req instanceof Request || typeof req.json === "function") {
    try {
      const body = await req.json().catch(() => ({}));
      const result = await run(body.mode, body.questId, body.success, body.agentId, body.name, body.trait);
      return new Response(JSON.stringify(result), {
        status: 200,
        headers: { "Content-Type": "application/json" },
      });
    } catch (err) {
      console.error("[agent-register]", err.message);
      return new Response(JSON.stringify({ error: err.message }), { status: 500 });
    }
  }

  // Express/Vercel Node.js style
  if (req.method && req.method !== "POST") {
    return res.status(405).json({ error: "Method not allowed" });
  }
  try {
    const body = req.body ?? {};
    const result = await run(body.mode, body.questId, body.success, body.agentId, body.name, body.trait);
    return res.status(200).json(result);
  } catch (err) {
    console.error("[agent-register]", err.message);
    return res.status(500).json({ error: err.message });
  }
}
