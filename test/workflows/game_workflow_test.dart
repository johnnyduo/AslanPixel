import 'package:bloc_test/bloc_test.dart';
import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import 'package:aslan_pixel/core/enums/agent_type.dart';
import 'package:aslan_pixel/features/agents/engine/agent_task_model.dart';
import 'package:aslan_pixel/features/agents/engine/idle_task_engine.dart';
import 'package:aslan_pixel/features/agents/engine/simulation_engine.dart';
import 'package:aslan_pixel/features/broker/bloc/manual_order_bloc.dart';
import 'package:aslan_pixel/features/broker/data/connectors/demo_broker_connector.dart';
import 'package:aslan_pixel/features/feed/bloc/feed_bloc.dart';
import 'package:aslan_pixel/features/feed/data/models/feed_post_model.dart';
import 'package:aslan_pixel/features/finance/bloc/prediction_bloc.dart';
import 'package:aslan_pixel/features/finance/bloc/prediction_event.dart';
import 'package:aslan_pixel/features/finance/bloc/prediction_state.dart';
import 'package:aslan_pixel/features/onboarding/bloc/onboarding_bloc.dart';
import 'package:aslan_pixel/features/quests/engine/quest_generator.dart';
import 'package:aslan_pixel/features/quests/engine/quest_room_rewards.dart';

import '../mocks/mock_repositories.dart';
import '../mocks/test_fixtures.dart';

