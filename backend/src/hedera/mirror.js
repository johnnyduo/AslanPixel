/**
 * Hedera Mirror Node API client
 * Testnet: https://testnet.mirrornode.hedera.com
 */

const MIRROR_BASE = "https://testnet.mirrornode.hedera.com";

export async function queryMirrorNode(path) {
  const res = await fetch(`${MIRROR_BASE}${path}`, {
    headers: { "Accept": "application/json" },
  });
  if (!res.ok) throw new Error(`Mirror Node ${res.status}: ${path}`);
  return res.json();
}

export async function getHbarPrice() {
  try {
    const data = await queryMirrorNode("/api/v1/network/exchangerate");
    // Returns cents per HBAR
    const usd = data.current_rate?.cent_equivalent / data.current_rate?.hbar_equivalent / 100;
    return usd?.toFixed(4) ?? "0.0641";
  } catch {
    return "0.0641";
  }
}

export async function getAccountBalance(accountId) {
  const data = await queryMirrorNode(`/api/v1/accounts/${accountId}`);
  return {
    hbar: data.balance?.balance / 1e8,
    tinyhbar: data.balance?.balance,
    tokens: data.balance?.tokens ?? [],
  };
}

export async function getLatestHCSMessages(topicId = "0.0.1234") {
  try {
    const data = await queryMirrorNode(
      `/api/v1/topics/${topicId}/messages?limit=5&order=desc`
    );
    return data.messages ?? [];
  } catch {
    return [];
  }
}

export async function getLatestTransactions(accountId) {
  try {
    const data = await queryMirrorNode(
      `/api/v1/transactions?account.id=${accountId}&limit=10&order=desc`
    );
    return data.transactions ?? [];
  } catch {
    return [];
  }
}

export async function getTokenInfo(tokenId) {
  return queryMirrorNode(`/api/v1/tokens/${tokenId}`);
}
