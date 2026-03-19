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

  // ── EconomyLevelUp state ──────────────────────────────────────────────────

  group('EconomyLevelUp state', () {
    test('has correct newLevel and bonusCoins', () {
      const state = EconomyLevelUp(newLevel: 5, bonusCoins: 250);
      expect(state.newLevel, 5);
      expect(state.bonusCoins, 250);
    });

    test('equality: same values are equal', () {
      const s1 = EconomyLevelUp(newLevel: 3, bonusCoins: 150);
      const s2 = EconomyLevelUp(newLevel: 3, bonusCoins: 150);
      expect(s1, equals(s2));
    });

    test('equality: different values are not equal', () {
      const s1 = EconomyLevelUp(newLevel: 3, bonusCoins: 150);
      const s2 = EconomyLevelUp(newLevel: 4, bonusCoins: 200);
      expect(s1, isNot(equals(s2)));
    });

    test('props includes newLevel and bonusCoins', () {
      const state = EconomyLevelUp(newLevel: 7, bonusCoins: 350);
      expect(state.props, [7, 350]);
    });
  });

  // ── Level-up detection in EconomyBloc ─────────────────────────────────────

  group('EconomyBloc level-up detection', () {
    blocTest<EconomyBloc, EconomyState>(
      'emits EconomyLevelUp when level increases on stream update',
      build: build,
      setUp: () {
        // First snapshot: level 1 (xp=0), second: level 2 (xp=1000).
        when(() => repo.watchEconomy(any())).thenAnswer(
          (_) => Stream.fromIterable([
            _model(xp: 0),
            _model(xp: 1000),
          ]),
        );
      },
      act: (bloc) => bloc.add(const EconomyWatchStarted('uid_01')),
      expect: () => [
        isA<EconomyLoading>(),
        // First snapshot: level 1, no level-up (previous was 0).
        isA<EconomyLoaded>().having((s) => s.level, 'level', 1),
        // Level-up detected: 1 → 2.
        isA<EconomyLevelUp>()
            .having((s) => s.newLevel, 'newLevel', 2)
            .having((s) => s.bonusCoins, 'bonusCoins', 100),
        // Then continues with EconomyLoaded.
        isA<EconomyLoaded>().having((s) => s.level, 'level', 2),
      ],
    );

    blocTest<EconomyBloc, EconomyState>(
      'does not emit EconomyLevelUp on first snapshot (initial load)',
      build: build,
      setUp: () {
        when(() => repo.watchEconomy(any()))
            .thenAnswer((_) => Stream.value(_model(xp: 5000)));
      },
      act: (bloc) => bloc.add(const EconomyWatchStarted('uid_01')),
      expect: () => [
        isA<EconomyLoading>(),
        // Level 6 on first load — no level-up emitted.
        isA<EconomyLoaded>().having((s) => s.level, 'level', 6),
      ],
    );

    blocTest<EconomyBloc, EconomyState>(
      'does not emit EconomyLevelUp when level stays the same',
      build: build,
      setUp: () {
        when(() => repo.watchEconomy(any())).thenAnswer(
          (_) => Stream.fromIterable([
            _model(coins: 100, xp: 500),
            _model(coins: 200, xp: 800),
          ]),
        );
      },
      act: (bloc) => bloc.add(const EconomyWatchStarted('uid_01')),
      expect: () => [
        isA<EconomyLoading>(),
        isA<EconomyLoaded>().having((s) => s.level, 'level', 1),
        // Same level — no EconomyLevelUp.
        isA<EconomyLoaded>().having((s) => s.level, 'level', 1),
      ],
    );

    blocTest<EconomyBloc, EconomyState>(
      'emits EconomyLevelUp with bonusCoins = newLevel * 50',
      build: build,
      setUp: () {
        // Jump from level 1 to level 5.
        when(() => repo.watchEconomy(any())).thenAnswer(
          (_) => Stream.fromIterable([
            _model(xp: 0), // level 1
            _model(xp: 4000), // level 5
          ]),
        );
      },
      act: (bloc) => bloc.add(const EconomyWatchStarted('uid_01')),
      expect: () => [
        isA<EconomyLoading>(),
        isA<EconomyLoaded>().having((s) => s.level, 'level', 1),
        isA<EconomyLevelUp>()
            .having((s) => s.newLevel, 'newLevel', 5)
            .having((s) => s.bonusCoins, 'bonusCoins', 250),
        isA<EconomyLoaded>().having((s) => s.level, 'level', 5),
      ],
    );
  });
}
