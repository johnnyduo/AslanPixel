---
description: Generate an AI-powered portfolio summary card from broker snapshot data. Explains current exposure, unrealized PnL, position concentration, and key risks in plain language (Thai). Use when user asks for "สรุป port", portfolio explanation, AI portfolio review, or exposure analysis.
argument-hint: "[broker account id or 'current'] [optional: detail level basic|full]"
---

# Portfolio Summary Skill — Aslan Pixel

Explain a broker portfolio snapshot in clear, plain Thai language for the Portfolio Dashboard screen.

## Input Expected

Receives a `PortfolioSnapshot` object from the `BrokerConnector`:
- Account equity + balance
- Open positions (symbol, side, lot, entry price, current PnL)
- Asset exposure breakdown

If no broker connected, generate an explanation of the demo/simulated portfolio instead.

## Output Format

### Card Summary (Thai, shown in UI)
```
สรุปพอร์ต: [date]
มูลค่ารวม: [equity] USD
กำไร/ขาดทุนที่ยังเปิดอยู่: [unrealized PnL]
สินทรัพย์หลัก: [top 2 positions]
ความเสี่ยง: [1-2 key risks in plain Thai]
คำแนะนำ AI: [1 sentence insight — not financial advice]
```

### Structured JSON (for AiInsightRepository caching)
```json
{
  "generatedAt": "ISO8601",
  "accountId": "...",
  "equity": 0.0,
  "unrealizedPnl": 0.0,
  "positionCount": 0,
  "topExposure": [{ "symbol": "...", "weight": 0.0 }],
  "riskFlags": [],
  "summaryTh": "...",
  "disclaimerShown": true
}
```

## Constraints

- **Always show disclaimer**: "นี่คือข้อมูลเพื่อการศึกษา ไม่ใช่คำแนะนำทางการเงิน"
- Never suggest specific buy/sell actions
- Real portfolio data: never display publicly (respect privacy settings)
- For demo portfolio: clearly label as "พอร์ตจำลอง"
- Route to Claude Sonnet only for full detail analysis; Gemini Flash-Lite for basic card
