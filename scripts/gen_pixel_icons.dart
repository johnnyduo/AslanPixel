// ignore_for_file: avoid_print
/// Generates 16x16 pixel art icon PNGs for the Aslan Pixel UI.
///
/// Run: dart run scripts/gen_pixel_icons.dart
library;

import 'dart:io';
import 'package:image/image.dart' as img;

// ── Color palette ────────────────────────────────────────────────────────────
const int _neonGreen = 0xFF00F5A0;
const int _gold = 0xFFF5C518;
const int _cyan = 0xFF00D9FF;
const int _purple = 0xFF7B2FFF;
const int _orange = 0xFFFF6B35;
const int _red = 0xFFFF4D6A;
const int _gray = 0xFFAAAAAA;
const int _darkGray = 0xFF777777;
const int _white = 0xFFFFFFFF;
const int _transparent = 0x00000000;

/// Convert ARGB int to image library Color.
img.Color _c(int argb) {
  final a = (argb >> 24) & 0xFF;
  final r = (argb >> 16) & 0xFF;
  final g = (argb >> 8) & 0xFF;
  final b = argb & 0xFF;
  return img.ColorRgba8(r, g, b, a);
}

/// Create a 16x16 transparent image.
img.Image _blank() =>
    img.Image(width: 16, height: 16, numChannels: 4);

/// Set a pixel from a pattern grid.
void _draw(img.Image image, List<String> pattern, int color,
    {Map<String, int>? colorMap}) {
  final c = _c(color);
  for (int y = 0; y < pattern.length && y < 16; y++) {
    final row = pattern[y];
    for (int x = 0; x < row.length && x < 16; x++) {
      final ch = row[x];
      if (ch == '#') {
        image.setPixel(x, y, c);
      } else if (colorMap != null && colorMap.containsKey(ch)) {
        image.setPixel(x, y, _c(colorMap[ch]!));
      }
    }
  }
}

/// Save an image as PNG to the output directory.
Future<void> _save(img.Image image, String name) async {
  final dir = Directory('assets/sprites/ui');
  if (!dir.existsSync()) dir.createSync(recursive: true);
  final file = File('${dir.path}/${name}_icon.png');
  file.writeAsBytesSync(img.encodePng(image));
  print('  [OK] ${file.path}');
}

// ── Icon patterns (16x16, # = primary color) ────────────────────────────────

img.Image _homeIcon() {
  final im = _blank();
  _draw(im, [
    '......##........',
    '.....####.......',
    '....######......',
    '...########.....',
    '..##########....',
    '.############...',
    '####..####..####',
    '####..####..####',
    '####..####..####',
    '####..####..####',
    '####......##....',
    '####......##....',
    '####...##.##....',
    '####...##.##....',
    '####...##.##....',
    '################',
  ], _neonGreen);
  // Door highlight
  final door = _c(0xFF00C080);
  for (int y = 12; y < 15; y++) {
    im.setPixel(7, y, door);
    im.setPixel(8, y, door);
  }
  return im;
}

img.Image _worldIcon() {
  final im = _blank();
  _draw(im, [
    '....########....',
    '..############..',
    '.##..####..####.',
    '.#....####...##.',
    '##....####....##',
    '################',
    '##....####....##',
    '##....####....##',
    '################',
    '##....####....##',
    '##....####....##',
    '.#....####...##.',
    '.##..####..####.',
    '..############..',
    '....########....',
    '................',
  ], _cyan);
  return im;
}

img.Image _chartIcon() {
  final im = _blank();
  // Draw ascending bar chart
  final c = _c(_gold);
  final cDark = _c(0xFFC49E10);
  // Bar 1 (shortest, left)
  for (int y = 12; y < 15; y++) {
    im.setPixel(1, y, cDark);
    im.setPixel(2, y, c);
    im.setPixel(3, y, c);
  }
  // Bar 2
  for (int y = 9; y < 15; y++) {
    im.setPixel(5, y, cDark);
    im.setPixel(6, y, c);
    im.setPixel(7, y, c);
  }
  // Bar 3
  for (int y = 6; y < 15; y++) {
    im.setPixel(9, y, cDark);
    im.setPixel(10, y, c);
    im.setPixel(11, y, c);
  }
  // Bar 4 (tallest, right)
  for (int y = 2; y < 15; y++) {
    im.setPixel(13, y, cDark);
    im.setPixel(14, y, c);
  }
  // Base line
  for (int x = 0; x < 16; x++) {
    im.setPixel(x, 15, _c(_gold));
  }
  return im;
}

