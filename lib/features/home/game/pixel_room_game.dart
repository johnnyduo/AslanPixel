import 'package:flame/components.dart';
import 'package:flame/events.dart';
import 'package:flame/game.dart';
import 'package:flutter/material.dart' show Color;

import 'package:aslan_pixel/core/enums/agent_type.dart';
import 'package:aslan_pixel/features/home/bloc/agent_status.dart';
import 'package:aslan_pixel/features/home/data/models/room_item_model.dart';
import 'package:aslan_pixel/features/home/game/room_background_component.dart';
import 'package:aslan_pixel/features/home/game/room_item_component.dart';

// ---------------------------------------------------------------------------
// Canvas dimensions
// ---------------------------------------------------------------------------

const double _canvasWidth = 400;
const double _canvasHeight = 800;

// ---------------------------------------------------------------------------
// PixelRoomGame
// ---------------------------------------------------------------------------

/// The Flame game that renders the pixel world room.
///
/// Renders only the room background and any unlocked room items.
/// Agent sprites and NPC walkers have been removed — the map is clean.
class PixelRoomGame extends FlameGame with TapCallbacks {
  PixelRoomGame({
    required Map<AgentType, AgentStatus> agentStatuses,
    required this.onAgentTapped,
  }) : _agentStatuses = Map.unmodifiable(agentStatuses);

  // Kept for API compatibility with RoomPage widget tree.
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

    await add(
      RoomBackgroundComponent(
        roomSize: Vector2(_canvasWidth, _canvasHeight),
      ),
    );
  }

  /// No-op — agent statuses are kept for API compatibility but not rendered.
  void updateAgentStatuses(Map<AgentType, AgentStatus> statuses) {
    _agentStatuses = Map.unmodifiable(statuses);
  }

  /// Replaces all rendered room items with [items].
  void updateRoomItems(List<RoomItem> items) {
    for (final component in _itemComponents) {
      component.removeFromParent();
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
