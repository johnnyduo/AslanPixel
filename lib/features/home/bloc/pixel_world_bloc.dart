import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:aslan_pixel/core/enums/agent_type.dart';
import 'package:aslan_pixel/features/home/bloc/agent_status.dart';
import 'package:aslan_pixel/features/home/bloc/pixel_world_event.dart';
import 'package:aslan_pixel/features/home/bloc/pixel_world_state.dart';

export 'package:aslan_pixel/features/home/bloc/agent_status.dart';
export 'package:aslan_pixel/features/home/bloc/pixel_world_event.dart';
export 'package:aslan_pixel/features/home/bloc/pixel_world_state.dart';

/// Default statuses served before any remote data arrives.
const _defaultStatuses = {
  AgentType.analyst: AgentStatus.idle,
  AgentType.scout: AgentStatus.idle,
  AgentType.risk: AgentStatus.idle,
  AgentType.social: AgentStatus.idle,
};

/// BLoC that manages the lifecycle and state of the pixel world room.
class PixelWorldBloc extends Bloc<PixelWorldEvent, PixelWorldState> {
  PixelWorldBloc() : super(const PixelWorldInitial()) {
    on<PixelWorldStarted>(_onStarted);
    on<PixelWorldAgentTapped>(_onAgentTapped);
    on<PixelWorldRoomLoaded>(_onRoomLoaded);
  }

  // ---------------------------------------------------------------------------
  // Handlers
  // ---------------------------------------------------------------------------

  Future<void> _onStarted(
    PixelWorldStarted event,
    Emitter<PixelWorldState> emit,
  ) async {
    emit(const PixelWorldLoading());

    // Phase 3 will replace this with a real Firestore fetch.
    // For now we resolve immediately with default idle statuses.
    emit(const PixelWorldLoaded(_defaultStatuses));
  }

  void _onAgentTapped(
    PixelWorldAgentTapped event,
    Emitter<PixelWorldState> emit,
  ) {
    // Phase 3: dispatch mission or open detail sheet from here.
    // For now we simply keep current state and let the UI handle the tap.
  }

  void _onRoomLoaded(
    PixelWorldRoomLoaded event,
    Emitter<PixelWorldState> emit,
  ) {
    final rawStatuses =
        event.roomData['agentStatuses'] as Map<String, dynamic>? ?? {};

    final parsed = <AgentType, AgentStatus>{};
    for (final entry in rawStatuses.entries) {
      final agentType = AgentTypeValue.fromString(entry.key);
      final status = _parseStatus(entry.value as String?);
      parsed[agentType] = status;
    }

    // Fill in any agents missing from the remote data.
    for (final type in AgentType.values) {
      parsed.putIfAbsent(type, () => AgentStatus.idle);
    }

    emit(PixelWorldLoaded(Map.unmodifiable(parsed)));
  }

  // ---------------------------------------------------------------------------
  // Helpers
  // ---------------------------------------------------------------------------

  AgentStatus _parseStatus(String? raw) {
    switch (raw) {
      case 'working':
        return AgentStatus.working;
      case 'returning':
        return AgentStatus.returning;
      case 'celebrating':
        return AgentStatus.celebrating;
      case 'fail':
        return AgentStatus.fail;
      default:
        return AgentStatus.idle;
    }
  }
}
