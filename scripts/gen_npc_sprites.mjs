/**
 * gen_npc_sprites.mjs
 *
 * Generates NPC pixel-art sprites using Gemini gemini-2.0-flash-preview-image-generation
 * Each NPC gets 4 directional idle frames (south/north/east/west)
 * Optionally generates a 4-frame walk cycle per direction (set WALK=1)
 *
 * Usage:
 *   GEMINI_API_KEY=your_key node scripts/gen_npc_sprites.mjs
 *   GEMINI_API_KEY=your_key WALK=1 node scripts/gen_npc_sprites.mjs   # + walk frames
 *   GEMINI_API_KEY=your_key NPC=npc_banker node scripts/gen_npc_sprites.mjs  # single NPC
 *
 * Output: assets/sprites/npcs/{npc_name}_{direction}.png
 *         assets/sprites/npcs/{npc_name}_{direction}_walk{1-4}.png  (if WALK=1)
 */

import { GoogleGenAI } from '@google/genai';
import { writeFileSync, mkdirSync } from 'fs';
import { join, dirname } from 'path';
import { fileURLToPath } from 'url';

const __dirname = dirname(fileURLToPath(import.meta.url));
const OUTPUT_DIR = join(__dirname, '../assets/sprites/npcs');

const API_KEY = process.env.GEMINI_API_KEY ?? '';
const ONLY_NPC = process.env.NPC ?? null;
const GEN_WALK = process.env.WALK === '1';

if (!API_KEY) {
  console.error('❌ Set GEMINI_API_KEY env var');
  process.exit(1);
}

const ai = new GoogleGenAI({ apiKey: API_KEY });

// ---------------------------------------------------------------------------
// Shared style prefix
// ---------------------------------------------------------------------------
const STYLE = [
  'pixel art character sprite, exactly 48x48 pixels, crisp hard pixel edges, zero anti-aliasing,',
  'top-down RPG view, dark navy #0a1628 transparent-style background,',
  'limited palette: neon green #00f5a0, gold #f5c518, cyber purple #7b2fff, cyan #4fc3f7, white, dark grey,',
  'chunky pixel blocks, retro 16-bit RPG style, no text, no watermark, no border,',
  'single character centered with padding, no shadow',
].join(' ');

// Direction modifiers
const DIR_PROMPTS = {
  south: 'facing viewer directly, front view, walking toward camera',
  north: 'facing away from viewer, back view, walking away from camera',
  east: 'facing right side, profile right, walking right',
  west: 'facing left side, profile left, walking left',
};

// Walk frame modifiers (relative to idle pose)
const WALK_FRAMES = [
  'idle standing pose, weight evenly distributed',
  'mid-stride left foot forward, right arm back',
  'standing transition, feet together',
  'mid-stride right foot forward, left arm back',
];

// ---------------------------------------------------------------------------
// NPC definitions
// ---------------------------------------------------------------------------
const NPCS = [
  {
    name: 'npc_banker',
    base: 'elderly banker in dark navy pinstripe suit, gold pocket watch chain visible, round wire glasses, white neatly combed hair, serious stern expression',
  },
  {
    name: 'npc_trader',
    base: 'energetic young male stock trader in white shirt with rolled sleeves, cyan tie loosened, holding papers in one hand, spiky dark hair, confident grin',
  },
  {
    name: 'npc_champion',
    base: 'female champion investor in gleaming gold armor breastplate, cyber purple cape flowing behind, short silver hair, holding small glowing gold trophy, heroic upright stance',
  },
  {
    name: 'npc_merchant',
    base: 'chubby friendly merchant in green robe with small gold coin patterns embroidered, large brown backpack, warm smile, bald head with short brown beard',
  },
  {
    name: 'npc_sysbot',
    base: 'cute boxy robot with navy blue square body, glowing neon green LED visor eyes, small antenna on top, rounded arm joints, friendly chibi proportions',
  },
  {
    name: 'npc_pixelcat',
    base: 'small cute cat with cyan fur, round chibi body, gold coin collar pendant, big bright circular eyes, short fluffy tail, quadruped cat shape',
  },
  {
    name: 'npc_analyst_senior',
    base: 'senior female analyst in dark navy jacket with subtle cyber purple shoulder trim, long straight dark hair, holding holographic glowing tablet, focused concentrated expression',
  },
  {
    name: 'npc_hacker',
    base: 'mysterious figure in dark charcoal hoodie with glowing neon green circuit line patterns, face hidden by pixelated green dot-matrix mask, slightly hunched posture',
  },
  {
    name: 'npc_oracle',
    base: 'mystical oracle in flowing purple and gold layered robes, long white flowing beard, tall wooden staff with glowing cyan crystal orb on top, wise serene expression',
  },
  {
    name: 'npc_intern',
    base: 'young enthusiastic intern in oversized navy blazer, chibi round head and large hopeful eyes, carrying tall wobbly stack of papers, slightly nervous excited expression',
  },
];

