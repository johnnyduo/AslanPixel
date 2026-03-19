import { GoogleGenAI } from "@google/genai";
import * as fs from "node:fs";
import * as path from "node:path";

const ai = new GoogleGenAI({ apiKey: process.env.GEMINI_API_KEY ?? "" });

const outputDir = "/Library/WebServer/Documents/AslanPixel/assets/sprites/room_backgrounds";

// Portrait ratio ~9:16 to match mobile phone screens
const rooms = [
  {
    filename: "room_starter.png",
    prompt: "Pixel art top-down RPG room interior, PORTRAIT orientation TALL image (9:16 ratio), dark navy blue wooden floor (#0a1628), cozy trader's room with wooden desk and glowing CRT monitor showing stock charts, bookshelf with finance books, potted plant, warm desk lamp, scattered papers, coffee mug, 16-bit retro game style, no characters, no border, no frame, fill entire image edge to edge, game background asset",
  },
  {
    filename: "room_office.png",
    prompt: "Pixel art top-down RPG room interior, PORTRAIT orientation TALL image (9:16 ratio), dark navy floor (#0a1628), professional trading office with 6 monitors showing candlestick charts in neon green (#00f5a0), dual workstation desk, office chair, city skyline window at night, server rack in corner, whiteboard with market analysis, 16-bit retro game style, no characters, no border, no frame, fill entire image edge to edge, game background asset",
  },
  {
    filename: "room_penthouse.png",
    prompt: "Pixel art top-down RPG room interior, PORTRAIT orientation TALL image (9:16 ratio), dark navy floor (#0a1628), luxury penthouse trading floor, golden furniture (#f5c518), panoramic floor-to-ceiling windows with city skyline, holographic floating displays, cyber purple neon accent lights (#7b2fff), marble accents, expensive rug, mini bar, 16-bit retro game style, no characters, no border, no frame, fill entire image edge to edge, game background asset",
  },
];

for (const room of rooms) {
  console.log(`Generating ${room.filename}...`);
  try {
    const response = await ai.models.generateContent({
      model: "gemini-2.0-flash-preview-image-generation",
      contents: room.prompt,
      config: {
        responseModalities: ["image", "text"],
      },
    });

    const outputPath = path.join(outputDir, room.filename);
    let saved = false;

    for (const part of response.candidates[0].content.parts) {
      if (part.inlineData) {
        const buffer = Buffer.from(part.inlineData.data, "base64");
        fs.writeFileSync(outputPath, buffer);
        const stats = fs.statSync(outputPath);
        console.log(`  Saved: ${outputPath} (${stats.size} bytes)`);
        saved = true;
        break;
      }
    }

    if (!saved) {
      console.log(`  No image data returned for ${room.filename}`);
    }
  } catch (e) {
    console.error(`  Error generating ${room.filename}: ${e.message}`);
  }
}

console.log("Done!");
