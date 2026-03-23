import 'dart:math' show Random;
import 'dart:ui' as ui;
import 'dart:ui' show Paint;

import 'package:flame/components.dart';
import 'package:flame/events.dart';
import 'package:flame/game.dart';
import 'package:flutter/material.dart'
    show Color, Colors, FontWeight, Shadow, TextStyle;
import 'package:flutter/services.dart' show rootBundle;

import 'package:aslan_pixel/core/enums/agent_type.dart';
import 'package:aslan_pixel/features/home/bloc/agent_status.dart';
import 'package:aslan_pixel/features/home/data/models/room_item_model.dart';
import 'package:aslan_pixel/features/home/game/npc_sprite_component.dart';
import 'package:aslan_pixel/features/home/game/npc_walk_controller.dart';
import 'package:aslan_pixel/features/home/game/room_collision_map.dart';
import 'package:aslan_pixel/features/home/game/room_background_component.dart';
import 'package:aslan_pixel/features/home/game/room_item_component.dart';

// ---------------------------------------------------------------------------
// Color constants
// ---------------------------------------------------------------------------

const _colorNavy = Color(0xFF0A1628);
const _colorAnalyst = Color(0xFF00F5A0); // neon green
const _colorScout = Color(0xFFF5C518); // gold
const _colorRisk = Color(0xFF7B2FFF); // cyber purple
const _colorSocial = Color(0xFF00D9FF); // cyan

Color _agentColor(AgentType type) {
  switch (type) {
    case AgentType.analyst:
      return _colorAnalyst;
    case AgentType.scout:
      return _colorScout;
    case AgentType.risk:
      return _colorRisk;
    case AgentType.social:
      return _colorSocial;
  }
}

// ---------------------------------------------------------------------------
// Canvas dimensions
// ---------------------------------------------------------------------------

const double _canvasWidth = 400;
const double _canvasHeight = 800; // Match 1:2 portrait room background (1024×2048)

/// Quadrant centre positions for each agent — placed in the walkable area
/// (bottom half of the room, below the furniture zone).
final _agentPositions = <AgentType, Vector2>{
  AgentType.analyst: Vector2(60, 420),
  AgentType.scout: Vector2(340, 420),
  AgentType.risk: Vector2(60, 720),
  AgentType.social: Vector2(340, 720),
};

// ---------------------------------------------------------------------------
// PixelAgentComponent
// ---------------------------------------------------------------------------

