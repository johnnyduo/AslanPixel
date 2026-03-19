import 'package:aslan_pixel/core/enums/agent_type.dart';
import 'package:aslan_pixel/features/agents/engine/agent_task_model.dart';
import 'package:aslan_pixel/features/agents/engine/reward_summary.dart';

/// Maximum number of agents a player may have on their team.
const int kMaxTeamSize = 8;

/// Pure Dart idle-task engine — no Firebase, no Flutter dependencies.
///
/// Handles task creation, lazy settlement, and display helpers.
class IdleTaskEngine {
  const IdleTaskEngine._();

  static const Map<TaskTier, Duration> tierDurations = {
    TaskTier.quick: Duration(minutes: 1),
    TaskTier.basic: Duration(minutes: 5),
    TaskTier.standard: Duration(minutes: 30),
    TaskTier.advanced: Duration(hours: 2),
    TaskTier.elite: Duration(hours: 8),
  };

  static const Map<TaskTier, int> tierBaseReward = {
    TaskTier.quick: 5,
    TaskTier.basic: 10,
    TaskTier.standard: 50,
    TaskTier.advanced: 200,
    TaskTier.elite: 800,
  };

  /// XP awarded per tier on settlement (flat, before any multipliers).
  static const Map<TaskTier, int> tierXpReward = {
    TaskTier.quick: 5,
    TaskTier.basic: 10,
    TaskTier.standard: 35,
    TaskTier.advanced: 120,
    TaskTier.elite: 500,
  };

  /// Streak multiplier applied to coin rewards.
  ///
  /// Each consecutive day the user collects rewards adds 0.1× to the
  /// multiplier, capped at 2.0× on day 10.
  ///
  /// Examples:
  ///   day 0  → 1.0×
  ///   day 1  → 1.1×
  ///   day 5  → 1.5×
  ///   day 10 → 2.0×  (maximum)
  static double streakMultiplier(int streakDays) {
    return 1.0 + (streakDays.clamp(0, 10) * 0.1);
  }

  /// Returns true when [streakDays] is a reward-milestone day (3, 7 or 10).
  static bool isStreakMilestone(int streakDays) {
    return streakDays == 3 || streakDays == 7 || streakDays == 10;
  }

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
  /// Returns the updated task list AND a [RewardSummary] describing totals
  /// across all newly-settled tasks, applying the [streakDays] multiplier.
  ///
  /// The raw task list (without summary) is available at
  /// [RewardSummary] fields; the updated list is the first element of the
  /// returned record.
  static ({List<AgentTask> tasks, RewardSummary summary}) settleTasks(
    List<AgentTask> tasks,
    DateTime now, {
    int streakDays = 0,
  }) {
    final mult = streakMultiplier(streakDays);
    var totalCoins = 0;
    var totalXp = 0;
    var settledCount = 0;

    final updated = tasks.map((task) {
      if (task.isSettled || !now.isAfter(task.completesAt)) return task;
      final lvlMult = 1.0 + (_getAgentLevelFromTask(task) * 0.05);
      final reward = ((task.baseReward * lvlMult) * mult).round();
      final xp = tierXpReward[task.tier] ?? task.xpReward;
      totalCoins += reward;
      totalXp += xp;
      settledCount++;
      return task.copyWith(isSettled: true, actualReward: reward);
    }).toList();

    final summary = RewardSummary(
      totalCoins: totalCoins,
      totalXp: totalXp,
      settledCount: settledCount,
      streakBonus: mult,
      isStreakMilestone: isStreakMilestone(streakDays),
    );

    return (tasks: updated, summary: summary);
  }

  // Legacy helper kept for callers that only need the task list.
  static List<AgentTask> settleTasksOnly(
    List<AgentTask> tasks,
    DateTime now,
  ) =>
      settleTasks(tasks, now).tasks;

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
      case TaskTier.quick:
        return 'ด่วน (1 นาที)';
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
