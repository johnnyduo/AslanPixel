---
description: Generate in-game dialogue for an AI agent character (Analyst, Scout, Risk, or Social agent). Creates short, personality-driven dialogue lines for idle, working, returning, and celebrate/fail states. Thai primary. Use when building agent sprite dialogue bubbles, NPC interactions, or quest completion messages.
argument-hint: "[agent type: analyst|scout|risk|social] [state: idle|working|returning|celebrate|fail] [optional: context]"
---

# Agent Dialogue Generator — Aslan Pixel

Generate short pixel-game dialogue lines for AI agent characters.

## Agent Personalities

| Agent | Personality | Tone |
|-------|------------|------|
| **Analyst** | Smart, slightly nerdy, finance-focused | Analytical but approachable |
| **Scout** | Energetic, explorer, adventurous | Upbeat, casual |
| **Risk** | Careful, conservative, protective | Calm, measured |
| **Social** | Friendly, trend-aware, social butterfly | Playful, outgoing |

## State Templates

### idle
Brief, character-appropriate idle remark. Max 2 lines.
```
Analyst: "กำลังดูข้อมูลตลาดอยู่นะ... 📊"
Scout: "พร้อมออกสำรวจแล้ว! บอกได้เลย 🗺️"
Risk: "ตรวจสอบ exposure รอบสุดท้าย... ✅"
Social: "มีข่าวน่าสนใจในฟีดเลยนะ 👀"
```

### working
Active task commentary. Max 2 lines.
```
Analyst: "วิเคราะห์แนวโน้ม BTC อยู่... รอแป๊บนึงนะ"
Scout: "กำลังสำรวจ Zone ใหม่อยู่! เจอของดีแน่ๆ"
```

### returning
Coming back with result. Max 2 lines.
```
Analyst: "วิเคราะห์เสร็จแล้ว! มีข้อมูลน่าสนใจมาฝาก"
Scout: "กลับมาแล้ว! ได้ของมาเยอะเลย 🎒"
```

### celebrate
Success moment. Max 2 lines, energetic.
```
Analyst: "คาดการณ์ถูกต้อง! ตลาดเป็นไปตามที่วิเคราะห์ 🎉"
Scout: "ภารกิจสำเร็จ! ได้รางวัลมาเต็มๆ เลย ⭐"
```

### fail
Mild failure, still encouraging. Max 2 lines.
```
Analyst: "ครั้งนี้ตลาดไม่เป็นไปตามคาด... แต่เราเรียนรู้ได้"
Scout: "ภารกิจนี้ยากเกินไปหน่อย แต่ครั้งหน้าต้องได้!"
```

## Output Format

Return an array of 3-5 dialogue options per state (for variety in-game):

```json
{
  "agent": "analyst",
  "state": "celebrate",
  "lines": [
    "คาดการณ์ถูกต้อง! ตลาดเป็นไปตามที่วิเคราะห์ 🎉",
    "ข้อมูลไม่โกหก! เราทำได้แล้ว 📈",
    "สัญญาณที่อ่านมาถูกต้องทุกอย่างเลย ✨"
  ]
}
```

## Constraints

- Max 60 characters per line (fits dialogue bubble in pixel game)
- Thai primary; English acceptable for short phrases/terms
- No real financial advice language
- Keep personality consistent with agent type
- Use 1 emoji max per line (pixel aesthetic)
- Avoid breaking immersion with technical jargon
