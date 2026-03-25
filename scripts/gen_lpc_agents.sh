#!/bin/bash
# ============================================================================
# gen_lpc_agents.sh — AslanPixel LPC Agent Spritesheet Generator
#
# Composites real LPC layers from the Universal LPC Spritesheet Generator
# into 576×256 walk spritesheets (9 frames × 4 rows × 64×64 px).
#
# 13 characters: 4 core agents + 10 NPC personalities
# Aslan Wealth theme: navy, neon-green, gold, cyber-purple, cyan
# ============================================================================

SRC=/tmp/lpc-generator/spritesheets
OUT=/Library/WebServer/Documents/AslanPixel/assets/sprites/lpc_npcs
mkdir -p "$OUT"

# ── Silently skips any layer file that doesn't exist ────────────────────────
gen_agent() {
  local name="$1"; shift
  local existing=()
  for f in "$@"; do
    [[ -f "$f" ]] && existing+=("$f")
  done

  if [[ ${#existing[@]} -eq 0 ]]; then
    echo "  SKIP $name — no layers found"; return 1
  fi

  local out="$OUT/${name}_walk.png"
  local cmd="magick ${existing[0]}"
  for ((i=1; i<${#existing[@]}; i++)); do
    cmd="$cmd ${existing[$i]} -composite"
  done
  eval "$cmd $out"

  local dims; dims=$(identify -format '%wx%h' "$out" 2>/dev/null)
  echo "  OK $name → $dims (${#existing[@]} layers)"
}

# Shorthand prefixes
B="$SRC/body/bodies"
EY="$SRC/eyes/human/adult/neutral/walk"
EB="$SRC/eyes/eyebrows/thick/adult/walk"
H="$SRC/hair"
TL="$SRC/torso/clothes/longsleeve/longsleeve"  # body-fitted longsleeve
TFS="$SRC/torso/clothes/longsleeve/formal_striped"
TA="$SRC/torso/armour/plate"
LP="$SRC/legs/pants"
LF="$SRC/legs/formal/thin"   # formal thin pants
LA="$SRC/legs/armour/plate"
HAT="$SRC/hat"
SH="$SRC/shoulders"
BE="$SRC/beards"
FA="$SRC/facial"

echo "=== Generating AslanPixel LPC Agent Spritesheets ==="
echo ""

# ============================================================================
# CORE AGENTS (4) — Aslan Wealth color palette
# ============================================================================

# 1. ANALYST — Female, neon-green suit, black bangs, professional glasses
echo "1. npc_analyst_senior (Analyst — Neon Green)"
gen_agent "npc_analyst_senior" \
  "$B/female/walk/light.png" \
  "$EY/brown.png" \
  "$EB/black.png" \
  "$H/bangslong/adult/walk/black.png" \
  "$LF/walk/teal.png" \
  "$TL/female/walk/teal.png" \
  "$FA/glasses/sunglasses/adult/walk/teal.png"

# 2. SCOUT — Young male, gold/yellow outfit, blonde bedhead, explorer
echo "2. npc_scout (Scout — Gold)"
gen_agent "npc_scout" \
  "$B/male/walk/light.png" \
  "$EY/blue.png" \
  "$EB/blonde.png" \
  "$H/bedhead/adult/walk/blonde.png" \
  "$LP/male/walk/black.png" \
  "$TL/male/walk/yellow.png"

# 3. RISK — Male, dark skin, cyber-purple, silver mohawk, intense
echo "3. npc_risk (Risk Guardian — Cyber Purple)"
gen_agent "npc_risk" \
  "$B/male/walk/dark.png" \
  "$EY/purple.png" \
  "$EB/ash.png" \
  "$H/shorthawk/adult/walk/ash.png" \
  "$LP/male/walk/black.png" \
  "$TL/male/walk/lavender.png"

# 4. SOCIAL — Female, light skin, cyan top, pink bob, energetic
echo "4. npc_social (Social Agent — Cyan)"
gen_agent "npc_social" \
  "$B/female/walk/light.png" \
  "$EY/blue.png" \
  "$EB/rose.png" \
  "$H/bob/adult/walk/rose.png" \
  "$LF/walk/sky.png" \
  "$TL/female/walk/sky.png"

echo ""
# ============================================================================
# NPC PERSONALITIES (10)
# ============================================================================

# 5. BANKER — Elderly, navy formal suit, white balding, tophat
echo "5. npc_banker (Banker — Navy/Black Formal)"
gen_agent "npc_banker" \
  "$B/male/walk/light.png" \
  "$EY/gray.png" \
  "$EB/gray.png" \
  "$H/balding/adult/walk/white.png" \
  "$LF/walk/black.png" \
  "$TFS/male/walk/white.png" \
  "$HAT/formal/tophat/adult/walk/black.png"

# 6. TRADER — Young male, white shirt, teal pants, dark bedhead
echo "6. npc_trader (Trader — White/Teal)"
gen_agent "npc_trader" \
  "$B/male/walk/light.png" \
  "$EY/brown.png" \
  "$EB/dark_brown.png" \
  "$H/bedhead/adult/walk/dark_brown.png" \
  "$LP/male/walk/teal.png" \
  "$TL/male/walk/white.png"

# 7. CHAMPION — Female warrior, gold plate armor, white pixie cut
echo "7. npc_champion (Champion — Gold Armor)"
gen_agent "npc_champion" \
  "$B/female/walk/light.png" \
  "$EY/gray.png" \
  "$EB/gray.png" \
  "$H/pixie/adult/walk/white.png" \
  "$LA/female/walk/gold.png" \
  "$TA/female/walk/gold.png" \
  "$SH/plate/female/walk/gold.png"

# 8. ORACLE — Old male, purple robe, wizard hat buckle lavender, white beard
echo "8. npc_oracle (Oracle — Purple/Mystical)"
gen_agent "npc_oracle" \
  "$B/male/walk/light.png" \
  "$EY/gray.png" \
  "$EB/gray.png" \
  "$H/balding/adult/walk/white.png" \
  "$BE/beard/walk/basic.png" \
  "$LP/male/walk/lavender.png" \
  "$TL/male/walk/lavender.png" \
  "$HAT/magic/wizard/buckle/adult/walk/silver.png"

# 9. HACKER — Dark skin, dark clothing, green mohawk, cyberpunk
echo "9. npc_hacker (Hacker — Dark/Green)"
gen_agent "npc_hacker" \
  "$B/male/walk/dark.png" \
  "$EY/green.png" \
  "$EB/ginger.png" \
  "$H/shorthawk/adult/walk/green.png" \
  "$LP/male/walk/black.png" \
  "$TL/male/walk/black.png"

# 10. MERCHANT — Muscular, olive skin, forest green robe, chestnut mustache
echo "10. npc_merchant (Merchant — Forest/Earthy)"
gen_agent "npc_merchant" \
  "$B/muscular/walk/olive.png" \
  "$EY/brown.png" \
  "$EB/chestnut.png" \
  "$H/balding/adult/walk/brunette.png" \
  "$BE/mustache/walk/5oclock_shadow.png" \
  "$LP/male/walk/maroon.png" \
  "$TL/male/walk/forest.png"

# 11. PIXELCAT — Child, light, blue outfit, chestnut bangs
echo "11. npc_pixelcat (PixelCat)"
gen_agent "npc_pixelcat" \
  "$B/child/walk/light.png" \
  "$SRC/eyes/human/child/neutral/walk/blue.png" \
  "$H/bangs/child/walk/chestnut.png" \
  "$LP/teen/walk/blue.png" \
  "$TL/teen/walk/blue.png"

# 12. SYSBOT — Skeleton (robot-like)
echo "12. npc_sysbot (SysBot — Skeleton)"
gen_agent "npc_sysbot" \
  "$B/skeleton/walk/skeleton.png"

# 13. INTERN — Teen, maroon shirt, brown pants, brunette messy hair
echo "13. npc_intern (Intern)"
gen_agent "npc_intern" \
  "$B/teen/walk/light.png" \
  "$EY/brown.png" \
  "$EB/chestnut.png" \
  "$H/messy1/teen/walk/brunette.png" \
  "$LP/teen/walk/brown.png" \
  "$TL/teen/walk/maroon.png"

echo ""
echo "=== Generated files ==="
ls -lh "$OUT"/*.png 2>/dev/null
echo ""
echo "Total: $(ls "$OUT"/*.png 2>/dev/null | wc -l) sprites"
