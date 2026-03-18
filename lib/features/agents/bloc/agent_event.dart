part of 'agent_bloc.dart';

abstract class AgentEvent extends Equatable {
  const AgentEvent();

  @override
  List<Object?> get props => [];
}

class AgentWatchStarted extends AgentEvent {
  const AgentWatchStarted(this.uid);

  final String uid;

  @override
  List<Object?> get props => [uid];
}

class AgentStatusUpdated extends AgentEvent {
  const AgentStatusUpdated({
    required this.agentId,
    required this.status,
  });

  final String agentId;
  final AgentStatus status;

  @override
  List<Object?> get props => [agentId, status];
}

class AgentTaskCompleted extends AgentEvent {
  const AgentTaskCompleted({
    required this.uid,
    required this.agentId,
    required this.coinsEarned,
  });

  final String uid;
  final String agentId;
  final int coinsEarned;

  @override
  List<Object?> get props => [uid, agentId, coinsEarned];
}