/// A single agent rendered as a pixel-art sprite with a name label below it.
///
/// Sprites are loaded from `assets/sprites/agents/agent_{name}_{status}.png`
/// via Flutter's [rootBundle] (bypasses Flame's `assets/images/` prefix).
/// Falls back to a coloured circle if the sprite asset is missing.
///
/// Implements [TapCallbacks] so individual agent taps can be detected.
class PixelAgentComponent extends PositionComponent
    with TapCallbacks, HasGameReference<FlameGame> {
  PixelAgentComponent({
    required this.agentType,
    required AgentStatus agentStatus,
    required this.onTapped,
    required Vector2 position,
  })  : _agentStatus = agentStatus,
        super(
          position: position,
          size: Vector2.all(_spriteSize),
          anchor: Anchor.center,
        );

  /// Display size on canvas (scaled up from 16px pixel art).
  static const double _spriteSize = 64;
  final AgentType agentType;
  AgentStatus _agentStatus;
  final void Function(AgentType) onTapped;

  SpriteComponent? _spriteComp;
  late TextComponent _label;

  AgentStatus get agentStatus => _agentStatus;

  set agentStatus(AgentStatus status) {
    _agentStatus = status;
    _loadStatusSprite();
  }

  @override
  Future<void> onLoad() async {
    await super.onLoad();
    await _loadStatusSprite();

    _label = TextComponent(
      text: agentType.displayName,
      position: Vector2(_spriteSize / 2, _spriteSize + 4),
      anchor: Anchor.topCenter,
      textRenderer: TextPaint(
        style: const TextStyle(
          color: Colors.white,
          fontSize: 11,
          fontWeight: FontWeight.w600,
          shadows: [Shadow(color: Colors.black, blurRadius: 4)],
        ),
      ),
    );
    await add(_label);
  }

  Future<void> _loadStatusSprite() async {
    final agentName = _agentSpriteName(agentType);
    final statusName = _statusSpriteName(_agentStatus);
    final path = 'assets/sprites/agents/agent_${agentName}_$statusName.png';

    try {
      final data = await rootBundle.load(path);
      final bytes = data.buffer.asUint8List();
      final codec = await ui.instantiateImageCodec(bytes);
      final frame = await codec.getNextFrame();
      final sheetImg = frame.image;

      // Agent sprites are sprite sheets (e.g. 64×16 = 4 frames of 16×16).
      // Use Sprite's built-in srcPosition/srcSize to crop the first frame
      // instead of PictureRecorder which can fail on some devices.
      final frameH = sheetImg.height.toDouble();
      final frameW = frameH; // Each frame is square (16×16)

      final sprite = Sprite(
        sheetImg,
        srcPosition: Vector2(0, 0),
        srcSize: Vector2(frameW, frameH),
      );

      if (_spriteComp != null) {
        _spriteComp!.sprite = sprite;
      } else {
        _spriteComp = SpriteComponent(
          sprite: sprite,
          size: Vector2.all(_spriteSize),
          anchor: Anchor.topLeft,
        );
        await add(_spriteComp!);
      }
    } catch (e) {
      // Fallback to colored circle if sprite fails
      if (_spriteComp == null) {
        final circle = CircleComponent(
          radius: _spriteSize / 2,
          paint: Paint()..color = _agentColor(agentType),
          anchor: Anchor.center,
          position: Vector2(_spriteSize / 2, _spriteSize / 2),
        );
        await add(circle);
      }
    }
  }

  String _agentSpriteName(AgentType type) {
    switch (type) {
      case AgentType.analyst:
        return 'analyst';
      case AgentType.scout:
        return 'scout';
      case AgentType.risk:
        return 'guardian';
      case AgentType.social:
        return 'social';
    }
  }

  String _statusSpriteName(AgentStatus status) {
    switch (status) {
      case AgentStatus.idle:
        return 'idle';
      case AgentStatus.working:
        return 'working';
      case AgentStatus.returning:
        return 'returning';
      case AgentStatus.celebrating:
        return 'celebrating';
      case AgentStatus.fail:
        return 'fail';
    }
  }

  @override
  void onTapDown(TapDownEvent event) => onTapped(agentType);
}

// ---------------------------------------------------------------------------
// PixelRoomGame
// ---------------------------------------------------------------------------

/// The Flame game that renders the pixel world room.
///
/// [agentStatuses] is provided at construction time and can be updated by
/// calling [updateAgentStatuses] from the Flutter widget tree.
class PixelRoomGame extends FlameGame with TapCallbacks {
  PixelRoomGame({
    required Map<AgentType, AgentStatus> agentStatuses,
    required this.onAgentTapped,
  }) : _agentStatuses = Map.unmodifiable(agentStatuses);

  Map<AgentType, AgentStatus> _agentStatuses;

  /// Called with the tapped [AgentType] whenever the user taps an agent.
  final void Function(AgentType) onAgentTapped;

  final Map<AgentType, PixelAgentComponent> _agentComponents = {};

  /// Room item components currently rendered on the canvas.
  final List<RoomItemComponent> _itemComponents = [];

  @override
  Color backgroundColor() => _colorNavy;

  @override
  void onGameResize(Vector2 size) {
    super.onGameResize(size);
    if (size.x <= 0 || size.y <= 0) return;

    // Fill screen: zoom so the 400px-wide world covers the full screen width.
    // Height adjusts proportionally — no stretch, no black bars.
    final zoom = size.x / _canvasWidth;
    camera.viewfinder.zoom = zoom;

    // Center camera so top of room aligns with top of screen.
    camera.viewfinder.position = Vector2(_canvasWidth / 2, size.y / zoom / 2);
  }