// ---------------------------------------------------------------------------
// Gemini image generation
// ---------------------------------------------------------------------------
async function generateImage(prompt, outputPath) {
  const response = await ai.models.generateContent({
    model: 'gemini-3.1-flash-image-preview',
    contents: prompt,
    config: {
      responseModalities: ['IMAGE', 'TEXT'],
    },
  });

  for (const part of response.candidates[0].content.parts) {
    if (part.inlineData) {
      const buffer = Buffer.from(part.inlineData.data, 'base64');
      writeFileSync(outputPath, buffer);
      return buffer.length;
    }
  }
  throw new Error('No image in response');
}

async function sleep(ms) {
  return new Promise(r => setTimeout(r, ms));
}

// ---------------------------------------------------------------------------
// Generate one NPC
// ---------------------------------------------------------------------------
async function generateNpc(npc) {
  const results = [];

  for (const [dir, dirPrompt] of Object.entries(DIR_PROMPTS)) {
    // Idle / directional sprite
    const idlePrompt = `${STYLE}, ${npc.base}, ${dirPrompt}, idle standing`;
    const idlePath = join(OUTPUT_DIR, `${npc.name}_${dir}.png`);

    try {
      const bytes = await generateImage(idlePrompt, idlePath);
      console.log(`  ✅ ${npc.name}_${dir}.png (${(bytes / 1024).toFixed(1)} KB)`);
      results.push({ file: `${npc.name}_${dir}`, ok: true });
    } catch (err) {
      console.error(`  ❌ ${npc.name}_${dir}: ${err.message}`);
      results.push({ file: `${npc.name}_${dir}`, ok: false });
    }

    await sleep(1200); // rate limit

    // Walk frames
    if (GEN_WALK) {
      for (let i = 0; i < WALK_FRAMES.length; i++) {
        const walkPrompt = `${STYLE}, ${npc.base}, ${dirPrompt}, ${WALK_FRAMES[i]}`;
        const walkPath = join(OUTPUT_DIR, `${npc.name}_${dir}_walk${i + 1}.png`);
        try {
          const bytes = await generateImage(walkPrompt, walkPath);
          console.log(`     walk${i + 1} ✅ (${(bytes / 1024).toFixed(1)} KB)`);
        } catch (err) {
          console.error(`     walk${i + 1} ❌ ${err.message}`);
        }
        await sleep(1200);
      }
    }
  }

  // Also generate idle (south alias)
  const idleSrcPath = join(OUTPUT_DIR, `${npc.name}_south.png`);
  const idleDestPath = join(OUTPUT_DIR, `${npc.name}_idle.png`);
  try {
    const { copyFileSync } = await import('fs');
    copyFileSync(idleSrcPath, idleDestPath);
    console.log(`  📋 ${npc.name}_idle.png (copied from south)`);
  } catch (_) {}

  return results;
}

// ---------------------------------------------------------------------------
// Main
// ---------------------------------------------------------------------------
async function main() {
  console.log('🎨 Aslan Pixel — Gemini NPC Sprite Generator');
  console.log(`📁 Output: ${OUTPUT_DIR}`);
  console.log(`🚶 Walk frames: ${GEN_WALK ? 'YES (4 frames/direction)' : 'NO (idle only)'}\n`);

  mkdirSync(OUTPUT_DIR, { recursive: true });

  const npcsToGen = ONLY_NPC
    ? NPCS.filter(n => n.name === ONLY_NPC)
    : NPCS;

  if (npcsToGen.length === 0) {
    console.error(`❌ NPC "${ONLY_NPC}" not found`);
    process.exit(1);
  }

  let totalOk = 0;
  let totalFail = 0;

  for (const npc of npcsToGen) {
    console.log(`\n⏳ Generating ${npc.name} (${GEN_WALK ? '16' : '4'} images)...`);
    const results = await generateNpc(npc);
    totalOk += results.filter(r => r.ok).length;
    totalFail += results.filter(r => !r.ok).length;
    await sleep(2000);
  }

  console.log(`\n🏁 Done: ${totalOk} OK, ${totalFail} failed`);
  console.log('💡 Tip: Use NPC=npc_banker to regenerate a single NPC');
  console.log('💡 Tip: Use WALK=1 to add 4-frame walk cycles (uses more API quota)');
}

main().catch(console.error);
