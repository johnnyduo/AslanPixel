/**
 * Vercel API Route: POST /api/store-receipt
 * Node.js runtime (NOT edge) — uses ethers + HEDERA_PRIVATE_KEY to write onchain.
 *
 * Body: { intent: string, success: boolean, questId: number }
 * Returns: { receiptId: number, txHash: string }
 */

import { JsonRpcProvider, Wallet, Contract } from "ethers";
import { readFileSync } from "fs";
import { join } from "path";
import {
  Client,
  PrivateKey,
  TopicMessageSubmitTransaction,
  AccountId,
} from "@hashgraph/sdk";

const RPC_URL = "https://testnet.hashio.io/api";
const QUEST_RECEIPT_ADDRESS = "0x444f5895D29809847E8642Df0e0f4DBdBf541C7D";

function loadAbi() {
  try {
    const artifactPath = join(process.cwd(), "artifacts/contracts/QuestReceipt.sol/QuestReceipt.json");
    const artifact = JSON.parse(readFileSync(artifactPath, "utf8"));
    return artifact.abi;
  } catch {
    return [
      "function storeReceipt(bytes32 inputHash, bytes32 outputHash, bytes32 txHash, string intent, bool success) returns (uint256 questId)",
      "function questCount() view returns (uint256)",
    ];
  }
}

async function sha256Hex(str) {
  const { createHash } = await import("crypto");
  return "0x" + createHash("sha256").update(str).digest("hex");
}

async function run(intent, success, questId) {
  const pk = process.env.HEDERA_PRIVATE_KEY || process.env.DEPLOY_PRIVATE_KEY;
  if (!pk) throw new Error("HEDERA_PRIVATE_KEY not configured");

  const provider = new JsonRpcProvider(RPC_URL);
  const wallet = new Wallet(pk.startsWith("0x") ? pk : "0x" + pk, provider);
  const abi = loadAbi();
  const contract = new Contract(QUEST_RECEIPT_ADDRESS, abi, wallet);

  const inputHash  = await sha256Hex(intent);
  const outputHash = await sha256Hex(intent + (questId ?? Date.now()));
  const txHashBytes = "0x" + "00".repeat(32);

  const tx = await contract.storeReceipt(inputHash, outputHash, txHashBytes, intent, Boolean(success));
  const receipt = await tx.wait();

  let receiptId = questId;
  try {
    const count = await contract.questCount();
    receiptId = Number(count);
  } catch {
    receiptId = questId ?? Date.now();
  }

  const txHash = receipt.hash ?? tx.hash;

  // Post HCS message and record quest results (fire-and-forget — don't block response)
  setImmediate(async () => {
    try {
      const accountId = process.env.HEDERA_ACCOUNT_ID;
      const topicId = process.env.HEDERA_HCS_TOPIC_ID;
      if (accountId && topicId) {
        const pk = process.env.HEDERA_PRIVATE_KEY || process.env.DEPLOY_PRIVATE_KEY;
        const hederaClient = Client.forTestnet();
        const hPk = pk.startsWith("0x") ? pk.slice(2) : pk;
        hederaClient.setOperator(AccountId.fromString(accountId), PrivateKey.fromStringECDSA(hPk));
        await new TopicMessageSubmitTransaction()
          .setTopicId(topicId)
          .setMessage(JSON.stringify({ event: "quest_receipt", receiptId, txHash, intent, success, ts: new Date().toISOString() }))
          .execute(hederaClient);
      }
    } catch { /* non-blocking */ }

    // Record quest results for all agents in AgentRegistry
    try {
      const agentRegistryAddr = "0x8B90AA6D1A12111C8F08C8B9Af4cca9f90336CC4";
      const agentRegistryAbi = ["function recordQuestResult(string agentId, uint256 questId, bool success) nonpayable"];
      const reg = new Contract(agentRegistryAddr, agentRegistryAbi, wallet);
      const agentIds = ["scout", "strategist", "sentinel", "treasurer", "executor", "archivist"];
      await Promise.allSettled(agentIds.map((id) => reg.recordQuestResult(id, receiptId, Boolean(success)).then((tx) => tx.wait())));
    } catch { /* non-blocking */ }
  });

  return { receiptId, txHash };
}

// Vercel/Next.js style handler (req has .body, res has .status().json())
export default async function handler(req, res) {
  // Web API Request (edge-style from dev server)
  if (req instanceof Request || typeof req.json === "function") {
    try {
      const body = await req.json().catch(() => ({}));
      const { intent, success = true, questId } = body;
      if (!intent) return new Response(JSON.stringify({ error: "intent required" }), { status: 400 });
      const result = await run(intent, success, questId);
      return new Response(JSON.stringify(result), {
        status: 200,
        headers: { "Content-Type": "application/json" },
      });
    } catch (err) {
      console.error("[store-receipt]", err.message);
      return new Response(JSON.stringify({ error: err.message }), { status: 500 });
    }
  }

  // Express/Vercel Node.js style (req.body, res.json)
  if (req.method && req.method !== "POST") {
    return res.status(405).json({ error: "Method not allowed" });
  }
  const { intent, success = true, questId } = req.body ?? {};
  if (!intent) return res.status(400).json({ error: "intent required" });
  try {
    const result = await run(intent, success, questId);
    return res.status(200).json(result);
  } catch (err) {
    console.error("[store-receipt]", err.message);
    return res.status(500).json({ error: err?.reason ?? err?.message ?? "Onchain write failed" });
  }
}
