import 'package:flame/components.dart';
import 'package:flame/game.dart';

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
      final sprite = await Sprite.load(
        'assets/sprites/room_backgrounds/$assetName',
        images: game.images,
      );
      _bgSprite = SpriteComponent(
        sprite: sprite,
        size: size,
        position: Vector2.zero(),
        anchor: Anchor.topLeft,
      );
      await add(_bgSprite!);
    } catch (_) {
      // Asset missing — renders blank, no crash.
    }
  }
}
