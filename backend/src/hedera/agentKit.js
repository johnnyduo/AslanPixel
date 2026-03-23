/**
 * Hedera Agent Kit integration
 * @hashgraph/hedera-agent-kit — official Hedera AI agent toolkit
 * Enables: HBAR transfer, HTS token ops, HCS messaging, smart contract calls
 *
 * Docs: https://github.com/hashgraph/hedera-agent-kit
 */
import { HederaAgentKit } from "@hashgraph/hedera-agent-kit";

let kit = null;

export function getAgentKit() {
  if (kit) return kit;

  if (!process.env.HEDERA_ACCOUNT_ID || !process.env.HEDERA_PRIVATE_KEY) {
    console.warn("[AgentKit] HEDERA_ACCOUNT_ID or HEDERA_PRIVATE_KEY not set — using mock mode");
    return null;
  }

  kit = new HederaAgentKit(
    process.env.HEDERA_ACCOUNT_ID,
    process.env.HEDERA_PRIVATE_KEY,
    process.env.HEDERA_NETWORK ?? "testnet"
  );

  return kit;
}

/**
 * Transfer HBAR between accounts
 */
export async function transferHBAR(toAccountId, amountHbar) {
  const k = getAgentKit();
  if (!k) return { mock: true, txId: `0.0.MOCK@${Date.now()}`, amount: amountHbar };

  const result = await k.transferHbar(toAccountId, amountHbar);
  return { txId: result.transactionId, amount: amountHbar, status: result.status };
}

/**
 * Submit message to HCS topic (used by Kael for audit trail)
 */
export async function submitHCSViaKit(topicId, message) {
  const k = getAgentKit();
  if (!k) return { mock: true, sequenceNumber: Math.floor(Math.random() * 50000) };

  const result = await k.submitMessageToTopic(topicId, message);
  return { sequenceNumber: result.sequenceNumber, topicId };
}

/**
 * Create HTS token (used by Token Forge operations)
 */
export async function createHTSToken({ name, symbol, decimals = 2, initialSupply = 1000000 }) {
  const k = getAgentKit();
  if (!k) return { mock: true, tokenId: `0.0.${Math.floor(Math.random() * 900000 + 100000)}` };

  const result = await k.createToken({ name, symbol, decimals, initialSupply });
  return { tokenId: result.tokenId };
}

/**
 * Get account balance via Agent Kit
 */
export async function getBalance(accountId) {
  const k = getAgentKit();
  if (!k) return { hbar: 12847.5, mock: true };

  const balance = await k.getAccountBalance(accountId);
  return { hbar: balance.hbars.toBigNumber().toNumber(), tokens: balance.tokens };
}

/**
 * Call EVM smart contract (QuestReceipt.sol, PolicyManager.sol)
 */
export async function callContract(contractId, functionName, params = []) {
  const k = getAgentKit();
  if (!k) return { mock: true, result: "0x" + Math.random().toString(16).slice(2, 18) };

  const result = await k.callContractFunction(contractId, functionName, params);
  return { result: result.bytes, txId: result.transactionId };
}
