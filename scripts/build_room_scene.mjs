/**
 * build_room_scene.mjs — v2
 *
 * Merges KayKit GLB models into a positioned room scene.
 * Each item gets proper translation so the room looks correct.
 */

import { NodeIO, Document } from '@gltf-transform/core';
import { mergeDocuments } from '@gltf-transform/functions';
import { join } from 'path';
import { mkdirSync } from 'fs';

const BASE = process.cwd();
const OUT_DIR = join(BASE, 'assets/3d/scenes');
mkdirSync(OUT_DIR, { recursive: true });

const io = new NodeIO();

// Room layout with positions [x, y, z] and scale
const roomItems = [
  // Floor
  { file: 'prototype/Floor.glb', pos: [0, 0, 0], scale: 3.0 },

  // Main desk area (back wall)
  { file: 'furniture/table_medium.glb', pos: [0, 0, -2.5] },
  { file: 'furniture/chair_A.glb', pos: [0, 0, -1.2] },

  // Side desk
  { file: 'furniture/table_small.glb', pos: [-2.5, 0, -2.5] },

  // Bookshelves (back corners)
  { file: 'furniture/shelf_B_large_decorated.glb', pos: [-3.5, 0, -3.0] },
  { file: 'furniture/shelf_A_big.glb', pos: [3.5, 0, -3.0] },

  // Seating area (front)
  { file: 'furniture/couch.glb', pos: [2.0, 0, 1.5] },
  { file: 'furniture/armchair.glb', pos: [-2.0, 0, 1.5] },
  { file: 'furniture/table_low.glb', pos: [0, 0, 1.5] },

  // Decorations
  { file: 'furniture/lamp_standing.glb', pos: [-3.5, 0, 1.0] },
  { file: 'furniture/lamp_table.glb', pos: [0.8, 0.65, -2.5] },
  { file: 'furniture/rug_rectangle_A.glb', pos: [0, 0, 0] },
  { file: 'furniture/cactus_medium_A.glb', pos: [3.5, 0, -1.0] },
  { file: 'furniture/book_set.glb', pos: [-0.5, 0.65, -2.5] },

  // Wall art
  { file: 'furniture/pictureframe_large_A.glb', pos: [0, 2.0, -3.8] },

  // Trading props
  { file: 'resources/Gold_Bars.glb', pos: [1.2, 0.65, -2.3] },
  { file: 'prototype/Coin_A.glb', pos: [0.3, 0.7, -2.0] },
  { file: 'prototype/Coin_B.glb', pos: [-0.3, 0.7, -2.1] },

  // Cabinets (sides)
  { file: 'furniture/cabinet_medium.glb', pos: [-3.5, 0, -1.0] },
  { file: 'furniture/cabinet_small.glb', pos: [3.5, 0, 1.5] },
];

async function buildScene() {
  console.log('Building trading room scene v2...');

  // Start with empty document from first item
  const firstItem = roomItems[0];
  const sceneDoc = await io.read(join(BASE, 'assets/3d', firstItem.file));

  // Position the first item's root nodes
  const firstRoot = sceneDoc.getRoot();
  for (const node of firstRoot.listNodes()) {
    if (!node.listChildren().length && node.getMesh()) {
      node.setTranslation(firstItem.pos);
      if (firstItem.scale) node.setScale([firstItem.scale, firstItem.scale, firstItem.scale]);
    }
  }

  let loaded = 1;
  console.log(`  ✓ ${firstItem.file}`);

  for (let i = 1; i < roomItems.length; i++) {
    const item = roomItems[i];
    const filePath = join(BASE, 'assets/3d', item.file);
    try {
      const itemDoc = await io.read(filePath);

      // Set position on root nodes before merging
      const itemRoot = itemDoc.getRoot();
      for (const node of itemRoot.listNodes()) {
        // Only transform root-level mesh nodes
        if (node.getMesh() || node.listChildren().length > 0) {
          const current = node.getTranslation();
          node.setTranslation([
            current[0] + item.pos[0],
            current[1] + item.pos[1],
            current[2] + item.pos[2],
          ]);
          if (item.scale) {
            node.setScale([item.scale, item.scale, item.scale]);
          }
        }
      }

      await mergeDocuments(sceneDoc, itemDoc);
      loaded++;
      console.log(`  ✓ ${item.file} @ [${item.pos}]`);
    } catch (e) {
      console.log(`  ✗ ${item.file} — ${e.message}`);
    }
  }

  // Merge all buffers into one (required for GLB)
  const root = sceneDoc.getRoot();
  const buffers = root.listBuffers();
  if (buffers.length > 1) {
    const keepBuffer = buffers[0];
    for (let i = 1; i < buffers.length; i++) {
      const buf = buffers[i];
      for (const accessor of root.listAccessors()) {
        if (accessor.getBuffer() === buf) {
          accessor.setBuffer(keepBuffer);
        }
      }
      buf.dispose();
    }
  }

  const outPath = join(OUT_DIR, 'trading_room.glb');
  await io.write(outPath, sceneDoc);

  const { statSync } = await import('fs');
  const size = Math.round(statSync(outPath).size / 1024);
  console.log(`\nDone! ${loaded} items, output: ${outPath} (${size}KB)`);
}

buildScene().catch(e => {
  console.error('Build failed:', e.message);
  process.exit(1);
});
