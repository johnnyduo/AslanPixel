/**
 * composeFeedCaption
 *
 * Callable. Client passes { achievementType, agentType?, score?, extra? }.
 * Returns a short Thai + English caption for auto-generated feed posts
 * (achievement unlocked, agent leveled up, prediction win, etc.).
 *
 * Uses Gemini Flash-Lite — cheap, fast, high volume.
 */

import { onCall, HttpsError } from "firebase-functions/v2/https";
import { db } from "./admin";
import axios from "axios";
import { logger } from "firebase-functions";
import { defineSecret } from "firebase-functions/params";

const geminiApiKey = defineSecret("GEMINI_API_KEY");

export const composeFeedCaption = onCall(
  {
    region: "asia-southeast1",
    memory: "256MiB",
    timeoutSeconds: 15,
    secrets: [geminiApiKey],
  },
  async (request) => {
    const uid = request.auth?.uid;
    if (!uid) throw new HttpsError("unauthenticated", "Must be authenticated");

    const { achievementType, agentType, score, extra } = request.data as {
      achievementType: string;
      agentType?: string;
      score?: number;
      extra?: string;
    };

    if (!achievementType) {
      throw new HttpsError("invalid-argument", "achievementType required");
    }

    const apiKey = geminiApiKey.value();
    if (!apiKey) {
      return { content: "", contentTh: "" };
    }

    const prompt = buildCaptionPrompt(achievementType, agentType, score, extra);

    let content = "";
    let contentTh = "";

    try {
      const response = await axios.post(
        `https://generativelanguage.googleapis.com/v1beta/models/gemini-2.0-flash-lite:generateContent?key=${apiKey}`,
        {
          system_instruction: {
            parts: [
              {
                text: `You are a feed caption writer for Aslan Pixel — a financial gamified app.
Write short, exciting captions (1 sentence each) for game achievement events.
Output JSON: { "content": "English caption", "contentTh": "Thai caption" }
Use emojis. Keep under 20 words per language. Tone: celebratory and fun.`,
              },
            ],
          },
          contents: [{ parts: [{ text: prompt }] }],
          generationConfig: {
            responseMimeType: "application/json",
            maxOutputTokens: 128,
            temperature: 0.9,
          },
        },
        { timeout: 10000 }
      );

      const raw = response.data?.candidates?.[0]?.content?.parts?.[0]?.text ?? "{}";
      const parsed = JSON.parse(raw);
      content = parsed.content ?? "";
      contentTh = parsed.contentTh ?? "";
    } catch (err) {
      logger.warn("[composeFeedCaption] Gemini error (returning empty):", err);
    }

    // Also log user display name for richer feed posts
    const userSnap = await db.collection("users").doc(uid).get();
    const displayName = userSnap.data()?.displayName ?? "A player";

    return { content, contentTh, displayName };
  }
);

function buildCaptionPrompt(
  achievementType: string,
  agentType?: string,
  score?: number,
  extra?: string
): string {
  const parts: string[] = [`Achievement: ${achievementType}`];
  if (agentType) parts.push(`Agent: ${agentType}`);
  if (score !== undefined) parts.push(`Score/Value: ${score}`);
  if (extra) parts.push(`Extra context: ${extra}`);
  return parts.join(". ");
}
