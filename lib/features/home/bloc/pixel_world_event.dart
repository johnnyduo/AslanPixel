import 'package:equatable/equatable.dart';

import 'package:aslan_pixel/core/enums/agent_type.dart';

/// Base class for all PixelWorld BLoC events.
abstract class PixelWorldEvent extends Equatable {
  const PixelWorldEvent();

  @override
  List<Object?> get props => [];
}

/// Fired once when the pixel world screen is first mounted.
class PixelWorldStarted extends PixelWorldEvent {
  const PixelWorldStarted();
}

/// Fired when the user taps on a specific agent sprite.
class PixelWorldAgentTapped extends PixelWorldEvent {
  const PixelWorldAgentTapped(this.agentType);

  final AgentType agentType;

  @override
  List<Object?> get props => [agentType];
}

/// Fired when remote room data has been fetched (e.g. from Firestore).
class PixelWorldRoomLoaded extends PixelWorldEvent {
  const PixelWorldRoomLoaded(this.roomData);

  final Map<String, dynamic> roomData;

  @override
  List<Object?> get props => [roomData];
}
