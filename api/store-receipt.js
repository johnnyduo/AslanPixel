/**
 * Vercel API Route: POST /api/store-receipt
 * Node.js runtime (NOT edge) — uses ethers + HEDERA_PRIVATE_KEY to write onchain.
 *
 * Body: { intent: string, success: boolean, questId: number }
 * Returns: { receiptId: number, txHash: string }
 */

// Node.js runtime — ethers secp256k1 signing works here
import { JsonRpcProvider, Wallet, Contract } from "ethers";
import { readFileSync } from "fs";
import { join } from "path";

const RPC_URL = "https://testnet.hashio.io/api";
const QUEST_RECEIPT_ADDRESS = "0x444f5895D29809847E8642Df0e0f4DBdBf541C7D";

// Load ABI from compiled artifact
function loadAbi() {
  try {
    const artifactPath = join(process.cwd(), "artifacts/contracts/QuestReceipt.sol/QuestReceipt.json");
    const artifact = JSON.parse(readFileSync(artifactPath, "utf8"));
    return artifact.abi;
  } catch {
    // Fallback minimal ABI if artifact not present at runtime
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

export default async function handler(req, res) {
  if (req.method !== "POST") {
    return res.status(405).json({ error: "Method not allowed" });
  }

  const { intent, success = true, questId } = req.body ?? {};

  if (!intent) {
    return res.status(400).json({ error: "intent is required" });
  }

  const pk = process.env.HEDERA_PRIVATE_KEY || process.env.DEPLOY_PRIVATE_KEY;
  if (!pk) {
    return res.status(500).json({ error: "HEDERA_PRIVATE_KEY not configured" });
  }

  try {
    const provider = new JsonRpcProvider(RPC_URL);
    const wallet = new Wallet(pk.startsWith("0x") ? pk : "0x" + pk, provider);
    const abi = loadAbi();
    const contract = new Contract(QUEST_RECEIPT_ADDRESS, abi, wallet);

    const inputHash  = await sha256Hex(intent);
    const outputHash = await sha256Hex(intent + (questId ?? Date.now()));
    // txHash placeholder — represents this store-receipt call itself
    const txHashBytes = "0x" + "00".repeat(32);

    const tx = await contract.storeReceipt(
      inputHash,
      outputHash,
      txHashBytes,
      intent,
      Boolean(success)
    );

    const receipt = await tx.wait();

    // The storeReceipt function returns the new questId (receiptId)
    // Parse it from the transaction receipt logs or use questCount fallback
    let receiptId = questId;
    try {
      // Decode return value via a static call before sending was not possible,
      // so we read questCount (which is incremented after store)
      const count = await contract.questCount();
      receiptId = Number(count);
    } catch {
      receiptId = questId ?? Date.now();
    }

    return res.status(200).json({
      receiptId,
      txHash: receipt.hash ?? tx.hash,
    });
  } catch (err) {
    console.error("[store-receipt] onchain write failed:", err);
    return res.status(500).json({
      error: err?.reason ?? err?.message ?? "Onchain write failed",
    });
  }
}
