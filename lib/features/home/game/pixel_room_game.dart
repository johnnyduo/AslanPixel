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

    final zoom = size.x / _canvasWidth;
    camera.viewfinder.zoom = zoom;
    camera.viewfinder.position = Vector2(_canvasWidth / 2, size.y / zoom / 2);
  }

  @override
  Future<void> onLoad() async {
    await super.onLoad();
    camera.viewfinder.anchor = Anchor.center;

    // Layer 1: background
    await add(RoomBackgroundComponent(
      roomSize: Vector2(_canvasWidth, _canvasHeight),
    ));

    // Layer 2: NPCs with walk animation
    final rng = Random();
    final collisionMap = RoomCollisionMap();

    // Spread NPCs across walkable zone in a grid pattern
    final positions = _spreadPositions(rng, collisionMap, _kNpcNames.length);

    for (var i = 0; i < _kNpcNames.length; i++) {
      final npc = NpcSpriteComponent(
        npcName: _kNpcNames[i],
        position: positions[i],
        initialDirection: NpcDirection.values[rng.nextInt(4)],
      );
      await add(npc);
      await add(NpcWalkController(npc: npc, collisionMap: collisionMap));
    }
  }

  /// Generates [count] starting positions spread across the walkable area,
  /// falling back to any walkable cell if a preferred slot is blocked.
  List<Vector2> _spreadPositions(
      Random rng, RoomCollisionMap map, int count) {
    final result = <Vector2>[];
    // Divide walkable zone into a loose grid to avoid all spawning in one spot
    final cols = 4;
    final rows = (count / cols).ceil();
    final xStep = (_canvasWidth - 80) / cols;
    final yStart = 300.0;
    final yEnd = 700.0;
    final yStep = (yEnd - yStart) / rows;

    for (var i = 0; i < count; i++) {
      final col = i % cols;
      final row = i ~/ cols;
      final base = Vector2(
        40 + col * xStep + rng.nextDouble() * (xStep * 0.6),
        yStart + row * yStep + rng.nextDouble() * (yStep * 0.6),
      );
      final pos = map.isPositionWalkable(base)
          ? base
          : map.randomWalkablePosition(rng);
      result.add(pos);
    }
    return result;
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
