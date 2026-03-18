# Aslan Pixel — Pixel Art Asset System Design

> Version: 1.0.0 | Date: 2026-03-18 | Status: Design Spec

---

## 1. Art Style Guide

### Resolution: 16×16 Base Tile
All game sprites use 16×16 pixels per tile. Rationale:
- Flame room canvas is 400×700px — at 16px/tile = 25×43 tile grid
- Agents render at ~48px (3× native) — crisp nearest-neighbor scaling
- Plaza dots render at 16px — pixel-perfect avatar display
- Multi-tile items scale as integers: 1×1, 2×1, 2×2

### Master 16-Color Palette

| # | Hex | Name | Usage |
|---|-----|------|-------|
| 00 | `#0A1628` | Deep Navy (transparent) | Background / alpha |
| 01 | `#0D1F3C` | Shadow Navy | Darkest shadow |
| 02 | `#162040` | Surface Navy | Mid-shadow |
| 03 | `#1C2A4E` | Elevated Navy | Light shadow |
| 04 | `#3D5A78` | Muted Steel | Outlines, inactive |
| 05 | `#A8C4E0` | Ice Blue | Neutral body mid, skin |
| 06 | `#E8F4FF` | Pixel White | Highlight, eyes, shine |
| 07 | `#00F5A0` | Neon Green | Analyst, XP, profit |
| 08 | `#00C77D` | Deep Green | Neon green shadow |
| 09 | `#F5C518` | Gold | Coins, Scout, shield |
| 10 | `#C9940A` | Dark Gold | Gold shadow |
| 11 | `#7B2FFF` | Cyber Purple | Oracle, AI glow |
| 12 | `#5A1FCC` | Deep Purple | Cyber purple shadow |
| 13 | `#00D9FF` | Cyan | Social agent, Arena |
| 14 | `#009BB5` | Deep Cyan | Cyan shadow |
| 15 | `#FF4D4F` | Alert Red | Fail state, loss |

**Rules:** No gradients. 1px dark outline (index 01 or 04) on every sprite. 2-tone shading via dithering. Index 00 = transparent in PNG export.

### Animation Specs
| State | Frames | FPS |
|-------|--------|-----|
| idle | 4 | 6 |
| working | 4 | 8 |
| celebrating | 6 | 10 |
| returning | 4 | 8 |
| fail | 3 | 5 |

All spritesheets: **horizontal strips**. Format: `agent_{type}_{state}.png`

---

## 2. Agent Character Sprites

| Agent | Color | Silhouette Key Feature |
|-------|-------|----------------------|
| Analyst | Neon Green #00F5A0 | Gold-framed glasses + glowing tablet |
| Scout | Gold #F5C518 | Pointed hood tip + binoculars at eye level |
| Risk Guardian | Cyber Purple #7B2FFF | Wide armored shoulders + gold kite shield |
| Social | Cyan #00D9FF | Speech bubble floating above right shoulder |
| Oracle (future) | Deep Purple #5A1FCC | Wizard hat + robe hem expansion + crystal ball |

**Color mapping matches existing `pixel_room_game.dart`** — no code changes needed until sprites are ready.

### Agent Special Effects (1 particle effect each)
- Analyst: Data stream — cascade of #00F5A0 1px dots from tablet, 0.3s fade
- Scout: Scout beam — 1px cyan line sweeps 45° arc from binoculars, 0.5s
- Risk Guardian: Shield burst — 8 gold pixels radiate from shield, 4-frame fade
- Social: Heart burst — 6 cyan pixels scatter from speech bubble, 0.4s arc
- Oracle: Vision ring — purple→cyan dithered ring expands 6px, 6-frame fade

---

## 3. User Avatar Presets (8 total)

| ID | Name | Presentation | Primary Color |
|----|------|-------------|---------------|
| A1 | NEXUS | Male | Neon Green #00F5A0 |
| A2 | VALEN | Male | Gold #F5C518 |
| A3 | LYRA | Female | Cyber Purple #7B2FFF |
| A4 | SORA | Female | Cyan #00D9FF |
| A5 | RIVEN | Neutral | Muted Steel #3D5A78 |
| A6 | KAI | Neutral | Deep Purple #5A1FCC |
| A7 | SPECTER-X | Robot | Ice Blue #A8C4E0 |
| A8 | DRAKO | Fantasy/Dragon | Alert Red #FF4D4F |

**Plaza fallback dot color** (when sprite not loaded):
```dart
static const Map<String, Color> avatarDotColor = {
  'A1': Color(0xFF00F5A0), 'A2': Color(0xFFF5C518),
  'A3': Color(0xFF7B2FFF), 'A4': Color(0xFF00D9FF),
  'A5': Color(0xFF3D5A78), 'A6': Color(0xFF5A1FCC),
  'A7': Color(0xFFA8C4E0), 'A8': Color(0xFFFF4D4F),
};
```

---

## 4. Plaza NPC Designs

