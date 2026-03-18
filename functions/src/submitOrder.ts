/**
 * submitOrder
 *
 * Callable. Proxies buy/sell orders to broker APIs.
 * NEVER touches client-provided broker tokens — reads from brokerConnections/{uid}.
 *
 * Security checks:
 *   - User must be authenticated
 *   - Broker must be connected
 *   - Order parameters validated server-side
 *   - Rate limit: max 10 orders/minute per user
 */

import { onCall, HttpsError } from "firebase-functions/v2/https";
import { FieldValue, Timestamp } from "firebase-admin/firestore";
import { db } from "./admin";
import axios from "axios";
import { logger } from "firebase-functions";

interface OrderRequest {
  symbol: string;
  side: "buy" | "sell";
  qty: number;
  orderType: "market" | "limit";
  limitPrice?: number;
  note?: string;
}

interface OrderResult {
  orderId: string;
  status: "submitted" | "filled" | "rejected";
  symbol: string;
  side: string;
  qty: number;
  executedPrice?: number;
  message?: string;
}

const ORDER_RATE_LIMIT = 10; // max orders per minute
const ORDER_WINDOW_MS = 60 * 1000;

export const submitOrder = onCall(
  {
    region: "asia-southeast1",
    memory: "256MiB",
    timeoutSeconds: 30,
  },
  async (request): Promise<OrderResult> => {
    const uid = request.auth?.uid;
    if (!uid) throw new HttpsError("unauthenticated", "Must be authenticated");

    const order = request.data as OrderRequest;
    _validateOrder(order);

    // Rate limit check
    await _checkRateLimit(uid);

    // Read broker connection
    const connSnap = await db.collection("brokerConnections").doc(uid).get();
    if (!connSnap.exists || !connSnap.data()?.isActive) {
      throw new HttpsError("not-found", "No active broker connected");
    }

    const conn = connSnap.data()!;

    // Demo mode
    if (conn.connectorId === "demo") {
      return _demoOrder(order);
    }

    // Real broker
    const token = Buffer.from(conn.encryptedToken, "base64").toString("utf8");
    let result: OrderResult;

    try {
      const response = await axios.post(
        `${conn.apiBaseUrl}/orders`,
        {
          symbol: order.symbol,
          side: order.side,
          quantity: order.qty,
          type: order.orderType,
          price: order.limitPrice,
        },
        {
          headers: { Authorization: `Bearer ${token}` },
          timeout: 15000,
        }
      );
      result = {
        orderId: response.data.orderId ?? `ord_${Date.now()}`,
        status: response.data.status ?? "submitted",
        symbol: order.symbol,
        side: order.side,
        qty: order.qty,
        executedPrice: response.data.executedPrice,
        message: response.data.message,
      };
    } catch (err) {
      logger.error(`[submitOrder] Broker error uid=${uid}:`, err);
      throw new HttpsError("unavailable", "Broker order submission failed");
    }

    // Log order
    await db
      .collection("users")
      .doc(uid)
      .collection("orderHistory")
      .add({
        ...order,
        ...result,
        uid,
        submittedAt: FieldValue.serverTimestamp(),
      });

    logger.info(`[submitOrder] uid=${uid} ${order.side} ${order.qty}x${order.symbol} → ${result.status}`);
    return result;
  }
);

function _validateOrder(order: OrderRequest) {
  if (!order.symbol || typeof order.symbol !== "string") {
    throw new HttpsError("invalid-argument", "Invalid symbol");
  }
  if (order.side !== "buy" && order.side !== "sell") {
    throw new HttpsError("invalid-argument", "side must be buy or sell");
  }
  if (!order.qty || order.qty <= 0 || order.qty > 1_000_000) {
    throw new HttpsError("invalid-argument", "qty must be 1–1,000,000");
  }
  if (order.orderType === "limit" && !order.limitPrice) {
    throw new HttpsError("invalid-argument", "limitPrice required for limit orders");
  }
}

async function _checkRateLimit(uid: string) {
  const windowStart = Timestamp.fromMillis(Date.now() - ORDER_WINDOW_MS);
  const recent = await db
    .collection("users")
    .doc(uid)
    .collection("orderHistory")
    .where("submittedAt", ">=", windowStart)
    .count()
    .get();

  if (recent.data().count >= ORDER_RATE_LIMIT) {
    throw new HttpsError(
      "resource-exhausted",
      `Rate limit: max ${ORDER_RATE_LIMIT} orders per minute`
    );
  }
}

function _demoOrder(order: OrderRequest): OrderResult {
  const executedPrice =
    order.limitPrice ??
    Math.round((50 + Math.random() * 200) * 100) / 100;

  return {
    orderId: `demo_${Date.now()}_${Math.random().toString(36).slice(2, 8)}`,
    status: "filled",
    symbol: order.symbol,
    side: order.side,
    qty: order.qty,
    executedPrice,
    message: "Demo order filled",
  };
}
