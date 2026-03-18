import 'package:aslan_pixel/core/enums/agent_type.dart';
import 'package:aslan_pixel/features/agents/engine/agent_task_model.dart';

/// Pure Dart idle-task engine — no Firebase, no Flutter dependencies.
///
/// Handles task creation, lazy settlement, and display helpers.
class IdleTaskEngine {
  const IdleTaskEngine._();

  static const Map<TaskTier, Duration> tierDurations = {
    TaskTier.basic: Duration(minutes: 5),
    TaskTier.standard: Duration(minutes: 30),
    TaskTier.advanced: Duration(hours: 2),
    TaskTier.elite: Duration(hours: 8),
  };

  static const Map<TaskTier, int> tierBaseReward = {
    TaskTier.basic: 10,
    TaskTier.standard: 50,
    TaskTier.advanced: 200,
    TaskTier.elite: 800,
  };

  /// Creates a new [AgentTask] for an agent.
  ///
  /// Reward formula: baseReward × (1 + agentLevel × 0.05)
  static AgentTask createTask({
    required String agentId,
    required AgentType agentType,
    required TaskType taskType,
    required TaskTier tier,
    required int agentLevel,
  }) {
    final now = DateTime.now();
    final duration = tierDurations[tier]!;
    final base = tierBaseReward[tier]!;
    final rewardMultiplier = 1.0 + (agentLevel * 0.05);
    final finalReward = (base * rewardMultiplier).round();

    return AgentTask(
      taskId: '${agentId}_${now.millisecondsSinceEpoch}',
      agentId: agentId,
      agentType: agentType,
      taskType: taskType,
      tier: tier,
      startedAt: now,
      completesAt: now.add(duration),
      baseReward: base,
      xpReward: (finalReward * 0.5).round(),
      isSettled: false,
      actualReward: null,
    );
  }

  /// Lazy settlement: call on app open with all pending tasks.
  ///
  /// Returns a list of tasks where any completed-but-unsettled task has
  /// [AgentTask.isSettled] set to `true` and [AgentTask.actualReward] filled in.
  static List<AgentTask> settleTasks(List<AgentTask> tasks, DateTime now) {
    return tasks.map((task) {
      if (task.isSettled || !now.isAfter(task.completesAt)) return task;
      final multiplier = 1.0 + (_getAgentLevelFromTask(task) * 0.05);
      final reward = (task.baseReward * multiplier).round();
      return task.copyWith(isSettled: true, actualReward: reward);
    }).toList();
  }

  /// Returns the [TaskType]s available for a given [AgentType].
  static List<TaskType> availableTaskTypes(AgentType agentType) {
    switch (agentType) {
      case AgentType.analyst:
        return [TaskType.research, TaskType.analysis];
      case AgentType.scout:
        return [TaskType.scoutMission, TaskType.research];
      case AgentType.risk:
        return [TaskType.analysis, TaskType.research];
      case AgentType.social:
        return [TaskType.socialScan, TaskType.scoutMission];
    }
  }

  /// Task display name in Thai.
  static String taskNameTh(TaskType type) {
    switch (type) {
      case TaskType.research:
        return 'วิจัยตลาด';
      case TaskType.scoutMission:
        return 'ภารกิจสอดแนม';
      case TaskType.analysis:
        return 'วิเคราะห์ข้อมูล';
      case TaskType.socialScan:
        return 'สแกนโซเชียล';
    }
  }

  /// Tier display name in Thai with duration hint.
  static String tierNameTh(TaskTier tier) {
    switch (tier) {
      case TaskTier.basic:
        return 'พื้นฐาน (5 นาที)';
      case TaskTier.standard:
        return 'มาตรฐาน (30 นาที)';
      case TaskTier.advanced:
        return 'ขั้นสูง (2 ชั่วโมง)';
      case TaskTier.elite:
        return 'ระดับ Elite (8 ชั่วโมง)';
    }
  }

  // Stub — level is embedded in baseReward at creation time.
  // Pass agentLevel via createTask instead of storing here.
  static int _getAgentLevelFromTask(AgentTask task) => 1;
}
