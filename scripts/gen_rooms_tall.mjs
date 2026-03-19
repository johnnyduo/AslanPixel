import { GoogleGenAI } from "@google/genai";
import * as fs from "node:fs";
import * as path from "node:path";
import { execSync } from "node:child_process";

const ai = new GoogleGenAI({ apiKey: process.env.GEMINI_API_KEY ?? "" });
const outputDir = "/Library/WebServer/Documents/AslanPixel/assets/sprites/room_backgrounds";
const tmpDir = "/tmp/room_gen";
fs.mkdirSync(tmpDir, { recursive: true });

// Generate 2 images per room: top (furniture) + bottom (floor), then stitch
const rooms = [
  {
    filename: "room_starter.png",
    topPrompt: "Pixel art top-down RPG room interior, dark navy blue wooden parquet floor (#0a1628), cozy trader room with wooden desk, glowing CRT monitor showing green stock charts, bookshelf with books, potted plant, warm desk lamp, coffee mug, papers on desk, 16-bit SNES retro game style, fill entire image, no border, no frame, no margin, game background sprite asset",
    bottomPrompt: "Pixel art top-down RPG room floor continuation, dark navy blue wooden parquet floor (#0a1628), same wood plank pattern, scattered papers, a small rug, wooden crate in corner, boots near door, 16-bit SNES retro game style, fill entire image, no border, no frame, no margin, game background sprite asset, seamless floor texture",
  },
  {
    filename: "room_office.png",
    topPrompt: "Pixel art top-down RPG trading office room, dark navy floor (#0a1628), 6 monitors showing candlestick charts in neon green (#00f5a0), dual desk setup, office chair, city skyline window at night with glowing buildings, server rack, whiteboard, 16-bit SNES retro game style, fill entire image, no border, no frame, no margin, game background sprite asset",
    bottomPrompt: "Pixel art top-down RPG office floor continuation, dark navy floor (#0a1628), clean office carpet pattern, filing cabinet, potted plant, power cables on floor, paper shredder, 16-bit SNES retro game style, fill entire image, no border, no frame, no margin, game background sprite asset, seamless floor",
  },
  {
    filename: "room_penthouse.png",
    topPrompt: "Pixel art top-down RPG luxury penthouse, dark navy floor (#0a1628), golden furniture (#f5c518), panoramic windows with night city skyline, holographic floating displays, cyber purple neon lights (#7b2fff), marble desk, champagne on table, 16-bit SNES retro game style, fill entire image, no border, no frame, no margin, game background sprite asset",
    bottomPrompt: "Pixel art top-down RPG luxury penthouse floor continuation, dark navy marble floor (#0a1628) with gold trim (#f5c518), expensive persian rug, mini bar with bottles, leather sofa, floor lamp, cyber purple accent (#7b2fff), 16-bit SNES retro game style, fill entire image, no border, no frame, no margin, game background sprite asset, seamless floor",
  },
];

async function generateImage(prompt, outputPath) {
  const response = await ai.models.generateContent({
    model: "gemini-2.5-flash-image",
    contents: prompt,
    config: { responseModalities: ["image", "text"] },
  });

  for (const part of response.candidates[0].content.parts) {
    if (part.inlineData) {
      const buffer = Buffer.from(part.inlineData.data, "base64");
      fs.writeFileSync(outputPath, buffer);
      return true;
    }
  }
  return false;
}

for (const room of rooms) {
  console.log(`\n=== Generating ${room.filename} ===`);

  const topPath = path.join(tmpDir, `top_${room.filename}`);
  const bottomPath = path.join(tmpDir, `bottom_${room.filename}`);
  const finalPath = path.join(outputDir, room.filename);

  try {
    // Generate top half (room with furniture)
    console.log("  Generating top half (furniture)...");
    const topOk = await generateImage(room.topPrompt, topPath);
    if (!topOk) { console.log("  FAILED: no image for top"); continue; }

    // Generate bottom half (floor continuation)
    console.log("  Generating bottom half (floor)...");
    const bottomOk = await generateImage(room.bottomPrompt, bottomPath);
    if (!bottomOk) { console.log("  FAILED: no image for bottom"); continue; }

    // Stitch: top + bottom → tall portrait image
    console.log("  Stitching...");
    execSync(`magick ${topPath} ${bottomPath} -append -resize 1024x2048 ${finalPath}`);

    const stats = fs.statSync(finalPath);
    const dims = execSync(`identify -format "%wx%h" ${finalPath}`).toString().trim();
    console.log(`  OK: ${finalPath} (${dims}, ${stats.size} bytes)`);

  } catch (e) {
    console.error(`  Error: ${e.message}`);
  }
}

console.log("\nDone!");
