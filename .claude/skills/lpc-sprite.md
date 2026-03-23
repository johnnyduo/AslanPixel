# LPC Sprite Generator

Generate animated pixel-art NPC spritesheets using the Universal LPC Spritesheet Character Generator.

## Generator URL
https://liberatedpixelcup.github.io/Universal-LPC-Spritesheet-Character-Generator/

## How It Works

The generator is a web app that composites layered PNG spritesheets. Characters are defined by URL hash params or JSON config. Output is an 832×3456px PNG spritesheet with 64×64px frames.

## URL Hash Format

```
https://liberatedpixelcup.github.io/Universal-LPC-Spritesheet-Character-Generator/#<params>
```

Key params:
- `sex` — `male` | `female` | `muscular` | `teen` | `child` | `pregnant`
- `body` — e.g. `Body_color_light`, `Body_color_dark`, `Body_color_tanned`
- `heads` — e.g. `Human_male_light`, `Human_female_dark`
- `hair` — hairstyle variant
- `headwear` — helmet, hat, crown
- `torso` — shirt, armor, robe
- `legs` — pants, leggings
- `feet` — boots, shoes
- `weapon` — equipped weapon
- `shield` — equipped shield

## Animations Available

| Animation | Frames | Use |
|-----------|--------|-----|
| `walk` | 8 | NPC patrol |
| `idle` | 3 | Waiting |
| `run` | 8 | Fast movement |
| `slash` | 6 | Combat |
| `spellcast` | 7 | Magic |
| `hurt` | 6 | Damage reaction |
| `sit` | 15 | Resting |
| `emote` | 15 | Expression |

## Spritesheet Layout

- Canvas: 832 × 3456 px
- Frame: 64 × 64 px
- Frames per row: 13
- Directions: South (row 0–2), West (3–5), East (6–8), North (9–11)

## JSON Config Format (v2)

```json
{
  "version": 2,
  "bodyType": "male",
  "selections": {
    "body": { "itemId": "body", "variant": "light" },
    "heads": { "itemId": "heads_human_male", "variant": "light" },
    "hair": { "itemId": "hair_plain", "variant": "blonde" },
    "torso": { "itemId": "torso_leather_armor", "variant": "brown" },
    "legs": { "itemId": "legs_pants", "variant": "dark_blue" },
    "feet": { "itemId": "feet_boots", "variant": "black" }
  },
  "selectedAnimation": "walk",
  "enabledAnimations": { "walk": true, "idle": true }
}
```

## AslanGuild Agent Presets

### Scout (cyan — data discovery)
```
#sex=male&body=Body_color_light&heads=Human_male_light&hair=Hair_bangs_light&torso=Torso_leather_armor_cyan&legs=Legs_pants_dark_blue&feet=Feet_boots_black
```
Walk anim, 20s patrol loop.

### Strategist (gold — planning)
```
#sex=male&body=Body_color_tanned&heads=Human_male_tanned&hair=Hair_long_gold&headwear=Headwear_crown_gold&torso=Torso_robe_gold&legs=Legs_robe_gold
```
Slow patrol near Strategy Tower.

### Sentinel (green — risk/policy)
```
#sex=female&body=Body_color_dark&heads=Human_female_dark&hair=Hair_bun_dark&torso=Torso_plate_armor_green&legs=Legs_plate_green&feet=Feet_boots_green&shield=Shield_kite_green
```
Guards perimeter, slash animation on hover.

### Treasurer (purple — budget)
```
#sex=male&body=Body_color_tanned&heads=Human_male_tanned&hair=Hair_short_brown&torso=Torso_noble_purple&legs=Legs_pants_black&feet=Feet_shoes_black
```
Stays near Vault House, idle animation.

### Archivist (red — onchain logging)
```
#sex=female&body=Body_color_light&heads=Human_female_light&hair=Hair_long_red&torso=Torso_robe_red&legs=Legs_robe_red&feet=Feet_sandals
```
Slow walk, sits near Archive Library.

## Using Spritesheets in React/PixiJS

```typescript
// Load spritesheet as base texture
const texture = PIXI.BaseTexture.from('/assets/npc-scout.png');

// Extract walk-south frames (row 0, frames 0–7)
const walkFrames = Array.from({ length: 8 }, (_, i) =>
  new PIXI.Texture(texture, new PIXI.Rectangle(i * 64, 0, 64, 64))
);

const sprite = new PIXI.AnimatedSprite(walkFrames);
sprite.animationSpeed = 0.15;
sprite.play();
```

## CSS Sprite Animation Alternative

```css
.npc-walk {
  width: 64px;
  height: 64px;
  background-image: url('/assets/npc-scout.png');
  background-position: 0 0;
  animation: npc-walk-frames 0.6s steps(8) infinite;
}

@keyframes npc-walk-frames {
  from { background-position: 0 0; }
  to   { background-position: -512px 0; } /* 8 frames × 64px */
}
```

## Step-by-Step: Generate NPC for AslanGuild

1. Open the generator URL above
2. Select body type and skin tone matching agent personality
3. Pick layer options — armor/robe/weapon to match role
4. Enable only: `walk` + `idle` animations
5. Click **Download PNG** — save to `/public/assets/npc-<name>.png`
6. Use the CSS or PixiJS snippet above to animate in-app

## Attribution

All LPC sprites require credit. Use the generator's **Download Credits (TXT)** button and include in `/public/assets/CREDITS.txt`.

License options: CC0, CC-BY-SA 3.0/4.0, CC-BY 3.0/4.0, OGA-BY 3.0, GPL 2.0/3.0.
