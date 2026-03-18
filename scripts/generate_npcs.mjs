/**
 * generate_npcs.mjs
 *
 * Generates 10 NPC pixel art characters via PixelLab API v2
 * with walking animations, then downloads sprite sheets to
 * assets/sprites/npcs/
 *
 * Usage:
 *   PIXELLAB_API_KEY=your_key node scripts/generate_npcs.mjs
 *
 * API key: get from https://pixellab.ai/account
 */

import { writeFileSync, mkdirSync } from 'fs';
import { join, dirname } from 'path';
import { fileURLToPath } from 'url';

const __dirname = dirname(fileURLToPath(import.meta.url));
const OUTPUT_DIR = join(__dirname, '../assets/sprites/npcs');
const BASE_URL = 'https://api.pixellab.ai/v2';
const API_KEY = process.env.PIXELLAB_API_KEY ?? '6df734b9-17ed-4cbd-b6be-b615dd3de1fd';

const headers = {
  'Authorization': `Bearer ${API_KEY}`,
  'Content-Type': 'application/json',
};

// 10 NPCs matching our game design
// Aslan Pixel color theme: navy, neon green, gold, cyber purple, cyan
const npcs = [
  {
    filename: 'npc_banker',
    description: 'elderly banker in dark navy pinstripe suit, gold pocket watch, round glasses, white hair, serious expression, pixel art RPG style',
    proportions: 'realistic_male',
    size: 48,
    view: 'low top-down',
  },
  {
    filename: 'npc_trader',
    description: 'energetic young male stock trader in white shirt with rolled sleeves, cyan tie, holding papers, spiky dark hair, confident grin',
    proportions: 'stylized',
    size: 48,
    view: 'low top-down',
  },
  {
    filename: 'npc_champion',
    description: 'female champion investor in gold armor with cyber purple cape, short silver hair, holding glowing trophy, heroic stance',
    proportions: 'heroic',
    size: 48,
    view: 'low top-down',
  },
  {
    filename: 'npc_merchant',
    description: 'chubby friendly merchant in green robe with gold coins embroidered, large backpack, warm smile, bald with beard',
    proportions: 'cartoon',
    size: 48,
    view: 'low top-down',
  },
  {
    filename: 'npc_sysbot',
    description: 'cute robot NPC with boxy navy blue body, glowing neon green visor eyes, small antenna, rounded joints, friendly pixel art style',
    proportions: 'chibi',
    size: 48,
    view: 'low top-down',
  },
  {
    filename: 'npc_pixelcat',
    description: 'small pixel art cat with cyan fur, gold collar with coin pendant, big bright eyes, fluffy tail, cute chibi proportions',
    body_type: 'quadruped',
    template: 'cat',
    proportions: 'default',
    size: 48,
    view: 'low top-down',
  },
  {
    filename: 'npc_analyst_senior',
    description: 'senior female analyst in dark suit with cyber purple accent trim, long dark hair, holographic tablet in hand, focused serious look',
    proportions: 'realistic_female',
    size: 48,
    view: 'low top-down',
  },
  {
    filename: 'npc_hacker',
    description: 'mysterious hacker in dark hoodie with glowing circuit patterns, face hidden by neon green pixel mask, hunched posture',
    proportions: 'stylized',
    size: 48,
    view: 'low top-down',
  },
  {
    filename: 'npc_oracle',
    description: 'mystical oracle in flowing purple and gold robes, long white beard, staff topped with glowing cyan crystal ball, wise expression',
    proportions: 'default',
    size: 48,
    view: 'low top-down',
  },
  {
    filename: 'npc_intern',
    description: 'young enthusiastic intern in oversized navy blazer, round chibi head, big hopeful eyes, carrying stack of papers, chibi proportions',
    proportions: 'chibi',
    size: 48,
    view: 'low top-down',
  },
];

async function sleep(ms) {
  return new Promise(r => setTimeout(r, ms));
}

async function createCharacter(npc) {
  const body = {
    description: npc.description,
    n_directions: 4,
    size: npc.size,
    view: npc.view,
    proportions: { type: 'preset', name: npc.proportions ?? 'default' },
    shading: { type: 'basic' },
    detail: { type: 'medium' },
  };

  if (npc.body_type === 'quadruped') {
    body.body_type = 'quadruped';
    body.template = npc.template;
  }

  const res = await fetch(`${BASE_URL}/characters`, {
    method: 'POST',
    headers,
    body: JSON.stringify(body),
  });

  if (!res.ok) {
    const err = await res.text();
    throw new Error(`Create failed (${res.status}): ${err}`);
  }

  const data = await res.json();
  return data.data?.character_id ?? data.id ?? data.character_id;
}

