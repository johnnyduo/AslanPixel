import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:aslan_pixel/core/enums/agent_type.dart';
import 'package:aslan_pixel/features/agents/data/models/agent_model.dart';
import 'package:aslan_pixel/features/agents/engine/agent_task_model.dart';
import 'package:aslan_pixel/features/agents/engine/reward_summary.dart';
import 'package:aslan_pixel/features/auth/data/models/user_model.dart';
import 'package:aslan_pixel/features/broker/data/models/portfolio_snapshot_model.dart';
import 'package:aslan_pixel/features/inventory/data/models/economy_model.dart';

import '../mocks/test_fixtures.dart';

void main() {
  // ═══════════════════════════════════════════════════════════════════════════
  // EconomyModel
  // ═══════════════════════════════════════════════════════════════════════════
  group('EconomyModel', () {
    final now = DateTime(2026, 3, 18, 12, 0);

    test('stores all fields correctly', () {
      final model = EconomyModel(
        coins: 100,
        xp: 2500,
        unlockPoints: 5,
        lastUpdated: now,
      );
      expect(model.coins, 100);
      expect(model.xp, 2500);
      expect(model.unlockPoints, 5);
      expect(model.lastUpdated, now);
    });

    test('level getter returns (xp ~/ 1000) + 1', () {
      expect(
        EconomyModel(coins: 0, xp: 0, unlockPoints: 0, lastUpdated: now).level,
        1,
      );
      expect(
        EconomyModel(coins: 0, xp: 999, unlockPoints: 0, lastUpdated: now).level,
        1,
      );
      expect(
        EconomyModel(coins: 0, xp: 1000, unlockPoints: 0, lastUpdated: now).level,
        2,
      );
      expect(
        EconomyModel(coins: 0, xp: 2500, unlockPoints: 0, lastUpdated: now).level,
        3,
      );
      expect(
        EconomyModel(coins: 0, xp: 9999, unlockPoints: 0, lastUpdated: now).level,
        10,
      );
    });

    test('copyWith replaces only specified fields', () {
      final original = EconomyModel(
        coins: 100,
        xp: 2000,
        unlockPoints: 5,
        lastUpdated: now,
      );
      final copied = original.copyWith(coins: 200, xp: 3000);
      expect(copied.coins, 200);
      expect(copied.xp, 3000);
      expect(copied.unlockPoints, 5);
      expect(copied.lastUpdated, now);
    });

    test('copyWith with no arguments returns equivalent model', () {
      final original = EconomyModel(
        coins: 100,
        xp: 2000,
        unlockPoints: 5,
        lastUpdated: now,
      );
      final copied = original.copyWith();
      expect(copied.coins, original.coins);
      expect(copied.xp, original.xp);
      expect(copied.unlockPoints, original.unlockPoints);
      expect(copied.lastUpdated, original.lastUpdated);
    });

    test('toMap produces correct keys and values', () {
      final model = EconomyModel(
        coins: 500,
        xp: 2000,
        unlockPoints: 10,
        lastUpdated: now,
      );
      final map = model.toMap();
      expect(map['coins'], 500);
      expect(map['xp'], 2000);
      expect(map['unlockPoints'], 10);
      expect(map['lastUpdated'], isA<Timestamp>());
      expect((map['lastUpdated'] as Timestamp).toDate(), now);
    });
  });

  // ═══════════════════════════════════════════════════════════════════════════
  // AgentTask
  // ═══════════════════════════════════════════════════════════════════════════
  group('AgentTask', () {
    final start = DateTime(2026, 3, 18, 10, 0);
    final end = DateTime(2026, 3, 18, 12, 0);

    AgentTask makeTask({
      bool isSettled = false,
      int? actualReward,
      TaskType taskType = TaskType.research,
      TaskTier tier = TaskTier.basic,
    }) =>
        AgentTask(
          taskId: 'task_1',
          agentId: 'agent_1',
          agentType: AgentType.analyst,
          taskType: taskType,
          tier: tier,
          startedAt: start,
          completesAt: end,
          baseReward: 10,
          xpReward: 5,
          isSettled: isSettled,
          actualReward: actualReward,
        );

    test('stores all fields correctly', () {
      final task = makeTask();
      expect(task.taskId, 'task_1');
      expect(task.agentId, 'agent_1');
      expect(task.agentType, AgentType.analyst);
      expect(task.taskType, TaskType.research);
      expect(task.tier, TaskTier.basic);
      expect(task.startedAt, start);
      expect(task.completesAt, end);
      expect(task.baseReward, 10);
      expect(task.xpReward, 5);
      expect(task.isSettled, false);
      expect(task.actualReward, isNull);
    });

    test('duration getter returns completesAt - startedAt', () {
      final task = makeTask();
      expect(task.duration, const Duration(hours: 2));
    });

    test('copyWith replaces only specified fields', () {
      final task = makeTask();
      final copied = task.copyWith(
        isSettled: true,
        actualReward: 15,
        taskType: TaskType.analysis,
      );
      expect(copied.isSettled, true);
      expect(copied.actualReward, 15);
      expect(copied.taskType, TaskType.analysis);
      // Unchanged fields
      expect(copied.taskId, 'task_1');
      expect(copied.agentId, 'agent_1');
      expect(copied.baseReward, 10);
      expect(copied.tier, TaskTier.basic);
    });

    test('copyWith with no arguments returns equivalent task', () {
      final task = makeTask(isSettled: true, actualReward: 12);
      final copied = task.copyWith();
      expect(copied.taskId, task.taskId);
      expect(copied.isSettled, task.isSettled);
      expect(copied.actualReward, task.actualReward);
    });

    test('toMap produces correct keys and values', () {
      final task = makeTask(isSettled: true, actualReward: 15);
      final map = task.toMap();
      expect(map['taskId'], 'task_1');
      expect(map['agentId'], 'agent_1');
      expect(map['agentType'], 'analyst');
      expect(map['taskType'], 'research');
      expect(map['tier'], 'basic');
      expect(map['startedAt'], isA<Timestamp>());
      expect(map['completesAt'], isA<Timestamp>());
      expect(map['baseReward'], 10);
      expect(map['xpReward'], 5);
      expect(map['isSettled'], true);
      expect(map['actualReward'], 15);
    });

    test('toMap serializes all TaskType values correctly', () {
      for (final type in TaskType.values) {
        final task = makeTask(taskType: type);
        final map = task.toMap();
        expect(map['taskType'], isA<String>());
        expect((map['taskType'] as String).isNotEmpty, true);
      }
    });

    test('toMap serializes all TaskTier values correctly', () {
      for (final tier in TaskTier.values) {
        final task = makeTask(tier: tier);
        final map = task.toMap();
        expect(map['tier'], isA<String>());
        expect((map['tier'] as String).isNotEmpty, true);
      }
    });

    test('toMap tier string values match expected names', () {
      expect(makeTask(tier: TaskTier.basic).toMap()['tier'], 'basic');
      expect(makeTask(tier: TaskTier.standard).toMap()['tier'], 'standard');
      expect(makeTask(tier: TaskTier.advanced).toMap()['tier'], 'advanced');
      expect(makeTask(tier: TaskTier.elite).toMap()['tier'], 'elite');
    });

    test('toMap taskType string values match expected names', () {
      expect(makeTask(taskType: TaskType.research).toMap()['taskType'], 'research');
      expect(makeTask(taskType: TaskType.scoutMission).toMap()['taskType'], 'scoutMission');
      expect(makeTask(taskType: TaskType.analysis).toMap()['taskType'], 'analysis');
      expect(makeTask(taskType: TaskType.socialScan).toMap()['taskType'], 'socialScan');
    });

    test('toMap with null actualReward includes null value', () {
      final map = makeTask().toMap();
      expect(map.containsKey('actualReward'), true);
      expect(map['actualReward'], isNull);
    });
  });

  // ═══════════════════════════════════════════════════════════════════════════
  // RewardSummary
  // ═══════════════════════════════════════════════════════════════════════════
  group('RewardSummary', () {
    test('stores all fields correctly', () {
      const summary = RewardSummary(
        totalCoins: 100,
        totalXp: 50,
        settledCount: 3,
        streakBonus: 1.3,
        isStreakMilestone: true,
      );
      expect(summary.totalCoins, 100);
      expect(summary.totalXp, 50);
      expect(summary.settledCount, 3);
      expect(summary.streakBonus, 1.3);
      expect(summary.isStreakMilestone, true);
    });

    test('bonusPercent returns rounded percentage above 1x', () {
      const s1 = RewardSummary(
        totalCoins: 0,
        totalXp: 0,
        settledCount: 0,
        streakBonus: 1.3,
        isStreakMilestone: false,
      );
      expect(s1.bonusPercent, 30);

      const s2 = RewardSummary(
        totalCoins: 0,
        totalXp: 0,
        settledCount: 0,
        streakBonus: 1.0,
        isStreakMilestone: false,
      );
      expect(s2.bonusPercent, 0);

      const s3 = RewardSummary(
        totalCoins: 0,
        totalXp: 0,
        settledCount: 0,
        streakBonus: 1.5,
        isStreakMilestone: false,
      );
      expect(s3.bonusPercent, 50);

      const s4 = RewardSummary(
        totalCoins: 0,
        totalXp: 0,
        settledCount: 0,
        streakBonus: 2.0,
        isStreakMilestone: false,
      );
      expect(s4.bonusPercent, 100);
    });

    test('bonusPercent rounds correctly for fractional values', () {
      const s = RewardSummary(
        totalCoins: 0,
        totalXp: 0,
        settledCount: 0,
        streakBonus: 1.15,
        isStreakMilestone: false,
      );
      expect(s.bonusPercent, 15);
    });

    test('toString contains all fields', () {
      const summary = RewardSummary(
        totalCoins: 100,
        totalXp: 50,
        settledCount: 3,
        streakBonus: 1.3,
        isStreakMilestone: true,
      );
      final str = summary.toString();
      expect(str, contains('100'));
      expect(str, contains('50'));
      expect(str, contains('3'));
      expect(str, contains('1.3'));
      expect(str, contains('true'));
      expect(str, startsWith('RewardSummary('));
    });

    test('toString format matches expected pattern', () {
      const summary = RewardSummary(
        totalCoins: 42,
        totalXp: 10,
        settledCount: 1,
        streakBonus: 1.0,
        isStreakMilestone: false,
      );
      expect(
        summary.toString(),
        'RewardSummary(coins: 42, xp: 10, settled: 1, streak: 1.0x, milestone: false)',
      );
    });
  });

  // ═══════════════════════════════════════════════════════════════════════════
  // PositionModel
  // ═══════════════════════════════════════════════════════════════════════════
  group('PositionModel', () {
    test('stores all fields correctly', () {
      const pos = PositionModel(
        symbol: 'PTT',
        qty: 100.0,
        avgCost: 35.0,
        currentPrice: 37.5,
        unrealizedPnl: 250.0,
      );
      expect(pos.symbol, 'PTT');
      expect(pos.qty, 100.0);
      expect(pos.avgCost, 35.0);
      expect(pos.currentPrice, 37.5);
      expect(pos.unrealizedPnl, 250.0);
    });

    test('fromMap / toMap round-trip preserves data', () {
      const original = PositionModel(
        symbol: 'SCB',
        qty: 200.0,
        avgCost: 110.5,
        currentPrice: 115.0,
        unrealizedPnl: 900.0,
      );
      final map = original.toMap();
      final restored = PositionModel.fromMap(map);
      expect(restored, original);
    });

    test('toMap produces correct keys', () {
      const pos = PositionModel(
        symbol: 'AOT',
        qty: 50.0,
        avgCost: 60.0,
        currentPrice: 65.0,
        unrealizedPnl: 250.0,
      );
      final map = pos.toMap();
      expect(map.keys, containsAll(['symbol', 'qty', 'avgCost', 'currentPrice', 'unrealizedPnl']));
    });

    test('fromMap handles integer num values', () {
      final map = {
        'symbol': 'DELTA',
        'qty': 100,
        'avgCost': 25,
        'currentPrice': 30,
        'unrealizedPnl': 500,
      };
      final pos = PositionModel.fromMap(map);
      expect(pos.qty, 100.0);
      expect(pos.avgCost, 25.0);
      expect(pos.currentPrice, 30.0);
      expect(pos.unrealizedPnl, 500.0);
    });

    test('equatable equality works', () {
      const a = PositionModel(symbol: 'X', qty: 1, avgCost: 2, currentPrice: 3, unrealizedPnl: 1);
      const b = PositionModel(symbol: 'X', qty: 1, avgCost: 2, currentPrice: 3, unrealizedPnl: 1);
      const c = PositionModel(symbol: 'Y', qty: 1, avgCost: 2, currentPrice: 3, unrealizedPnl: 1);
      expect(a, b);
      expect(a, isNot(c));
    });
  });

  // ═══════════════════════════════════════════════════════════════════════════
  // PortfolioSnapshotModel
  // ═══════════════════════════════════════════════════════════════════════════
  group('PortfolioSnapshotModel', () {
    final snapshotTime = DateTime(2026, 3, 18, 16, 0, 0);

    PortfolioSnapshotModel makeSnapshot() => PortfolioSnapshotModel(
          totalValue: 100000.0,
          dailyPnl: 1500.0,
          dailyPnlPercent: 1.52,
          positions: const [
            PositionModel(
              symbol: 'PTT',
              qty: 100,
              avgCost: 35.0,
              currentPrice: 37.5,
              unrealizedPnl: 250.0,
            ),
            PositionModel(
              symbol: 'SCB',
              qty: 200,
              avgCost: 110.0,
              currentPrice: 115.0,
              unrealizedPnl: 1000.0,
            ),
          ],
          snapshotAt: snapshotTime,
        );

    test('stores all fields correctly', () {
      final model = makeSnapshot();
      expect(model.totalValue, 100000.0);
      expect(model.dailyPnl, 1500.0);
      expect(model.dailyPnlPercent, 1.52);
      expect(model.positions.length, 2);
      expect(model.positions[0].symbol, 'PTT');
      expect(model.positions[1].symbol, 'SCB');
      expect(model.snapshotAt, snapshotTime);
    });

    test('fromMap / toMap round-trip preserves data', () {
      final original = makeSnapshot();
      final map = original.toMap();
      final restored = PortfolioSnapshotModel.fromMap(map);
      expect(restored, original);
    });

    test('toMap serializes snapshotAt as ISO 8601 string', () {
      final model = makeSnapshot();
      final map = model.toMap();
      expect(map['snapshotAt'], isA<String>());
      expect(DateTime.parse(map['snapshotAt'] as String), snapshotTime);
    });

    test('toMap serializes positions as list of maps', () {
      final model = makeSnapshot();
      final map = model.toMap();
      final positions = map['positions'] as List<dynamic>;
      expect(positions.length, 2);
      expect((positions[0] as Map<String, dynamic>)['symbol'], 'PTT');
    });

    test('fromMap handles empty positions list', () {
      final map = {
        'totalValue': 0.0,
        'dailyPnl': 0.0,
        'dailyPnlPercent': 0.0,
        'positions': <dynamic>[],
        'snapshotAt': snapshotTime.toIso8601String(),
      };
      final model = PortfolioSnapshotModel.fromMap(map);
      expect(model.positions, isEmpty);
    });

    test('equatable equality works', () {
      final a = makeSnapshot();
      final b = makeSnapshot();
      expect(a, b);
    });

    test('equatable detects difference', () {
      final a = makeSnapshot();
      final b = PortfolioSnapshotModel(
        totalValue: 99999.0,
        dailyPnl: 1500.0,
        dailyPnlPercent: 1.52,
        positions: const [],
        snapshotAt: snapshotTime,
      );
      expect(a, isNot(b));
    });
  });

  // ═══════════════════════════════════════════════════════════════════════════
  // Test Fixtures Validation
  // ═══════════════════════════════════════════════════════════════════════════
  group('Test Fixtures Validation', () {
    // ── UserModel fixtures ──────────────────────────────────────────────────
    group('UserModel fixtures', () {
      test('kUser is not empty and has onboarding complete', () {
        expect(kUser.isNotEmpty, true);
        expect(kUser.isEmpty, false);
        expect(kUser.uid, 'uid_test_01');
        expect(kUser.displayName, 'Test User');
        expect(kUser.email, 'test@aslanpixel.com');
        expect(kUser.onboardingComplete, true);
        expect(kUser.avatarId, 'A1');
      });

      test('kUserOnboarding is not empty and has onboarding incomplete', () {
        expect(kUserOnboarding.isNotEmpty, true);
        expect(kUserOnboarding.isEmpty, false);
        expect(kUserOnboarding.uid, 'uid_test_02');
        expect(kUserOnboarding.onboardingComplete, false);
      });

      test('UserModel with null uid is empty', () {
        const emptyUser = UserModel();
        expect(emptyUser.isEmpty, true);
        expect(emptyUser.isNotEmpty, false);
      });

      test('UserModel with empty uid string is empty', () {
        const emptyUser = UserModel(uid: '');
        expect(emptyUser.isEmpty, true);
      });
    });

    // ── AgentModel fixtures ─────────────────────────────────────────────────
    group('AgentModel fixtures', () {
      test('kAnalystAgent is well-formed', () {
        expect(kAnalystAgent.agentId, 'agent_analyst_01');
        expect(kAnalystAgent.type, AgentType.analyst);
        expect(kAnalystAgent.level, 3);
        expect(kAnalystAgent.xp, 2400);
        expect(kAnalystAgent.status, AgentStatus.idle);
        expect(kAnalystAgent.activeTaskId, isNull);
      });

      test('kScoutAgent is well-formed', () {
        expect(kScoutAgent.agentId, 'agent_scout_01');
        expect(kScoutAgent.type, AgentType.scout);
        expect(kScoutAgent.level, 1);
        expect(kScoutAgent.xp, 0);
        expect(kScoutAgent.status, AgentStatus.idle);
      });

      test('kWorkingAgent is working and has an active task', () {
        expect(kWorkingAgent.agentId, 'agent_analyst_02');
        expect(kWorkingAgent.type, AgentType.analyst);
        expect(kWorkingAgent.status, AgentStatus.working);
        expect(kWorkingAgent.activeTaskId, 'task_001');
      });
    });

    // ── AgentTask fixtures ──────────────────────────────────────────────────
    group('AgentTask fixtures', () {
      test('kPendingTask is not settled and completes in the future', () {
        final task = kPendingTask();
        expect(task.taskId, 'task_basic_001');
        expect(task.isSettled, false);
        expect(task.actualReward, isNull);
        expect(task.completesAt, kFuture);
        expect(task.agentType, AgentType.analyst);
        expect(task.taskType, TaskType.research);
        expect(task.tier, TaskTier.basic);
      });

      test('kCompletedTask has completesAt in the past', () {
        final task = kCompletedTask();
        expect(task.completesAt, kPast);
        expect(task.isSettled, false);
      });

      test('kSettledTask is settled with an actual reward', () {
        final task = kSettledTask();
        expect(task.isSettled, true);
        expect(task.actualReward, 11);
        expect(task.taskId, 'task_basic_settled');
      });

      test('kPendingTask duration is 4 hours (kPast to kFuture)', () {
        final task = kPendingTask();
        expect(task.duration, const Duration(hours: 4));
      });

      test('kPendingTask accepts custom completesAt', () {
        final custom = DateTime(2026, 3, 19);
        final task = kPendingTask(completesAt: custom);
        expect(task.completesAt, custom);
      });
    });

    // ── EconomyModel fixtures ───────────────────────────────────────────────
    group('EconomyModel fixtures', () {
      test('kEconomy default has 500 coins and level 3', () {
        final e = kEconomy();
        expect(e.coins, 500);
        expect(e.xp, 2000);
        expect(e.level, 3); // (2000 ~/ 1000) + 1 = 3
        expect(e.unlockPoints, 10);
        expect(e.lastUpdated, kNow);
      });

      test('kEconomy with custom coins and xp', () {
        final e = kEconomy(coins: 1000, xp: 5500);
        expect(e.coins, 1000);
        expect(e.xp, 5500);
        expect(e.level, 6); // (5500 ~/ 1000) + 1 = 6
      });

      test('kEconomy with 0 xp has level 1', () {
        final e = kEconomy(xp: 0);
        expect(e.level, 1);
      });
    });

    // ── QuestModel fixtures ─────────────────────────────────────────────────
    group('QuestModel fixtures', () {
      test('kDailyQuest default is incomplete with progress 0', () {
        final q = kDailyQuest();
        expect(q.questId, 'daily_send_agent_2026-03-18');
        expect(q.type, 'daily');
        expect(q.progress, 0);
        expect(q.target, 1);
        expect(q.completed, false);
        expect(q.isComplete, false);
        expect(q.objective, isNotEmpty);
        expect(q.objectiveTh, isNotEmpty);
        expect(q.reward, isNotEmpty);
        expect(q.expiresAt, kFuture);
      });

      test('kCompletedQuest is marked complete', () {
        final q = kCompletedQuest();
        expect(q.progress, 1);
        expect(q.completed, true);
        expect(q.isComplete, true);
      });

      test('kDailyQuest with custom progress', () {
        final q = kDailyQuest(progress: 1, completed: true);
        expect(q.progress, 1);
        expect(q.completed, true);
      });
    });

    // ── FeedPostModel fixtures ──────────────────────────────────────────────
    group('FeedPostModel fixtures', () {
      test('kFeedPost is well-formed', () {
        final post = kFeedPost();
        expect(post.postId, 'post_001');
        expect(post.type, 'user');
        expect(post.authorUid, 'uid_test_01');
        expect(post.content, isNotEmpty);
        expect(post.contentTh, isNotEmpty);
        expect(post.metadata, isEmpty);
        expect(post.createdAt, kNow);
        expect(post.reactions, isNotEmpty);
        expect(post.reactions.values.every((v) => v > 0), true);
      });

      test('kFeedPost accepts custom postId', () {
        final post = kFeedPost(postId: 'custom_42');
        expect(post.postId, 'custom_42');
      });
    });

    // ── PredictionEventModel fixtures ───────────────────────────────────────
    group('PredictionEventModel fixtures', () {
      test('kPredictionEvent is well-formed', () {
        final event = kPredictionEvent();
        expect(event.eventId, 'event_ptt_001');
        expect(event.symbol, 'PTT');
        expect(event.title, isNotEmpty);
        expect(event.titleTh, isNotEmpty);
        expect(event.options.length, 2);
        expect(event.options[0].optionId, 'yes');
        expect(event.options[1].optionId, 'no');
        expect(event.coinCost, 10);
        expect(event.settlementAt, kFuture);
        expect(event.settlementRule, 'above');
        expect(event.status, 'open');
        expect(event.createdAt, kPast);
      });
    });

    // ── PredictionEntryModel fixtures ───────────────────────────────────────
    group('PredictionEntryModel fixtures', () {
      test('kPredictionEntry is well-formed', () {
        final entry = kPredictionEntry();
        expect(entry.entryId, 'entry_001');
        expect(entry.eventId, 'event_ptt_001');
        expect(entry.uid, 'uid_test_01');
        expect(entry.selectedOptionId, 'yes');
        expect(entry.coinStaked, 10);
        expect(entry.enteredAt, kNow);
        expect(entry.result, isNull);
        expect(entry.rewardGranted, 0);
      });
    });

    // ── AiInsightModel fixtures ─────────────────────────────────────────────
    group('AiInsightModel fixtures', () {
      test('kAiInsight default is not expired', () {
        final insight = kAiInsight();
        expect(insight.insightId, 'insight_001');
        expect(insight.uid, 'uid_test_01');
        expect(insight.type, 'market_summary');
        expect(insight.content, isNotEmpty);
        expect(insight.contentTh, isNotEmpty);
        expect(insight.modelUsed, 'gemini-2.0-flash-lite');
        expect(insight.generatedAt, kNow);
        expect(insight.expiresAt, kFuture);
      });

      test('kAiInsight expired has expiresAt in the past', () {
        final insight = kAiInsight(expired: true);
        expect(insight.expiresAt, kPast);
        // isExpired depends on DateTime.now(), but we know kPast is in the past fixture time
      });

      test('expired and non-expired insights differ only in expiresAt', () {
        final normal = kAiInsight();
        final expired = kAiInsight(expired: true);
        expect(normal.insightId, expired.insightId);
        expect(normal.content, expired.content);
        expect(normal.expiresAt, isNot(expired.expiresAt));
      });
    });

    // ── NotificationModel fixtures ──────────────────────────────────────────
    group('NotificationModel fixtures', () {
      test('kNotification default is unread', () {
        final n = kNotification();
        expect(n.notifId, 'notif_001');
        expect(n.type, 'agent_returned');
        expect(n.title, 'Agent Returned');
        expect(n.titleTh, isNotEmpty);
        expect(n.body, isNotEmpty);
        expect(n.bodyTh, isNotEmpty);
        expect(n.isRead, false);
        expect(n.createdAt, kNow);
      });

      test('kNotification isRead variant is read', () {
        final n = kNotification(isRead: true);
        expect(n.isRead, true);
      });
    });

    // ── BadgeModel fixtures ─────────────────────────────────────────────────
    group('BadgeModel fixtures', () {
      test('kBadge default is earned', () {
        final b = kBadge();
        expect(b.badgeId, 'first_mission');
        expect(b.name, 'First Mission');
        expect(b.nameTh, isNotEmpty);
        expect(b.description, isNotEmpty);
        expect(b.descriptionTh, isNotEmpty);
        expect(b.iconEmoji, isNotEmpty);
        expect(b.category, 'game');
        expect(b.isEarned, true);
        expect(b.earnedAt, kNow);
      });

      test('kBadge not earned has isEarned false and earnedAt null', () {
        final b = kBadge(isEarned: false);
        expect(b.isEarned, false);
        expect(b.earnedAt, isNull);
      });
    });
  });
}
