// ---------------------------------------------------------------------------
// npc_walk_controller.dart
//
// A Flame Component that drives autonomous "wander" behaviour for an
// NpcSpriteComponent.
//
// Behaviour loop
// ──────────────
//  1. Pick a random target within the room canvas (400 × 700, margin 60 px).
//  2. Walk toward the target at 40 px/s, updating the NPC facing direction
//     each frame based on the movement vector.
//  3. When within 8 px of the target ("arrival"), stop the NPC and pause for
//     2–5 s (random).
//  4. On arrival there is a 20 % chance a random quote bubble is shown for 3 s
//     (added to the parent game, positioned above the NPC).
//  5. After the pause, go back to step 1.
// ---------------------------------------------------------------------------

import 'dart:math' show Random;

import 'package:flame/components.dart';
import 'package:flame/game.dart';

import 'package:aslan_pixel/features/home/game/npc_quote_bubble.dart';
import 'package:aslan_pixel/features/home/game/npc_quotes.dart';
import 'package:aslan_pixel/features/home/game/npc_sprite_component.dart';
import 'package:aslan_pixel/features/home/game/room_collision_map.dart';

// ---------------------------------------------------------------------------
// NpcWalkController
// ---------------------------------------------------------------------------

/// A headless [Component] (no rendering of its own) that controls the wander
/// behaviour of a single [NpcSpriteComponent].
///
/// Add this component directly to [PixelRoomGame] (not as a child of the NPC
/// sprite) so it can freely read and update the sprite's position.
///
/// ```dart
/// final npc = NpcSpriteComponent(npcName: 'npc_banker', position: start);
/// await add(npc);
/// await add(NpcWalkController(npc: npc));
/// ```
class NpcWalkController extends Component with HasGameReference<FlameGame> {
  NpcWalkController({
    required NpcSpriteComponent npc,
    RoomCollisionMap? collisionMap,
    double walkSpeed = 40,
    double arrivalThreshold = 8,
    double quoteProbability = 0.20,
  })  : _npc = npc,
        _collisionMap = collisionMap ?? RoomCollisionMap(),
        _walkSpeed = walkSpeed,
        _arrivalThreshold = arrivalThreshold,
        _quoteProbability = quoteProbability,
        _rng = Random();

  // The NPC sprite this controller drives.
  final NpcSpriteComponent _npc;

  // Collision map — NPCs only walk on walkable cells.
  final RoomCollisionMap _collisionMap;

  // Movement configuration.
  final double _walkSpeed;
  final double _arrivalThreshold;
  final double _quoteProbability;

  final Random _rng;

  // ---- State machine ----
  _WalkState _state = _WalkState.idle;
  Vector2 _target = Vector2.zero();
  double _pauseRemaining = 0;

  // Whether a quote bubble is currently active (prevents spawning duplicates).
  bool _quoteBubbleActive = false;

  // ---------------------------------------------------------------------------
  // Lifecycle
  // ---------------------------------------------------------------------------

  @override
  Future<void> onLoad() async {
    await super.onLoad();
    // Kick off the wander loop.
    _pickNewTarget();
  }

  // ---------------------------------------------------------------------------
  // Update
  // ---------------------------------------------------------------------------

  @override
  void update(double dt) {
    super.update(dt);

    switch (_state) {
      case _WalkState.walking:
        _updateWalking(dt);
      case _WalkState.pausing:
        _updatePausing(dt);
      case _WalkState.idle:
        _pickNewTarget();
    }
  }

  // ---------------------------------------------------------------------------
  // Walking phase
  // ---------------------------------------------------------------------------

  void _updateWalking(double dt) {
    final delta = _target - _npc.position;
    final distance = delta.length;

    if (distance <= _arrivalThreshold) {
      // Arrived at target.
      _npc.position.setFrom(_target);
      _npc.stopWalking();
      _onArrival();
      return;
    }

    // Calculate next position.
    final step = delta.normalized() * (_walkSpeed * dt);
    final nextPos = _npc.position + step;

    // Check if next position is walkable — if blocked, pick a new target.
    if (!_collisionMap.isPositionWalkable(nextPos)) {
      _npc.stopWalking();
      _pickNewTarget();
      return;
    }

    // Move toward target.
    _npc.position.add(step);

    // Update NPC facing direction based on dominant axis.
    _npc.startWalking(_directionFromDelta(delta));
  }

  // ---------------------------------------------------------------------------
  // Pause phase
  // ---------------------------------------------------------------------------

  void _updatePausing(double dt) {
    _pauseRemaining -= dt;
    if (_pauseRemaining <= 0) {
      _pickNewTarget();
    }
  }

  // ---------------------------------------------------------------------------
  // Arrival logic
  // ---------------------------------------------------------------------------

  void _onArrival() {
    // 20 % chance to show a quote.
    if (!_quoteBubbleActive && _rng.nextDouble() < _quoteProbability) {
      _showQuoteBubble();
    }

    // Pause for 2–5 seconds.
    _pauseRemaining = 2.0 + _rng.nextDouble() * 3.0;
    _state = _WalkState.pausing;
  }

  // ---------------------------------------------------------------------------
  // Quote bubble
  // ---------------------------------------------------------------------------

  void _showQuoteBubble() {
    final quotes = kNpcQuotes[_npc.npcName];
    if (quotes == null || quotes.isEmpty) return;

    final quote = quotes[_rng.nextInt(quotes.length)];
    final text = NpcQuotes.textOf(quote);

    const bubbleLifetime = 3.0;
    final bubble = NpcQuoteBubble(
      text: text,
      npcPosition: _npc.position.clone(),
      displaySeconds: bubbleLifetime,
    );

    _quoteBubbleActive = true;

    // Add bubble to the game (not to the NPC component) so z-ordering is clean.
    game.add(bubble);

    // Mark quote as done after its lifetime elapses.
    Future.delayed(
      Duration(milliseconds: (bubbleLifetime * 1000).round()),
      () => _quoteBubbleActive = false,
    );
  }

  // ---------------------------------------------------------------------------
  // Target selection
  // ---------------------------------------------------------------------------

  void _pickNewTarget() {
    _state = _WalkState.walking;

    // Pick a random walkable cell from the collision map.
    // Also verify the path is somewhat clear (no walking through walls).
    for (int attempt = 0; attempt < 10; attempt++) {
      final candidate = _collisionMap.randomWalkablePosition(_rng);
      if (_collisionMap.isPathClear(_npc.position, candidate)) {
        _target = candidate;
        return;
      }
    }
    // Fallback: pick any walkable position even if path isn't fully clear.
    _target = _collisionMap.randomWalkablePosition(_rng);
  }

  // ---------------------------------------------------------------------------
  // Direction helper
  // ---------------------------------------------------------------------------

  /// Returns the dominant [NpcDirection] for a movement [delta] vector.
  NpcDirection _directionFromDelta(Vector2 delta) {
    if (delta.x.abs() >= delta.y.abs()) {
      return delta.x >= 0 ? NpcDirection.east : NpcDirection.west;
    } else {
      return delta.y >= 0 ? NpcDirection.south : NpcDirection.north;
    }
  }
}

// ---------------------------------------------------------------------------
// Internal state enum
// ---------------------------------------------------------------------------

enum _WalkState {
  idle,
  walking,
  pausing,
}
