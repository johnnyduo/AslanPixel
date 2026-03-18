/**
 * generate_avatars.mjs
 *
 * Generates 8 pixel-art avatar PNGs using Gemini 3.1 Flash Image Preview
 * and saves them to assets/sprites/avatars/
 *
 * Usage:
 *   GEMINI_API_KEY=your_key node scripts/generate_avatars.mjs
 *
 * Requires: @google/genai
 *   npm install @google/genai
 */

import { GoogleGenAI } from '@google/genai';
import { writeFileSync, mkdirSync } from 'fs';
import { join, dirname } from 'path';
import { fileURLToPath } from 'url';

const __dirname = dirname(fileURLToPath(import.meta.url));
const OUTPUT_DIR = join(__dirname, '../assets/sprites/avatars');

// GCP API key — set via env var GEMINI_API_KEY or paste directly
const ai = new GoogleGenAI({ apiKey: process.env.GEMINI_API_KEY ?? '' });

// Aslan Pixel palette: navy #0a1628, neon green #00f5a0, gold #f5c518,
// cyber purple #7b2fff, cyan #00d9ff, red #ff4d4f

const STYLE_BASE = [
  'pixel art character sprite, 64x64 pixels, crisp hard pixel edges, zero anti-aliasing,',
  'full body front-facing RPG game character, dark navy #0a1628 background,',
  'limited neon color palette: neon green #00f5a0, gold #f5c518, cyber purple #7b2fff, cyan #00d9ff,',
  'chunky pixel blocks, retro 16-bit game style, vibrant contrast, no text, no watermark,',
  'centered character with slight padding on all sides',
].join(' ');

const avatars = [
  {
    id: 'A1',
    filename: 'avatar_a1_nexus_front.png',
    prompt: `${STYLE_BASE}, male analyst in dark navy suit, neon green tie, short dark hair, tiny rectangular glasses with cyan lenses, holding glowing holographic tablet, confident upright pose`,
  },
  {
    id: 'A2',
    filename: 'avatar_a2_valen_front.png',
    prompt: `${STYLE_BASE}, male scout in dark hoodie with gold trim details, baseball cap, small backpack with glowing gold straps, sneakers, energetic slightly leaning forward stance`,
  },
  {
    id: 'A3',
    filename: 'avatar_a3_lyra_front.png',
    prompt: `${STYLE_BASE}, female trader in purple blazer with gold buttons, flowing dark hair with single cyan streak, small coin purse in hand, elegant confident pose`,
  },
  {
    id: 'A4',
    filename: 'avatar_a4_sora_front.png',
    prompt: `${STYLE_BASE}, androgynous hacker in dark hoodie with glowing purple circuit line patterns, cyan visor covering eyes, arms crossed, mysterious cool pose`,
  },
  {
    id: 'A5',
    filename: 'avatar_a5_riven_front.png',
    prompt: `${STYLE_BASE}, female social influencer in neon green jacket over dark outfit, colorful hair with pink and cyan pixel streaks, holding glowing smartphone, cheerful waving pose`,
  },
  {
    id: 'A6',
    filename: 'avatar_a6_kai_front.png',
    prompt: `${STYLE_BASE}, male pixel wizard in long purple robe with small gold star pixel patterns, tall pointed hat, holding staff topped with neon green glowing orb, mystical upright pose`,
  },
  {
    id: 'A7',
    filename: 'avatar_a7_specter_front.png',
    prompt: `${STYLE_BASE}, female cyber agent in sleek black bodysuit with cyan circuit line details, short silver hair, thin cyan visor across eyes, utility belt, cool hands-at-sides stance`,
  },
  {
    id: 'A8',
    filename: 'avatar_a8_drako_front.png',
    prompt: `${STYLE_BASE}, male VIP tycoon wearing gold pixel crown, dark red royal cape with gold trim, black formal suit underneath, arms crossed, powerful regal frontal pose`,
  },
];

async function generateAvatar(avatar) {
  console.log(`⏳ Generating ${avatar.id} — ${avatar.filename}...`);

  try {
    const response = await ai.models.generateContent({
      model: 'gemini-3.1-flash-image-preview',
      contents: avatar.prompt,
    });

    let saved = false;
    for (const part of response.candidates[0].content.parts) {
      if (part.inlineData) {
        const buffer = Buffer.from(part.inlineData.data, 'base64');
        const outputPath = join(OUTPUT_DIR, avatar.filename);
        writeFileSync(outputPath, buffer);
        console.log(`  ✅ Saved: ${avatar.filename} (${(buffer.length / 1024).toFixed(1)} KB)`);
        saved = true;
        break;
      }
    }

    if (!saved) {
      const textParts = response.candidates[0].content.parts
        .filter(p => p.text)
        .map(p => p.text)
        .join(' ');
      console.error(`  ❌ No image returned for ${avatar.id}. Response: ${textParts.slice(0, 120)}`);
    }
    return saved;
  } catch (err) {
    console.error(`  ❌ Error generating ${avatar.id}:`, err.message);
    return false;
  }
}

async function main() {
  if (!process.env.GEMINI_API_KEY) {
    console.error('❌ Set your GCP API key:');
    console.error('   export GEMINI_API_KEY=your_gcp_api_key');
    console.error('   then re-run: node scripts/generate_avatars.mjs');
    process.exit(1);
  }

  console.log('🎨 Aslan Pixel — Avatar Generator (Gemini 3.1 Flash Image)');
  console.log(`📁 Output: ${OUTPUT_DIR}\n`);

  mkdirSync(OUTPUT_DIR, { recursive: true });

  let success = 0;
  for (const avatar of avatars) {
    const ok = await generateAvatar(avatar);
    if (ok) success++;
    // Delay to avoid rate limiting
    await new Promise(r => setTimeout(r, 1500));
  }

  console.log(`\n🏁 Done: ${success}/${avatars.length} avatars generated`);
  if (success < avatars.length) {
    console.log('⚠️  Some failed — re-run to retry');
  }
}

main();
