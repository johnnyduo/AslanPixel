import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import 'package:aslan_pixel/features/home/bloc/ranking_bloc.dart';
import 'package:aslan_pixel/features/home/data/models/ranking_entry_model.dart';
import 'package:aslan_pixel/features/home/data/repositories/ranking_repository.dart';

// ── Mock ─────────────────────────────────────────────────────────────────────

class MockRankingRepository extends Mock implements RankingRepository {}

// ── Helpers ──────────────────────────────────────────────────────────────────

RankingEntryModel _entry({
  required String uid,
  required int score,
  required int rank,
}) =>
    RankingEntryModel(
      uid: uid,
      score: score,
      rank: rank,
      category: 'weekly',
      displayName: 'User $uid',
    );

void main() {
  late MockRankingRepository repo;

  setUp(() {
    repo = MockRankingRepository();
  });

  RankingBloc build() => RankingBloc(repo);

  // ── Initial state ─────────────────────────────────────────────────────────

  group('RankingBloc initial state', () {
    test('starts as RankingInitial', () {
      expect(build().state, isA<RankingInitial>());
    });
  });

  // ── RankingWatchStarted ───────────────────────────────────────────────────

  group('RankingWatchStarted', () {
    blocTest<RankingBloc, RankingState>(
      'emits [RankingLoading, RankingLoaded] with entries from stream',
      build: build,
      setUp: () {
        when(() => repo.watchLeaderboard('weekly', limit: 50)).thenAnswer(
          (_) => Stream.value([
            _entry(uid: 'uid_01', score: 1000, rank: 1),
            _entry(uid: 'uid_02', score: 800, rank: 2),
          ]),
        );
      },
      act: (bloc) =>
          bloc.add(const RankingWatchStarted(uid: 'uid_01', period: 'weekly')),
      expect: () => [
        isA<RankingLoading>(),
        isA<RankingLoaded>()
            .having((s) => s.entries.length, 'count', 2)
            .having((s) => s.period, 'period', 'weekly'),
      ],
    );

    blocTest<RankingBloc, RankingState>(
      'sets myRank to 1 when current user is first in list',
      build: build,
      setUp: () {
        when(() => repo.watchLeaderboard(any(), limit: 50)).thenAnswer(
          (_) => Stream.value([
            _entry(uid: 'uid_me', score: 9999, rank: 1),
            _entry(uid: 'uid_other', score: 5000, rank: 2),
          ]),
        );
      },
      act: (bloc) => bloc
          .add(const RankingWatchStarted(uid: 'uid_me', period: 'weekly')),
      expect: () => [
        isA<RankingLoading>(),
        isA<RankingLoaded>().having((s) => s.myRank, 'myRank', 1),
      ],
    );

    blocTest<RankingBloc, RankingState>(
      'sets myRank to null when current user is not in list',
      build: build,
      setUp: () {
        when(() => repo.watchLeaderboard(any(), limit: 50)).thenAnswer(
          (_) => Stream.value([
            _entry(uid: 'uid_other', score: 9999, rank: 1),
          ]),
        );
      },
      act: (bloc) => bloc
          .add(const RankingWatchStarted(uid: 'uid_me', period: 'weekly')),
      expect: () => [
        isA<RankingLoading>(),
        isA<RankingLoaded>().having((s) => s.myRank, 'myRank', isNull),
      ],
    );

    blocTest<RankingBloc, RankingState>(
      'emits [RankingLoading, RankingError] when stream throws',
      build: build,
      setUp: () {
        when(() => repo.watchLeaderboard(any(), limit: 50))
            .thenAnswer((_) => Stream.error(Exception('Firestore offline')));
      },
      act: (bloc) =>
          bloc.add(const RankingWatchStarted(uid: 'uid_01', period: 'weekly')),
      expect: () => [isA<RankingLoading>(), isA<RankingError>()],
    );

    blocTest<RankingBloc, RankingState>(
      'does not re-subscribe when same uid+period dispatched twice',
      build: build,
      setUp: () {
        when(() => repo.watchLeaderboard(any(), limit: 50))
            .thenAnswer((_) => Stream.value([]));
      },
      act: (bloc) async {
        bloc.add(const RankingWatchStarted(uid: 'uid_01', period: 'weekly'));
        await Future<void>.delayed(Duration.zero);
        bloc.add(const RankingWatchStarted(uid: 'uid_01', period: 'weekly'));
      },
      verify: (_) =>
          verify(() => repo.watchLeaderboard('weekly', limit: 50)).called(1),
    );
  });

  // ── RankingPeriodChanged ──────────────────────────────────────────────────

  group('RankingPeriodChanged', () {
    blocTest<RankingBloc, RankingState>(
      're-watches with new period after period change',
      build: build,
      setUp: () {
        when(() => repo.watchLeaderboard(any(), limit: 50))
            .thenAnswer((_) => Stream.value([]));
      },
      act: (bloc) async {
        bloc.add(const RankingWatchStarted(uid: 'uid_01', period: 'weekly'));
        await Future<void>.delayed(Duration.zero);
        bloc.add(
            const RankingPeriodChanged(uid: 'uid_01', period: 'alltime'));
        await Future<void>.delayed(Duration.zero);
      },
      verify: (_) {
        verify(() => repo.watchLeaderboard('weekly', limit: 50)).called(1);
        verify(() => repo.watchLeaderboard('alltime', limit: 50)).called(1);
      },
    );

    blocTest<RankingBloc, RankingState>(
      'emits RankingLoaded with alltime period after period change',
      build: build,
      setUp: () {
        when(() => repo.watchLeaderboard('weekly', limit: 50))
            .thenAnswer((_) => Stream.value([]));
        when(() => repo.watchLeaderboard('alltime', limit: 50)).thenAnswer(
          (_) => Stream.value([_entry(uid: 'uid_01', score: 500, rank: 1)]),
        );
      },
      act: (bloc) async {
        bloc.add(const RankingWatchStarted(uid: 'uid_01', period: 'weekly'));
        await Future<void>.delayed(Duration.zero);
        bloc.add(const RankingPeriodChanged(uid: 'uid_01', period: 'alltime'));
        await Future<void>.delayed(Duration.zero);
      },
      expect: () => [
        isA<RankingLoading>(),
        isA<RankingLoaded>().having((s) => s.period, 'period', 'weekly'),
        isA<RankingLoading>(),
        isA<RankingLoaded>().having((s) => s.period, 'period', 'alltime'),
      ],
    );
  });
}
