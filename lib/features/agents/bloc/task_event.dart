part of 'task_bloc.dart';

abstract class TaskEvent extends Equatable {
  const TaskEvent();

  @override
  List<Object?> get props => [];
}

class TaskWatchStarted extends TaskEvent {
  const TaskWatchStarted(this.uid);

  final String uid;

  @override
  List<Object?> get props => [uid];
}

class TaskCreated extends TaskEvent {
  const TaskCreated({
    required this.uid,
    required this.agentId,
    required this.agentType,
    required this.taskType,
    required this.tier,
    required this.agentLevel,
  });

  final String uid;
  final String agentId;
  final AgentType agentType;
  final TaskType taskType;
  final TaskTier tier;
  final int agentLevel;

  @override
  List<Object?> get props => [uid, agentId, agentType, taskType, tier, agentLevel];
}

class TasksSettled extends TaskEvent {
  const TasksSettled(this.uid);

  final String uid;

  @override
  List<Object?> get props => [uid];
}

class TasksSettleRequested extends TaskEvent {
  const TasksSettleRequested({required this.uid});

  final String uid;

  @override
  List<Object?> get props => [uid];
}
