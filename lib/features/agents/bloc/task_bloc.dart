import 'dart:async';

import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:aslan_pixel/core/enums/agent_type.dart';
import 'package:aslan_pixel/core/utils/local_notification_service.dart';
import 'package:aslan_pixel/features/agents/data/repositories/agent_task_repository.dart';
import 'package:aslan_pixel/features/agents/engine/agent_task_model.dart';
import 'package:aslan_pixel/features/agents/engine/idle_task_engine.dart';

part 'task_event.dart';
part 'task_state.dart';

class TaskBloc extends Bloc<TaskEvent, TaskState> {
  TaskBloc({required AgentTaskRepository repository})
      : _repository = repository,
        super(const TaskInitial()) {
    on<TaskWatchStarted>(_onWatchStarted);
    on<TaskCreated>(_onTaskCreated);
    on<TasksSettled>(_onTasksSettled);
    on<TasksSettleRequested>(_onSettleRequested);
  }

  final AgentTaskRepository _repository;
  String? _watchedUid;

  Future<void> _onWatchStarted(
    TaskWatchStarted event,
    Emitter<TaskState> emit,
  ) async {
    if (_watchedUid == event.uid) return;

    _watchedUid = event.uid;
    emit(const TaskLoading());

    await emit.forEach<List<AgentTask>>(
      _repository.watchPendingTasks(event.uid),
      onData: TaskLoaded.new,
      onError: (error, _) => TaskError(error.toString()),
    );
  }

  Future<void> _onTaskCreated(
    TaskCreated event,
    Emitter<TaskState> emit,
  ) async {
    emit(const TaskCreating());
    try {
      final task = IdleTaskEngine.createTask(
        agentId: event.agentId,
        agentType: event.agentType,
        taskType: event.taskType,
        tier: event.tier,
        agentLevel: event.agentLevel,
      );
      await _repository.saveTask(event.uid, task);

      // Re-watch to emit updated list (stream will update automatically).
      _watchedUid = null;
      add(TaskWatchStarted(event.uid));
    } catch (e) {
      emit(TaskError(e.toString()));
    }
  }

  Future<void> _onTasksSettled(
    TasksSettled event,
    Emitter<TaskState> emit,
  ) async {
    final current = state;
    if (current is! TaskLoaded) return;

    try {
      final now = DateTime.now();
      final settled = IdleTaskEngine.settleTasks(current.tasks, now);

      // Persist each newly settled task to Firestore.
      final toSettle = settled.where(
        (t) =>
            t.isSettled &&
            t.actualReward != null &&
            current.tasks.any((old) => old.taskId == t.taskId && !old.isSettled),
      );

      for (final task in toSettle) {
        await _repository.settleTask(event.uid, task.taskId, task.actualReward!);
        unawaited(LocalNotificationService.instance.showTaskComplete(
          task.agentType.displayName,
          task.actualReward!,
        ));
      }

      final newlySettled =
          settled.where((t) => t.isSettled && t.actualReward != null).toList();
      if (newlySettled.isNotEmpty) {
        emit(TaskSettledSuccess(newlySettled));
      }
      emit(TaskLoaded(settled));
    } catch (e) {
      emit(TaskError(e.toString()));
    }
  }

  Future<void> _onSettleRequested(
    TasksSettleRequested event,
    Emitter<TaskState> emit,
  ) async {
    final current = state;
    List<AgentTask> tasks;

    if (current is TaskLoaded) {
      tasks = current.tasks;
    } else {
      // Fetch tasks from repository if stream hasn't loaded yet.
      try {
        tasks = await _repository
            .watchPendingTasks(event.uid)
            .first;
      } catch (e) {
        emit(TaskError(e.toString()));
        return;
      }
    }

    try {
      final now = DateTime.now();
      final settled = IdleTaskEngine.settleTasks(tasks, now);

      final toSettle = settled.where(
        (t) =>
            t.isSettled &&
            t.actualReward != null &&
            tasks.any((old) => old.taskId == t.taskId && !old.isSettled),
      );

      for (final task in toSettle) {
        await _repository.settleTask(event.uid, task.taskId, task.actualReward!);
        unawaited(LocalNotificationService.instance.showTaskComplete(
          task.agentType.displayName,
          task.actualReward!,
        ));
      }

      final newlySettled = toSettle.toList();
      if (newlySettled.isNotEmpty) {
        emit(TaskSettledSuccess(newlySettled));
      }
      emit(TaskLoaded(settled));
    } catch (e) {
      emit(TaskError(e.toString()));
    }
  }
}
