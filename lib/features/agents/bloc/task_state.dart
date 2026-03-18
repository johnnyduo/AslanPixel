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
  const TaskSettledSuccess(this.settledTasks);

  final List<AgentTask> settledTasks;

  @override
  List<Object?> get props => [settledTasks];
}
