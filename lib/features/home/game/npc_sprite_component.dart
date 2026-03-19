import 'dart:ui' as ui;
import 'dart:ui' show Offset;

import 'package:flame/components.dart';
import 'package:flame/game.dart';
import 'package:flutter/material.dart'
    show Colors, FontWeight, Shadow, TextStyle;
import 'package:flutter/services.dart' show rootBundle;

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
///   - Idle bob: ±2 px vertical oscillation over a 1.5 s period (only when not walking).
///   - Walk animation: per-direction 4-frame sprite animation via [startWalking] / [stopWalking].
///   - Name label rendered below the sprite.
///
/// [spriteWidth] and [spriteHeight] default to 48 × 48 logical pixels.
/// The anchor is [Anchor.center].
class NpcSpriteComponent extends PositionComponent
    with HasGameReference<FlameGame> {
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

  // Per-direction walk animation cache — populated lazily in onLoad.
  final Map<NpcDirection, SpriteAnimation?> _walkAnimations = {};

  late NpcDirection _direction;
  Sprite? _currentSprite;

  // Idle bob state
  double _bobTimer = 0;
  static const double _bobPeriod = 1.5; // seconds
  static const double _bobAmplitude = 2.0; // pixels
  double _bobOffset = 0;

  // Walk state
  bool _isWalking = false;

  // Sub-components
  SpriteComponent? _spriteComponent;
  SpriteAnimationComponent? _walkComponent;
  TextComponent? _labelComponent;

  // ---------------------------------------------------------------------------
  // Lifecycle
  // ---------------------------------------------------------------------------

  @override
  Future<void> onLoad() async {
    await super.onLoad();

    _direction = initialDirection;

    // Pre-load all available directional sprites, idle fallback, and walk frames.
    await _preloadSprites();

    _currentSprite = _sprites[_direction] ?? _sprites[NpcDirection.south];

    // If no sprite loaded at all, skip visual component (graceful degradation).
    if (_currentSprite == null) return;

    // Sprite sub-component — sits at (0,0) relative to this component.
    _spriteComponent = SpriteComponent(
      sprite: _currentSprite!,
      size: Vector2(spriteWidth, spriteHeight),
      anchor: Anchor.topLeft,
      position: Vector2.zero(),
    );
    await add(_spriteComponent!);

    // Walk animation sub-component — created if any walk animation was loaded.
    final firstWalkAnim = _firstAvailableWalkAnimation();
    if (firstWalkAnim != null) {
      _walkComponent = SpriteAnimationComponent(
        animation: firstWalkAnim,
        size: Vector2(spriteWidth, spriteHeight),
        position: Vector2.zero(),
        playing: false,
      );
      _walkComponent!.opacity = 0.0;
      await add(_walkComponent!);
    }

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
  // Update — idle bob animation (only when not walking)
  // ---------------------------------------------------------------------------

  // Walk step animation state (used when no walk frames exist)
  double _walkStepTimer = 0;
  static const double _walkStepPeriod = 0.25; // fast step bounce
  static const double _walkStepAmplitude = 3.0; // pixels bounce
  double _walkStepOffset = 0;

  @override
  void update(double dt) {
    super.update(dt);

    if (_isWalking) {
      // Walk step bounce animation — makes NPC look like it's stepping
      // even without dedicated walk frame sprites.
      _walkStepTimer += dt;
      if (_walkStepTimer > _walkStepPeriod) {
        _walkStepTimer -= _walkStepPeriod;
      }
      final walkPhase =
          (_walkStepTimer / _walkStepPeriod) * 2 * 3.141592653589793;
      final walkSin = _sinApprox(walkPhase).abs(); // absolute = bouncy step
      final newWalkOffset = -walkSin * _walkStepAmplitude;
      final walkDelta = newWalkOffset - _walkStepOffset;
      _walkStepOffset = newWalkOffset;
      _spriteComponent?.position.y += walkDelta;
      return;
    }

    // Idle bob animation
    _bobTimer += dt;
    if (_bobTimer > _bobPeriod) {
      _bobTimer -= _bobPeriod;
    }

    final phase = (_bobTimer / _bobPeriod) * 2 * 3.141592653589793;
    final sinVal = _sinApprox(phase);
    final newOffset = sinVal * _bobAmplitude;

    final delta = newOffset - _bobOffset;
    _bobOffset = newOffset;

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

  /// Start walking in [direction]: shows walk animation if available, otherwise
  /// keeps the static directional sprite visible.
  void startWalking(NpcDirection direction) {
    _isWalking = true;
    setDirection(direction);

    final walkAnim = _walkAnimations[direction];
    if (walkAnim != null && _walkComponent != null) {
      _walkComponent!.animation = walkAnim;
      _walkComponent!.opacity = 1.0;
      _walkComponent!.playing = true;
      _spriteComponent?.opacity = 0.0;
    }
    // If no walk animation for this direction, keep static sprite visible.
  }

  /// Stop walking: hides walk animation and restores static sprite.
  void stopWalking() {
    _isWalking = false;
    _walkComponent?.opacity = 0.0;
    _walkComponent?.playing = false;
    _spriteComponent?.opacity = 1.0;
  }

  // ---------------------------------------------------------------------------
  // Private helpers
  // ---------------------------------------------------------------------------

  /// Load a sprite from Flutter's asset bundle (bypasses Flame's
  /// `assets/images/` prefix that causes path resolution failures).
  Future<Sprite> _loadSprite(String path) async {
    final data = await rootBundle.load(path);
    final bytes = data.buffer.asUint8List();
    final codec = await ui.instantiateImageCodec(bytes);
    final frame = await codec.getNextFrame();
    return Sprite(frame.image);
  }

  Future<void> _preloadSprites() async {
    // Attempt to load all four directional sprites.
    for (final dir in NpcDirection.values) {
      final path = 'assets/sprites/npcs/${npcName}_${dir.name}.png';
      try {
        final sprite = await _loadSprite(path);
        _sprites[dir] = sprite;
      } catch (_) {
        // Asset not found for this direction — slot stays null.
      }
    }

    // If no directional sprites were loaded (e.g. npc with only `_idle.png`),
    // fall back to the idle sprite and apply it to every direction slot.
    if (_sprites.values.every((s) => s == null)) {
      final idlePath = 'assets/sprites/npcs/${npcName}_idle.png';
      try {
        final idleSprite = await _loadSprite(idlePath);
        for (final dir in NpcDirection.values) {
          _sprites[dir] = idleSprite;
        }
      } catch (_) {
        // No sprite found at all — component will render blank (no crash).
      }
    }

    // Attempt to load walk frame animations (4 frames per direction).
    for (final dir in NpcDirection.values) {
      final frames = <Sprite>[];
      for (var i = 1; i <= 4; i++) {
        final path =
            'assets/sprites/npcs/${npcName}_${dir.name}_walk$i.png';
        try {
          final frame = await _loadSprite(path);
          frames.add(frame);
        } catch (_) {
          // Frame not found — break out; require all 4 to form a valid animation.
          break;
        }
      }
      if (frames.length == 4) {
        _walkAnimations[dir] =
            SpriteAnimation.spriteList(frames, stepTime: 1 / 8);
      }
    }
  }

  /// Returns the first non-null walk animation, or null if none were loaded.
  SpriteAnimation? _firstAvailableWalkAnimation() {
    for (final dir in NpcDirection.values) {
      final anim = _walkAnimations[dir];
      if (anim != null) return anim;
    }
    return null;
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
