#!/bin/bash
# ============================================================================
# gen_lpc_agents.sh — AslanPixel LPC Agent Spritesheet Generator
#
# Composites real LPC layers in CORRECT z-order (from sheet_definitions):
#   z=10  body
#   z=20  legs/pants
#   z=35  torso/shirt
#   z=60  armour plate
#   z=105 eyes          ← MUST come after body/clothes
#   z=106 eyebrows
#   z=110 beard
#   z=115 glasses
#   z=130 hair          ← on top of everything except hat
#   z=130 hat
#
# Output: 576×256 walk spritesheets (9 frames × 4 rows × 64×64 px)
# ============================================================================

SRC=/tmp/lpc-generator/spritesheets
OUT=/Library/WebServer/Documents/AslanPixel/assets/sprites/lpc_npcs
mkdir -p "$OUT"

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

# Path shortcuts
B="$SRC/body/bodies"
EY="$SRC/eyes/human/adult/neutral/walk"   # z=105 eyes
EB="$SRC/eyes/eyebrows/thick/adult/walk"  # z=106 eyebrows
BE="$SRC/beards"                           # z=110 beard
FA="$SRC/facial/glasses"                   # z=115 glasses
H="$SRC/hair"                              # z=130 hair
LP="$SRC/legs/pants"                       # z=20 pants
LF="$SRC/legs/formal/thin/walk"           # z=20 formal pants
LA="$SRC/legs/armour/plate"               # z=60 armour legs
TL="$SRC/torso/clothes/longsleeve/longsleeve"    # z=35 shirt
TFS="$SRC/torso/clothes/longsleeve/formal_striped" # z=35 formal shirt
TA="$SRC/torso/armour/plate"              # z=60 armour chest
SH="$SRC/shoulders/plate"                 # z=60 shoulders
HAT="$SRC/hat"                            # z=130 hat

echo "=== Generating AslanPixel LPC Agent Spritesheets ==="
echo "(z-order: body→legs→torso→armor→eyes→eyebrows→beard→glasses→hair→hat)"
echo ""

# ============================================================================
# CORE AGENTS (4)
# ============================================================================

echo "1. npc_analyst_senior (Analyst — Teal)"
gen_agent "npc_analyst_senior" \
  "$B/female/walk/light.png" \
  "$LF/black.png" \
  "$TL/female/walk/teal.png" \
  "$EY/brown.png" \
  "$EB/black.png" \
  "$FA/sunglasses/adult/walk/teal.png" \
  "$H/bangslong/adult/walk/black.png"

echo "2. npc_scout (Scout — Gold/Yellow)"
gen_agent "npc_scout" \
  "$B/male/walk/light.png" \
  "$LP/male/walk/black.png" \
  "$TL/male/walk/yellow.png" \
  "$EY/blue.png" \
  "$EB/blonde.png" \
  "$H/bedhead/adult/walk/blonde.png"

echo "3. npc_risk (Risk — Cyber Purple)"
gen_agent "npc_risk" \
  "$B/male/walk/dark.png" \
  "$LP/male/walk/black.png" \
  "$TL/male/walk/lavender.png" \
  "$EY/purple.png" \
  "$EB/ash.png" \
  "$H/shorthawk/adult/walk/ash.png"

echo "4. npc_social (Social — Cyan/Pink)"
gen_agent "npc_social" \
  "$B/female/walk/light.png" \
  "$LF/sky.png" \
  "$TL/female/walk/sky.png" \
  "$EY/blue.png" \
  "$EB/rose.png" \
  "$H/bob/adult/walk/rose.png"

echo ""
# ============================================================================
# NPC PERSONALITIES (9)
# ============================================================================

echo "5. npc_banker (Banker — Navy Formal + Tophat)"
gen_agent "npc_banker" \
  "$B/male/walk/light.png" \
  "$LF/black.png" \
  "$TFS/male/walk/white.png" \
  "$EY/gray.png" \
  "$EB/gray.png" \
  "$H/balding/adult/walk/white.png" \
  "$HAT/formal/tophat/adult/walk/black.png"

echo "6. npc_trader (Trader — White/Teal)"
gen_agent "npc_trader" \
  "$B/male/walk/light.png" \
  "$LP/male/walk/teal.png" \
  "$TL/male/walk/white.png" \
  "$EY/brown.png" \
  "$EB/dark_brown.png" \
  "$H/bedhead/adult/walk/dark_brown.png"

echo "7. npc_champion (Champion — Gold Armor)"
gen_agent "npc_champion" \
  "$B/female/walk/light.png" \
  "$LA/female/walk/gold.png" \
  "$TA/female/walk/gold.png" \
  "$SH/female/walk/gold.png" \
  "$EY/gray.png" \
  "$EB/gray.png" \
  "$H/pixie/adult/walk/white.png"

echo "8. npc_oracle (Oracle — Purple Wizard)"
gen_agent "npc_oracle" \
  "$B/male/walk/light.png" \
  "$LP/male/walk/lavender.png" \
  "$TL/male/walk/lavender.png" \
  "$EY/gray.png" \
  "$EB/gray.png" \
  "$BE/beard/walk/basic.png" \
  "$H/balding/adult/walk/white.png" \
  "$HAT/magic/wizard/buckle/adult/walk/silver.png"

echo "9. npc_hacker (Hacker — Dark + Green)"
gen_agent "npc_hacker" \
  "$B/male/walk/dark.png" \
  "$LP/male/walk/black.png" \
  "$TL/male/walk/black.png" \
  "$EY/green.png" \
  "$EB/ginger.png" \
  "$H/shorthawk/adult/walk/green.png"

echo "10. npc_merchant (Merchant — Forest/Earthy)"
gen_agent "npc_merchant" \
  "$B/muscular/walk/olive.png" \
  "$LP/male/walk/maroon.png" \
  "$TL/male/walk/forest.png" \
  "$EY/brown.png" \
  "$EB/chestnut.png" \
  "$BE/mustache/walk/5oclock_shadow.png" \
  "$H/balding/adult/walk/brunette.png"

echo "11. npc_pixelcat (PixelCat)"
gen_agent "npc_pixelcat" \
  "$B/child/walk/light.png" \
  "$LP/teen/walk/blue.png" \
  "$TL/teen/walk/blue.png" \
  "$SRC/eyes/human/child/neutral/walk/blue.png" \
  "$H/bangs/child/walk/chestnut.png"

echo "12. npc_sysbot (SysBot — Skeleton)"
gen_agent "npc_sysbot" \
  "$B/skeleton/walk/skeleton.png"

echo "13. npc_intern (Intern)"
gen_agent "npc_intern" \
  "$B/teen/walk/light.png" \
  "$LP/teen/walk/brown.png" \
  "$TL/teen/walk/maroon.png" \
  "$EY/brown.png" \
  "$EB/chestnut.png" \
  "$H/messy1/teen/walk/brunette.png"

echo ""
echo "=== Generated files ==="
ls -lh "$OUT"/*_walk.png 2>/dev/null
echo "Total: $(ls "$OUT"/*_walk.png 2>/dev/null | wc -l) sprites"
