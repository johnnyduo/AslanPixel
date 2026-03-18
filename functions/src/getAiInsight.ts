/**
 * getAiInsight
 *
 * Callable function. Client calls with { type, context, uid }.
 * Routes to Gemini Flash-Lite (cheap) or Gemini Flash (balanced) based on type.
 * Caches result in users/{uid}/insights/{insightId} with TTL.
 * Returns cached result if not expired.
 *
 * Types:
 *   market_summary      → Flash-Lite (cheap, high volume)
 *   portfolio_explanation → Flash (balanced, personalized)
 *   prediction_context  → Flash-Lite
 *   agent_tip           → Flash-Lite
 */

import { onCall, HttpsError } from "firebase-functions/v2/https";
import { FieldValue, Timestamp } from "firebase-admin/firestore";
import { db } from "./admin";
import axios from "axios";
import { logger } from "firebase-functions";
import { defineSecret } from "firebase-functions/params";

const geminiApiKey = defineSecret("GEMINI_API_KEY");

type InsightType =
  | "market_summary"
  | "portfolio_explanation"
  | "prediction_context"
  | "agent_tip";

const MODEL_MAP: Record<InsightType, { model: string; ttlMinutes: number }> = {
  market_summary: { model: "gemini-2.0-flash-lite", ttlMinutes: 60 },
  portfolio_explanation: { model: "gemini-2.0-flash", ttlMinutes: 30 },
  prediction_context: { model: "gemini-2.0-flash-lite", ttlMinutes: 120 },
  agent_tip: { model: "gemini-2.0-flash-lite", ttlMinutes: 240 },
};

const SYSTEM_PROMPT = `You are Aslan, an AI financial assistant inside Aslan Pixel — a social financial gamified app.
Keep responses concise (max 3 sentences). Always output JSON with two fields: "content" (English) and "contentTh" (Thai).
Tone: professional but friendly, like a smart trading mentor. No financial advice disclaimers needed.`;

export const getAiInsight = onCall(
  {
    region: "asia-southeast1",
    memory: "512MiB",
    timeoutSeconds: 30,
    secrets: [geminiApiKey],
  },
  async (request) => {
    const uid = request.auth?.uid;
    if (!uid) throw new HttpsError("unauthenticated", "Must be authenticated");

    const { type, context } = request.data as {
      type: InsightType;
      context?: string;
    };

    if (!type || !MODEL_MAP[type]) {
      throw new HttpsError("invalid-argument", `Invalid insight type: ${type}`);
    }

    const { model, ttlMinutes } = MODEL_MAP[type];

    // ── Check cache ──────────────────────────────────────────────────────────
    const cachedRef = db
      .collection("users")
      .doc(uid)
      .collection("insights")
      .where("type", "==", type)
      .where("expiresAt", ">", Timestamp.now())
      .orderBy("expiresAt", "desc")
      .limit(1);

    const cachedSnap = await cachedRef.get();
    if (!cachedSnap.empty) {
      const cached = cachedSnap.docs[0].data();
      logger.debug(`[getAiInsight] Cache hit for uid=${uid} type=${type}`);
      return {
        insightId: cachedSnap.docs[0].id,
        content: cached.content,
        contentTh: cached.contentTh,
        modelUsed: cached.modelUsed,
        cached: true,
      };
    }

    // ── Generate with Gemini ──────────────────────────────────────────────────
    const apiKey = geminiApiKey.value();
    if (!apiKey) throw new HttpsError("internal", "Gemini API key not configured");

    const prompt = buildPrompt(type, context);

    let content = "";
    let contentTh = "";

    try {
      const response = await axios.post(
        `https://generativelanguage.googleapis.com/v1beta/models/${model}:generateContent?key=${apiKey}`,
        {
          system_instruction: { parts: [{ text: SYSTEM_PROMPT }] },
          contents: [{ parts: [{ text: prompt }] }],
          generationConfig: {
            responseMimeType: "application/json",
            maxOutputTokens: 256,
            temperature: 0.7,
          },
        },
        { timeout: 15000 }
      );

      const raw = response.data?.candidates?.[0]?.content?.parts?.[0]?.text ?? "{}";
      const parsed = JSON.parse(raw);
      content = parsed.content ?? "Market data unavailable";
      contentTh = parsed.contentTh ?? content;
    } catch (err) {
      logger.error("[getAiInsight] Gemini error:", err);
      // Fail-open with placeholder
      content = "Market insights temporarily unavailable.";
      contentTh = "ข้อมูลตลาดไม่พร้อมใช้งานชั่วคราว";
    }

    // ── Save to Firestore ─────────────────────────────────────────────────────
    const expiresAt = Timestamp.fromDate(
      new Date(Date.now() + ttlMinutes * 60 * 1000)
    );

    const insightRef = db
      .collection("users")
      .doc(uid)
      .collection("insights")
      .doc();
    await insightRef.set({
      insightId: insightRef.id,
      uid,
      type,
      content,
      contentTh,
      modelUsed: model,
      generatedAt: FieldValue.serverTimestamp(),
      expiresAt,
    });

    logger.info(`[getAiInsight] Generated ${type} for uid=${uid} via ${model}`);

    return {
      insightId: insightRef.id,
      content,
      contentTh,
      modelUsed: model,
      cached: false,
    };
  }
);

function buildPrompt(type: InsightType, context?: string): string {
  switch (type) {
    case "market_summary":
      return `Give a brief market summary for today. Context: ${context ?? "general Thai stock market"}`;
    case "portfolio_explanation":
      return `Explain this portfolio situation in simple terms: ${context ?? "no portfolio data"}`;
    case "prediction_context":
      return `Provide context for this market prediction event: ${context ?? "no event data"}`;
    case "agent_tip":
      return `Give a quick tip for a ${context ?? "financial analyst"} agent in a pixel world finance game`;
    default:
      return `Provide a market insight about: ${context ?? "markets"}`;
  }
}