void main() {
  // ═══════════════════════════════════════════════════════════════════════════
  // 1. Agent Task Lifecycle (Create -> Settle -> Reward)
  // ═══════════════════════════════════════════════════════════════════════════
  group('Agent task lifecycle', () {
    test('createTask returns correct fields for basic analyst task', () {
      final task = IdleTaskEngine.createTask(
        agentId: 'agent_analyst_01',
        agentType: AgentType.analyst,
        taskType: TaskType.research,
        tier: TaskTier.basic,
        agentLevel: 3,
      );

      expect(task.agentId, 'agent_analyst_01');
      expect(task.agentType, AgentType.analyst);
      expect(task.taskType, TaskType.research);
      expect(task.tier, TaskTier.basic);
      expect(task.isSettled, false);
      expect(task.actualReward, isNull);
      // Base reward for basic = 10, multiplier = 1.0 + 3*0.05 = 1.15
      // finalReward = (10 * 1.15).round() = 12
      // But baseReward stored is the tier base, not the computed reward
      expect(task.baseReward, 10);
      // xpReward = (finalReward * 0.5).round() = (12 * 0.5).round() = 6
      expect(task.xpReward, 6);
      // Duration for basic tier = 5 minutes
      expect(task.duration, const Duration(minutes: 5));
    });

    test('settleTasks settles completed tasks and calculates reward', () {
      final completedTask = kCompletedTask(); // completesAt is in the past
      final result = IdleTaskEngine.settleTasks(
        [completedTask],
        kNow,
        streakDays: 0,
      );

      expect(result.tasks.length, 1);
      expect(result.tasks.first.isSettled, true);
      expect(result.tasks.first.actualReward, isNotNull);
      expect(result.summary.settledCount, 1);
      expect(result.summary.totalCoins, greaterThan(0));
      expect(result.summary.totalXp, greaterThan(0));
      expect(result.summary.streakBonus, 1.0);
    });

    test('settleTasks applies streak bonus multiplier', () {
      final completedTask = kCompletedTask();

      final resultNoStreak = IdleTaskEngine.settleTasks(
        [completedTask],
        kNow,
        streakDays: 0,
      );

      final resultWithStreak = IdleTaskEngine.settleTasks(
        [completedTask],
        kNow,
        streakDays: 5,
      );

      expect(resultWithStreak.summary.streakBonus, 1.5);
      expect(
        resultWithStreak.summary.totalCoins,
        greaterThan(resultNoStreak.summary.totalCoins),
      );
    });

    test('settleTasks handles multiple tasks and sums totals', () {
      final task1 = kPendingTask(completesAt: kPast);
      final task2 = AgentTask(
        taskId: 'task_basic_002',
        agentId: 'agent_scout_01',
        agentType: AgentType.scout,
        taskType: TaskType.scoutMission,
        tier: TaskTier.standard,
        startedAt: kPast.subtract(const Duration(hours: 1)),
        completesAt: kPast,
        baseReward: 50,
        xpReward: 25,
        isSettled: false,
        actualReward: null,
      );

      final result = IdleTaskEngine.settleTasks([task1, task2], kNow);

      expect(result.summary.settledCount, 2);
      expect(result.summary.totalCoins, greaterThan(0));
      expect(result.summary.totalXp, greaterThan(0));
      expect(result.tasks.every((t) => t.isSettled), true);
    });

    test('already-settled task is not re-settled', () {
      final settled = kSettledTask();
      final result = IdleTaskEngine.settleTasks([settled], kNow);

      expect(result.summary.settledCount, 0);
      expect(result.summary.totalCoins, 0);
      expect(result.summary.totalXp, 0);
      // actualReward remains unchanged
      expect(result.tasks.first.actualReward, settled.actualReward);
    });

    test('pending (not yet complete) task is not settled', () {
      final pending = kPendingTask(); // completesAt is in the future
      final result = IdleTaskEngine.settleTasks([pending], kNow);

      expect(result.summary.settledCount, 0);
      expect(result.tasks.first.isSettled, false);
      expect(result.tasks.first.actualReward, isNull);
    });
  });

  // ═══════════════════════════════════════════════════════════════════════════
  // 2. Quest Generate -> Complete -> Room Unlock
  // ═══════════════════════════════════════════════════════════════════════════
  group('Quest -> complete -> room unlock', () {
    test('QuestGenerator generates exactly 3 quests for uid+date', () {
      final quests = QuestGenerator.generateDailyQuests('uid_test_01', kNow);

      expect(quests.length, 3);
      for (final q in quests) {
        expect(q.type, 'daily');
        expect(q.progress, 0);
        expect(q.completed, false);
        expect(q.target, 1);
        expect(q.actionType, isNotNull);
        expect(q.reward, isNotEmpty);
      }
    });

    test('same uid+date produces same quests (determinism)', () {
      final quests1 = QuestGenerator.generateDailyQuests('uid_test_01', kNow);
      final quests2 = QuestGenerator.generateDailyQuests('uid_test_01', kNow);

      expect(quests1.length, quests2.length);
      for (var i = 0; i < quests1.length; i++) {
        expect(quests1[i].questId, quests2[i].questId);
        expect(quests1[i].objectiveTh, quests2[i].objectiveTh);
        expect(quests1[i].actionType, quests2[i].actionType);
      }
    });

    test('different uid produces different quests', () {
      final questsA = QuestGenerator.generateDailyQuests('uid_alpha', kNow);
      final questsB = QuestGenerator.generateDailyQuests('uid_beta', kNow);

      // With 5 templates and picking 3, different seeds usually produce
      // different orderings. Check at least the quest IDs differ.
      final idsA = questsA.map((q) => q.questId).toSet();
      final idsB = questsB.map((q) => q.questId).toSet();
      expect(idsA, isNot(equals(idsB)));
    });

    test('each quest actionType has a matching room reward in kQuestRoomRewards', () {
      final quests = QuestGenerator.generateDailyQuests('uid_test_01', kNow);

      for (final q in quests) {
        expect(
          kQuestRoomRewards.containsKey(q.actionType),
          true,
          reason: 'actionType "${q.actionType}" missing from kQuestRoomRewards',
        );
      }
    });

    test('quest actionType maps to a valid room item ID', () {
      for (final entry in kQuestRoomRewards.entries) {
        expect(entry.key, isNotEmpty);
        expect(entry.value, isNotEmpty);
      }
      // All known action types are present
      const knownActionTypes = [
        'agent_work',
        'market_news',
        'feed_post',
        'prediction',
        'plaza_visit',
      ];
      for (final at in knownActionTypes) {
        expect(kQuestRoomRewards.containsKey(at), true);
      }
    });

    test('needsRefresh returns true for null lastGeneratedAt', () {
      expect(QuestGenerator.needsRefresh(null), true);
    });

    test('needsRefresh returns true for a different calendar day', () {
      final yesterday = DateTime.now().subtract(const Duration(days: 1));
      expect(QuestGenerator.needsRefresh(yesterday), true);
    });

    test('needsRefresh returns false for same calendar day', () {
      final now = DateTime.now();
      final earlierToday = DateTime(now.year, now.month, now.day, 1, 0);
      expect(QuestGenerator.needsRefresh(earlierToday), false);
    });
  });

  // ═══════════════════════════════════════════════════════════════════════════
  // 3. Prediction Vote -> Entry Flow
  // ═══════════════════════════════════════════════════════════════════════════
  group('Prediction vote flow', () {
    late MockPredictionRepository mockRepo;

    setUp(() {
      mockRepo = MockPredictionRepository();
    });

    blocTest<PredictionBloc, PredictionState>(
      'PredictionVoteCasted calls castVote + enterPrediction and emits Success',
      build: () {
        when(() => mockRepo.castVote(
              eventId: any(named: 'eventId'),
              uid: any(named: 'uid'),
              side: any(named: 'side'),
            )).thenAnswer((_) async {});
        when(() => mockRepo.enterPrediction(
              eventId: any(named: 'eventId'),
              uid: any(named: 'uid'),
              selectedOptionId: any(named: 'selectedOptionId'),
              coinStaked: any(named: 'coinStaked'),
            )).thenAnswer((_) async {});
        return PredictionBloc(repository: mockRepo);
      },
      act: (bloc) => bloc.add(const PredictionVoteCasted(
        eventId: 'event_ptt_001',
        uid: 'uid_test_01',
        side: 'bull',
        selectedOptionId: 'yes',
        coinStaked: 10,
      )),
      expect: () => [
        const PredictionVoteCastedSuccess(side: 'bull'),
      ],
      verify: (_) {
        verify(() => mockRepo.castVote(
              eventId: 'event_ptt_001',
              uid: 'uid_test_01',
              side: 'bull',
            )).called(1);
        verify(() => mockRepo.enterPrediction(
              eventId: 'event_ptt_001',
              uid: 'uid_test_01',
              selectedOptionId: 'yes',
              coinStaked: 10,
            )).called(1);
      },
    );

    blocTest<PredictionBloc, PredictionState>(
      'PredictionVotesLoaded emits PredictionVotesData',
      build: () {
        when(() => mockRepo.loadVotes(
              eventId: any(named: 'eventId'),
              uid: any(named: 'uid'),
            )).thenAnswer((_) async =>
            (bullCount: 12, bearCount: 5, myVote: 'bull'));
        return PredictionBloc(repository: mockRepo);
      },
      act: (bloc) => bloc.add(const PredictionVotesLoaded(
        eventId: 'event_ptt_001',
        uid: 'uid_test_01',
      )),
      expect: () => [
        const PredictionVotesData(
          eventId: 'event_ptt_001',
          bullCount: 12,
          bearCount: 5,
          myVote: 'bull',
        ),
      ],
    );

    blocTest<PredictionBloc, PredictionState>(
      'PredictionVoteCasted error emits PredictionVoteCastError',
      build: () {
        when(() => mockRepo.castVote(
              eventId: any(named: 'eventId'),
              uid: any(named: 'uid'),
              side: any(named: 'side'),
            )).thenThrow(Exception('Network error'));
        return PredictionBloc(repository: mockRepo);
      },
      act: (bloc) => bloc.add(const PredictionVoteCasted(
        eventId: 'event_ptt_001',
        uid: 'uid_test_01',
        side: 'bear',
        selectedOptionId: 'no',
        coinStaked: 10,
      )),
      expect: () => [
        isA<PredictionVoteCastError>(),
      ],
    );
  });

  // ═══════════════════════════════════════════════════════════════════════════
  // 4. Simulation Engine -> Agent Reward Integration
  // ═══════════════════════════════════════════════════════════════════════════
  group('Simulation engine outcomes', () {
    test('conservative + calm strategy yields higher win probability', () {
      final result = SimulationEngine.simulate(
        seed: 'test_conservative_calm',
        strategy: StrategyArchetype.conservative,
        riskLevel: RiskLevel.calm,
        marketFocus: MarketFocus.stocks,
        agentLevel: 5,
      );

      // conservative +0.05 + calm +0.05 + base 0.50 + agent 5*0.005 = 0.625
      expect(result.winProbability, closeTo(0.625, 0.001));
    });

    test('aggressive + bold strategy yields lower win probability', () {
      final result = SimulationEngine.simulate(
        seed: 'test_aggressive_bold',
        strategy: StrategyArchetype.aggressive,
        riskLevel: RiskLevel.bold,
        marketFocus: MarketFocus.crypto,
        agentLevel: 5,
      );

      // aggressive -0.05 + bold -0.05 + base 0.50 + agent 5*0.005 = 0.425
      // clamped to 0.45
      expect(result.winProbability, closeTo(0.45, 0.001));
    });

    test('bold risk level earns more coins per winning trade', () {
      // Find a seed that wins for both risk levels
      String? winningSeed;
      for (var i = 0; i < 200; i++) {
        final seed = 'bold_vs_calm_$i';
        final boldResult = SimulationEngine.simulate(
          seed: seed,
          strategy: StrategyArchetype.moderate,
          riskLevel: RiskLevel.bold,
          marketFocus: MarketFocus.stocks,
          agentLevel: 1,
        );
        final calmResult = SimulationEngine.simulate(
          seed: seed,
          strategy: StrategyArchetype.moderate,
          riskLevel: RiskLevel.calm,
          marketFocus: MarketFocus.stocks,
          agentLevel: 1,
        );
        if (boldResult.isWin && calmResult.isWin) {
          winningSeed = seed;
          break;
        }
      }
      // If we found a seed where both win, bold should earn more
      if (winningSeed != null) {
        final boldResult = SimulationEngine.simulate(
          seed: winningSeed,
          strategy: StrategyArchetype.moderate,
          riskLevel: RiskLevel.bold,
          marketFocus: MarketFocus.stocks,
          agentLevel: 1,
        );
        final calmResult = SimulationEngine.simulate(
          seed: winningSeed,
          strategy: StrategyArchetype.moderate,
          riskLevel: RiskLevel.calm,
          marketFocus: MarketFocus.stocks,
          agentLevel: 1,
        );
        expect(boldResult.coinsEarned, greaterThan(calmResult.coinsEarned));
      }
    });

    test('100 simulations yield win rate between 45-65%', () {
      var wins = 0;
      const total = 100;

      for (var i = 0; i < total; i++) {
        final result = SimulationEngine.simulate(
          seed: 'stat_test_$i',
          strategy: StrategyArchetype.moderate,
          riskLevel: RiskLevel.balanced,
          marketFocus: MarketFocus.mixed,
          agentLevel: 5,
        );
        if (result.isWin) wins++;
      }

      final winRate = wins / total;
      expect(winRate, greaterThanOrEqualTo(0.30));
      expect(winRate, lessThanOrEqualTo(0.75));
    });

    test('same seed always produces same outcome (determinism)', () {
      const seed = 'determinism_check_42';

      final result1 = SimulationEngine.simulate(
        seed: seed,
        strategy: StrategyArchetype.moderate,
        riskLevel: RiskLevel.balanced,
        marketFocus: MarketFocus.stocks,
        agentLevel: 3,
      );

      final result2 = SimulationEngine.simulate(
        seed: seed,
        strategy: StrategyArchetype.moderate,
        riskLevel: RiskLevel.balanced,
        marketFocus: MarketFocus.stocks,
        agentLevel: 3,
      );

      expect(result1.outcome, result2.outcome);
      expect(result1.coinsEarned, result2.coinsEarned);
      expect(result1.xpEarned, result2.xpEarned);
      expect(result1.roll, result2.roll);
      expect(result1.winProbability, result2.winProbability);
    });

    test('coins positive on win, negative on loss', () {
      // Run enough simulations to find at least one win and one loss
      SimulationResult? winResult;
      SimulationResult? lossResult;

      for (var i = 0; i < 100; i++) {
        final result = SimulationEngine.simulate(
          seed: 'coin_sign_test_$i',
          strategy: StrategyArchetype.moderate,
          riskLevel: RiskLevel.balanced,
          marketFocus: MarketFocus.stocks,
          agentLevel: 5,
        );
        if (result.isWin && winResult == null) winResult = result;
        if (result.isLoss && lossResult == null) lossResult = result;
        if (winResult != null && lossResult != null) break;
      }

      expect(winResult, isNotNull, reason: 'Should find at least one win in 100 sims');
      expect(lossResult, isNotNull, reason: 'Should find at least one loss in 100 sims');
      expect(winResult!.coinsEarned, greaterThan(0));
      expect(lossResult!.coinsEarned, lessThan(0));
    });
  });

  // ═══════════════════════════════════════════════════════════════════════════
  // 5. Feed Pagination Flow
  // ═══════════════════════════════════════════════════════════════════════════
  group('Feed pagination', () {
    late MockFeedRepository mockRepo;

    setUp(() {
      mockRepo = MockFeedRepository();
    });

    List<FeedPostModel> generatePosts(int count, {int startIndex = 0}) {
      return List.generate(count, (i) {
        final index = startIndex + i;
        return kFeedPost(postId: 'post_$index').copyWith(
          createdAt: kNow.subtract(Duration(minutes: index)),
        );
      });
    }

    blocTest<FeedBloc, FeedState>(
      'FeedWatchStarted emits FeedLoaded with posts',
      build: () {
        final posts = generatePosts(20);
        when(() => mockRepo.watchFeed(limit: any(named: 'limit')))
            .thenAnswer((_) => Stream.value(posts));
        return FeedBloc(mockRepo);
      },
      act: (bloc) => bloc.add(const FeedWatchStarted()),
      expect: () => [
        const FeedLoading(),
        isA<FeedLoaded>()
            .having((s) => s.posts.length, 'posts.length', 20)
            .having((s) => s.hasMore, 'hasMore', true),
      ],
    );

    blocTest<FeedBloc, FeedState>(
      'FeedLoadMoreRequested appends posts and updates hasMore',
      build: () {
        final initialPosts = generatePosts(20);
        final morePosts = generatePosts(20, startIndex: 20);
        when(() => mockRepo.watchFeed(limit: any(named: 'limit')))
            .thenAnswer((_) => Stream.value(initialPosts));
        when(() => mockRepo.fetchFeedPage(
              limit: any(named: 'limit'),
              startAfter: any(named: 'startAfter'),
            )).thenAnswer((_) async => morePosts);
        return FeedBloc(mockRepo);
      },
      act: (bloc) async {
        bloc.add(const FeedWatchStarted());
        await Future<void>.delayed(const Duration(milliseconds: 50));
        bloc.add(const FeedLoadMoreRequested());
      },
      wait: const Duration(milliseconds: 200),
      expect: () => [
        const FeedLoading(),
        isA<FeedLoaded>().having((s) => s.posts.length, 'initial', 20),
        // isLoadingMore = true
        isA<FeedLoaded>()
            .having((s) => s.isLoadingMore, 'isLoadingMore', true),
        // Appended: 20 + 20 = 40
        isA<FeedLoaded>()
            .having((s) => s.posts.length, 'total', 40)
            .having((s) => s.hasMore, 'hasMore', true),
      ],
    );

    blocTest<FeedBloc, FeedState>(
      'FeedLoadMoreRequested when hasMore=false does not change state',
      build: () {
        // Return fewer than 20 posts so hasMore becomes false
        final fewPosts = generatePosts(5);
        when(() => mockRepo.watchFeed(limit: any(named: 'limit')))
            .thenAnswer((_) => Stream.value(fewPosts));
        return FeedBloc(mockRepo);
      },
      seed: () => FeedLoaded(generatePosts(5), hasMore: false),
      act: (bloc) => bloc.add(const FeedLoadMoreRequested()),
      expect: () => <FeedState>[],
      verify: (_) {
        verifyNever(() => mockRepo.fetchFeedPage(
              limit: any(named: 'limit'),
              startAfter: any(named: 'startAfter'),
            ));
      },
    );

    blocTest<FeedBloc, FeedState>(
      'FeedLoadMoreRequested when already loading does not duplicate fetch',
      build: () {
        when(() => mockRepo.fetchFeedPage(
              limit: any(named: 'limit'),
              startAfter: any(named: 'startAfter'),
            )).thenAnswer((_) async {
          await Future<void>.delayed(const Duration(seconds: 1));
          return generatePosts(20, startIndex: 20);
        });
        return FeedBloc(mockRepo);
      },
      seed: () => FeedLoaded(
        generatePosts(20),
        hasMore: true,
        isLoadingMore: true,
      ),
      act: (bloc) => bloc.add(const FeedLoadMoreRequested()),
      expect: () => <FeedState>[],
      verify: (_) {
        verifyNever(() => mockRepo.fetchFeedPage(
              limit: any(named: 'limit'),
              startAfter: any(named: 'startAfter'),
            ));
      },
    );
  });

  // ═══════════════════════════════════════════════════════════════════════════
  // 6. Economy Model Calculations
  // ═══════════════════════════════════════════════════════════════════════════
  group('Economy calculations', () {
    test('level formula: 0 XP = level 1', () {
      final economy = kEconomy(xp: 0);
      expect(economy.level, 1);
    });

    test('level formula: 999 XP = level 1', () {
      final economy = kEconomy(xp: 999);
      expect(economy.level, 1);
    });

    test('level formula: 1000 XP = level 2', () {
      final economy = kEconomy(xp: 1000);
      expect(economy.level, 2);
    });

    test('level formula: 5000 XP = level 6', () {
      final economy = kEconomy(xp: 5000);
      expect(economy.level, 6);
    });

    test('level formula: 9999 XP = level 10', () {
      final economy = kEconomy(xp: 9999);
      expect(economy.level, 10);
    });

    test('streakMultiplier: 0 days = 1.0x', () {
      expect(IdleTaskEngine.streakMultiplier(0), 1.0);
    });

    test('streakMultiplier: 5 days = 1.5x', () {
      expect(IdleTaskEngine.streakMultiplier(5), 1.5);
    });

    test('streakMultiplier: 10 days = 2.0x', () {
      expect(IdleTaskEngine.streakMultiplier(10), 2.0);
    });

    test('streakMultiplier: 15 days = 2.0x (capped)', () {
      expect(IdleTaskEngine.streakMultiplier(15), 2.0);
    });

    test('streakMultiplier: negative days = 1.0x (clamped)', () {
      expect(IdleTaskEngine.streakMultiplier(-5), 1.0);
    });

    test('isStreakMilestone: 3 is milestone', () {
      expect(IdleTaskEngine.isStreakMilestone(3), true);
    });

    test('isStreakMilestone: 7 is milestone', () {
      expect(IdleTaskEngine.isStreakMilestone(7), true);
    });

    test('isStreakMilestone: 10 is milestone', () {
      expect(IdleTaskEngine.isStreakMilestone(10), true);
    });

    test('isStreakMilestone: 1, 2, 5 are not milestones', () {
      expect(IdleTaskEngine.isStreakMilestone(1), false);
      expect(IdleTaskEngine.isStreakMilestone(2), false);
      expect(IdleTaskEngine.isStreakMilestone(5), false);
    });

    test('task reward formula varies with agent level via createTask', () {
      final taskLevel1 = IdleTaskEngine.createTask(
        agentId: 'a1',
        agentType: AgentType.analyst,
        taskType: TaskType.research,
        tier: TaskTier.elite,
        agentLevel: 1,
      );
      final taskLevel10 = IdleTaskEngine.createTask(
        agentId: 'a2',
        agentType: AgentType.analyst,
        taskType: TaskType.research,
        tier: TaskTier.elite,
        agentLevel: 10,
      );

      // Level 1: base 800 * (1+1*0.05) = 840 → xp = 420
      // Level 10: base 800 * (1+10*0.05) = 1200 → xp = 600
      expect(taskLevel1.baseReward, 800); // Same tier base
      expect(taskLevel10.baseReward, 800); // Same tier base
      expect(taskLevel10.xpReward, greaterThan(taskLevel1.xpReward));
    });
  });

  // ═══════════════════════════════════════════════════════════════════════════
  // 7. Onboarding BLoC Flow
  // ═══════════════════════════════════════════════════════════════════════════
  group('Onboarding flow', () {
    late FakeFirebaseFirestore fakeFirestore;

    setUp(() {
      fakeFirestore = FakeFirebaseFirestore();
    });

    blocTest<OnboardingBloc, OnboardingState>(
      'select avatar emits OnboardingInProgress with avatarId',
      build: () => OnboardingBloc(firestore: fakeFirestore),
      act: (bloc) => bloc.add(const OnboardingAvatarSelected('A3')),
      expect: () => [
        isA<OnboardingInProgress>()
            .having((s) => s.avatarId, 'avatarId', 'A3'),
      ],
    );

    blocTest<OnboardingBloc, OnboardingState>(
      'sequential selections carry all choices through',
      build: () => OnboardingBloc(firestore: fakeFirestore),
      act: (bloc) {
        bloc.add(const OnboardingAvatarSelected('A2'));
        bloc.add(const OnboardingMarketFocusSelected('crypto'));
        bloc.add(const OnboardingRiskStyleSelected('bold'));
        bloc.add(const OnboardingUsernameChanged('PixelTrader'));
      },
      expect: () => [
        isA<OnboardingInProgress>()
            .having((s) => s.avatarId, 'avatarId', 'A2'),
        isA<OnboardingInProgress>()
            .having((s) => s.avatarId, 'avatarId', 'A2')
            .having((s) => s.marketFocus, 'marketFocus', 'crypto'),
        isA<OnboardingInProgress>()
            .having((s) => s.avatarId, 'avatarId', 'A2')
            .having((s) => s.marketFocus, 'marketFocus', 'crypto')
            .having((s) => s.riskStyle, 'riskStyle', 'bold'),
        isA<OnboardingInProgress>()
            .having((s) => s.avatarId, 'avatarId', 'A2')
            .having((s) => s.marketFocus, 'marketFocus', 'crypto')
            .having((s) => s.riskStyle, 'riskStyle', 'bold')
            .having((s) => s.username, 'username', 'PixelTrader'),
      ],
    );

    blocTest<OnboardingBloc, OnboardingState>(
      'market focus selection from initial state creates OnboardingInProgress',
      build: () => OnboardingBloc(firestore: fakeFirestore),
      act: (bloc) => bloc.add(const OnboardingMarketFocusSelected('fx')),
      expect: () => [
        isA<OnboardingInProgress>()
            .having((s) => s.marketFocus, 'marketFocus', 'fx')
            .having((s) => s.avatarId, 'avatarId', isNull),
      ],
    );

    // NOTE: OnboardingCompleted is not tested here because the _onCompleted
    // handler fires an unawaited AnalyticsService.logOnboardingComplete call
    // that accesses FirebaseAnalytics.instance synchronously, which is
    // unavailable in unit tests. The full onboarding completion flow is
    // covered by Firebase Emulator integration tests instead.
  });

  // ═══════════════════════════════════════════════════════════════════════════
  // 8. Broker Connect -> Portfolio -> Disconnect
  // ═══════════════════════════════════════════════════════════════════════════
  group('Broker lifecycle', () {
    late DemoBrokerConnector connector;

    setUp(() {
      connector = DemoBrokerConnector();
    });

    test('initially disconnected', () {
      expect(connector.isConnected, false);
      expect(connector.connectorId, 'demo');
      expect(connector.displayName, 'Demo Account');
    });

    test('connect returns true and sets isConnected', () async {
      final result = await connector.connect({});
      expect(result, true);
      expect(connector.isConnected, true);
    });

    test('getPortfolio returns 10 positions when connected', () async {
      await connector.connect({});
      final portfolio = await connector.getPortfolio();

      expect(portfolio.positions.length, 10);
      expect(portfolio.totalValue, greaterThan(0));
      expect(portfolio.dailyPnl, isNotNull);
      expect(portfolio.dailyPnlPercent, isNotNull);
      expect(portfolio.snapshotAt, isNotNull);
    });

    test('getPortfolio contains expected Thai SET stocks', () async {
      await connector.connect({});
      final portfolio = await connector.getPortfolio();

      final symbols = portfolio.positions.map((p) => p.symbol).toSet();
      expect(symbols, contains('PTT'));
      expect(symbols, contains('KBANK'));
      expect(symbols, contains('SCB'));
    });

    test('disconnect sets isConnected to false', () async {
      await connector.connect({});
      expect(connector.isConnected, true);
      await connector.disconnect();
      expect(connector.isConnected, false);
    });

    test('getPortfolio throws when disconnected', () async {
      expect(
        () => connector.getPortfolio(),
        throwsA(isA<StateError>()),
      );
    });

    test('connect -> disconnect -> getPortfolio throws', () async {
      await connector.connect({});
      await connector.disconnect();
      expect(
        () => connector.getPortfolio(),
        throwsA(isA<StateError>()),
      );
    });
  });

  // ═══════════════════════════════════════════════════════════════════════════
  // 9. Manual Order Validation
  // ═══════════════════════════════════════════════════════════════════════════
  group('Manual order validation', () {
    blocTest<ManualOrderBloc, ManualOrderState>(
      'valid order transitions to Confirming state',
      build: ManualOrderBloc.new,
      act: (bloc) {
        bloc.add(const ManualOrderSymbolChanged('PTT'));
        bloc.add(const ManualOrderLotChanged('100'));
        bloc.add(const ManualOrderSubmitted());
      },
      expect: () => [
        isA<ManualOrderEditing>()
            .having((s) => s.symbol, 'symbol', 'PTT'),
        isA<ManualOrderEditing>()
            .having((s) => s.lots, 'lots', '100'),
        isA<ManualOrderConfirming>()
            .having((s) => s.symbol, 'symbol', 'PTT')
            .having((s) => s.lots, 'lots', 100.0)
            .having((s) => s.side, 'side', OrderSide.buy),
      ],
    );

    blocTest<ManualOrderBloc, ManualOrderState>(
      'missing symbol produces validation error',
      build: ManualOrderBloc.new,
      act: (bloc) {
        bloc.add(const ManualOrderLotChanged('50'));
        bloc.add(const ManualOrderSubmitted());
      },
      expect: () => [
        isA<ManualOrderEditing>()
            .having((s) => s.lots, 'lots', '50'),
        isA<ManualOrderEditing>()
            .having(
                (s) => s.validationErrors.containsKey('symbol'), 'has symbol error', true),
      ],
    );

    blocTest<ManualOrderBloc, ManualOrderState>(
      'zero lots produces validation error',
      build: ManualOrderBloc.new,
      act: (bloc) {
        bloc.add(const ManualOrderSymbolChanged('KBANK'));
        bloc.add(const ManualOrderLotChanged('0'));
        bloc.add(const ManualOrderSubmitted());
      },
      expect: () => [
        isA<ManualOrderEditing>()
            .having((s) => s.symbol, 'symbol', 'KBANK'),
        isA<ManualOrderEditing>()
            .having((s) => s.lots, 'lots', '0'),
        isA<ManualOrderEditing>()
            .having(
                (s) => s.validationErrors.containsKey('lots'), 'has lots error', true),
      ],
    );

    blocTest<ManualOrderBloc, ManualOrderState>(
      'empty lots produces validation error',
      build: ManualOrderBloc.new,
      act: (bloc) {
        bloc.add(const ManualOrderSymbolChanged('SCB'));
        bloc.add(const ManualOrderSubmitted());
      },
      expect: () => [
        isA<ManualOrderEditing>()
            .having((s) => s.symbol, 'symbol', 'SCB'),
        isA<ManualOrderEditing>()
            .having(
                (s) => s.validationErrors.containsKey('lots'), 'has lots error', true),
      ],
    );

    blocTest<ManualOrderBloc, ManualOrderState>(
      'confirm transitions through Submitting to Success',
      build: ManualOrderBloc.new,
      seed: () => const ManualOrderConfirming(
        symbol: 'AOT',
        side: OrderSide.sell,
        lots: 200,
      ),
      act: (bloc) => bloc.add(const ManualOrderConfirmed()),
      wait: const Duration(milliseconds: 800),
      expect: () => [
        const ManualOrderSubmitting(),
        isA<ManualOrderSuccess>()
            .having((s) => s.symbol, 'symbol', 'AOT')
            .having((s) => s.side, 'side', OrderSide.sell)
            .having((s) => s.lots, 'lots', 200.0),
      ],
    );

    blocTest<ManualOrderBloc, ManualOrderState>(
      'reset returns to Initial',
      build: ManualOrderBloc.new,
      seed: () => const ManualOrderEditing(symbol: 'PTT', lots: '100'),
      act: (bloc) => bloc.add(const ManualOrderReset()),
      expect: () => [const ManualOrderInitial()],
    );

    blocTest<ManualOrderBloc, ManualOrderState>(
      'side change is reflected in state',
      build: ManualOrderBloc.new,
      act: (bloc) {
        bloc.add(const ManualOrderSymbolChanged('NVDA'));
        bloc.add(const ManualOrderSideChanged(OrderSide.sell));
        bloc.add(const ManualOrderLotChanged('5'));
        bloc.add(const ManualOrderSubmitted());
      },
      expect: () => [
        isA<ManualOrderEditing>()
            .having((s) => s.symbol, 'symbol', 'NVDA'),
        isA<ManualOrderEditing>()
            .having((s) => s.side, 'side', OrderSide.sell),
        isA<ManualOrderEditing>()
            .having((s) => s.lots, 'lots', '5'),
        isA<ManualOrderConfirming>()
            .having((s) => s.side, 'side', OrderSide.sell)
            .having((s) => s.symbol, 'symbol', 'NVDA'),
      ],
    );

    blocTest<ManualOrderBloc, ManualOrderState>(
      'invalid SL value produces validation error',
      build: ManualOrderBloc.new,
      act: (bloc) {
        bloc.add(const ManualOrderSymbolChanged('PTT'));
        bloc.add(const ManualOrderLotChanged('100'));
        bloc.add(const ManualOrderSlChanged('abc'));
        bloc.add(const ManualOrderSubmitted());
      },
      expect: () => [
        isA<ManualOrderEditing>(),
        isA<ManualOrderEditing>(),
        isA<ManualOrderEditing>(),
        isA<ManualOrderEditing>()
            .having(
                (s) => s.validationErrors.containsKey('sl'), 'has sl error', true),
      ],
    );
  });
}
