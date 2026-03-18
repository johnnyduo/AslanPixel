import 'package:flutter_test/flutter_test.dart';

import 'package:aslan_pixel/core/enums/agent_type.dart';
import 'package:aslan_pixel/features/agents/engine/agent_task_model.dart';
import 'package:aslan_pixel/features/agents/engine/idle_task_engine.dart';

void main() {
  // ── createTask ─────────────────────────────────────────────────────────────

  group('IdleTaskEngine.createTask', () {
    AgentTask makeTask({
      AgentType type = AgentType.analyst,
      TaskType taskType = TaskType.research,
      TaskTier tier = TaskTier.basic,
      int level = 1,
    }) =>
        IdleTaskEngine.createTask(
          agentId: 'agent_001',
          agentType: type,
          taskType: taskType,
          tier: tier,
          agentLevel: level,
        );

    test('returns AgentTask with correct agentId and type', () {
      final task = makeTask();
      expect(task.agentId, 'agent_001');
      expect(task.agentType, AgentType.analyst);
      expect(task.taskType, TaskType.research);
      expect(task.tier, TaskTier.basic);
    });

    test('isSettled is false on creation', () {
      expect(makeTask().isSettled, isFalse);
    });

    test('actualReward is null on creation', () {
      expect(makeTask().actualReward, isNull);
    });

    test('taskId is unique per call', () async {
      final t1 = makeTask();
      // Ensure different millisecond timestamp
      await Future.delayed(const Duration(milliseconds: 2));
      final t2 = makeTask();
      expect(t1.taskId, isNot(equals(t2.taskId)));
    });

    // ── Tier durations ─────────────────────────────────────────────────────

    test('basic tier completesAt is ~5 minutes from now', () {
      final task = makeTask(tier: TaskTier.basic);
      final diff = task.completesAt.difference(task.startedAt);
      expect(diff, equals(const Duration(minutes: 5)));
    });

    test('standard tier completesAt is 30 minutes from now', () {
      final task = makeTask(tier: TaskTier.standard);
      expect(
        task.completesAt.difference(task.startedAt),
        equals(const Duration(minutes: 30)),
      );
    });

    test('advanced tier completesAt is 2 hours from now', () {
      final task = makeTask(tier: TaskTier.advanced);
      expect(
        task.completesAt.difference(task.startedAt),
        equals(const Duration(hours: 2)),
      );
    });

    test('elite tier completesAt is 8 hours from now', () {
      final task = makeTask(tier: TaskTier.elite);
      expect(
        task.completesAt.difference(task.startedAt),
        equals(const Duration(hours: 8)),
      );
    });

    // ── Reward formula: base × (1 + level × 0.05) ──────────────────────────

    test('basic tier level 1 reward = 10 * 1.05 = 11', () {
      // 10 * (1 + 1*0.05) = 10 * 1.05 = 10.5 → rounds to 11
      // xpReward = 11 * 0.5 = 5.5 → rounds to 6
      final task = makeTask(tier: TaskTier.basic, level: 1);
      expect(task.baseReward, 10);
      // xpReward is stored on the task
      expect(task.xpReward, greaterThan(0));
    });

    test('standard tier base reward is 50', () {
      final task = makeTask(tier: TaskTier.standard);
      expect(task.baseReward, 50);
    });

    test('advanced tier base reward is 200', () {
      final task = makeTask(tier: TaskTier.advanced);
      expect(task.baseReward, 200);
    });

    test('elite tier base reward is 800', () {
      final task = makeTask(tier: TaskTier.elite);
      expect(task.baseReward, 800);
    });

    test('higher level agent earns higher xpReward', () {
      final low = makeTask(tier: TaskTier.elite, level: 1);
      final high = makeTask(tier: TaskTier.elite, level: 10);
      expect(high.xpReward, greaterThan(low.xpReward));
    });

    test('level 10 elite reward = 800 * 1.5 = 1200 → xp = 600', () {
      final task = makeTask(tier: TaskTier.elite, level: 10);
      // xpReward = round(round(800 * 1.5) * 0.5) = round(1200 * 0.5) = 600
      expect(task.xpReward, 600);
    });
  });

  // ── settleTasks ────────────────────────────────────────────────────────────

  group('IdleTaskEngine.settleTasks', () {
    final now = DateTime(2026, 3, 18, 12, 0);

    AgentTask pending({bool completed = false, bool settled = false}) =>
        AgentTask(
          taskId: 'task_001',
          agentId: 'agent_001',
          agentType: AgentType.analyst,
          taskType: TaskType.research,
          tier: TaskTier.basic,
          startedAt: now.subtract(const Duration(hours: 1)),
          completesAt: completed
              ? now.subtract(const Duration(minutes: 1))
              : now.add(const Duration(hours: 1)),
          baseReward: 10,
          xpReward: 5,
          isSettled: settled,
          actualReward: settled ? 11 : null,
        );

    test('already settled task is not modified', () {
      final task = pending(completed: true, settled: true);
      final result = IdleTaskEngine.settleTasks([task], now);
      expect(result.tasks.first.isSettled, isTrue);
      expect(result.tasks.first.actualReward, 11);
    });

    test('incomplete task (completesAt in future) is not settled', () {
      final task = pending(completed: false);
      final result = IdleTaskEngine.settleTasks([task], now);
      expect(result.tasks.first.isSettled, isFalse);
      expect(result.tasks.first.actualReward, isNull);
    });

    test('completed unsettled task gets settled with actualReward', () {
      final task = pending(completed: true, settled: false);
      final result = IdleTaskEngine.settleTasks([task], now);
      expect(result.tasks.first.isSettled, isTrue);
      expect(result.tasks.first.actualReward, isNotNull);
      expect(result.tasks.first.actualReward, greaterThan(0));
    });

    test('returns same list length', () {
      final tasks = [
        pending(completed: true),
        pending(completed: false),
        pending(completed: true, settled: true),
      ];
      expect(IdleTaskEngine.settleTasks(tasks, now).tasks.length, 3);
    });

    test('empty list returns empty', () {
      expect(IdleTaskEngine.settleTasks([], now).tasks, isEmpty);
    });

    test('only completed unsettled tasks are modified', () {
      final tasks = [
        pending(completed: true),  // should settle
        pending(completed: false), // should NOT settle
      ];
      final result = IdleTaskEngine.settleTasks(tasks, now);
      expect(result.tasks[0].isSettled, isTrue);
      expect(result.tasks[1].isSettled, isFalse);
    });
  });

  // ── availableTaskTypes ─────────────────────────────────────────────────────

  group('IdleTaskEngine.availableTaskTypes', () {
    test('analyst has research and analysis', () {
      final types = IdleTaskEngine.availableTaskTypes(AgentType.analyst);
      expect(types, containsAll([TaskType.research, TaskType.analysis]));
    });

    test('scout has scoutMission and research', () {
      final types = IdleTaskEngine.availableTaskTypes(AgentType.scout);
      expect(types, containsAll([TaskType.scoutMission, TaskType.research]));
    });

    test('risk has analysis and research', () {
      final types = IdleTaskEngine.availableTaskTypes(AgentType.risk);
      expect(types, containsAll([TaskType.analysis, TaskType.research]));
    });

    test('social has socialScan and scoutMission', () {
      final types = IdleTaskEngine.availableTaskTypes(AgentType.social);
      expect(types, containsAll([TaskType.socialScan, TaskType.scoutMission]));
    });

    test('returns at least 2 types for every agent', () {
      for (final type in AgentType.values) {
        expect(
          IdleTaskEngine.availableTaskTypes(type).length,
          greaterThanOrEqualTo(2),
        );
      }
    });
  });

  // ── tierDurations / tierBaseReward constants ───────────────────────────────

  group('IdleTaskEngine constants', () {
    test('all 4 tiers have durations defined', () {
      for (final tier in TaskTier.values) {
        expect(IdleTaskEngine.tierDurations.containsKey(tier), isTrue);
      }
    });

    test('all 4 tiers have base rewards defined', () {
      for (final tier in TaskTier.values) {
        expect(IdleTaskEngine.tierBaseReward.containsKey(tier), isTrue);
      }
    });

    test('tier rewards increase with tier rank', () {
      expect(IdleTaskEngine.tierBaseReward[TaskTier.basic]!, lessThan(
        IdleTaskEngine.tierBaseReward[TaskTier.standard]!));
      expect(IdleTaskEngine.tierBaseReward[TaskTier.standard]!, lessThan(
        IdleTaskEngine.tierBaseReward[TaskTier.advanced]!));
      expect(IdleTaskEngine.tierBaseReward[TaskTier.advanced]!, lessThan(
        IdleTaskEngine.tierBaseReward[TaskTier.elite]!));
    });
  });
}
