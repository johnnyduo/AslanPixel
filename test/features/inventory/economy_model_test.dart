import 'package:flutter_test/flutter_test.dart';

import '../../mocks/test_fixtures.dart';

void main() {
  // ── level computation ──────────────────────────────────────────────────────

  group('EconomyModel.level', () {
    test('level 1 at 0 xp', () {
      expect(kEconomy(xp: 0).level, 1);
    });

    test('level 1 at 999 xp', () {
      expect(kEconomy(xp: 999).level, 1);
    });

    test('level 2 at 1000 xp', () {
      expect(kEconomy(xp: 1000).level, 2);
    });

    test('level 2 at 1999 xp', () {
      expect(kEconomy(xp: 1999).level, 2);
    });

    test('level 3 at 2000 xp', () {
      expect(kEconomy(xp: 2000).level, 3);
    });

    test('level 11 at 10000 xp', () {
      expect(kEconomy(xp: 10000).level, 11);
    });

    test('level increases by 1 per 1000 xp', () {
      for (int i = 1; i <= 20; i++) {
        expect(kEconomy(xp: i * 1000).level, i + 1);
      }
    });
  });

  // ── copyWith ───────────────────────────────────────────────────────────────

  group('EconomyModel.copyWith', () {
    test('copyWith coins changes only coins', () {
      final original = kEconomy(coins: 500, xp: 2000);
      final updated = original.copyWith(coins: 600);
      expect(updated.coins, 600);
      expect(updated.xp, 2000);
      expect(updated.unlockPoints, original.unlockPoints);
    });

    test('copyWith xp changes only xp', () {
      final original = kEconomy(coins: 500, xp: 2000);
      final updated = original.copyWith(xp: 3000);
      expect(updated.xp, 3000);
      expect(updated.coins, 500);
    });

    test('copyWith with no args returns same values', () {
      final original = kEconomy(coins: 500, xp: 2000);
      final copy = original.copyWith();
      expect(copy.coins, original.coins);
      expect(copy.xp, original.xp);
      expect(copy.unlockPoints, original.unlockPoints);
    });

    test('copyWith unlockPoints changes only unlockPoints', () {
      final original = kEconomy();
      final updated = original.copyWith(unlockPoints: 20);
      expect(updated.unlockPoints, 20);
      expect(updated.coins, original.coins);
    });
  });

  // ── equality ───────────────────────────────────────────────────────────────

  // EconomyModel does not extend Equatable — uses reference equality.
  // We verify data-level equality via field comparison instead.
  group('EconomyModel field comparison', () {
    test('two models with same values have same coins', () {
      expect(kEconomy(coins: 500).coins, equals(kEconomy(coins: 500).coins));
    });

    test('two models with same xp have same level', () {
      expect(kEconomy(xp: 2000).level, equals(kEconomy(xp: 2000).level));
    });

    test('different coins produce different values', () {
      expect(kEconomy(coins: 100).coins, isNot(equals(kEconomy(coins: 200).coins)));
    });

    test('different xp produce different levels at boundary', () {
      expect(kEconomy(xp: 999).level, isNot(equals(kEconomy(xp: 1000).level)));
    });
  });

  // ── toMap / serialization ──────────────────────────────────────────────────

  group('EconomyModel.toMap', () {
    test('toMap contains coins key', () {
      expect(kEconomy(coins: 500).toMap(), containsPair('coins', 500));
    });

    test('toMap contains xp key', () {
      expect(kEconomy(xp: 2000).toMap(), containsPair('xp', 2000));
    });

    test('toMap contains unlockPoints key', () {
      expect(
        kEconomy().toMap(),
        containsPair('unlockPoints', 10),
      );
    });

    test('toMap contains lastUpdated key', () {
      final map = kEconomy().toMap();
      expect(map.containsKey('lastUpdated'), isTrue);
    });

    test('round-trip: toMap preserves coin value', () {
      final original = kEconomy(coins: 9999);
      expect(original.toMap()['coins'], 9999);
    });
  });
}
