import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import 'package:aslan_pixel/features/inventory/bloc/economy_bloc.dart';
import 'package:aslan_pixel/features/inventory/data/models/economy_model.dart';
import 'package:aslan_pixel/features/inventory/data/repositories/economy_repository.dart';
import '../../../mocks/test_fixtures.dart';

// ── Mock ─────────────────────────────────────────────────────────────────────

class MockEconomyRepository extends Mock implements EconomyRepository {}

// ── Helpers ──────────────────────────────────────────────────────────────────

EconomyModel _model({int coins = 500, int xp = 0}) => EconomyModel(
      coins: coins,
      xp: xp,
      unlockPoints: 0,
      lastUpdated: kNow,
    );

void main() {
  late MockEconomyRepository repo;

  setUp(() {
    repo = MockEconomyRepository();
  });

  EconomyBloc build() => EconomyBloc(repository: repo);

  // ── Initial state ─────────────────────────────────────────────────────────

  group('EconomyBloc initial state', () {
    test('starts as EconomyInitial', () {
      expect(build().state, isA<EconomyInitial>());
    });
  });

  // ── EconomyWatchStarted ───────────────────────────────────────────────────

  group('EconomyWatchStarted', () {
    blocTest<EconomyBloc, EconomyState>(
      'emits [EconomyLoading, EconomyLoaded] with coins/xp/level from stream',
      build: build,
      setUp: () {
        when(() => repo.watchEconomy('uid_01'))
            .thenAnswer((_) => Stream.value(_model(coins: 500, xp: 2000)));
      },
      act: (bloc) => bloc.add(const EconomyWatchStarted('uid_01')),
      expect: () => [
        isA<EconomyLoading>(),
        isA<EconomyLoaded>()
            .having((s) => s.coins, 'coins', 500)
            .having((s) => s.xp, 'xp', 2000)
            .having((s) => s.level, 'level', 3),
      ],
    );

    blocTest<EconomyBloc, EconomyState>(
      'emits [EconomyLoading, EconomyError] when stream throws',
      build: build,
      setUp: () {
        when(() => repo.watchEconomy(any()))
            .thenAnswer((_) => Stream.error(Exception('Firestore offline')));
      },
      act: (bloc) => bloc.add(const EconomyWatchStarted('uid_01')),
      expect: () => [isA<EconomyLoading>(), isA<EconomyError>()],
    );

    blocTest<EconomyBloc, EconomyState>(
      'does not re-subscribe for the same uid',
      build: build,
      setUp: () {
        when(() => repo.watchEconomy(any()))
            .thenAnswer((_) => Stream.value(_model()));
      },
      act: (bloc) async {
        bloc.add(const EconomyWatchStarted('uid_01'));
        await Future<void>.delayed(Duration.zero);
        bloc.add(const EconomyWatchStarted('uid_01'));
      },
      verify: (_) => verify(() => repo.watchEconomy('uid_01')).called(1),
    );

    blocTest<EconomyBloc, EconomyState>(
      'emits multiple EconomyLoaded states on stream updates',
      build: build,
      setUp: () {
        when(() => repo.watchEconomy(any())).thenAnswer(
          (_) => Stream.fromIterable([
            _model(coins: 100, xp: 0),
            _model(coins: 200, xp: 1000),
          ]),
        );
      },
      act: (bloc) => bloc.add(const EconomyWatchStarted('uid_01')),
      expect: () => [
        isA<EconomyLoading>(),
        isA<EconomyLoaded>().having((s) => s.coins, 'coins', 100),
        isA<EconomyLoaded>().having((s) => s.coins, 'coins', 200),
      ],
    );
  });

  // ── Level calculation ─────────────────────────────────────────────────────
  //
  // Formula: xp ~/ 1000 + 1  (minimum level 1)
  // Defined in EconomyModel.level; EconomyBloc passes it straight through.

  group('EconomyLoaded level calculation via EconomyWatchStarted', () {
    void expectLevel(int xp, int expectedLevel) {
      blocTest<EconomyBloc, EconomyState>(
        'xp=$xp → level=$expectedLevel',
        build: build,
        setUp: () {
          when(() => repo.watchEconomy(any()))
              .thenAnswer((_) => Stream.value(_model(xp: xp)));
        },
        act: (bloc) => bloc.add(const EconomyWatchStarted('uid_01')),
        expect: () => [
          isA<EconomyLoading>(),
          isA<EconomyLoaded>()
              .having((s) => s.level, 'level', expectedLevel),
        ],
      );
    }

    expectLevel(0, 1);
    expectLevel(999, 1);
    expectLevel(1000, 2);
    expectLevel(2500, 3);
    expectLevel(9999, 10);
    expectLevel(10000, 11);
  });

  // ── EconomyCoinsAdded ─────────────────────────────────────────────────────

  group('EconomyCoinsAdded', () {
    blocTest<EconomyBloc, EconomyState>(
      'calls repository addCoins with correct uid, amount and reason',
      build: build,
      setUp: () {
        when(() => repo.watchEconomy(any()))
            .thenAnswer((_) => Stream.value(_model()));
        when(() => repo.addCoins(any(), any(), any()))
            .thenAnswer((_) async {});
      },
      act: (bloc) async {
        bloc.add(const EconomyWatchStarted('uid_01'));
        await Future<void>.delayed(Duration.zero);
        bloc.add(const EconomyCoinsAdded(
          uid: 'uid_01',
          amount: 50,
          reason: 'quest_reward',
        ));
      },
      verify: (_) =>
          verify(() => repo.addCoins('uid_01', 50, 'quest_reward')).called(1),
    );

    blocTest<EconomyBloc, EconomyState>(
      'emits EconomyError when addCoins throws',
      build: build,
      setUp: () {
        when(() => repo.watchEconomy(any()))
            .thenAnswer((_) => Stream.value(_model()));
        when(() => repo.addCoins(any(), any(), any()))
            .thenThrow(Exception('write failed'));
      },
      act: (bloc) async {
        bloc.add(const EconomyWatchStarted('uid_01'));
        await Future<void>.delayed(Duration.zero);
        bloc.add(const EconomyCoinsAdded(
          uid: 'uid_01',
          amount: 50,
          reason: 'quest_reward',
        ));
      },
      expect: () => [
        isA<EconomyLoading>(),
        isA<EconomyLoaded>(),
        isA<EconomyError>(),
      ],
    );
  });

  // ── EconomyCoinsDeducted ──────────────────────────────────────────────────

  group('EconomyCoinsDeducted', () {
    blocTest<EconomyBloc, EconomyState>(
      'calls repository deductCoins with correct args',
      build: build,
      setUp: () {
        when(() => repo.watchEconomy(any()))
            .thenAnswer((_) => Stream.value(_model(coins: 200)));
        when(() => repo.deductCoins(any(), any(), any()))
            .thenAnswer((_) async {});
      },
      act: (bloc) async {
        bloc.add(const EconomyWatchStarted('uid_01'));
        await Future<void>.delayed(Duration.zero);
        bloc.add(const EconomyCoinsDeducted(
          uid: 'uid_01',
          amount: 10,
          reason: 'prediction_entry',
        ));
      },
      verify: (_) =>
          verify(() => repo.deductCoins('uid_01', 10, 'prediction_entry'))
              .called(1),
    );

    blocTest<EconomyBloc, EconomyState>(
      'emits EconomyError when deductCoins throws',
      build: build,
      setUp: () {
        when(() => repo.watchEconomy(any()))
            .thenAnswer((_) => Stream.value(_model(coins: 5)));
        when(() => repo.deductCoins(any(), any(), any()))
            .thenThrow(Exception('InsufficientCoinsException'));
      },
      act: (bloc) async {
        bloc.add(const EconomyWatchStarted('uid_01'));
        await Future<void>.delayed(Duration.zero);
        bloc.add(const EconomyCoinsDeducted(
          uid: 'uid_01',
          amount: 100,
          reason: 'prediction_entry',
        ));
      },
      expect: () => [
        isA<EconomyLoading>(),
        isA<EconomyLoaded>(),
        isA<EconomyError>(),
      ],
    );
  });

  // ── State equality ────────────────────────────────────────────────────────

  group('EconomyState equality', () {
    test('EconomyInitial == EconomyInitial', () {
      expect(const EconomyInitial(), equals(const EconomyInitial()));
    });

    test('EconomyLoading == EconomyLoading', () {
      expect(const EconomyLoading(), equals(const EconomyLoading()));
    });

    test('EconomyLoaded with same values are equal', () {
      const s1 = EconomyLoaded(coins: 100, xp: 500, level: 1);
      const s2 = EconomyLoaded(coins: 100, xp: 500, level: 1);
      expect(s1, equals(s2));
    });

    test('EconomyLoaded with different coins are not equal', () {
      const s1 = EconomyLoaded(coins: 100, xp: 500, level: 1);
      const s2 = EconomyLoaded(coins: 200, xp: 500, level: 1);
      expect(s1, isNot(equals(s2)));
    });

    test('EconomyError with same message are equal', () {
      expect(
        const EconomyError('error'),
        equals(const EconomyError('error')),
      );
    });
  });
}
