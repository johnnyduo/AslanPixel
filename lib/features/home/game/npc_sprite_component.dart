import 'dart:ui' show Offset;

import 'package:flame/components.dart';
import 'package:flame/game.dart';
import 'package:flutter/material.dart'
    show Colors, FontWeight, Shadow, TextStyle;

// ---------------------------------------------------------------------------
// NpcDirection
// ---------------------------------------------------------------------------

/// The four cardinal facing directions for an NPC sprite.
enum NpcDirection { south, north, east, west }

// ---------------------------------------------------------------------------
// NpcSpriteComponent
// ---------------------------------------------------------------------------

/// A Flame component that renders an NPC sprite loaded from
/// `assets/sprites/npcs/{name}_{direction}.png`.
///
/// Sprite priority:
///   1. `{name}_{direction}.png` (directional variant, e.g. `_south.png`)
///   2. `{name}_idle.png` — fallback used when all directional assets are absent
///
/// Features:
///   - 4-direction facing via [setDirection] (hot-swaps the active sprite).
///   - Idle bob: ±2 px vertical oscillation over a 1.5 s period.
///   - Name label rendered below the sprite.
///
/// [spriteWidth] and [spriteHeight] default to 48 × 48 logical pixels.
/// The anchor is [Anchor.center].
class NpcSpriteComponent extends PositionComponent with HasGameReference<FlameGame> {
  NpcSpriteComponent({
    required this.npcName,
    required Vector2 position,
    this.initialDirection = NpcDirection.south,
    this.spriteWidth = 48.0,
    this.spriteHeight = 48.0,
  }) : super(
          position: position,
          size: Vector2(spriteWidth, spriteHeight),
          anchor: Anchor.center,
        );

  final String npcName;
  NpcDirection initialDirection;

  /// Width of the sprite render area in logical pixels.
  final double spriteWidth;

  /// Height of the sprite render area in logical pixels.
  final double spriteHeight;

  // Per-direction sprite cache — populated lazily in onLoad.
  final Map<NpcDirection, Sprite?> _sprites = {};

  late NpcDirection _direction;
  Sprite? _currentSprite;

  // Idle bob state
  double _bobTimer = 0;
  static const double _bobPeriod = 1.5; // seconds
  static const double _bobAmplitude = 2.0; // pixels
  double _bobOffset = 0;

  // Sub-components
  SpriteComponent? _spriteComponent;
  TextComponent? _labelComponent;

  // ---------------------------------------------------------------------------
  // Lifecycle
  // ---------------------------------------------------------------------------

  @override
  Future<void> onLoad() async {
    await super.onLoad();

    _direction = initialDirection;

    // Pre-load all available directional sprites and the idle fallback.
    await _preloadSprites();

    _currentSprite = _sprites[_direction] ?? _sprites[NpcDirection.south];

    // Sprite sub-component — sits at (0,0) relative to this component.
    _spriteComponent = SpriteComponent(
      sprite: _currentSprite,
      size: Vector2(spriteWidth, spriteHeight),
      anchor: Anchor.topLeft,
      position: Vector2.zero(),
    );
    await add(_spriteComponent!);

    // Name label below the sprite.
    _labelComponent = TextComponent(
      text: _displayName(npcName),
      position: Vector2(spriteWidth / 2, spriteHeight + 4),
      anchor: Anchor.topCenter,
      textRenderer: TextPaint(
        style: const TextStyle(
          color: Colors.white70,
          fontSize: 10,
          fontWeight: FontWeight.w600,
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
    await add(_labelComponent!);
  }

  // ---------------------------------------------------------------------------
  // Update — idle bob animation
  // ---------------------------------------------------------------------------

  @override
  void update(double dt) {
    super.update(dt);

    _bobTimer += dt;
    if (_bobTimer > _bobPeriod) {
      _bobTimer -= _bobPeriod;
    }

    // Sine wave: one full oscillation per period.
    final phase = (_bobTimer / _bobPeriod) * 2 * 3.141592653589793;
    final sinVal = _sinApprox(phase);
    final newOffset = sinVal * _bobAmplitude;

    final delta = newOffset - _bobOffset;
    _bobOffset = newOffset;

    // Shift only the sprite sub-component vertically; the label stays put.
    _spriteComponent?.position.y += delta;
  }

  // ---------------------------------------------------------------------------
  // Public API
  // ---------------------------------------------------------------------------

  /// Change the facing direction and hot-swap the sprite accordingly.
  void setDirection(NpcDirection direction) {
    if (_direction == direction) return;
    _direction = direction;
    final newSprite = _sprites[direction] ?? _sprites[NpcDirection.south];
    if (newSprite != null) {
      _spriteComponent?.sprite = newSprite;
      _currentSprite = newSprite;
    }
  }

  /// The currently active facing direction.
  NpcDirection get direction => _direction;

  // ---------------------------------------------------------------------------
  // Private helpers
  // ---------------------------------------------------------------------------

  Future<void> _preloadSprites() async {
    // Attempt to load all four directional sprites.
    for (final dir in NpcDirection.values) {
      final path = 'assets/sprites/npcs/${npcName}_${dir.name}.png';
      try {
        final sprite = await Sprite.load(path, images: game.images);
        _sprites[dir] = sprite;
      } catch (_) {
        // Asset not found for this direction — slot stays null.
      }
    }

    // If no directional sprites were loaded (e.g. npc_merchant, npc_sysbot,
    // npc_pixelcat which only have `_idle.png`), fall back to the idle sprite
    // and apply it to every direction slot.
    if (_sprites.values.every((s) => s == null)) {
      final idlePath = 'assets/sprites/npcs/${npcName}_idle.png';
      try {
        final idleSprite =
            await Sprite.load(idlePath, images: game.images);
        for (final dir in NpcDirection.values) {
          _sprites[dir] = idleSprite;
        }
      } catch (_) {
        // No sprite found at all — component will render blank (no crash).
      }
    }
  }

  /// Converts a snake_case NPC identifier to a human-readable display name.
  ///
  /// Example: `"npc_banker"` → `"Banker"`, `"npc_pixel_cat"` → `"Pixel Cat"`.
  String _displayName(String name) {
    final stripped = name.startsWith('npc_') ? name.substring(4) : name;
    return stripped
        .split('_')
        .map((w) => w.isEmpty ? '' : '${w[0].toUpperCase()}${w.substring(1)}')
        .join(' ');
  }

  /// Sine approximation via Taylor series (avoids a `dart:math` dependency).
  ///
  /// Accurate to ~4 decimal places for |x| <= 2π — sufficient for animation.
  double _sinApprox(double x) {
    const twoPi = 2 * 3.141592653589793;
    while (x > 3.141592653589793) {
      x -= twoPi;
    }
    while (x < -3.141592653589793) {
      x += twoPi;
    }
    final x3 = x * x * x;
    final x5 = x3 * x * x;
    final x7 = x5 * x * x;
    return x - x3 / 6.0 + x5 / 120.0 - x7 / 5040.0;
  }
}
