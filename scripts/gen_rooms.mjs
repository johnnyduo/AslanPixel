import { GoogleGenAI } from "@google/genai";
import * as fs from "node:fs";
import * as path from "node:path";

const ai = new GoogleGenAI({ apiKey: process.env.GEMINI_API_KEY ?? "" });

const outputDir = "/Library/WebServer/Documents/AslanPixel/assets/sprites/room_backgrounds";

const rooms = [
  {
    filename: "room_starter.png",
    prompt: "Small cozy pixel art top-down room, dark navy blue floor (#0a1628), wooden desk with glowing monitor, small bookshelf, single plant, warm lamp light, 16-bit RPG style, 400x400px, no characters, game asset background, viewed from above at isometric or top-down angle",
  },
  {
    filename: "room_office.png",
    prompt: "Medium pixel art top-down office room, dark navy floor (#0a1628), multiple monitors showing stock charts, neon green glowing screens (#00f5a0), trading workstation setup, city window view at night, 16-bit RPG style, 400x400px, no characters, game asset background, viewed from above at isometric or top-down angle",
  },
  {
    filename: "room_penthouse.png",
    prompt: "Large luxurious pixel art top-down penthouse room, dark navy floor (#0a1628), golden furniture (#f5c518), panoramic city skyline window, holographic displays, cyber purple accent lights (#7b2fff), 16-bit RPG style, 400x400px, no characters, game asset background, viewed from above at isometric or top-down angle",
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
      console.log("  Response parts:", JSON.stringify(response.candidates[0].content.parts.map(p => ({ type: p.text ? "text" : p.inlineData ? "inlineData" : "unknown", textSnippet: p.text?.slice(0, 100) })), null, 2));
    }
  } catch (err) {
    console.error(`  Error generating ${room.filename}:`, err.message);
    if (err.response) {
      console.error("  Response:", JSON.stringify(err.response, null, 2));
    }
  }
}

console.log("\nDone.");
