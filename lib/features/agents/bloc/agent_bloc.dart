import 'dart:async';

import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../data/models/agent_model.dart';
import '../data/repositories/agent_repository.dart';

part 'agent_event.dart';
part 'agent_state.dart';

class AgentBloc extends Bloc<AgentEvent, AgentState> {
  AgentBloc({required AgentRepository repository})
      : _repository = repository,
        super(const AgentInitial()) {
    on<AgentWatchStarted>(_onWatchStarted);
    on<AgentStatusUpdated>(_onStatusUpdated);
    on<AgentTaskCompleted>(_onTaskCompleted);
  }

  final AgentRepository _repository;
  StreamSubscription<List<AgentModel>>? _agentsSubscription;
  String? _watchedUid;

  Future<void> _onWatchStarted(
    AgentWatchStarted event,
    Emitter<AgentState> emit,
  ) async {
    if (_watchedUid == event.uid) return;

    _watchedUid = event.uid;
    emit(const AgentLoading());

    await _agentsSubscription?.cancel();

    await emit.forEach<List<AgentModel>>(
      _repository.watchAgents(event.uid),
      onData: AgentLoaded.new,
      onError: (error, _) => AgentError(error.toString()),
    );
  }

  Future<void> _onStatusUpdated(
    AgentStatusUpdated event,
    Emitter<AgentState> emit,
  ) async {
    final uid = _watchedUid;
    if (uid == null) return;

    try {
      await _repository.updateAgentStatus(uid, event.agentId, event.status);
    } catch (e) {
      emit(AgentError(e.toString()));
    }
  }

  Future<void> _onTaskCompleted(
    AgentTaskCompleted event,
    Emitter<AgentState> emit,
  ) async {
    try {
      await _repository.updateAgentStatus(
        event.uid,
        event.agentId,
        AgentStatus.returning,
      );

      await Future<void>.delayed(const Duration(seconds: 1));

      await _repository.updateAgentStatus(
        event.uid,
        event.agentId,
        AgentStatus.celebrating,
      );

      await Future<void>.delayed(const Duration(seconds: 2));

      await _repository.updateAgentStatus(
        event.uid,
        event.agentId,
        AgentStatus.idle,
      );
      await _repository.clearActiveTask(event.uid, event.agentId);
    } catch (e) {
      emit(AgentError(e.toString()));
    }
  }

  @override
  Future<void> close() async {
    await _agentsSubscription?.cancel();
    return super.close();
  }
}
