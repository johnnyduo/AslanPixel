/**
 * build_room_scene.mjs
 *
 * Merges KayKit GLTF models into a single room scene GLB.
 * Uses @gltf-transform/core to read individual models and compose them.
 *
 * Usage: node scripts/build_room_scene.mjs
 * Output: assets/3d/scenes/trading_room.glb
 */

import { NodeIO, Document } from '@gltf-transform/core';
import { mergeDocuments, flatten } from '@gltf-transform/functions';
import { join } from 'path';
import { mkdirSync } from 'fs';

const BASE = process.cwd();
const OUT_DIR = join(BASE, 'assets/3d/scenes');
mkdirSync(OUT_DIR, { recursive: true });

const io = new NodeIO();

// Room layout: position each furniture piece in the scene
const roomItems = [
  // Desks and work area
  { file: 'furniture/table_medium.gltf', pos: [0, 0, -2], rot: 0, label: 'main_desk' },
  { file: 'furniture/table_small.gltf', pos: [-2, 0, -2], rot: 0, label: 'side_desk' },
  { file: 'furniture/chair_A.gltf', pos: [0, 0, -1], rot: Math.PI, label: 'desk_chair' },

  // Bookshelves
  { file: 'furniture/shelf_B_large_decorated.gltf', pos: [-3, 0, -3], rot: 0, label: 'bookshelf_left' },
  { file: 'furniture/shelf_A_big.gltf', pos: [3, 0, -3], rot: 0, label: 'bookshelf_right' },

  // Seating area
  { file: 'furniture/couch.gltf', pos: [2, 0, 1], rot: -Math.PI/2, label: 'couch' },
  { file: 'furniture/armchair.gltf', pos: [-2, 0, 1], rot: Math.PI/2, label: 'armchair' },
  { file: 'furniture/table_low.gltf', pos: [0, 0, 1], rot: 0, label: 'coffee_table' },

  // Lamps
  { file: 'furniture/lamp_standing.gltf', pos: [-3, 0, 1], rot: 0, label: 'lamp' },
  { file: 'furniture/lamp_table.gltf', pos: [0.5, 0.7, -2], rot: 0, label: 'desk_lamp' },

  // Decorations
  { file: 'furniture/rug_rectangle_A.gltf', pos: [0, 0, 0], rot: 0, label: 'rug' },
  { file: 'furniture/cactus_medium_A.gltf', pos: [3, 0, -1], rot: 0, label: 'plant' },
  { file: 'furniture/book_set.gltf', pos: [-0.5, 0.7, -2], rot: 0.3, label: 'books' },

  // Wall art
  { file: 'furniture/pictureframe_large_A.gltf', pos: [0, 1.5, -3.4], rot: 0, label: 'frame_center' },
  { file: 'furniture/pictureframe_small_A.gltf', pos: [-1.5, 1.5, -3.4], rot: 0, label: 'frame_left' },

  // Resources / Trading props
  { file: 'resources/Gold_Bars.gltf', pos: [1, 0.7, -2], rot: 0.2, label: 'gold_bars' },
  { file: 'resources/Silver_Bars.gltf', pos: [-1, 0.7, -1.8], rot: -0.1, label: 'silver_bars' },

  // Coins on desk
  { file: 'prototype/Coin_A.gltf', pos: [0.3, 0.75, -1.8], rot: 0, label: 'coin_1' },
  { file: 'prototype/Coin_B.gltf', pos: [0.5, 0.75, -1.9], rot: 0.5, label: 'coin_2' },

  // Floor base
  { file: 'prototype/Floor.gltf', pos: [0, -0.01, 0], rot: 0, label: 'floor' },
];

// Character to place in center
const characterFile = 'characters/Knight.glb';

async function buildScene() {
  console.log('Building trading room scene...');

  // Create a new document for the combined scene
  const sceneDoc = await io.read(join(BASE, 'assets/3d', characterFile));
  const sceneRoot = sceneDoc.getRoot();
  const scene = sceneRoot.listScenes()[0];

  // Position the character
  const charNode = sceneRoot.listNodes()[0];
  if (charNode) {
    charNode.setTranslation([0, 0, 0]);
    charNode.setName('character_knight');
  }

  let loaded = 0;
  let failed = 0;

  for (const item of roomItems) {
    const filePath = join(BASE, 'assets/3d', item.file);
    try {
      const itemDoc = await io.read(filePath);
      const itemRoot = itemDoc.getRoot();

      // Merge the item document into the scene document
      await mergeDocuments(sceneDoc, itemDoc);

      loaded++;
      console.log(`  ✓ ${item.label} (${item.file})`);
    } catch (e) {
      failed++;
      console.log(`  ✗ ${item.label} — ${e.message}`);
    }
  }

  // Merge all buffers into one (required for GLB export)
  const root = sceneDoc.getRoot();
  const buffers = root.listBuffers();
  if (buffers.length > 1) {
    const keepBuffer = buffers[0];
    for (let i = 1; i < buffers.length; i++) {
      const buf = buffers[i];
      // Move all accessors from this buffer to the first buffer
      for (const accessor of root.listAccessors()) {
        if (accessor.getBuffer() === buf) {
          accessor.setBuffer(keepBuffer);
        }
      }
      buf.dispose();
    }
  }

  // Write the combined scene
  const outPath = join(OUT_DIR, 'trading_room.glb');
  await io.write(outPath, sceneDoc);

  console.log(`\nDone! ${loaded} items loaded, ${failed} failed`);
  console.log(`Output: ${outPath}`);
}

buildScene().catch(e => {
  console.error('Build failed:', e.message);
  process.exit(1);
});
