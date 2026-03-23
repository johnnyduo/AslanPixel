/**
 * Vercel API Route: POST /api/agent-register
 * Node.js runtime — registers 6 agents in AgentRegistry.sol + posts HCS messages
 * Also records quest results when called with { questId, success }
 *
 * Returns: { topicId, registeredAgents, hcsMessageId }
 */

import { JsonRpcProvider, Wallet, Contract } from "ethers";
import {
  Client,
  PrivateKey,
  TopicCreateTransaction,
  TopicMessageSubmitTransaction,
  AccountId,
} from "@hashgraph/sdk";

const RPC_URL = "https://testnet.hashio.io/api";
const AGENT_REGISTRY_ADDRESS = "0x8B90AA6D1A12111C8F08C8B9Af4cca9f90336CC4";

const AGENT_REGISTRY_ABI = [
  "function registerAgent(string agentId, string name, string role, address wallet) nonpayable",
  "function recordQuestResult(string agentId, uint256 questId, bool success) nonpayable",
  "function getAgent(string agentId) view returns (tuple(string agentId, string name, uint256 reputation, uint256 completedQuests, uint256 successCount, uint256 registeredAt, bool active))",
  "function getAgentCount() view returns (uint256)",
];

const AGENTS = [
  { id: "scout",      name: "Nexus", role: "HCS Intelligence" },
  { id: "strategist", name: "Oryn",  role: "Strategy Engine" },
  { id: "sentinel",   name: "Drax",  role: "Risk Sentinel" },
  { id: "treasurer",  name: "Lyss",  role: "Treasury Keeper" },
  { id: "executor",   name: "Vex",   role: "TX Executor" },
  { id: "archivist",  name: "Kael",  role: "Ledger Archivist" },
];

// Module-level cache — persists within same Vercel warm instance
let _topicId = null;

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
  // Use cached or env-provided topic ID
  if (_topicId) return _topicId;
  if (process.env.HEDERA_HCS_TOPIC_ID) {
    _topicId = process.env.HEDERA_HCS_TOPIC_ID;
    return _topicId;
  }
  // Create a new topic
  try {
    const tx = await new TopicCreateTransaction()
      .setTopicMemo("AslanGuild Agent Activity — v1.0")
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

async function registerAgents(wallet) {
  const contract = new Contract(AGENT_REGISTRY_ADDRESS, AGENT_REGISTRY_ABI, wallet);
  const registered = [];
  const skipped = [];

  for (const agent of AGENTS) {
    try {
      const tx = await contract.registerAgent(agent.id, agent.name, agent.role, wallet.address);
      await tx.wait();
      registered.push(agent.id);
    } catch (err) {
      // "exists" revert is expected — agent already registered
      const msg = err?.reason ?? err?.message ?? "";
      if (msg.includes("exists") || msg.includes("execution reverted")) {
        skipped.push(agent.id);
      } else {
        skipped.push(agent.id);
      }
    }
  }
  return { registered, skipped };
}

async function recordAllQuestResults(wallet, questId, success) {
  const contract = new Contract(AGENT_REGISTRY_ADDRESS, AGENT_REGISTRY_ABI, wallet);
  const results = await Promise.allSettled(
    AGENTS.map((agent) =>
      contract.recordQuestResult(agent.id, questId, success).then((tx) => tx.wait())
    )
  );
  return results.filter((r) => r.status === "fulfilled").length;
}

async function run(mode, questId, success) {
  const pk = process.env.HEDERA_PRIVATE_KEY || process.env.DEPLOY_PRIVATE_KEY;
  if (!pk) throw new Error("HEDERA_PRIVATE_KEY not configured");

  const provider = new JsonRpcProvider(RPC_URL);
  const wallet = new Wallet(pk.startsWith("0x") ? pk : "0x" + pk, provider);
  const hederaClient = getHederaClient();
  const topicId = hederaClient ? await ensureHCSTopic(hederaClient) : (process.env.HEDERA_HCS_TOPIC_ID ?? null);

  if (mode === "record" && questId != null) {
    // Record quest results for all agents
    const count = await recordAllQuestResults(wallet, questId, success ?? true);

    // Post HCS message
    const seqNum = await postHCSMessage(hederaClient, topicId, {
      event: "quest_complete",
      questId,
      success: success ?? true,
      agents: AGENTS.map((a) => a.id),
      timestamp: new Date().toISOString(),
    });

    return { recorded: count, topicId, hcsSeq: seqNum };
  }

  // Default: register agents
  const { registered, skipped } = await registerAgents(wallet);

  // Post HCS message for registration
  const seqNum = await postHCSMessage(hederaClient, topicId, {
    event: "agents_registered",
    registered,
    skipped,
    timestamp: new Date().toISOString(),
    guild: "AslanGuild",
  });

  return { topicId, registeredAgents: registered, skippedAgents: skipped, hcsSeq: seqNum };
}

export default async function handler(req, res) {
  // Web API Request style (dev server)
  if (req instanceof Request || typeof req.json === "function") {
    try {
      const body = await req.json().catch(() => ({}));
      const result = await run(body.mode, body.questId, body.success);
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
    const result = await run(body.mode, body.questId, body.success);
    return res.status(200).json(result);
  } catch (err) {
    console.error("[agent-register]", err.message);
    return res.status(500).json({ error: err.message });
  }
}
