import 'package:aslan_pixel/features/agents/engine/agent_task_model.dart';

/// Abstract contract for persisting and observing [AgentTask] records.
abstract class AgentTaskRepository {
  /// Saves [task] under `agentTasks/{uid}/tasks/{task.taskId}`.
  Future<void> saveTask(String uid, AgentTask task);

  /// Stream of unsettled tasks for [uid].
  Stream<List<AgentTask>> watchPendingTasks(String uid);

  /// Marks [taskId] as settled, writes [actualReward] back, and credits
  /// coins + XP to the user's economy document inside a transaction.
  Future<void> settleTask(String uid, String taskId, int actualReward);

  /// Batch-deletes all settled tasks that are older than 7 days.
  Future<void> clearSettledTasks(String uid);
}
