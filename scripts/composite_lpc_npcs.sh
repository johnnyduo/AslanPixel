#!/bin/bash
# Composite LPC spritesheet layers into NPC spritesheets
# Each NPC = body + clothing + hair + accessories layered together
# Output: walk spritesheet (576x256 = 9 frames × 4 directions × 64×64)

SRC=/tmp/lpc-gen/spritesheets
OUT=/Library/WebServer/Documents/AslanPixel/assets/sprites/lpc_npcs
mkdir -p "$OUT"

# Function to composite layers for walk animation
composite_walk() {
  local name=$1
  shift
  local layers=("$@")

  # Start with first layer as base
  local cmd="magick ${layers[0]}"

  # Add remaining layers
  for ((i=1; i<${#layers[@]}; i++)); do
    cmd="$cmd ${layers[$i]} -composite"
  done

  cmd="$cmd $OUT/${name}_walk.png"
  eval $cmd
  echo "OK: $name ($(identify -format '%wx%h' $OUT/${name}_walk.png 2>/dev/null))"
}

# Function to composite layers for idle animation
composite_idle() {
  local name=$1
  shift
  local layers=("$@")

  local cmd="magick ${layers[0]}"
  for ((i=1; i<${#layers[@]}; i++)); do
    cmd="$cmd ${layers[$i]} -composite"
  done
  cmd="$cmd $OUT/${name}_idle.png"
  eval $cmd
}

echo "=== Generating LPC NPC Spritesheets ==="

# 1. BANKER — elderly male, formal suit, white hair, tophat
composite_walk "npc_banker" \
  "$SRC/body/bodies/male/walk/light.png" \
  "$SRC/legs/formal/walk/black.png" \
  "$SRC/torso/clothes/longsleeve/walk/black.png" \
  "$SRC/hair/balding/walk/white.png" \
  "$SRC/hat/formal/tophat/walk/black.png"

composite_idle "npc_banker" \
  "$SRC/body/bodies/male/idle/light.png" \
  "$SRC/legs/formal/idle/black.png" \
  "$SRC/torso/clothes/longsleeve/idle/black.png" \
  "$SRC/hair/balding/idle/white.png" \
  "$SRC/hat/formal/tophat/idle/black.png"

# 2. TRADER — energetic young male, white shirt, cyan tie area, spiky dark hair
composite_walk "npc_trader" \
  "$SRC/body/bodies/male/walk/light.png" \
  "$SRC/legs/pants/walk/teal.png" \
  "$SRC/torso/clothes/longsleeve/walk/white.png" \
  "$SRC/hair/bedhead/walk/raven.png"

composite_idle "npc_trader" \
  "$SRC/body/bodies/male/idle/light.png" \
  "$SRC/legs/pants/idle/teal.png" \
  "$SRC/torso/clothes/longsleeve/idle/white.png" \
  "$SRC/hair/bedhead/idle/raven.png"

# 3. CHAMPION — female warrior, gold armor, silver hair
composite_walk "npc_champion" \
  "$SRC/body/bodies/female/walk/light.png" \
  "$SRC/legs/armour/walk/gold.png" \
  "$SRC/torso/armour/chest/walk/gold.png" \
  "$SRC/hair/pixie/walk/white.png" \
  "$SRC/shoulders/armour/walk/gold.png"

composite_idle "npc_champion" \
  "$SRC/body/bodies/female/idle/light.png" \
  "$SRC/legs/armour/idle/gold.png" \
  "$SRC/torso/armour/chest/idle/gold.png" \
  "$SRC/hair/pixie/idle/white.png" \
  "$SRC/shoulders/armour/idle/gold.png"

# 4. MERCHANT — chubby male (muscular base), green robe, bald with beard
composite_walk "npc_merchant" \
  "$SRC/body/bodies/muscular/walk/olive.png" \
  "$SRC/legs/pants/walk/maroon.png" \
  "$SRC/torso/clothes/longsleeve/walk/green.png" \
  "$SRC/beards/mustache_short/walk/brunette.png"

composite_idle "npc_merchant" \
  "$SRC/body/bodies/muscular/idle/olive.png" \
  "$SRC/legs/pants/idle/maroon.png" \
  "$SRC/torso/clothes/longsleeve/idle/green.png" \
  "$SRC/beards/mustache_short/idle/brunette.png"

# 5. SYSBOT — skeleton base (robot look!), no hair, minimal
composite_walk "npc_sysbot" \
  "$SRC/body/bodies/skeleton/walk/skeleton.png"

composite_idle "npc_sysbot" \
  "$SRC/body/bodies/skeleton/idle/skeleton.png"

# 6. PIXELCAT — child base, playful, colorful
composite_walk "npc_pixelcat" \
  "$SRC/body/bodies/child/walk/light.png" \
  "$SRC/legs/pants/walk/blue.png" \
  "$SRC/torso/clothes/longsleeve/walk/blue.png" \
  "$SRC/hat/accessory/cat_ears/walk/brown.png"

composite_idle "npc_pixelcat" \
  "$SRC/body/bodies/child/idle/light.png" \
  "$SRC/legs/pants/idle/blue.png" \
  "$SRC/torso/clothes/longsleeve/idle/blue.png" \
  "$SRC/hat/accessory/cat_ears/idle/brown.png"

# 7. ANALYST SENIOR — female, navy suit, long dark hair, glasses
composite_walk "npc_analyst_senior" \
  "$SRC/body/bodies/female/walk/olive.png" \
  "$SRC/legs/formal/walk/navy.png" \
  "$SRC/torso/clothes/longsleeve/walk/navy.png" \
  "$SRC/hair/bangslong/walk/raven.png"

composite_idle "npc_analyst_senior" \
  "$SRC/body/bodies/female/idle/olive.png" \
  "$SRC/legs/formal/idle/navy.png" \
  "$SRC/torso/clothes/longsleeve/idle/navy.png" \
  "$SRC/hair/bangslong/idle/raven.png"

# 8. HACKER — male, dark hoodie, green visor (headband), hunched
composite_walk "npc_hacker" \
  "$SRC/body/bodies/male/walk/dark.png" \
  "$SRC/legs/pants/walk/black.png" \
  "$SRC/torso/clothes/longsleeve/walk/black.png" \
  "$SRC/hat/headband/headband/walk/green.png" \
  "$SRC/hair/shorthawk/walk/green.png"

composite_idle "npc_hacker" \
  "$SRC/body/bodies/male/idle/dark.png" \
  "$SRC/legs/pants/idle/black.png" \
  "$SRC/torso/clothes/longsleeve/idle/black.png" \
  "$SRC/hat/headband/headband/idle/green.png" \
  "$SRC/hair/shorthawk/idle/green.png"

# 9. ORACLE — old male, purple robe, white beard, wizard hat
composite_walk "npc_oracle" \
  "$SRC/body/bodies/male/walk/light.png" \
  "$SRC/legs/pants/walk/purple.png" \
  "$SRC/torso/clothes/longsleeve/walk/purple.png" \
  "$SRC/hair/balding/walk/white.png" \
  "$SRC/beards/long/walk/white.png" \
  "$SRC/hat/magic/wizard/walk/purple.png"

composite_idle "npc_oracle" \
  "$SRC/body/bodies/male/idle/light.png" \
  "$SRC/legs/pants/idle/purple.png" \
  "$SRC/torso/clothes/longsleeve/idle/purple.png" \
  "$SRC/hair/balding/idle/white.png" \
  "$SRC/beards/long/idle/white.png" \
  "$SRC/hat/magic/wizard/idle/purple.png"

# 10. INTERN — teen, oversized blazer, big eyes, carrying papers
composite_walk "npc_intern" \
  "$SRC/body/bodies/teen/walk/light.png" \
  "$SRC/legs/pants/walk/brown.png" \
  "$SRC/torso/clothes/longsleeve/walk/maroon.png" \
  "$SRC/hair/messy1/walk/brunette.png"

composite_idle "npc_intern" \
  "$SRC/body/bodies/teen/idle/light.png" \
  "$SRC/legs/pants/idle/brown.png" \
  "$SRC/torso/clothes/longsleeve/idle/maroon.png" \
  "$SRC/hair/messy1/idle/brunette.png"

echo ""
echo "=== Generated files ==="
ls -la "$OUT"/*.png 2>/dev/null
echo ""
echo "Total: $(ls "$OUT"/*.png 2>/dev/null | wc -l) sprites"