img.Image _socialIcon() {
  final im = _blank();
  _draw(im, [
    '................',
    '...####..####...',
    '..######.#####..',
    '..######.#####..',
    '...####..####...',
    '....##....##....',
    '..######.#####..',
    '.########.#####.',
    '.########.#####.',
    '..######.#####..',
    '..##..##.##..##.',
    '..##..##.##..##.',
    '..##..##.##..##.',
    '..##..##.##..##.',
    '................',
    '................',
  ], _purple);
  return im;
}

img.Image _profileIcon() {
  final im = _blank();
  _draw(im, [
    '................',
    '.....######.....',
    '....########....',
    '...##########...',
    '...##########...',
    '...##########...',
    '....########....',
    '.....######.....',
    '......####......',
    '....########....',
    '..############..',
    '.##############.',
    '.##############.',
    '################',
    '################',
    '................',
  ], _neonGreen);
  return im;
}

img.Image _trophyIcon() {
  final im = _blank();
  _draw(im, [
    '................',
    '.##############.',
    '.##############.',
    '####.######.####',
    '####.######.####',
    '.###.######.###.',
    '..##.######.##..',
    '...#.######.#...',
    '....########....',
    '.....######.....',
    '......####......',
    '......####......',
    '.....######.....',
    '....########....',
    '....########....',
    '................',
  ], _gold);
  return im;
}

img.Image _fireIcon() {
  final im = _blank();
  _draw(im, [
    '................',
    '.......##.......',
    '......###.......',
    '.....####.......',
    '....#####.......',
    '...######.#.....',
    '..########......',
    '..########......',
    '.##########.....',
    '.##########.....',
    '.##########.....',
    '..########......',
    '..########......',
    '...######.......',
    '....####........',
    '................',
  ], _orange, colorMap: {
    // Inner flame is gold
  });
  // Add gold inner flame
  final goldC = _c(_gold);
  for (int y = 5; y < 13; y++) {
    for (int x = 5; x < 9; x++) {
      if (im.getPixel(x, y).a > 0) {
        im.setPixel(x, y, goldC);
      }
    }
  }
  // Bright tip
  final whiteC = _c(_white);
  im.setPixel(6, 8, whiteC);
  im.setPixel(7, 9, whiteC);
  im.setPixel(6, 9, whiteC);
  return im;
}

img.Image _heartIcon() {
  final im = _blank();
  _draw(im, [
    '................',
    '................',
    '..####..####....',
    '.######.######..',
    '.#############..',
    '..############..',
    '..############..',
    '..############..',
    '...##########...',
    '....########....',
    '.....######.....',
    '......####......',
    '.......##.......',
    '................',
    '................',
    '................',
  ], _red);
  // Highlight on top-left lobe
  im.setPixel(3, 3, _c(_white));
  im.setPixel(4, 3, _c(0xFFFF8DA0));
  return im;
}

img.Image _bellIcon() {
  final im = _blank();
  _draw(im, [
    '................',
    '.......##.......',
    '......####......',
    '.....######.....',
    '....########....',
    '....########....',
    '...##########...',
    '...##########...',
    '..############..',
    '..############..',
    '.##############.',
    '.##############.',
    '################',
    '................',
    '......####......',
    '................',
  ], _gold);
  return im;
}

