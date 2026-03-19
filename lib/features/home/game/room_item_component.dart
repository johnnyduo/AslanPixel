import 'dart:ui' as ui;
import 'dart:ui' show Offset;

import 'package:flame/components.dart';
import 'package:flutter/material.dart'
    show Canvas, Color, Colors, FontWeight, Paint, PaintingStyle, Rect, Shadow, TextStyle;
import 'package:flutter/services.dart' show rootBundle;

import 'package:aslan_pixel/features/home/data/models/room_item_model.dart';

// ---------------------------------------------------------------------------
// Color constants — item type palette (used only for Canvas fallback)
// ---------------------------------------------------------------------------

const _colorGold = Color(0xFFF5C518);
const _colorCyan = Color(0xFF00D9FF);
const _colorGreen = Color(0xFF00F5A0);
const _colorPurple = Color(0xFF7B2FFF);
const _colorBrown = Color(0xFF8B5E3C);
const _colorDarkSurface = Color(0xFF0F2040);

// ---------------------------------------------------------------------------
// Asset subdirectory mapping
// ---------------------------------------------------------------------------

/// Maps a [RoomItemType] to its subdirectory under `assets/sprites/room_items/`.
String _subdirForType(RoomItemType type) {
  switch (type) {
    case RoomItemType.furniture:
      return 'furniture';
    case RoomItemType.decoration:
      return 'decorations';
    case RoomItemType.plant:
      return 'decorations';
    case RoomItemType.chest:
      return 'furniture';
    case RoomItemType.floor:
      return 'furniture';
  }
}

/// All subdirectories to search when the item type doesn't yield a match.
const _allSubdirs = ['furniture', 'decorations', 'technology', 'special'];

// ---------------------------------------------------------------------------
// RoomItemComponent
// ---------------------------------------------------------------------------

/// A Flame [PositionComponent] that renders a placed [RoomItem].
///
/// Loads a PNG sprite from `assets/sprites/room_items/{subdir}/{assetKey}.png`
/// using Flutter's [rootBundle] + [ui.instantiateImageCodec] pattern (same as
/// NpcSpriteComponent and PixelAgentComponent).
///
/// Falls back to Canvas shape drawing if the PNG asset doesn't exist.
///
/// Positioned at `item.slotX * 48, item.slotY * 48` in room-local space.
/// Anchor is [Anchor.center]; size is 48 x 48.
class RoomItemComponent extends PositionComponent {
  RoomItemComponent({required this.item})
      : super(
          position: Vector2(
            item.slotX * 48.0,
            item.slotY * 48.0,
          ),
          size: Vector2.all(48),
          anchor: Anchor.center,
        );

  final RoomItem item;

  /// Whether a PNG sprite was successfully loaded.
  bool _hasSprite = false;

  // Cached paints for Canvas fallback (allocated in onLoad if needed).
  Paint? _fillPaint;
  Paint? _borderPaint;

  // ---------------------------------------------------------------------------
  // Lifecycle
  // ---------------------------------------------------------------------------

  @override
  Future<void> onLoad() async {
    await super.onLoad();

    // Attempt to load PNG sprite.
    _hasSprite = await _tryLoadSprite();

    // If no sprite, initialise Canvas fallback paints.
    if (!_hasSprite) {
      final palette = _paletteFor(item.itemId);
      _fillPaint = Paint()
        ..color = palette.fill
        ..style = PaintingStyle.fill;
      _borderPaint = Paint()
        ..color = palette.border
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.5;
    }

    // Name label rendered below the item.
    final label = TextComponent(
      text: _displayName(item.itemId),
      position: Vector2(size.x / 2, size.y + 4),
      anchor: Anchor.topCenter,
      textRenderer: TextPaint(
        style: const TextStyle(
          color: Colors.white70,
          fontSize: 8,
          fontWeight: FontWeight.w500,
          shadows: [
            Shadow(
              color: Colors.black,
              offset: Offset(1, 1),
              blurRadius: 2,
            ),
          ],
        ),
      ),
    );
    await add(label);
  }

  // ---------------------------------------------------------------------------
  // Sprite loading
  // ---------------------------------------------------------------------------