| NPC | Location | Color | Interaction |
|-----|----------|-------|-------------|
| Banker | Near Bank (bottom-center) | Gold #F5C518 | Shows coin balance + AI tip |
| Trader | Near Market (top-left) | Cyber Purple #7B2FFF | Latest market summary |
| Arena Champion | Near Arena (top-right) | Cyan #00D9FF | User's leaderboard rank |
| Wandering Merchant | Roams 3-waypoint path | Gold #F5C518 | Limited-time item shop |
| System Bot | Plaza center (when announcement active) | Neon Green #00F5A0 | System announcements |
| Pixel Cat | Follows user with 0.5s lag | Steel #3D5A78 | Pet (tap → meow) |

---

## 5. Room Items Catalog (24+ items)

### Starter Set (unlocked by default)
`desk_01` (2×1), `chair_01` (1×1), `bookshelf_01` (1×2), `plant_01` (1×1), `plant_02` (1×1), `plant_03` (1×1), `chest_01` (1×1), `rug_01` (2×2), `lamp_01` (1×1), `desk_02` (2×1), `desk_03` (2×1)

### Coins (unlock with coins)
- `bed_01` (2×2) — 200 coins
- `sofa_01` (2×1) — 150 coins
- `cabinet_01` (1×2) — 300 coins
- `clock_01` (1×1) — 80 coins
- `poster_finance` (1×1) — 50 coins
- `poster_neon` (1×1) — 50 coins
- `monitor_01` (1×1) — 100 coins
- `tv_01` (2×1) — 200 coins
- `server_rack_01` (1×2) — 400 coins
- `workstation_01` (2×2) — 500 coins
- `hologram_01` (1×1, animated) — 600 coins
- `neon_sign_aslan` (2×1, animated) — 1000 coins
- `pixel_cat_pet` (1×1, animated) — 500 coins

### Achievement Unlocks
- `trophy_shelf_01` (2×1) — Achievement: "First Win"
- `golden_throne` (2×2) — Achievement: "Top Rank Weekly"
- `crystal_ball_desk` (1×1, animated) — Achievement: "Oracle's Eye"

---

## 6. Asset File Structure

```
assets/sprites/
├── agents/         # agent_{type}_{state}.png (64×16 for 4-frame, 96×16 for 6-frame)
├── avatars/        # avatar_{ID}_front.png (16×16, static)
├── npcs/           # npc_{name}_{state}.png
├── room_items/
│   ├── furniture/
│   ├── decorations/
│   ├── technology/
│   └── special/
├── effects/        # effect_{name}.png (128×16, 8-frame)
└── ui/             # coin_icon, xp_icon, quest_icon, lock_icon (16×16)
```

**Total budget: ~55–70 KB compressed** (pixel art compresses extremely well)

---

## 7. Flame Integration

### Load spritesheet in PixelRoomGame.onLoad():
```dart
await Flame.images.loadAll([
  'sprites/agents/agent_analyst_idle.png',
  // ... all states × all agents
]);
```

### Replace CircleComponent with SpriteAnimationComponent:
```dart
_idleAnimation = SpriteAnimation.fromFrameData(
  image,
  SpriteAnimationData.sequenced(
    amount: 4,
    stepTime: 1 / 6,
    textureSize: Vector2(16, 16),
  ),
);
final component = SpriteAnimationComponent(
  animation: _idleAnimation,
  size: Vector2(48, 48),   // 3× scale
  anchor: Anchor.center,
);
```

### pubspec.yaml — add sprite asset directories:
```yaml
flutter:
  assets:
    - assets/sprites/agents/
    - assets/sprites/avatars/
    - assets/sprites/npcs/
    - assets/sprites/room_items/furniture/
    - assets/sprites/room_items/decorations/
    - assets/sprites/room_items/technology/
    - assets/sprites/room_items/special/
    - assets/sprites/effects/
    - assets/sprites/ui/
```

---

## 8. AI-Assisted Generation Strategy

**Primary tool: Aseprite** ($19.99) — indexed color mode, onion skinning, horizontal strip export.

**Prompt template for AI concept reference (DALL-E 3):**
```
pixel art character, 16x16 sprite, {DESCRIPTION}, dark navy background,
limited 16-color palette, sharp 1-pixel outline, no anti-aliasing,
front-facing, indie game sprite style
```

**Per-agent concept prompts:**
- Analyst: "finance analyst, neon green tinted glasses, glowing green tablet with chart"
- Scout: "hooded ranger, gold scarf, binoculars raised to eyes, crouching stance"
- Risk Guardian: "armored knight, purple cyber-armor, kite shield with golden emblem"
- Social: "friendly character, speech bubble overhead, waving arm, cyan outfit"
- Oracle: "mystical wizard, tall pointed hat, crystal ball, purple aura glow"

**Quality checklist:**
- [ ] Only 16 approved palette colors used
- [ ] Index 00 transparent in PNG
- [ ] No anti-aliasing
- [ ] 1px outline on every sprite
- [ ] Silhouette readable at 16px displayed size
- [ ] Spritesheet dimensions correct per spec
- [ ] Filename matches assetKey/convention

---

## 9. Aseprite Palette File

Save as `assets/aslan_16color.pal`:
```
JASC-PAL
0100
16
10 22 40
13 31 60
22 32 64
28 42 78
61 90 120
168 196 224
232 244 255
0 245 160
0 199 125
245 197 24
201 148 10
123 47 255
90 31 204
0 217 255
0 155 181
255 77 79
```
