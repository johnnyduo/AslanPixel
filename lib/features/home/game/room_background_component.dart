import 'dart:ui' as ui;

import 'package:flame/components.dart';
import 'package:flame/game.dart';
import 'package:flutter/services.dart' show rootBundle;

// ---------------------------------------------------------------------------
// RoomType
// ---------------------------------------------------------------------------

/// Identifies which room background variant to render.
enum RoomType { starter, office, penthouse }

// ---------------------------------------------------------------------------
// RoomBackgroundComponent
// ---------------------------------------------------------------------------

/// A Flame component that renders a Gemini-generated room background PNG.
///
/// Asset path: `assets/sprites/room_backgrounds/room_{type}.png`
///
/// Falls back gracefully if the asset is missing (no crash, renders blank).
class RoomBackgroundComponent extends PositionComponent
    with HasGameReference<FlameGame> {
  RoomBackgroundComponent({
    required Vector2 roomSize,
    this.roomType = RoomType.starter,
  }) : super(size: roomSize, position: Vector2.zero());

  final RoomType roomType;

  SpriteComponent? _bgSprite;

  // ---------------------------------------------------------------------------
  // Lifecycle
  // ---------------------------------------------------------------------------

  @override
  Future<void> onLoad() async {
    await super.onLoad();

    final assetName = switch (roomType) {
      RoomType.starter => 'room_starter.png',
      RoomType.office => 'room_office.png',
      RoomType.penthouse => 'room_penthouse.png',
    };

    try {
      final path = 'assets/sprites/room_backgrounds/$assetName';
      final data = await rootBundle.load(path);
      final bytes = data.buffer.asUint8List();
      final codec = await ui.instantiateImageCodec(bytes);
      final frame = await codec.getNextFrame();
      final sprite = Sprite(frame.image);
      // Cover the entire visible area — scale to fill width,
      // let height extend beyond if needed (no stretch distortion).
      final imgW = frame.image.width.toDouble();
      final imgH = frame.image.height.toDouble();
      final scale = size.x / imgW;
      final scaledH = imgH * scale;
      // Use whichever is taller: scaled image or requested room size
      final finalH = scaledH > size.y ? scaledH : size.y;

      _bgSprite = SpriteComponent(
        sprite: sprite,
        size: Vector2(size.x, finalH),
        position: Vector2.zero(),
        anchor: Anchor.topLeft,
      );
      await add(_bgSprite!);
    } catch (_) {
      // Asset missing — renders blank, no crash.
    }
  }
}
