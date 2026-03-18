/**
 * gen_npc_directions.mjs
 *
 * Takes an existing NPC south-facing image and uses Gemini image editing
 * to rotate it to face north, east, west — keeping the same character.
 *
 * Usage:
 *   GEMINI_API_KEY=your_key node scripts/gen_npc_directions.mjs npc_trader
 *   GEMINI_API_KEY=your_key node scripts/gen_npc_directions.mjs  # all NPCs
 *
 * This uses image-to-image (edit) mode, NOT new generation,
 * so character consistency is preserved across directions.
 */

import { GoogleGenAI } from '@google/genai';
import { writeFileSync, readFileSync, existsSync, mkdirSync } from 'fs';
import { join, dirname } from 'path';
import { fileURLToPath } from 'url';

const __dirname = dirname(fileURLToPath(import.meta.url));
const SPRITES_DIR = join(__dirname, '../assets/sprites/npcs');

const API_KEY = process.env.GEMINI_API_KEY ?? '';
if (!API_KEY) { console.error('❌ Set GEMINI_API_KEY'); process.exit(1); }

const ai = new GoogleGenAI({ apiKey: API_KEY });

const ONLY_NPC = process.argv[2] ?? null;

const NPCS = [
  'npc_banker', 'npc_trader', 'npc_champion', 'npc_merchant',
  'npc_sysbot', 'npc_pixelcat', 'npc_analyst_senior',
  'npc_hacker', 'npc_oracle', 'npc_intern',
];

// Direction edit prompts — all reference the input image character
const DIRECTION_EDITS = {
  north: 'Edit this pixel art character sprite: rotate the character to face away from the viewer (back view, facing north/up). Keep identical pixel art style, same colors, same outfit details, same size 48x48. Only change facing direction.',
  east:  'Edit this pixel art character sprite: rotate the character to face right (side profile, facing east/right). Keep identical pixel art style, same colors, same outfit details, same size 48x48. Only change facing direction.',
  west:  'Edit this pixel art character sprite: rotate the character to face left (side profile, facing west/left). Keep identical pixel art style, same colors, same outfit details, same size 48x48. Only change facing direction.',
};

async function sleep(ms) {
  return new Promise(r => setTimeout(r, ms));
}

async function editDirection(sourceImagePath, direction, outputPath) {
  const imageBytes = readFileSync(sourceImagePath);
  const base64 = imageBytes.toString('base64');

  const response = await ai.models.generateContent({
    model: 'gemini-3.1-flash-image-preview',
    contents: [
      {
        parts: [
          {
            inlineData: {
              mimeType: 'image/png',
              data: base64,
            },
          },
          { text: DIRECTION_EDITS[direction] },
        ],
      },
    ],
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

async function processNpc(npcName) {
  // Use south as the reference (front-facing baseline)
  const sourcePath = join(SPRITES_DIR, `${npcName}_south.png`);
  const idlePath = join(SPRITES_DIR, `${npcName}_idle.png`);

  // Find reference image: south > idle > any existing
  let refPath = null;
  if (existsSync(sourcePath)) refPath = sourcePath;
  else if (existsSync(idlePath)) refPath = idlePath;

  if (!refPath) {
    console.log(`  ⏭ ${npcName}: no south/idle reference found, skipping`);
    return;
  }

  console.log(`\n⏳ ${npcName} (ref: ${refPath.split('/').pop()})`);

  for (const dir of ['north', 'east', 'west']) {
    const outPath = join(SPRITES_DIR, `${npcName}_${dir}.png`);

    // Skip if already exists (from PixelLab)
    if (existsSync(outPath)) {
      console.log(`  ✓ ${dir} already exists, skipping`);
      continue;
    }

    try {
      const bytes = await editDirection(refPath, dir, outPath);
      console.log(`  ✅ ${dir} → ${(bytes / 1024).toFixed(1)} KB`);
    } catch (err) {
      console.error(`  ❌ ${dir}: ${err.message}`);
    }

    await sleep(1500);
  }
}

async function main() {
  mkdirSync(SPRITES_DIR, { recursive: true });

  const npcsToProcess = ONLY_NPC ? [ONLY_NPC] : NPCS;

  console.log('🎨 Gemini NPC Direction Generator (image-edit mode)');
  console.log(`📁 ${SPRITES_DIR}`);
  console.log(`👾 Processing: ${npcsToProcess.join(', ')}\n`);

  for (const npcName of npcsToProcess) {
    await processNpc(npcName);
    await sleep(2000);
  }

  console.log('\n🏁 Done');
}

main().catch(console.error);
