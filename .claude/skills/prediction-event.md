---
description: Create a new prediction event for the in-game prediction hub. Generates event title, question, options, coin cost, and settlement rule for a market prediction. Use when user or admin wants to create a prediction event, add a market question, or schedule a new wager.
argument-hint: "[asset: BTC|Gold|EURUSD|...] [timeframe: today|this-week|custom]"
---

# Prediction Event Creator — Aslan Pixel

Generate a structured prediction event for the in-game prediction hub (in-game coins only, not real money).

## Workflow

1. Parse asset and timeframe from argument
2. Search for relevant market context (recent price action, upcoming events, catalysts)
3. Generate event question + 2-3 options
4. Set coin cost and reward multiplier based on difficulty
5. Define settlement rule (price threshold, time of settlement)
6. Output Firestore-ready document

## Output: Firestore Document (predictionEvents/{eventId})

```json
{
  "id": "auto",
  "assetClass": "crypto|fx|stocks",
  "symbol": "BTC/USD",
  "title": "BTC จะปิดเหนือ $95,000 วันนี้ไหม?",
  "titleEn": "Will BTC close above $95,000 today?",
  "options": [
    { "id": "yes", "label": "ใช่", "multiplier": 1.8 },
    { "id": "no",  "label": "ไม่", "multiplier": 1.4 }
  ],
  "coinCost": 50,
  "settlementAt": "ISO8601",
  "settlementRule": {
    "type": "price_threshold",
    "symbol": "BTC/USD",
    "threshold": 95000,
    "direction": "above",
    "settlementTime": "23:59 UTC"
  },
  "context": "Brief market context shown to user before placing wager",
  "difficulty": "easy|medium|hard",
  "status": "open",
  "createdAt": "ISO8601"
}
```

## Difficulty Guidelines

| Difficulty | Coin Cost | Multiplier range | Example |
|-----------|-----------|-----------------|---------|
| easy | 20–50 | 1.3–1.5x | "BTC above 90k?" after strong rally |
| medium | 50–150 | 1.5–2.0x | "Gold breaks range?" |
| hard | 150–500 | 2.0–4.0x | "FX pair extreme move?" |

## Constraints

- In-game coins only — never real money language
- Show context to help users make informed in-game decisions
- Settlement must be automated via Cloud Scheduler + Firestore
- Deterministic settlement: use price data feed, not LLM opinion
- Max 3 active events per asset class at a time
