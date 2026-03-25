import 'dart:math' show Random;

import 'package:flame/components.dart';
import 'package:flame/events.dart';
import 'package:flame/game.dart';
import 'package:flutter/material.dart' show Color;

import 'package:aslan_pixel/core/enums/agent_type.dart';
import 'package:aslan_pixel/features/home/bloc/agent_status.dart';
import 'package:aslan_pixel/features/home/data/models/room_item_model.dart';
import 'package:aslan_pixel/features/home/game/npc_sprite_component.dart';
import 'package:aslan_pixel/features/home/game/npc_walk_controller.dart';
import 'package:aslan_pixel/features/home/game/room_collision_map.dart';
import 'package:aslan_pixel/features/home/game/room_background_component.dart';
import 'package:aslan_pixel/features/home/game/room_item_component.dart';

const double _canvasWidth = 400;
const double _canvasHeight = 800;

// All 13 characters that have LPC walk spritesheets
const _kNpcNames = [
  'npc_analyst_senior',
  'npc_scout',
  'npc_risk',
  'npc_social',
  'npc_banker',
  'npc_trader',
  'npc_champion',
  'npc_oracle',
  'npc_hacker',
  'npc_merchant',
  'npc_pixelcat',
  'npc_sysbot',
  'npc_intern',
];

/// The Flame game that renders the pixel world room.
///
/// Layer order:
///   1. Room background
///   2. 13 NPCs with autonomous walk animation (LPC spritesheets)
///   3. Unlocked room items
class PixelRoomGame extends FlameGame with TapCallbacks {
  PixelRoomGame({
    required Map<AgentType, AgentStatus> agentStatuses,
    required this.onAgentTapped,
  }) : _agentStatuses = Map.unmodifiable(agentStatuses);

  // ignore: unused_field
  Map<AgentType, AgentStatus> _agentStatuses;
  final void Function(AgentType) onAgentTapped;

  final List<RoomItemComponent> _itemComponents = [];

  @override
  Color backgroundColor() => const Color(0xFF0A1628);

  @override
  void onGameResize(Vector2 size) {
    super.onGameResize(size);
    if (size.x <= 0 || size.y <= 0) return;

    // Scale world to fill screen width exactly.
    // Anchor = topLeft so (0,0) world = top-left of screen.
    final zoom = size.x / _canvasWidth;
    camera.viewfinder.zoom = zoom;
    camera.viewfinder.position = Vector2.zero();
  }

  @override
  Future<void> onLoad() async {
    await super.onLoad();
    camera.viewfinder.anchor = Anchor.topLeft;

    // Layer 1: background
    await add(RoomBackgroundComponent(
      roomSize: Vector2(_canvasWidth, _canvasHeight),
    ));

    // Layer 2: NPCs with walk animation
    final rng = Random();
    final collisionMap = RoomCollisionMap();

    for (var i = 0; i < _kNpcNames.length; i++) {
      final pos = _spawnPosition(i, _kNpcNames.length, rng, collisionMap);
      final npc = NpcSpriteComponent(
        npcName: _kNpcNames[i],
        position: pos,
        initialDirection: NpcDirection.values[rng.nextInt(4)],
      );
      await add(npc);
      await add(NpcWalkController(npc: npc, collisionMap: collisionMap));
    }
  }

  /// Spreads NPCs across the visible walkable floor (y: 250–650, x: 40–360).
  /// Uses a 4-column grid with random jitter per slot.
  Vector2 _spawnPosition(
      int index, int total, Random rng, RoomCollisionMap map) {
    const cols = 4;
    const xPad = 40.0;
    const yStart = 260.0; // below furniture zone
    const yEnd = 640.0;   // above bottom wall

    final col = index % cols;
    final row = index ~/ cols;
    final rows = (total / cols).ceil();
    final xStep = (_canvasWidth - xPad * 2) / cols;
    final yStep = (yEnd - yStart) / rows;

    final x = xPad + col * xStep + rng.nextDouble() * (xStep * 0.7);
    final y = yStart + row * yStep + rng.nextDouble() * (yStep * 0.7);
    final candidate = Vector2(x, y);

    return map.isPositionWalkable(candidate)
        ? candidate
        : map.randomWalkablePosition(rng);
  }

  void updateAgentStatuses(Map<AgentType, AgentStatus> statuses) {
    _agentStatuses = Map.unmodifiable(statuses);
  }

  void updateRoomItems(List<RoomItem> items) {
    for (final c in _itemComponents) {
      c.removeFromParent();
    }
    _itemComponents.clear();

    for (final item in items) {
      if (!item.isUnlocked) continue;
      final component = RoomItemComponent(item: item);
      _itemComponents.add(component);
      add(component);
    }
  }
}
