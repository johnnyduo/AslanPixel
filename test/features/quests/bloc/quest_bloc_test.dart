import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import 'package:aslan_pixel/features/quests/bloc/quest_bloc.dart';
import 'package:aslan_pixel/features/quests/data/models/quest_model.dart';
import '../../../mocks/mock_repositories.dart';
import '../../../mocks/test_fixtures.dart';

void main() {
  late MockQuestRepository repo;

  setUp(() {
    repo = MockQuestRepository();
    // ensureDailyQuestsExist is always called in _onWatchStarted — stub it.
    when(() => repo.ensureDailyQuestsExist(any()))
        .thenAnswer((_) async {});
  });

  QuestBloc build() => QuestBloc(repository: repo);

  // ── QuestWatchStarted ─────────────────────────────────────────────────────

  group('QuestWatchStarted', () {
    blocTest<QuestBloc, QuestState>(
      'emits [QuestLoading, QuestLoaded(quests)] from stream',
      build: build,
      setUp: () {
        when(() => repo.watchActiveQuests('uid_01'))
            .thenAnswer((_) => Stream.value([kDailyQuest()]));
      },
      act: (bloc) => bloc.add(const QuestWatchStarted('uid_01')),
      expect: () => [
        isA<QuestLoading>(),
        isA<QuestLoaded>().having((s) => s.quests.length, 'count', 1),
      ],
      verify: (_) =>
          verify(() => repo.watchActiveQuests('uid_01')).called(1),
    );

    blocTest<QuestBloc, QuestState>(
      'emits [QuestLoading, QuestLoaded([])] for empty quest list — not error',
      build: build,
      setUp: () {
        when(() => repo.watchActiveQuests(any()))
            .thenAnswer((_) => Stream.value(<QuestModel>[]));
      },
      act: (bloc) => bloc.add(const QuestWatchStarted('uid_01')),
      expect: () => [
        isA<QuestLoading>(),
        isA<QuestLoaded>().having((s) => s.quests, 'quests', isEmpty),
      ],
    );

    blocTest<QuestBloc, QuestState>(
      'emits [QuestLoading, QuestError] when stream throws',
      build: build,
      setUp: () {
        when(() => repo.watchActiveQuests(any()))
            .thenAnswer((_) => Stream.error(Exception('Firestore offline')));
      },
      act: (bloc) => bloc.add(const QuestWatchStarted('uid_01')),
      expect: () => [isA<QuestLoading>(), isA<QuestError>()],
    );

    blocTest<QuestBloc, QuestState>(
      'does not re-subscribe when same uid dispatched twice',
      build: build,
      setUp: () {
        when(() => repo.watchActiveQuests(any()))
            .thenAnswer((_) => Stream.value([kDailyQuest()]));
      },
      act: (bloc) async {
        bloc.add(const QuestWatchStarted('uid_01'));
        await Future<void>.delayed(Duration.zero);
        bloc.add(const QuestWatchStarted('uid_01'));
      },
      verify: (_) =>
          verify(() => repo.watchActiveQuests('uid_01')).called(1),
    );
  });

  // ── QuestRewardClaimed ────────────────────────────────────────────────────

  group('QuestRewardClaimed', () {
    blocTest<QuestBloc, QuestState>(
      'emits QuestRewardClaimedSuccess when quest exists in current state',
      build: build,
      setUp: () {
        final quest = QuestModel(
          questId: 'quest_agent_work',
          type: 'daily',
          objective: 'Send agent',
          objectiveTh: 'ส่ง Agent ทำงาน 1 ครั้ง',
          reward: const {'coins': 20, 'xp': 10},
          progress: 1,
          target: 1,
          completed: true,
          expiresAt: kFuture,
          actionType: 'agent_work',
        );
        when(() => repo.watchActiveQuests(any()))
            .thenAnswer((_) => Stream.value([quest]));
        when(() => repo.claimQuestReward(any(), any()))
            .thenAnswer((_) async {});
      },
      act: (bloc) async {
        bloc.add(const QuestWatchStarted('uid_01'));
        await Future<void>.delayed(Duration.zero);
        bloc.add(const QuestRewardClaimed(
          questId: 'quest_agent_work',
          uid: 'uid_01',
        ));
      },
      expect: () => [
        isA<QuestLoading>(),
        isA<QuestLoaded>(),
        isA<QuestRewardClaimedSuccess>()
            .having((s) => s.questId, 'questId', 'quest_agent_work')
            .having((s) => s.coinsEarned, 'coinsEarned', 20),
      ],
      verify: (_) =>
          verify(() => repo.claimQuestReward('uid_01', 'quest_agent_work'))
              .called(1),
    );

    blocTest<QuestBloc, QuestState>(
      'emits QuestError when claimQuestReward throws',
      build: build,
      setUp: () {
        when(() => repo.watchActiveQuests(any()))
            .thenAnswer((_) => Stream.value([kCompletedQuest()]));
        when(() => repo.claimQuestReward(any(), any()))
            .thenThrow(Exception('claim failed'));
      },
      act: (bloc) async {
        bloc.add(const QuestWatchStarted('uid_01'));
        await Future<void>.delayed(Duration.zero);
        bloc.add(QuestRewardClaimed(
          questId: kCompletedQuest().questId,
          uid: 'uid_01',
        ));
      },
      expect: () => [
        isA<QuestLoading>(),
        isA<QuestLoaded>(),
        isA<QuestError>(),
      ],
    );
  });

  // ── QuestProgressUpdated ──────────────────────────────────────────────────

  group('QuestProgressUpdated', () {
    blocTest<QuestBloc, QuestState>(
      'calls repository updateQuestProgress with correct arguments',
      build: build,
      setUp: () {
        when(() => repo.watchActiveQuests(any()))
            .thenAnswer((_) => Stream.value([kDailyQuest()]));
        when(() => repo.updateQuestProgress(any(), any(), any()))
            .thenAnswer((_) async {});
      },
      act: (bloc) async {
        bloc.add(const QuestWatchStarted('uid_01'));
        await Future<void>.delayed(Duration.zero);
        bloc.add(QuestProgressUpdated(
          questId: kDailyQuest().questId,
          increment: 1,
        ));
      },
      verify: (_) => verify(
        () => repo.updateQuestProgress('uid_01', kDailyQuest().questId, 1),
      ).called(1),
    );

    blocTest<QuestBloc, QuestState>(
      'does nothing (no state change) when no uid is being watched',
      build: build,
      act: (bloc) => bloc.add(QuestProgressUpdated(
        questId: kDailyQuest().questId,
        increment: 1,
      )),
      expect: () => [],
    );

    blocTest<QuestBloc, QuestState>(
      'emits QuestError when updateQuestProgress throws',
      build: build,
      setUp: () {
        when(() => repo.watchActiveQuests(any()))
            .thenAnswer((_) => Stream.value([kDailyQuest()]));
        when(() => repo.updateQuestProgress(any(), any(), any()))
            .thenThrow(Exception('update failed'));
      },
      act: (bloc) async {
        bloc.add(const QuestWatchStarted('uid_01'));
        await Future<void>.delayed(Duration.zero);
        bloc.add(QuestProgressUpdated(
          questId: kDailyQuest().questId,
          increment: 1,
        ));
      },
      expect: () => [
        isA<QuestLoading>(),
        isA<QuestLoaded>(),
        isA<QuestError>(),
      ],
    );
  });

  // ── Initial state ─────────────────────────────────────────────────────────

  group('QuestBloc initial state', () {
    test('starts as QuestInitial', () {
      expect(build().state, isA<QuestInitial>());
    });
  });
}
