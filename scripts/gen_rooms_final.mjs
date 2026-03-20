import { GoogleGenAI } from "@google/genai";
import * as fs from "node:fs";
import * as path from "node:path";

const ai = new GoogleGenAI({ apiKey: process.env.GEMINI_API_KEY ?? "" });
const outputDir = "/Library/WebServer/Documents/AslanPixel/assets/sprites/room_backgrounds";

const rooms = [
  {
    filename: "room_starter.png",
    prompt: "Pixel art top-down RPG game room, dark navy blue wooden floor (#0a1628), cozy trader's room filling the entire tall portrait image, top area has wooden desk with glowing CRT monitor showing green stock charts, bookshelf with finance books, potted plant, warm desk lamp, coffee mug, bottom area has dark navy wood floor with small rug, scattered papers, wooden crate, boots near door, 16-bit SNES retro pixel art style, fill entire image edge to edge, no border no frame no margin, game background asset sprite",
  },
  {
    filename: "room_office.png",
    prompt: "Pixel art top-down RPG game room, dark navy floor (#0a1628), professional trading office filling entire tall portrait image, top area has 6 monitors showing green candlestick charts (#00f5a0), dual desk setup, city skyline window at night, bottom area has server racks, potted plants, power cables on floor, filing cabinet, paper shredder, 16-bit SNES retro pixel art style, fill entire image edge to edge, no border no frame no margin, game background asset sprite",
  },
  {
    filename: "room_penthouse.png",
    prompt: "Pixel art top-down RPG game room, dark navy floor (#0a1628), luxury penthouse trading room filling entire tall portrait image, top area has golden furniture (#f5c518), panoramic night city window, holographic displays, cyber purple neon (#7b2fff), marble desk, bottom area has mini bar with bottles, expensive persian rug, leather sofa, floor lamp, 16-bit SNES retro pixel art style, fill entire image edge to edge, no border no frame no margin, game background asset sprite",
  },
  {
    filename: "room_wallstreet_bull.png",
    prompt: "Pixel art top-down RPG game room, dark navy floor (#0a1628), Wall Street bull market trading floor filling entire tall portrait image, top area has golden bull statue centerpiece, green ticker screens everywhere, BUY signs, confetti, celebrating traders, bottom area has trading desks, stacked papers, coffee cups, green screens showing rising charts, 16-bit SNES retro pixel art style, fill entire image edge to edge, no border no frame no margin, game background asset sprite",
  },
  {
    filename: "room_wallstreet_bear.png",
    prompt: "Pixel art top-down RPG game room, dark navy floor (#0a1628), Wall Street bear market trading floor filling entire tall portrait image, gloomy atmosphere, top area has bear statue, red ticker screens, SELL signs, worried traders, bottom area has messy desks, crumpled papers, broken charts showing crash, red warning lights, 16-bit SNES retro pixel art style, fill entire image edge to edge, no border no frame no margin, game background asset sprite",
  },
];

for (const room of rooms) {
  console.log(`Generating ${room.filename}...`);
  try {
    const response = await ai.models.generateContent({
      model: "gemini-3.1-flash-image-preview",
      contents: room.prompt,
      config: {
        responseModalities: ["image", "text"],
        imageGenerationConfig: {
          aspectRatio: "9:16",
        },
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
