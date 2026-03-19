// ignore_for_file: avoid_print
/// Generates 4-frame walk animation sprites from static directional PNGs.
///
/// Classic 8-bit RPG walk technique:
///   Frame 1: original (neutral)
///   Frame 2: shift down 1px + shift left 1px  (left foot forward)
///   Frame 3: original (neutral, passing)
///   Frame 4: shift down 1px + shift right 1px (right foot forward)
///
/// Usage: dart run scripts/gen_walk_frames.dart
///
/// Input:  assets/sprites/npcs/npc_{name}_{dir}.png  (48×48)
/// Output: assets/sprites/npcs/npc_{name}_{dir}_walk{1-4}.png

import 'dart:io';
import 'package:image/image.dart' as img;

const npcs = [
  'npc_banker',
  'npc_trader',
  'npc_champion',
  'npc_merchant',
  'npc_sysbot',
  'npc_pixelcat',
  'npc_analyst_senior',
  'npc_hacker',
  'npc_oracle',
  'npc_intern',
];

const directions = ['south', 'north', 'east', 'west'];

void main() {
  var totalGenerated = 0;
  var totalSkipped = 0;

  for (final npc in npcs) {
    for (final dir in directions) {
      final srcPath = 'assets/sprites/npcs/${npc}_$dir.png';
      final srcFile = File(srcPath);

      if (!srcFile.existsSync()) {
        print('  SKIP $srcPath (not found)');
        totalSkipped++;
        continue;
      }

      final bytes = srcFile.readAsBytesSync();
      final original = img.decodePng(bytes);
      if (original == null) {
        print('  SKIP $srcPath (decode failed)');
        totalSkipped++;
        continue;
      }

      final w = original.width;
      final h = original.height;

      // Frame 1: original (neutral stance)
      final frame1 = img.Image.from(original);

      // Frame 2: shift down 1px + left 1px (left foot step)
      final frame2 = _shiftImage(original, dx: -1, dy: 1);

      // Frame 3: original again (passing through neutral)
      final frame3 = img.Image.from(original);

      // Frame 4: shift down 1px + right 1px (right foot step)
      final frame4 = _shiftImage(original, dx: 1, dy: 1);

      final frames = [frame1, frame2, frame3, frame4];
      for (var i = 0; i < frames.length; i++) {
        final outPath = 'assets/sprites/npcs/${npc}_${dir}_walk${i + 1}.png';
        File(outPath).writeAsBytesSync(img.encodePng(frames[i]));
      }

      totalGenerated += 4;
      print('  OK ${npc}_$dir → 4 walk frames ($w×$h)');
    }
  }

  print('\nDone! Generated: $totalGenerated frames, Skipped: $totalSkipped');
}

/// Shifts an image by [dx, dy] pixels, filling empty space with transparent.
img.Image _shiftImage(img.Image src, {required int dx, required int dy}) {
  final w = src.width;
  final h = src.height;
  final dst = img.Image(width: w, height: h, numChannels: 4);

  // Fill with transparent
  for (var y = 0; y < h; y++) {
    for (var x = 0; x < w; x++) {
      dst.setPixelRgba(x, y, 0, 0, 0, 0);
    }
  }

  // Copy shifted pixels
  for (var y = 0; y < h; y++) {
    for (var x = 0; x < w; x++) {
      final sx = x - dx;
      final sy = y - dy;
      if (sx >= 0 && sx < w && sy >= 0 && sy < h) {
        final pixel = src.getPixel(sx, sy);
        dst.setPixel(x, y, pixel);
      }
    }
  }

  return dst;
}