  @override
  Future<void> onLoad() async {
    await super.onLoad();

    camera.viewfinder.anchor = Anchor.center;

    // ------------------------------------------------------------------
    // Layer 1: Room background (replaces plain RectangleComponent fill)
    // ------------------------------------------------------------------
    await add(
      RoomBackgroundComponent(
        roomSize: Vector2(_canvasWidth, _canvasHeight),
      ),
    );

    // ------------------------------------------------------------------
    // Layer 2: NPC sprites + autonomous walk controllers
    //
    // Ten NPCs are spread across the 400 × 700 canvas.  Each gets a
    // NpcWalkController added as a sibling component (not a child of the
    // sprite) so the controller can freely update the sprite's position.
    //
    // Sprite identifiers match assets/sprites/npcs/npc_{name}_{dir}.png
    // Missing assets are handled gracefully inside NpcSpriteComponent.
    // ------------------------------------------------------------------
    // NPCs spread across the walkable area (bottom half of room).
    // Top half (0-400): room furniture area — BLOCKED
    // Bottom half (400-750): open floor / NPC walking area
    // NPCs spread across entire walkable area (rows 6-18, cols 1-8 = y:240-720, x:40-360)
    final npcConfigs = [
      _NpcConfig(name: 'npc_banker',         position: Vector2(80,  300), direction: NpcDirection.south),
      _NpcConfig(name: 'npc_trader',         position: Vector2(300, 350), direction: NpcDirection.east),
      _NpcConfig(name: 'npc_champion',       position: Vector2(200, 280), direction: NpcDirection.west),
      _NpcConfig(name: 'npc_merchant',       position: Vector2(160, 450), direction: NpcDirection.south),
      _NpcConfig(name: 'npc_sysbot',         position: Vector2(320, 500), direction: NpcDirection.south),
      _NpcConfig(name: 'npc_pixelcat',       position: Vector2(100, 550), direction: NpcDirection.east),
      _NpcConfig(name: 'npc_analyst_senior', position: Vector2(250, 400), direction: NpcDirection.east),
      _NpcConfig(name: 'npc_hacker',         position: Vector2(340, 620), direction: NpcDirection.west),
      _NpcConfig(name: 'npc_oracle',         position: Vector2(180, 650), direction: NpcDirection.south),
      _NpcConfig(name: 'npc_intern',         position: Vector2(120, 700), direction: NpcDirection.south),
    ];

    // Create shared collision map for NPC pathfinding.
    // Room items will be blocked dynamically when updateRoomItems is called.
    final collisionMap = RoomCollisionMap();

    for (final cfg in npcConfigs) {
      // Place NPC at a walkable starting position.
      final startPos = collisionMap.isPositionWalkable(cfg.position)
          ? cfg.position
          : collisionMap.randomWalkablePosition(Random());

      final npc = NpcSpriteComponent(
        npcName: cfg.name,
        position: startPos,
        initialDirection: cfg.direction,
      );
      await add(npc);

      // Walk controller uses collision map for valid pathfinding.
      await add(NpcWalkController(npc: npc, collisionMap: collisionMap));
    }

    // ------------------------------------------------------------------
    // Layer 3: Agent circles (existing PixelAgentComponent instances)
    // ------------------------------------------------------------------
    for (final type in AgentType.values) {
      final status = _agentStatuses[type] ?? AgentStatus.idle;
      final position = _agentPositions[type]!;

      final component = PixelAgentComponent(
        agentType: type,
        agentStatus: status,
        onTapped: onAgentTapped,
        position: position,
      );

      _agentComponents[type] = component;
      await add(component);
    }
  }

  /// Called from the Flutter widget tree when the BLoC emits a new
  /// [PixelWorldLoaded] state with updated agent statuses.
  void updateAgentStatuses(Map<AgentType, AgentStatus> statuses) {
    _agentStatuses = Map.unmodifiable(statuses);
    for (final entry in statuses.entries) {
      _agentComponents[entry.key]?.agentStatus = entry.value;
    }
  }

  /// Called from the Flutter widget tree when [RoomBloc] emits [RoomLoaded].
  ///
  /// Removes all previously rendered item components and re-adds every
  /// unlocked item from [items] at its grid-slot position.
  ///
  /// Items are rendered in the floor area (below ≈ 42 % of canvas height),
  /// which corresponds to slot-Y positions that map into the lower portion
  /// of the 400 × 700 canvas (`slotY * 48` ≥ ~ 0.42 * 700 ≈ 294 px
  /// for slotY ≥ 7).  Slots near the top half of the canvas are still valid
  /// and render correctly; the constraint is only visual / design guidance.
  void updateRoomItems(List<RoomItem> items) {
    // Remove all existing item components.
    for (final component in _itemComponents) {
      component.removeFromParent();
    }
    _itemComponents.clear();

    // Add a component for every unlocked item.
    for (final item in items) {
      if (!item.isUnlocked) continue;
      final component = RoomItemComponent(item: item);
      _itemComponents.add(component);
      add(component);
    }
  }
}

// ---------------------------------------------------------------------------
// Private data class
// ---------------------------------------------------------------------------

class _NpcConfig {
  const _NpcConfig({
    required this.name,
    required this.position,
    required this.direction,
  });

  final String name;
  final Vector2 position;
  final NpcDirection direction;
}