  /// Attempts to load a PNG sprite for this item. Returns true on success.
  ///
  /// Search order:
  ///   1. `{subdir for item.type}/{assetKey}.png`
  ///   2. All subdirectories (`furniture`, `decorations`, `technology`, `special`)
  Future<bool> _tryLoadSprite() async {
    final assetKey = item.assetKey.isNotEmpty ? item.assetKey : item.itemId;

    // Try the type-specific subdirectory first.
    final primaryDir = _subdirForType(item.type);
    final primaryPath = 'assets/sprites/room_items/$primaryDir/$assetKey.png';
    final sprite = await _loadSpriteFromPath(primaryPath);
    if (sprite != null) {
      await _addSpriteComponent(sprite);
      return true;
    }

    // Fall back: search all subdirectories.
    for (final dir in _allSubdirs) {
      if (dir == primaryDir) continue; // Already tried.
      final path = 'assets/sprites/room_items/$dir/$assetKey.png';
      final s = await _loadSpriteFromPath(path);
      if (s != null) {
        await _addSpriteComponent(s);
        return true;
      }
    }

    return false;
  }

  /// Loads a [Sprite] from Flutter's asset bundle using the
  /// [rootBundle] + [ui.instantiateImageCodec] pattern.
  /// Returns null if the asset does not exist or fails to decode.
  Future<Sprite?> _loadSpriteFromPath(String path) async {
    try {
      final data = await rootBundle.load(path);
      final bytes = data.buffer.asUint8List();
      final codec = await ui.instantiateImageCodec(bytes);
      final frame = await codec.getNextFrame();
      return Sprite(frame.image);
    } catch (_) {
      return null;
    }
  }

  /// Adds a [SpriteComponent] child sized to fill this component.
  Future<void> _addSpriteComponent(Sprite sprite) async {
    final comp = SpriteComponent(
      sprite: sprite,
      size: Vector2(size.x, size.y),
      anchor: Anchor.topLeft,
      position: Vector2.zero(),
    );
    await add(comp);
  }

  // ---------------------------------------------------------------------------
  // Render — Canvas fallback (only used when no PNG sprite is loaded)
  // ---------------------------------------------------------------------------

  @override
  void render(Canvas canvas) {
    super.render(canvas);
    if (!_hasSprite) {
      _drawShape(canvas);
    }
  }

  // ---------------------------------------------------------------------------
  // Canvas fallback drawing
  // ---------------------------------------------------------------------------

  void _drawShape(Canvas canvas) {
    final w = size.x;
    final h = size.y;

    switch (_shapeFor(item.itemId)) {
      case _ItemShape.goldDesk:
        final rect = Rect.fromLTWH(2, 4, w - 4, h - 8);
        canvas.drawRect(rect, _fillPaint!);
        canvas.drawRect(rect, _borderPaint!);
        final surfacePaint = Paint()
          ..color = _colorDarkSurface
          ..strokeWidth = 1.5
          ..style = PaintingStyle.stroke;
        canvas.drawLine(
          Offset(4, h * 0.45),
          Offset(w - 4, h * 0.45),
          surfacePaint,
        );

      case _ItemShape.cyanMonitor:
        final body = Rect.fromLTWH(3, 3, w - 6, h - 10);
        canvas.drawRect(body, _fillPaint!);
        canvas.drawRect(body, _borderPaint!);
        final linePaint = Paint()
          ..color = _colorDarkSurface.withValues(alpha: 0.7)
          ..strokeWidth = 1.0
          ..style = PaintingStyle.stroke;
        for (var y = 7.0; y < h - 10; y += 3) {
          canvas.drawLine(Offset(5, y), Offset(w - 5, y), linePaint);
        }
        final standPaint = Paint()
          ..color = _colorCyan
          ..strokeWidth = 2.0
          ..style = PaintingStyle.stroke;
        canvas.drawLine(
          Offset(w / 2, h - 7),
          Offset(w / 2, h - 3),
          standPaint,
        );
        canvas.drawLine(
          Offset(w / 2 - 4, h - 3),
          Offset(w / 2 + 4, h - 3),
          standPaint,
        );

      case _ItemShape.greenBoard:
        final board = Rect.fromLTWH(2, 2, w - 4, h - 4);
        canvas.drawRect(board, _fillPaint!);
        canvas.drawRect(board, _borderPaint!);
        final gridPaint = Paint()
          ..color = _colorDarkSurface.withValues(alpha: 0.5)
          ..strokeWidth = 0.8
          ..style = PaintingStyle.stroke;
        for (var x = 6.0; x < w - 4; x += 5) {
          canvas.drawLine(Offset(x, 4), Offset(x, h - 4), gridPaint);
        }
        for (var y = 6.0; y < h - 4; y += 5) {
          canvas.drawLine(Offset(4, y), Offset(w - 4, y), gridPaint);
        }

      case _ItemShape.purpleCircle:
        final center = Offset(w / 2, h / 2);
        final glowPaint = Paint()
          ..color = _colorPurple.withValues(alpha: 0.3)
          ..style = PaintingStyle.fill;
        canvas.drawCircle(center, (w / 2) - 1, glowPaint);
        canvas.drawCircle(center, (w / 2) - 4, _fillPaint!);
        canvas.drawCircle(center, (w / 2) - 4, _borderPaint!);
        final shinePaint = Paint()
          ..color = Colors.white.withValues(alpha: 0.5)
          ..style = PaintingStyle.fill;
        canvas.drawCircle(Offset(w * 0.38, h * 0.35), 2.5, shinePaint);

      case _ItemShape.brownMat:
        final mat = Rect.fromLTWH(1, h * 0.35, w - 2, h * 0.3);
        canvas.drawRect(mat, _fillPaint!);
        canvas.drawRect(mat, _borderPaint!);
        final weavePaint = Paint()
          ..color = _colorGold.withValues(alpha: 0.6)
          ..strokeWidth = 0.8
          ..style = PaintingStyle.stroke;
        for (var x = 4.0; x < w - 2; x += 4) {
          canvas.drawLine(
            Offset(x, h * 0.35),
            Offset(x, h * 0.65),
            weavePaint,
          );
        }

      case _ItemShape.generic:
        final rect = Rect.fromLTWH(3, 3, w - 6, h - 6);
        canvas.drawRect(rect, _fillPaint!);
        canvas.drawRect(rect, _borderPaint!);
    }
  }

