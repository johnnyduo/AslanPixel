import 'package:equatable/equatable.dart';

import 'package:aslan_pixel/core/enums/agent_type.dart';
import 'package:aslan_pixel/features/home/bloc/agent_status.dart';

/// Base class for all PixelWorld BLoC states.
abstract class PixelWorldState extends Equatable {
  const PixelWorldState();

  @override
  List<Object?> get props => [];
}

/// Initial state before the game has started loading.
class PixelWorldInitial extends PixelWorldState {
  const PixelWorldInitial();
}

/// Emitted while the room data is being fetched.
class PixelWorldLoading extends PixelWorldState {
  const PixelWorldLoading();
}

/// Emitted once the room is ready and agent statuses are known.
class PixelWorldLoaded extends PixelWorldState {
  const PixelWorldLoaded(this.agentStatuses);

  final Map<AgentType, AgentStatus> agentStatuses;

  @override
  List<Object?> get props => [agentStatuses];
}

/// Emitted when an unrecoverable error occurs during loading.
class PixelWorldError extends PixelWorldState {
  const PixelWorldError(this.message);

  final String message;

  @override
  List<Object?> get props => [message];
}

/// Emitted when an agent's AI-generated dialogue line is ready to display.
class PixelWorldDialogueLoaded extends PixelWorldState {
  const PixelWorldDialogueLoaded({
    required this.agentType,
    required this.text,
  });

  final AgentType agentType;
  final String text;

  @override
  List<Object?> get props => [agentType, text];
}
