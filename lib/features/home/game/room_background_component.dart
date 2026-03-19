import 'dart:ui' as ui;

import 'package:flame/components.dart';
import 'package:flame/game.dart';
import 'package:flutter/services.dart' show rootBundle;

/// Identifies which room background variant to render.
enum RoomType { starter, office, penthouse }

/// Renders a room background PNG with **fit-width** scaling.
///
/// The image scales to fill the room width exactly, preserving its
/// original aspect ratio. No stretch, no distortion.
class RoomBackgroundComponent extends PositionComponent
    with HasGameReference<FlameGame> {
  RoomBackgroundComponent({
    required Vector2 roomSize,
    this.roomType = RoomType.starter,
  }) : super(size: roomSize, position: Vector2.zero());

  final RoomType roomType;

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

      final imgW = frame.image.width.toDouble();
      final imgH = frame.image.height.toDouble();
      final aspect = imgH / imgW; // 1.0 for 1024×1024

      // Fit width: image fills canvas width exactly, height scales proportionally.
      final renderW = size.x;
      final renderH = size.x * aspect;

      await add(SpriteComponent(
        sprite: Sprite(frame.image),
        size: Vector2(renderW, renderH),
        position: Vector2.zero(),
        anchor: Anchor.topLeft,
      ));
    } catch (_) {
      // Asset missing — renders blank navy background.
    }
  }
}
