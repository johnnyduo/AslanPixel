import 'dart:ui' show Offset;

import 'package:flame/components.dart';
import 'package:flutter/material.dart'
    show Canvas, Color, Colors, FontWeight, Paint, PaintingStyle, Rect, Shadow, TextStyle;

import 'package:aslan_pixel/features/home/data/models/room_item_model.dart';

// ---------------------------------------------------------------------------
// Color constants — item type palette
// ---------------------------------------------------------------------------

const _colorGold = Color(0xFFF5C518);
const _colorCyan = Color(0xFF00D9FF);
const _colorGreen = Color(0xFF00F5A0);
const _colorPurple = Color(0xFF7B2FFF);
const _colorBrown = Color(0xFF8B5E3C);
const _colorDarkSurface = Color(0xFF0F2040);

// ---------------------------------------------------------------------------
// RoomItemComponent
// ---------------------------------------------------------------------------

/// A Flame [PositionComponent] that renders a placed [RoomItem] as a
/// coloured pixel-art shape on the room canvas.
///
/// No external PNG assets are required — shapes are drawn with Canvas
/// primitives so the feature works immediately even without art assets.
///
/// Positioned at `item.slotX * 48, item.slotY * 48` in room-local space.
/// Anchor is [Anchor.center]; size is 32 × 32.
class RoomItemComponent extends PositionComponent {
  RoomItemComponent({required this.item})
      : super(
          position: Vector2(
            item.slotX * 48.0,
            item.slotY * 48.0,
          ),
          size: Vector2.all(32),
          anchor: Anchor.center,
        );

  final RoomItem item;

  // Cached paints (allocated once in onLoad, not per frame).
  late Paint _fillPaint;
  late Paint _borderPaint;
  late TextComponent _label;

  // ---------------------------------------------------------------------------
  // Lifecycle
  // ---------------------------------------------------------------------------

  @override
  Future<void> onLoad() async {
    await super.onLoad();

    final palette = _paletteFor(item.itemId);

    _fillPaint = Paint()
      ..color = palette.fill
      ..style = PaintingStyle.fill;

    _borderPaint = Paint()
      ..color = palette.border
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5;

    // Name label rendered below the shape.
    _label = TextComponent(
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
    await add(_label);
  }

  // ---------------------------------------------------------------------------
  // Render
  // ---------------------------------------------------------------------------

  @override
  void render(Canvas canvas) {
    super.render(canvas);
    _drawShape(canvas);
  }

  // ---------------------------------------------------------------------------
  // Private helpers
  // ---------------------------------------------------------------------------

  void _drawShape(Canvas canvas) {
    final w = size.x;
    final h = size.y;

    switch (_shapeFor(item.itemId)) {
      case _ItemShape.goldDesk:
        // Gold rectangle — desk symbol (horizontal line across middle)
        final rect = Rect.fromLTWH(2, 4, w - 4, h - 8);
        canvas.drawRect(rect, _fillPaint);
        canvas.drawRect(rect, _borderPaint);
        // Desk surface line
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
        // Cyan rectangle — monitor with screen lines
        final body = Rect.fromLTWH(3, 3, w - 6, h - 10);
        canvas.drawRect(body, _fillPaint);
        canvas.drawRect(body, _borderPaint);
        // Screen scanlines
        final linePaint = Paint()
          ..color = _colorDarkSurface.withValues(alpha: 0.7)
          ..strokeWidth = 1.0
          ..style = PaintingStyle.stroke;
        for (var y = 7.0; y < h - 10; y += 3) {
          canvas.drawLine(Offset(5, y), Offset(w - 5, y), linePaint);
        }
        // Stand
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
        // Green rectangle — bulletin board with grid lines
        final board = Rect.fromLTWH(2, 2, w - 4, h - 4);
        canvas.drawRect(board, _fillPaint);
        canvas.drawRect(board, _borderPaint);
        // Grid lines
        final gridPaint = Paint()
          ..color = _colorDarkSurface.withValues(alpha: 0.5)
          ..strokeWidth = 0.8
          ..style = PaintingStyle.stroke;
        // Vertical
        for (var x = 6.0; x < w - 4; x += 5) {
          canvas.drawLine(Offset(x, 4), Offset(x, h - 4), gridPaint);
        }
        // Horizontal
        for (var y = 6.0; y < h - 4; y += 5) {
          canvas.drawLine(Offset(4, y), Offset(w - 4, y), gridPaint);
        }

      case _ItemShape.purpleCircle:
        // Purple circle — crystal ball with glow halo
        final center = Offset(w / 2, h / 2);
        final glowPaint = Paint()
          ..color = _colorPurple.withValues(alpha: 0.3)
          ..style = PaintingStyle.fill;
        canvas.drawCircle(center, (w / 2) - 1, glowPaint);
        canvas.drawCircle(center, (w / 2) - 4, _fillPaint);
        canvas.drawCircle(center, (w / 2) - 4, _borderPaint);
        // Shine dot
        final shinePaint = Paint()
          ..color = Colors.white.withValues(alpha: 0.5)
          ..style = PaintingStyle.fill;
        canvas.drawCircle(Offset(w * 0.38, h * 0.35), 2.5, shinePaint);

      case _ItemShape.brownMat:
        // Brown/gold small rectangle — door mat
        final mat = Rect.fromLTWH(1, h * 0.35, w - 2, h * 0.3);
        canvas.drawRect(mat, _fillPaint);
        canvas.drawRect(mat, _borderPaint);
        // Weave lines
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
        // Default: solid rect with a small icon indicator
        final rect = Rect.fromLTWH(3, 3, w - 6, h - 6);
        canvas.drawRect(rect, _fillPaint);
        canvas.drawRect(rect, _borderPaint);
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
  /// Example: `"desk_upgrade_01"` → `"Desk Up."`, `"plant_01"` → `"Plant 01"`.
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
