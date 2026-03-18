---
description: Generate AI market insight card for Aslan Pixel finance screen. Summarizes market overview, key movers, sentiment, and prediction hint for a given asset class (crypto/fx/stocks/mixed). Routes to cheap model (Gemini Flash-Lite) for summary, Claude for deep analysis. Use when user asks for market summary, AI insight, daily briefing, or market overview card.
argument-hint: "[asset class: crypto|fx|stocks|mixed] [optional: date or 'today']"
---

# Market Insight Skill — Aslan Pixel

Generate a structured AI market insight card for the Finance tab.

## Routing Rule

**Cheap path (Gemini Flash-Lite / default)**:
- Daily summary card
- Headline sentiment
- Top 3 movers
- Prediction hint

**Premium path (Claude Sonnet — only if user explicitly requests deep analysis)**:
- Detailed reasoning
- Portfolio exposure explanation
- Post-trade explanation

## Output Format

Produce a JSON-ready structure for the `AiInsightCard` Flutter widget:

```json
{
  "generatedAt": "ISO8601",
  "assetClass": "crypto|fx|stocks|mixed",
  "sentiment": "bullish|neutral|bearish",
  "headline": "One-line market summary (max 120 chars, Thai preferred)",
  "topMovers": [
    { "symbol": "BTC/USD", "change": "+2.3%", "note": "Brief reason" },
    { "symbol": "ETH/USD", "change": "-1.1%", "note": "Brief reason" }
  ],
  "predictionHint": "One sentence hinting at prediction event opportunity",
  "keyRisks": ["risk 1", "risk 2"],
  "modelUsed": "gemini-flash-lite|claude-sonnet"
}
```

## Workflow

1. Parse asset class from argument (default: mixed)
2. Search for latest market data / news for that asset class
3. Determine sentiment (bullish/neutral/bearish) based on price action + news
4. Identify top 3 movers with brief explanation
5. Generate prediction hint tied to a tradeable event (for in-game prediction hub)
6. Output structured JSON + human-readable card text (Thai)

## Important Constraints

- **Never use real PnL or financial advice language** — this is game context
- Prediction hint is for in-game coin wagering only, not real trading
- Keep Thai as primary language for human-readable text
- Cache TTL: 30 minutes (do not regenerate if within TTL)
- If no fresh data available, return stale flag in JSON
