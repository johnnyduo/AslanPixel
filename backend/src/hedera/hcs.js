/**
 * Hedera Consensus Service (HCS) — direct SDK integration
 * Used by Kael (Archivist) to post immutable audit trail
 */
import { Client, TopicMessageSubmitTransaction, PrivateKey } from "@hashgraph/sdk";

let client = null;

function getClient() {
  if (client) return client;

  const accountId = process.env.HEDERA_ACCOUNT_ID;
  const privateKey = process.env.HEDERA_PRIVATE_KEY;

  if (!accountId || !privateKey) {
    console.warn("[HCS] credentials not set — HCS submissions will be mocked");
    return null;
  }

  client = Client.forTestnet();
  client.setOperator(accountId, PrivateKey.fromStringED25519(privateKey));
  return client;
}

// Default audit topic — create this on testnet first
const AUDIT_TOPIC_ID = process.env.HCS_AUDIT_TOPIC_ID ?? "0.0.5178025";

export async function submitHCSMessage(message, topicId = AUDIT_TOPIC_ID) {
  const c = getClient();

  if (!c) {
    // Mock response
    return {
      mock: true,
      topicId,
      sequenceNumber: Math.floor(Math.random() * 50000 + 10000),
      consensusTimestamp: new Date().toISOString(),
    };
  }

  const tx = new TopicMessageSubmitTransaction()
    .setTopicId(topicId)
    .setMessage(typeof message === "string" ? message : JSON.stringify(message));

  const receipt = await (await tx.execute(c)).getReceipt(c);

  return {
    topicId,
    sequenceNumber: receipt.topicSequenceNumber?.toNumber(),
    consensusTimestamp: new Date().toISOString(),
    status: receipt.status?.toString(),
  };
}
