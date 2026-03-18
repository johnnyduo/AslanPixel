// ignore_for_file: prefer_const_constructors

import 'package:flutter_test/flutter_test.dart';

import 'package:aslan_pixel/core/enums/agent_type.dart';
import 'package:aslan_pixel/features/agents/engine/agent_task_model.dart';
import 'package:aslan_pixel/features/agents/engine/idle_task_engine.dart';

// ── Helpers ───────────────────────────────────────────────────────────────────

AgentTask _makeTask({
  String taskId = 'task_001',
  TaskTier tier = TaskTier.basic,
  int agentLevel = 1,
  bool completed = false,
  bool settled = false,
}) {
  final base = DateTime(2026, 3, 18, 12, 0);
  final start = base.subtract(const Duration(hours: 2));
  final completesAt = completed
      ? base.subtract(const Duration(minutes: 1))
      : base.add(const Duration(hours: 1));

  final baseReward = IdleTaskEngine.tierBaseReward[tier]!;
  final mult = 1.0 + (agentLevel * 0.05);
  final finalReward = (baseReward * mult).round();
  final xp = (finalReward * 0.5).round();

  return AgentTask(
    taskId: taskId,
    agentId: 'agent_001',
    agentType: AgentType.analyst,
    taskType: TaskType.research,
    tier: tier,
    startedAt: start,
    completesAt: completesAt,
    baseReward: baseReward,
    xpReward: xp,
    isSettled: settled,
    actualReward: settled ? finalReward : null,
  );
}