async function animateCharacter(characterId) {
  const body = {
    character_id: characterId,
    template_animation_id: 'walking',
    action_description: 'walking naturally',
    confirm_cost: true,
  };

  const res = await fetch(`${BASE_URL}/characters/${characterId}/animations`, {
    method: 'POST',
    headers,
    body: JSON.stringify(body),
  });

  if (!res.ok) {
    const err = await res.text();
    throw new Error(`Animate failed (${res.status}): ${err}`);
  }
  return true;
}

async function pollCharacter(characterId, maxWaitMs = 5 * 60 * 1000) {
  const start = Date.now();
  while (Date.now() - start < maxWaitMs) {
    const res = await fetch(`${BASE_URL}/characters/${characterId}?include_preview=true`, { headers });
    if (!res.ok) throw new Error(`Poll failed (${res.status})`);

    const data = await res.json();
    const char = data.data ?? data;

    if (char.status === 'completed' || char.status === 'ready') {
      return char;
    }
    if (char.status === 'failed') {
      throw new Error(`Character generation failed for ${characterId}`);
    }

    process.stdout.write('.');
    await sleep(8000); // poll every 8s
  }
  throw new Error(`Timeout waiting for character ${characterId}`);
}

async function downloadZip(characterId, filename) {
  const res = await fetch(`${BASE_URL}/characters/${characterId}/download`, { headers });
  if (!res.ok) throw new Error(`Download failed (${res.status})`);

  const buffer = Buffer.from(await res.arrayBuffer());
  const outPath = join(OUTPUT_DIR, `${filename}.zip`);
  writeFileSync(outPath, buffer);
  return outPath;
}

async function generateNpc(npc) {
  console.log(`\n⏳ [${npc.filename}] Creating character...`);

  // Step 1: Create
  const characterId = await createCharacter(npc);
  console.log(`   character_id: ${characterId}`);

  // Step 2: Wait for character to be ready
  process.stdout.write('   Generating');
  const char = await pollCharacter(characterId);
  console.log(' ✓');

  // Step 3: Queue walk animation
  console.log(`   Queuing walk animation...`);
  try {
    await animateCharacter(characterId);
    console.log(`   Animation queued ✓`);
  } catch (e) {
    console.warn(`   Animation skipped: ${e.message}`);
  }

  // Step 4: Download ZIP (contains all directions + frames)
  const zipPath = await downloadZip(characterId, npc.filename);
  console.log(`   ✅ Saved: ${npc.filename}.zip (${(require('fs').statSync(zipPath).size / 1024).toFixed(1)} KB)`);

  return characterId;
}

async function main() {
  if (!API_KEY) {
    console.error('❌ Set PIXELLAB_API_KEY env var');
    process.exit(1);
  }

  console.log('🎨 Aslan Pixel — NPC Generator (PixelLab API v2)');
  console.log(`📁 Output: ${OUTPUT_DIR}`);
  console.log(`👾 Generating ${npcs.length} NPCs with walk animations...\n`);

  mkdirSync(OUTPUT_DIR, { recursive: true });

  // Check balance first
  try {
    const balRes = await fetch(`${BASE_URL}/balance`, { headers });
    if (balRes.ok) {
      const bal = await balRes.json();
      console.log(`💰 Balance: ${JSON.stringify(bal.data ?? bal)}\n`);
    }
  } catch (_) {}

  const results = [];
  for (const npc of npcs) {
    try {
      const id = await generateNpc(npc);
      results.push({ filename: npc.filename, id, status: 'ok' });
    } catch (err) {
      console.error(`\n   ❌ ${npc.filename}: ${err.message}`);
      results.push({ filename: npc.filename, id: null, status: 'failed', error: err.message });
    }
    // Small delay between requests to avoid rate limiting
    await sleep(2000);
  }

  console.log('\n\n📊 Summary:');
  for (const r of results) {
    const icon = r.status === 'ok' ? '✅' : '❌';
    console.log(`  ${icon} ${r.filename}${r.id ? ` → ${r.id}` : ` (${r.error})`}`);
  }

  const ok = results.filter(r => r.status === 'ok').length;
  console.log(`\n🏁 Done: ${ok}/${npcs.length} NPCs generated`);
  console.log('📦 Unzip each .zip to get individual direction PNGs + sprite sheets');
}

main().catch(console.error);