img.Image _settingsIcon() {
  final im = _blank();
  _draw(im, [
    '................',
    '.....####.......',
    '....######......',
    '..############..',
    '..############..',
    '.####..####.###.',
    '.###....##..###.',
    '.###....##..###.',
    '.###....##..###.',
    '.####..####.###.',
    '..############..',
    '..############..',
    '....######......',
    '.....####.......',
    '................',
    '................',
  ], _gray);
  // Center dark hole
  final dark = _c(_darkGray);
  for (int y = 6; y < 10; y++) {
    for (int x = 6; x < 10; x++) {
      im.setPixel(x, y, dark);
    }
  }
  return im;
}

img.Image _storeIcon() {
  final im = _blank();
  _draw(im, [
    '................',
    '..############..',
    '..############..',
    '.##############.',
    '.##.####.####.#.',
    '.#..####..###...',
    '.##.####.####.#.',
    '.##############.',
    '.##.............',
    '.##..########...',
    '.##..########...',
    '.##..##....##...',
    '.##..##....##...',
    '.##..##....##...',
    '.##############.',
    '................',
  ], _gold);
  return im;
}

img.Image _swordIcon() {
  final im = _blank();
  _draw(im, [
    '..............##',
    '.............###',
    '............###.',
    '...........###..',
    '..........###...',
    '.........###....',
    '........###.....',
    '.......###......',
    '......###.......',
    '.....###........',
    '..#.###.........',
    '..####..........',
    '...###..........',
    '....##..........',
    '................',
    '................',
  ], _neonGreen);
  // Hilt crossguard
  final hilt = _c(0xFF00C080);
  for (int x = 1; x < 7; x++) {
    im.setPixel(x, 11, hilt);
  }
  // Grip
  im.setPixel(3, 12, hilt);
  im.setPixel(3, 13, hilt);
  im.setPixel(4, 13, hilt);
  return im;
}

img.Image _shieldIcon() {
  final im = _blank();
  _draw(im, [
    '................',
    '..############..',
    '.##############.',
    '.##############.',
    '.##############.',
    '.##############.',
    '.##############.',
    '.##############.',
    '..############..',
    '..############..',
    '...##########...',
    '....########....',
    '.....######.....',
    '......####......',
    '.......##.......',
    '................',
  ], _purple);
  // Inner emblem (a lighter cross)
  final inner = _c(0xFF9B5FFF);
  for (int y = 3; y < 11; y++) {
    im.setPixel(7, y, inner);
    im.setPixel(8, y, inner);
  }
  for (int x = 4; x < 12; x++) {
    im.setPixel(x, 6, inner);
    im.setPixel(x, 7, inner);
  }
  return im;
}

img.Image _potionIcon() {
  final im = _blank();
  _draw(im, [
    '................',
    '.....######.....',
    '.....######.....',
    '......####......',
    '......####......',
    '.....######.....',
    '....########....',
    '...##########...',
    '..############..',
    '..############..',
    '..############..',
    '..############..',
    '..############..',
    '...##########...',
    '....########....',
    '................',
  ], _cyan);
  // Cork / stopper at top
  final cork = _c(0xFFCC9933);
  for (int x = 5; x < 11; x++) {
    im.setPixel(x, 1, cork);
    im.setPixel(x, 2, cork);
  }
  // Liquid shimmer
  im.setPixel(5, 10, _c(_white));
  im.setPixel(6, 11, _c(0xFF66EEFF));
  return im;
}

// ── Main ─────────────────────────────────────────────────────────────────────

Future<void> main() async {
  print('Generating pixel art icons (16x16)...\n');

  final icons = <String, img.Image>{
    'home': _homeIcon(),
    'world': _worldIcon(),
    'chart': _chartIcon(),
    'social': _socialIcon(),
    'profile': _profileIcon(),
    'trophy': _trophyIcon(),
    'fire': _fireIcon(),
    'heart': _heartIcon(),
    'bell': _bellIcon(),
    'settings': _settingsIcon(),
    'store': _storeIcon(),
    'sword': _swordIcon(),
    'shield': _shieldIcon(),
    'potion': _potionIcon(),
  };

  for (final entry in icons.entries) {
    await _save(entry.value, entry.key);
  }

  print('\nDone! Generated ${icons.length} pixel art icons.');
}