void main() {
  final kNow = DateTime(2026, 3, 18, 12, 0);

  // ── kMaxTeamSize constant ──────────────────────────────────────────────────

  group('kMaxTeamSize', () {
    test('equals 8', () {
      expect(kMaxTeamSize, 8);
    });
  });

  // ── IdleTaskEngine.createTask ─────────────────────────────────────────────

  group('IdleTaskEngine.createTask — tier durations', () {
    test('basic tier duration is 5 minutes', () {
      final task = IdleTaskEngine.createTask(
        agentId: 'a1',
        agentType: AgentType.analyst,
        taskType: TaskType.research,
        tier: TaskTier.basic,
        agentLevel: 1,
      );
      expect(task.completesAt.difference(task.startedAt),
          const Duration(minutes: 5));
    });

    test('standard tier duration is 30 minutes', () {
      final task = IdleTaskEngine.createTask(
        agentId: 'a1',
        agentType: AgentType.scout,
        taskType: TaskType.scoutMission,
        tier: TaskTier.standard,
        agentLevel: 1,
      );
      expect(task.completesAt.difference(task.startedAt),
          const Duration(minutes: 30));
    });

    test('advanced tier duration is 2 hours', () {
      final task = IdleTaskEngine.createTask(
        agentId: 'a1',
        agentType: AgentType.risk,
        taskType: TaskType.analysis,
        tier: TaskTier.advanced,
        agentLevel: 1,
      );
      expect(task.completesAt.difference(task.startedAt),
          const Duration(hours: 2));
    });

    test('elite tier duration is 8 hours', () {
      final task = IdleTaskEngine.createTask(
        agentId: 'a1',
        agentType: AgentType.social,
        taskType: TaskType.socialScan,
        tier: TaskTier.elite,
        agentLevel: 1,
      );
      expect(task.completesAt.difference(task.startedAt),
          const Duration(hours: 8));
    });
  });

  group('IdleTaskEngine.createTask — reward formula', () {
    // Formula: baseReward × (1 + agentLevel × 0.05)

    test('basic tier level 1: 10 × 1.05 = 10 (base), xp > 0', () {
      final task = IdleTaskEngine.createTask(
        agentId: 'a1',
        agentType: AgentType.analyst,
        taskType: TaskType.research,
        tier: TaskTier.basic,
        agentLevel: 1,
      );
      expect(task.baseReward, 10);
      expect(task.xpReward, greaterThan(0));
    });

    test('elite tier level 10: 800 × 1.5 = 1200 → xp = 600', () {
      final task = IdleTaskEngine.createTask(
        agentId: 'a1',
        agentType: AgentType.analyst,
        taskType: TaskType.research,
        tier: TaskTier.elite,
        agentLevel: 10,
      );
      expect(task.xpReward, 600);
    });

    test('higher level agent earns higher xpReward on same tier', () {
      final low = IdleTaskEngine.createTask(
        agentId: 'a1',
        agentType: AgentType.analyst,
        taskType: TaskType.research,
        tier: TaskTier.elite,
        agentLevel: 1,
      );
      final high = IdleTaskEngine.createTask(
        agentId: 'a1',
        agentType: AgentType.analyst,
        taskType: TaskType.research,
        tier: TaskTier.elite,
        agentLevel: 10,
      );
      expect(high.xpReward, greaterThan(low.xpReward));
    });
  });

  // ── settleTasks — task settlement logic ───────────────────────────────────

  group('IdleTaskEngine.settleTasks — task settlement', () {
    test('completed unsettled task is settled with actualReward', () {
      final task = _makeTask(completed: true, settled: false);
      final result = IdleTaskEngine.settleTasks([task], kNow);
      final updated = result.tasks.first;
      expect(updated.isSettled, isTrue);
      expect(updated.actualReward, isNotNull);
      expect(updated.actualReward, greaterThan(0));
    });

    test('task not yet complete (completesAt in future) is NOT settled', () {
      final task = _makeTask(completed: false, settled: false);
      final result = IdleTaskEngine.settleTasks([task], kNow);
      expect(result.tasks.first.isSettled, isFalse);
      expect(result.tasks.first.actualReward, isNull);
    });

    test('already settled task is not re-settled', () {
      final task = _makeTask(completed: true, settled: true);
      final result = IdleTaskEngine.settleTasks([task], kNow);
      // isSettled and actualReward remain as they were
      expect(result.tasks.first.isSettled, isTrue);
      expect(result.tasks.first.actualReward, isNotNull);
      // settledCount should be 0 — this task was already settled
      expect(result.summary.settledCount, 0);
    });

    test('returns same list length for mixed tasks', () {
      final tasks = [
        _makeTask(taskId: 't1', completed: true),
        _makeTask(taskId: 't2', completed: false),
        _makeTask(taskId: 't3', completed: true, settled: true),
      ];
      final result = IdleTaskEngine.settleTasks(tasks, kNow);
      expect(result.tasks.length, 3);
    });

    test('only newly completed tasks are marked settled', () {
      final tasks = [
        _makeTask(taskId: 't1', completed: true),  // should settle
        _makeTask(taskId: 't2', completed: false), // should NOT
      ];
      final result = IdleTaskEngine.settleTasks(tasks, kNow);
      expect(result.tasks[0].isSettled, isTrue);
      expect(result.tasks[1].isSettled, isFalse);
    });

    test('empty task list returns empty tasks and zero summary', () {
      final result = IdleTaskEngine.settleTasks([], kNow);
      expect(result.tasks, isEmpty);
      expect(result.summary.totalCoins, 0);
      expect(result.summary.totalXp, 0);
      expect(result.summary.settledCount, 0);
    });
  });

  // ── RewardSummary totals ──────────────────────────────────────────────────

  group('IdleTaskEngine.settleTasks — RewardSummary totals', () {
    test('totalCoins sums actualReward for all newly settled tasks', () {
      final tasks = [
        _makeTask(taskId: 't1', tier: TaskTier.basic, completed: true),
        _makeTask(taskId: 't2', tier: TaskTier.standard, completed: true),
      ];
      final result = IdleTaskEngine.settleTasks(tasks, kNow);
      expect(result.summary.settledCount, 2);
      expect(result.summary.totalCoins, greaterThan(0));
    });

    test('totalXp uses tierXpReward values', () {
      final task = _makeTask(tier: TaskTier.advanced, completed: true);
      final result = IdleTaskEngine.settleTasks([task], kNow);
      // advanced tier XP = 120
      expect(result.summary.totalXp, 120);
    });

    test('settledCount equals number of newly settled tasks', () {
      final tasks = [
        _makeTask(taskId: 't1', completed: true),
        _makeTask(taskId: 't2', completed: true),
        _makeTask(taskId: 't3', completed: false),
        _makeTask(taskId: 't4', completed: true, settled: true),
      ];
      final result = IdleTaskEngine.settleTasks(tasks, kNow);
      expect(result.summary.settledCount, 2);
    });
  });

  // ── streakMultiplier ──────────────────────────────────────────────────────

  group('IdleTaskEngine.streakMultiplier', () {
    test('day 0 returns 1.0x', () {
      expect(IdleTaskEngine.streakMultiplier(0), closeTo(1.0, 0.001));
    });

    test('day 1 returns 1.1x', () {
      expect(IdleTaskEngine.streakMultiplier(1), closeTo(1.1, 0.001));
    });

    test('day 5 returns 1.5x', () {
      expect(IdleTaskEngine.streakMultiplier(5), closeTo(1.5, 0.001));
    });

    test('day 10 returns 2.0x (maximum)', () {
      expect(IdleTaskEngine.streakMultiplier(10), closeTo(2.0, 0.001));
    });

    test('day 11 is clamped to 2.0x — does not exceed cap', () {
      expect(IdleTaskEngine.streakMultiplier(11), closeTo(2.0, 0.001));
    });

    test('day 100 is clamped to 2.0x', () {
      expect(IdleTaskEngine.streakMultiplier(100), closeTo(2.0, 0.001));
    });

    test('negative days are clamped to 1.0x', () {
      expect(IdleTaskEngine.streakMultiplier(-5), closeTo(1.0, 0.001));
    });
  });

  // ── streak multiplier applied in settleTasks ──────────────────────────────

  group('IdleTaskEngine.settleTasks — streak bonus applied', () {
    test('streak day 0 and day 10 produce different totalCoins', () {
      final task = _makeTask(tier: TaskTier.standard, completed: true);

      final noStreak =
          IdleTaskEngine.settleTasks([task], kNow, streakDays: 0);
      final maxStreak =
          IdleTaskEngine.settleTasks([task], kNow, streakDays: 10);

      expect(maxStreak.summary.totalCoins,
          greaterThan(noStreak.summary.totalCoins));
    });

    test('summary.streakBonus reflects passed streakDays', () {
      final task = _makeTask(tier: TaskTier.basic, completed: true);
      final result =
          IdleTaskEngine.settleTasks([task], kNow, streakDays: 3);
      expect(result.summary.streakBonus, closeTo(1.3, 0.001));
    });

    test('isStreakMilestone is true for day 3', () {
      final task = _makeTask(tier: TaskTier.basic, completed: true);
      final result =
          IdleTaskEngine.settleTasks([task], kNow, streakDays: 3);
      expect(result.summary.isStreakMilestone, isTrue);
    });

    test('isStreakMilestone is true for day 7', () {
      final task = _makeTask(tier: TaskTier.basic, completed: true);
      final result =
          IdleTaskEngine.settleTasks([task], kNow, streakDays: 7);
      expect(result.summary.isStreakMilestone, isTrue);
    });

    test('isStreakMilestone is true for day 10', () {
      final task = _makeTask(tier: TaskTier.basic, completed: true);
      final result =
          IdleTaskEngine.settleTasks([task], kNow, streakDays: 10);
      expect(result.summary.isStreakMilestone, isTrue);
    });

    test('isStreakMilestone is false for day 5', () {
      final task = _makeTask(tier: TaskTier.basic, completed: true);
      final result =
          IdleTaskEngine.settleTasks([task], kNow, streakDays: 5);
      expect(result.summary.isStreakMilestone, isFalse);
    });
  });

  // ── tierXpReward constants ────────────────────────────────────────────────

  group('IdleTaskEngine.tierXpReward', () {
    test('basic XP = 10', () {
      expect(IdleTaskEngine.tierXpReward[TaskTier.basic], 10);
    });

    test('standard XP = 35', () {
      expect(IdleTaskEngine.tierXpReward[TaskTier.standard], 35);
    });

    test('advanced XP = 120', () {
      expect(IdleTaskEngine.tierXpReward[TaskTier.advanced], 120);
    });

    test('elite XP = 500', () {
      expect(IdleTaskEngine.tierXpReward[TaskTier.elite], 500);
    });

    test('XP increases with tier rank', () {
      expect(IdleTaskEngine.tierXpReward[TaskTier.basic]!,
          lessThan(IdleTaskEngine.tierXpReward[TaskTier.standard]!));
      expect(IdleTaskEngine.tierXpReward[TaskTier.standard]!,
          lessThan(IdleTaskEngine.tierXpReward[TaskTier.advanced]!));
      expect(IdleTaskEngine.tierXpReward[TaskTier.advanced]!,
          lessThan(IdleTaskEngine.tierXpReward[TaskTier.elite]!));
    });
  });

  // ── isStreakMilestone ─────────────────────────────────────────────────────

  group('IdleTaskEngine.isStreakMilestone', () {
    test('days 3, 7, 10 are milestones', () {
      expect(IdleTaskEngine.isStreakMilestone(3), isTrue);
      expect(IdleTaskEngine.isStreakMilestone(7), isTrue);
      expect(IdleTaskEngine.isStreakMilestone(10), isTrue);
    });

    test('days 0, 1, 2, 4, 5, 6, 8, 9 are NOT milestones', () {
      for (final d in [0, 1, 2, 4, 5, 6, 8, 9]) {
        expect(IdleTaskEngine.isStreakMilestone(d), isFalse,
            reason: 'day $d should not be a milestone');
      }
    });
  });
}
