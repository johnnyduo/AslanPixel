/**
 * syncPortfolio
 *
 * Callable. Client calls to refresh broker portfolio data.
 * Broker credentials are NEVER stored client-side.
 * Credentials stored encrypted in: brokerConnections/{uid} (private collection)
 *
 * Flow:
 *   1. Read broker connection from Firestore (server-only collection)
 *   2. Fetch portfolio from broker API
 *   3. Cache snapshot in users/{uid}/portfolio/latest
 *   4. Return snapshot to client
 *
 * Security:
 *   - brokerConnections collection: no client read/write in Firestore rules
 *   - Only Cloud Functions can access it
 */

import { onCall, HttpsError } from "firebase-functions/v2/https";
import { FieldValue } from "firebase-admin/firestore";
import { db } from "./admin";
import axios from "axios";
import { logger } from "firebase-functions";

interface PortfolioPosition {
  symbol: string;
  qty: number;
  avgCost: number;
  currentPrice: number;
  unrealizedPnl: number;
}

interface PortfolioSnapshot {
  totalValue: number;
  dailyPnl: number;
  dailyPnlPercent: number;
  positions: PortfolioPosition[];
  snapshotAt: string;
  connectorId: string;
}

export const syncPortfolio = onCall(
  {
    region: "asia-southeast1",
    memory: "256MiB",
    timeoutSeconds: 30,
  },
  async (request): Promise<PortfolioSnapshot> => {
    const uid = request.auth?.uid;
    if (!uid) throw new HttpsError("unauthenticated", "Must be authenticated");

    // Read broker connection (server-only)
    const connRef = db.collection("brokerConnections").doc(uid);
    const connSnap = await connRef.get();

    if (!connSnap.exists) {
      throw new HttpsError("not-found", "No broker connected");
    }

    const conn = connSnap.data()!;
    const { connectorId, encryptedToken, apiBaseUrl } = conn;

    if (!connectorId || !encryptedToken || !apiBaseUrl) {
      throw new HttpsError("failed-precondition", "Broker connection incomplete");
    }

    // Demo connector bypass (for testing)
    if (connectorId === "demo") {
      return _generateDemoPortfolio(uid);
    }

    // Real broker fetch (decrypt token server-side)
    const token = await _decryptToken(encryptedToken);
    let snapshot: PortfolioSnapshot;

    try {
      const response = await axios.get(`${apiBaseUrl}/portfolio`, {
        headers: { Authorization: `Bearer ${token}` },
        timeout: 20000,
      });

      snapshot = _normalizePortfolio(response.data, connectorId);
    } catch (err) {
      logger.error(`[syncPortfolio] Broker fetch failed uid=${uid}:`, err);
      throw new HttpsError("unavailable", "Broker API unavailable, try again");
    }

    // Cache snapshot
    await db
      .collection("users")
      .doc(uid)
      .collection("portfolio")
      .doc("latest")
      .set({
        ...snapshot,
        cachedAt: FieldValue.serverTimestamp(),
      });

    return snapshot;
  }
);

export const connectBroker = onCall(
  {
    region: "asia-southeast1",
    memory: "256MiB",
    timeoutSeconds: 30,
  },
  async (request) => {
    const uid = request.auth?.uid;
    if (!uid) throw new HttpsError("unauthenticated", "Must be authenticated");

    const { connectorId, apiKey, apiSecret } = request.data as {
      connectorId: string;
      apiKey?: string;
      apiSecret?: string;
    };

    if (!connectorId) {
      throw new HttpsError("invalid-argument", "connectorId required");
    }

    // Validate credentials with broker (if not demo)
    if (connectorId !== "demo") {
      if (!apiKey || !apiSecret) {
        throw new HttpsError("invalid-argument", "apiKey and apiSecret required");
      }
      await _validateBrokerCredentials(connectorId, apiKey, apiSecret);
    }

    const encryptedToken =
      connectorId === "demo" ? "demo" : await _encryptToken(`${apiKey}:${apiSecret}`);

    const apiBaseUrl = BROKER_BASE_URLS[connectorId] ?? "";

    // Store encrypted — never accessible by client
    await db.collection("brokerConnections").doc(uid).set({
      connectorId,
      encryptedToken,
      apiBaseUrl,
      connectedAt: FieldValue.serverTimestamp(),
      isActive: true,
    });

    logger.info(`[connectBroker] uid=${uid} connected to ${connectorId}`);
    return { success: true, connectorId };
  }
);

// ── Helpers ───────────────────────────────────────────────────────────────────

const BROKER_BASE_URLS: Record<string, string> = {
  demo: "",
  settrade: "https://api.settrade.com/v1",
  // Add more brokers as needed
};

async function _validateBrokerCredentials(
  connectorId: string,
  _apiKey: string,
  _apiSecret: string
): Promise<void> {
  // TODO: Implement per-broker validation
  logger.info(`[connectBroker] Validating credentials for ${connectorId}`);
}

async function _encryptToken(plaintext: string): Promise<string> {
  // Use Cloud KMS or simple base64 for MVP
  // TODO: Upgrade to Cloud KMS envelope encryption
  return Buffer.from(plaintext).toString("base64");
}

async function _decryptToken(encrypted: string): Promise<string> {
  return Buffer.from(encrypted, "base64").toString("utf8");
}

function _normalizePortfolio(
  raw: Record<string, unknown>,
  connectorId: string
): PortfolioSnapshot {
  // Each broker has different response shapes — normalize here
  return {
    totalValue: (raw.totalValue as number) ?? 0,
    dailyPnl: (raw.dailyPnl as number) ?? 0,
    dailyPnlPercent: (raw.dailyPnlPercent as number) ?? 0,
    positions: (raw.positions as PortfolioPosition[]) ?? [],
    snapshotAt: new Date().toISOString(),
    connectorId,
  };
}

async function _generateDemoPortfolio(uid: string): Promise<PortfolioSnapshot> {
  // Deterministic demo data seeded by uid
  const seed = uid.charCodeAt(0) + uid.charCodeAt(uid.length - 1);
  const rng = () => ((seed * 9301 + 49297) % 233280) / 233280;

  const symbols = ["PTT", "AOT", "CPALL", "SCB", "ADVANC"];
  const positions: PortfolioPosition[] = symbols.map((s) => {
    const avgCost = 40 + Math.floor(rng() * 200);
    const currentPrice = avgCost * (0.9 + rng() * 0.25);
    const qty = 100 + Math.floor(rng() * 900);
    return {
      symbol: s,
      qty,
      avgCost,
      currentPrice: Math.round(currentPrice * 100) / 100,
      unrealizedPnl: Math.round((currentPrice - avgCost) * qty * 100) / 100,
    };
  });

  const totalValue = positions.reduce((s, p) => s + p.currentPrice * p.qty, 0);
  const dailyPnl = positions.reduce((s, p) => s + p.unrealizedPnl * 0.1, 0);

  const snapshot: PortfolioSnapshot = {
    totalValue: Math.round(totalValue * 100) / 100,
    dailyPnl: Math.round(dailyPnl * 100) / 100,
    dailyPnlPercent: Math.round((dailyPnl / totalValue) * 10000) / 100,
    positions,
    snapshotAt: new Date().toISOString(),
    connectorId: "demo",
  };

  await db
    .collection("users")
    .doc(uid)
    .collection("portfolio")
    .doc("latest")
    .set({ ...snapshot, cachedAt: FieldValue.serverTimestamp() });

  return snapshot;
}
