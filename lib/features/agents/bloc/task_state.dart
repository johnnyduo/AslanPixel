part of 'task_bloc.dart';

abstract class TaskState extends Equatable {
  const TaskState();

  @override
  List<Object?> get props => [];
}

class TaskInitial extends TaskState {
  const TaskInitial();
}

class TaskLoading extends TaskState {
  const TaskLoading();
}

class TaskLoaded extends TaskState {
  const TaskLoaded(this.tasks);

  final List<AgentTask> tasks;

  @override
  List<Object?> get props => [tasks];
}

class TaskCreating extends TaskState {
  const TaskCreating();
}

class TaskError extends TaskState {
  const TaskError(this.message);

  final String message;

  @override
  List<Object?> get props => [message];
}

class TaskSettledSuccess extends TaskState {
  const TaskSettledSuccess(this.settledTasks, {this.summary});

  final List<AgentTask> settledTasks;

  /// Aggregated reward totals for the settlement pass.
  /// May be null when settlement is triggered by legacy callers.
  final RewardSummary? summary;

  @override
  List<Object?> get props => [settledTasks, summary];
}
