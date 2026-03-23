#!/usr/bin/env node
/**
 * AslanGuild Asset Generator
 * Generates pixel art images using Gemini Imagen API
 * Usage: node scripts/gen-assets.mjs [--map] [--favicon] [--all]
 */

import { execSync } from "child_process";
import { writeFileSync, mkdirSync } from "fs";
import { join, dirname } from "path";
import { fileURLToPath } from "url";

const __dirname = dirname(fileURLToPath(import.meta.url));
const ROOT = join(__dirname, "..");
const ASSETS = join(ROOT, "public", "assets");
mkdirSync(ASSETS, { recursive: true });

function getSecret(name) {
  return execSync(
    `gcloud secrets versions access latest --secret=${name} --project=aslanwealth-platform-32812`,
    { encoding: "utf8" }
  ).trim();
}

async function generateImage(prompt, outputPath, options = {}) {
  const apiKey = getSecret("GOOGLE_CLOUD_API_KEY");
  const model = options.model || "imagen-4.0-fast-generate-001";
  const url = `https://generativelanguage.googleapis.com/v1beta/models/${model}:predict?key=${apiKey}`;

  const payload = {
    instances: [{ prompt }],
    parameters: {
      sampleCount: 1,
      aspectRatio: options.aspectRatio || "16:9",
    },
  };

  const res = await fetch(url, {
    method: "POST",
    headers: { "Content-Type": "application/json" },
    body: JSON.stringify(payload),
  });

  if (!res.ok) {
    const err = await res.text();
    throw new Error(`Imagen API error ${res.status}: ${err}`);
  }

  const data = await res.json();
  const b64 = data.predictions[0].bytesBase64Encoded;
  const buf = Buffer.from(b64, "base64");
  writeFileSync(outputPath, buf);
  console.log(`✓ Saved ${outputPath} (${(buf.length / 1024).toFixed(0)}KB)`);
  return outputPath;
}

const PROMPTS = {
  "map-bg": {
    prompt:
      "pixel art top-down view office guild hall map, dark navy blue floor, glowing neon cyan and gold room borders, 6 rooms connected by corridors: central town square with office desks, guild hall command center, vault room with safe, strategy tower with maps, market trading floor, archive library with bookshelves, 16-bit retro RPG style, clean pixel art, corporate fantasy aesthetic, dark moody atmosphere",
    outputPath: join(ASSETS, "map-bg.png"),
    aspectRatio: "16:9",
  },
  "map-bg-wide": {
    prompt:
      "pixel art isometric guild office city exterior, neon-lit skyscraper with 'ASLAN GUILD' sign, multiple district buildings, trading district, archive district, market plaza, dark cyberpunk-fantasy pixel art, 16-bit SNES style, gold and cyan neon lights on dark navy",
    outputPath: join(ASSETS, "map-bg-city.png"),
    aspectRatio: "16:9",
  },
  splash: {
    prompt:
      "epic pixel art illustration of a glowing lion head shield logo, gold and cyan colors, dark navy background, 16-bit style, guild emblem, fantasy RPG, detailed pixel shading",
    outputPath: join(ASSETS, "splash.png"),
    aspectRatio: "1:1",
  },
};

async function main() {
  const args = process.argv.slice(2);
  const targets =
    args.includes("--all")
      ? Object.keys(PROMPTS)
      : args.length === 0
      ? ["map-bg"]
      : args.map((a) => a.replace("--", ""));

  for (const target of targets) {
    const cfg = PROMPTS[target];
    if (!cfg) {
      console.error(`Unknown target: ${target}. Available: ${Object.keys(PROMPTS).join(", ")}`);
      continue;
    }
    console.log(`Generating ${target}...`);
    try {
      await generateImage(cfg.prompt, cfg.outputPath, { aspectRatio: cfg.aspectRatio });
    } catch (e) {
      console.error(`✗ Failed: ${e.message}`);
    }
  }
}

main();
