import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import 'package:aslan_pixel/features/quests/bloc/quest_bloc.dart';
import 'package:aslan_pixel/features/quests/data/models/quest_model.dart';
import '../../mocks/mock_repositories.dart';
import '../../mocks/test_fixtures.dart';

void main() {
  late MockQuestRepository repo;

  setUp(() {
    repo = MockQuestRepository();
  });

  QuestBloc build() => QuestBloc(repository: repo);

  group('QuestBloc — initial state', () {
    test('initial state is QuestInitial', () {
      expect(build().state, isA<QuestInitial>());
    });
  });

  // ── QuestWatchStarted ──────────────────────────────────────────────────────

  group('QuestWatchStarted', () {
    blocTest<QuestBloc, QuestState>(
      'emits [Loading, Loaded] with quests from stream',
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
      'emits [Loading, Loaded] with empty list when no quests',
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
      'emits [Loading, Error] when stream throws',
      build: build,
      setUp: () {
        when(() => repo.watchActiveQuests(any()))
            .thenAnswer((_) => Stream.error(Exception('Firestore error')));
      },
      act: (bloc) => bloc.add(const QuestWatchStarted('uid_01')),
      expect: () => [isA<QuestLoading>(), isA<QuestError>()],
    );

    blocTest<QuestBloc, QuestState>(
      'emits multiple Loaded states on stream updates',
      build: build,
      setUp: () {
        when(() => repo.watchActiveQuests(any())).thenAnswer(
          (_) => Stream.fromIterable([
            [kDailyQuest()],
            [kDailyQuest(progress: 1, completed: true)],
          ]),
        );
      },
      act: (bloc) => bloc.add(const QuestWatchStarted('uid_01')),
      expect: () => [
        isA<QuestLoading>(),
        isA<QuestLoaded>().having(
            (s) => s.quests.first.completed, 'completed', false),
        isA<QuestLoaded>().having(
            (s) => s.quests.first.completed, 'completed', true),
      ],
    );

    blocTest<QuestBloc, QuestState>(
      'second call with same uid does not re-subscribe',
      build: build,
      setUp: () {
        when(() => repo.watchActiveQuests(any()))
            .thenAnswer((_) => Stream.value([kDailyQuest()]));
      },
      act: (bloc) async {
        bloc.add(const QuestWatchStarted('uid_01'));
        await Future.delayed(Duration.zero);
        bloc.add(const QuestWatchStarted('uid_01'));
      },
      verify: (_) =>
          verify(() => repo.watchActiveQuests('uid_01')).called(1),
    );
  });

  // ── QuestProgressUpdated ───────────────────────────────────────────────────

  group('QuestProgressUpdated', () {
    blocTest<QuestBloc, QuestState>(
      'calls repository updateQuestProgress with correct args',
      build: build,
      setUp: () {
        when(() => repo.watchActiveQuests(any()))
            .thenAnswer((_) => Stream.value([kDailyQuest()]));
        when(() => repo.updateQuestProgress(any(), any(), any()))
            .thenAnswer((_) async {});
      },
      act: (bloc) async {
        bloc.add(const QuestWatchStarted('uid_01'));
        await Future.delayed(Duration.zero);
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
        await Future.delayed(Duration.zero);
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

    blocTest<QuestBloc, QuestState>(
      'does nothing if no uid is being watched',
      build: build,
      act: (bloc) => bloc.add(QuestProgressUpdated(
        questId: kDailyQuest().questId,
        increment: 1,
      )),
      expect: () => [],
    );
  });

  // ── QuestRewardClaimed ─────────────────────────────────────────────────────

  group('QuestRewardClaimed', () {
    blocTest<QuestBloc, QuestState>(
      'calls repository claimQuestReward with correct args',
      build: build,
      setUp: () {
        when(() => repo.watchActiveQuests(any()))
            .thenAnswer((_) => Stream.value([kCompletedQuest()]));
        when(() => repo.claimQuestReward(any(), any()))
            .thenAnswer((_) async {});
      },
      act: (bloc) async {
        bloc.add(const QuestWatchStarted('uid_01'));
        await Future.delayed(Duration.zero);
        bloc.add(QuestRewardClaimed(
          questId: kCompletedQuest().questId,
          uid: 'uid_01',
        ));
      },
      verify: (_) => verify(
        () => repo.claimQuestReward('uid_01', kCompletedQuest().questId),
      ).called(1),
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
        await Future.delayed(Duration.zero);
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

  // ── State equality ─────────────────────────────────────────────────────────

  group('State equality', () {
    test('QuestInitial == QuestInitial', () {
      expect(const QuestInitial(), equals(const QuestInitial()));
    });

    test('QuestLoading == QuestLoading', () {
      expect(const QuestLoading(), equals(const QuestLoading()));
    });

    test('QuestLoaded with same quests list has same props', () {
      final quest = kDailyQuest();
      // QuestModel doesn't extend Equatable, so compare via shared reference
      final state1 = QuestLoaded([quest]);
      final state2 = QuestLoaded([quest]);
      expect(state1.quests, equals(state2.quests));
    });

    test('QuestError with same message are equal', () {
      expect(
        const QuestError('error'),
        equals(const QuestError('error')),
      );
    });
  });
}
