// ignore_for_file: prefer_const_constructors

import 'package:flutter_test/flutter_test.dart';

import 'package:aslan_pixel/core/enums/agent_type.dart';
import 'package:aslan_pixel/features/agents/engine/agent_task_model.dart';
import 'package:aslan_pixel/features/agents/engine/idle_task_engine.dart';

void main() {
  // ── TaskTier.quick — duration ─────────────────────────────────────────────

  group('TaskTier.quick — duration', () {
    test('TaskTier.quick has 1 minute duration', () {
      expect(
        IdleTaskEngine.tierDurations[TaskTier.quick],
        const Duration(minutes: 1),
      );
    });
  });

  // ── TaskTier.quick — base reward ──────────────────────────────────────────

  group('TaskTier.quick — base reward', () {
    test('TaskTier.quick has 5 base reward', () {
      expect(IdleTaskEngine.tierBaseReward[TaskTier.quick], 5);
    });

    test('TaskTier.quick has 5 XP reward', () {
      expect(IdleTaskEngine.tierXpReward[TaskTier.quick], 5);
    });
  });

  // ── createTask with quick tier ────────────────────────────────────────────

  group('createTask with quick tier', () {
    test('produces task with correct 1-minute duration', () {
      final task = IdleTaskEngine.createTask(
        agentId: 'a1',
        agentType: AgentType.analyst,
        taskType: TaskType.research,
        tier: TaskTier.quick,
        agentLevel: 1,
      );

      expect(
        task.completesAt.difference(task.startedAt),
        const Duration(minutes: 1),
      );
      expect(task.baseReward, 5);
      expect(task.tier, TaskTier.quick);
      expect(task.isSettled, isFalse);
    });
  });

  // ── settleTasks settles quick task after 1 minute ─────────────────────────

  group('settleTasks with quick tier', () {
    test('settles quick task after 1 minute', () {
      final start = DateTime(2026, 3, 18, 12, 0);
      final task = AgentTask(
        taskId: 'quick_001',
        agentId: 'agent_001',
        agentType: AgentType.analyst,
        taskType: TaskType.research,
        tier: TaskTier.quick,
        startedAt: start,
        completesAt: start.add(const Duration(minutes: 1)),
        baseReward: 5,
        xpReward: 3,
        isSettled: false,
        actualReward: null,
      );

      // Settle at 1 minute + 1 second after start
      final settleTime = start.add(const Duration(minutes: 1, seconds: 1));
      final result = IdleTaskEngine.settleTasks([task], settleTime);

      expect(result.tasks.first.isSettled, isTrue);
      expect(result.tasks.first.actualReward, isNotNull);
      expect(result.tasks.first.actualReward, greaterThan(0));
      expect(result.summary.settledCount, 1);
      expect(result.summary.totalXp, 5); // tierXpReward for quick
    });

    test('does NOT settle quick task before 1 minute', () {
      final start = DateTime(2026, 3, 18, 12, 0);
      final task = AgentTask(
        taskId: 'quick_002',
        agentId: 'agent_001',
        agentType: AgentType.analyst,
        taskType: TaskType.research,
        tier: TaskTier.quick,
        startedAt: start,
        completesAt: start.add(const Duration(minutes: 1)),
        baseReward: 5,
        xpReward: 3,
        isSettled: false,
        actualReward: null,
      );

      // Try to settle at 30 seconds (before completion)
      final settleTime = start.add(const Duration(seconds: 30));
      final result = IdleTaskEngine.settleTasks([task], settleTime);

      expect(result.tasks.first.isSettled, isFalse);
      expect(result.tasks.first.actualReward, isNull);
      expect(result.summary.settledCount, 0);
    });
  });

  // ── tierNameTh ────────────────────────────────────────────────────────────

  group('tierNameTh for quick', () {
    test('returns correct Thai name with duration hint', () {
      expect(
        IdleTaskEngine.tierNameTh(TaskTier.quick),
        'ด่วน (1 นาที)',
      );
    });
  });
}