  // ---------------------------------------------------------------------------
  // Static helpers
  // ---------------------------------------------------------------------------

  static _ItemShape _shapeFor(String itemId) {
    switch (itemId) {
      case 'desk_upgrade_01':
      case 'desk_01':
      case 'desk_02':
      case 'desk_03':
        return _ItemShape.goldDesk;
      case 'monitor_01':
        return _ItemShape.cyanMonitor;
      case 'bulletin_board_01':
      case 'bookshelf_01':
        return _ItemShape.greenBoard;
      case 'crystal_ball_01':
        return _ItemShape.purpleCircle;
      case 'door_mat_01':
      case 'rug_01':
        return _ItemShape.brownMat;
      default:
        return _itemShapeFromType(itemId);
    }
  }

  static _ItemShape _itemShapeFromType(String itemId) {
    if (itemId.startsWith('plant')) return _ItemShape.greenBoard;
    if (itemId.startsWith('chest')) return _ItemShape.purpleCircle;
    if (itemId.startsWith('lamp')) return _ItemShape.cyanMonitor;
    return _ItemShape.generic;
  }

  static _ItemPalette _paletteFor(String itemId) {
    final shape = _shapeFor(itemId);
    switch (shape) {
      case _ItemShape.goldDesk:
        return const _ItemPalette(
          fill: _colorGold,
          border: Color(0xFFB89010),
        );
      case _ItemShape.cyanMonitor:
        return const _ItemPalette(
          fill: _colorCyan,
          border: Color(0xFF009AB5),
        );
      case _ItemShape.greenBoard:
        return const _ItemPalette(
          fill: _colorGreen,
          border: Color(0xFF009960),
        );
      case _ItemShape.purpleCircle:
        return const _ItemPalette(
          fill: _colorPurple,
          border: Color(0xFF5010CC),
        );
      case _ItemShape.brownMat:
        return const _ItemPalette(
          fill: _colorBrown,
          border: Color(0xFF5A3A20),
        );
      case _ItemShape.generic:
        return const _ItemPalette(
          fill: Color(0xFF3A5A8A),
          border: Color(0xFF1E3050),
        );
    }
  }

  /// Converts a snake_case item id into a short human-readable label.
  ///
  /// Example: `"desk_upgrade_01"` -> `"Desk Up."`, `"plant_01"` -> `"Plant 01"`.
  static String _displayName(String itemId) {
    final parts = itemId.split('_');
    if (parts.isEmpty) return itemId;
    final base = parts.first;
    final capitalised = base.isEmpty
        ? ''
        : '${base[0].toUpperCase()}${base.substring(1)}';
    if (parts.length == 1) return capitalised;
    // Show base + last part (usually the number or short keyword).
    final suffix = parts.last;
    return '$capitalised $suffix';
  }
}

// ---------------------------------------------------------------------------
// Private data types
// ---------------------------------------------------------------------------

enum _ItemShape {
  goldDesk,
  cyanMonitor,
  greenBoard,
  purpleCircle,
  brownMat,
  generic,
}

class _ItemPalette {
  const _ItemPalette({required this.fill, required this.border});
  final Color fill;
  final Color border;
}
