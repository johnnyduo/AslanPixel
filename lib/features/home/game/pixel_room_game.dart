import 'dart:ui' show Paint;

import 'package:flame/components.dart';
import 'package:flame/events.dart';
import 'package:flame/game.dart';
import 'package:flutter/material.dart'
    show Color, Colors, FontWeight, TextStyle;

import 'package:aslan_pixel/core/enums/agent_type.dart';
import 'package:aslan_pixel/features/home/bloc/agent_status.dart';

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
const double _canvasHeight = 700;

/// Quadrant centre positions for each agent.
final _agentPositions = <AgentType, Vector2>{
  AgentType.analyst: Vector2(_canvasWidth * 0.25, _canvasHeight * 0.30),
  AgentType.scout: Vector2(_canvasWidth * 0.75, _canvasHeight * 0.30),
  AgentType.risk: Vector2(_canvasWidth * 0.25, _canvasHeight * 0.70),
  AgentType.social: Vector2(_canvasWidth * 0.75, _canvasHeight * 0.70),
};

// ---------------------------------------------------------------------------
// PixelAgentComponent
// ---------------------------------------------------------------------------

/// A single agent rendered as a coloured circle with a name label below it.
///
/// Implements [TapCallbacks] so individual agent taps can be detected.
class PixelAgentComponent extends PositionComponent with TapCallbacks {
  PixelAgentComponent({
    required this.agentType,
    required AgentStatus agentStatus,
    required this.onTapped,
    required Vector2 position,
  })  : _agentStatus = agentStatus,
        super(
          position: position,
          size: Vector2.all(_agentRadius * 2),
          anchor: Anchor.center,
        );

  static const double _agentRadius = 28;

  final AgentType agentType;
  AgentStatus _agentStatus;
  final void Function(AgentType) onTapped;

  late CircleComponent _circle;
  late TextComponent _label;

  AgentStatus get agentStatus => _agentStatus;

  /// Update the agent's status and re-tint the circle accordingly.
  // ignore: avoid_setters_without_getters
  set agentStatus(AgentStatus status) {
    _agentStatus = status;
    _circle.paint.color = _statusTint(status);
  }

  @override
  Future<void> onLoad() async {
    await super.onLoad();

    _circle = CircleComponent(
      radius: _agentRadius,
      paint: _makePaint(_statusTint(_agentStatus)),
      anchor: Anchor.center,
      position: Vector2(_agentRadius, _agentRadius),
    );

    _label = TextComponent(
      text: agentType.displayName,
      position: Vector2(_agentRadius, _agentRadius * 2 + 4),
      anchor: Anchor.topCenter,
      textRenderer: TextPaint(
        style: const TextStyle(
          color: Colors.white,
          fontSize: 11,
          fontWeight: FontWeight.w600,
        ),
      ),
    );

    await addAll([_circle, _label]);
  }

  @override
  void onTapDown(TapDownEvent event) {
    onTapped(agentType);
  }

  // --------------------------------------------------------------------------

  Color _statusTint(AgentStatus status) {
    if (status == AgentStatus.fail) return Colors.redAccent;
    return _agentColor(agentType);
  }

  static Paint _makePaint(Color color) => Paint()..color = color;
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

  @override
  Color backgroundColor() => _colorNavy;

  @override
  Future<void> onLoad() async {
    await super.onLoad();

    // Fixed canvas size — camera will letterbox/scale to fit the widget.
    camera.viewfinder.visibleGameSize = Vector2(_canvasWidth, _canvasHeight);

    // Background fill (redundant given backgroundColor() but explicit for
    // future sprite replacement).
    await add(
      RectangleComponent(
        size: Vector2(_canvasWidth, _canvasHeight),
        paint: Paint()..color = _colorNavy,
      ),
    );

    // Add one PixelAgentComponent per agent type.
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
}
