import 'package:aslan_pixel/features/agents/engine/reward_summary.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('RewardSummary', () {
    group('bonusPercent', () {
      test('returns 0 when streakBonus is 1.0 (no bonus)', () {
        const summary = RewardSummary(
          totalCoins: 100,
          totalXp: 50,
          settledCount: 2,
          streakBonus: 1.0,
          isStreakMilestone: false,
        );
        expect(summary.bonusPercent, 0);
      });

      test('returns 30 when streakBonus is 1.3', () {
        const summary = RewardSummary(
          totalCoins: 100,
          totalXp: 50,
          settledCount: 2,
          streakBonus: 1.3,
          isStreakMilestone: false,
        );
        expect(summary.bonusPercent, 30);
      });

      test('returns 100 when streakBonus is 2.0', () {
        const summary = RewardSummary(
          totalCoins: 200,
          totalXp: 100,
          settledCount: 5,
          streakBonus: 2.0,
          isStreakMilestone: true,
        );
        expect(summary.bonusPercent, 100);
      });

      test('returns 50 when streakBonus is 1.5', () {
        const summary = RewardSummary(
          totalCoins: 100,
          totalXp: 50,
          settledCount: 3,
          streakBonus: 1.5,
          isStreakMilestone: true,
        );
        expect(summary.bonusPercent, 50);
      });

      test('rounds correctly for fractional percentages (1.15 -> 15)', () {
        const summary = RewardSummary(
          totalCoins: 100,
          totalXp: 50,
          settledCount: 1,
          streakBonus: 1.15,
          isStreakMilestone: false,
        );
        expect(summary.bonusPercent, 15);
      });
    });

    group('toString', () {
      test('formats all fields correctly', () {
        const summary = RewardSummary(
          totalCoins: 250,
          totalXp: 120,
          settledCount: 3,
          streakBonus: 1.3,
          isStreakMilestone: true,
        );
        expect(
          summary.toString(),
          'RewardSummary(coins: 250, xp: 120, settled: 3, streak: 1.3x, milestone: true)',
        );
      });

      test('formats zero rewards correctly', () {
        const summary = RewardSummary(
          totalCoins: 0,
          totalXp: 0,
          settledCount: 0,
          streakBonus: 1.0,
          isStreakMilestone: false,
        );
        expect(
          summary.toString(),
          'RewardSummary(coins: 0, xp: 0, settled: 0, streak: 1.0x, milestone: false)',
        );
      });
    });

    group('zero rewards case', () {
      test('all values are zero with no streak', () {
        const summary = RewardSummary(
          totalCoins: 0,
          totalXp: 0,
          settledCount: 0,
          streakBonus: 1.0,
          isStreakMilestone: false,
        );
        expect(summary.totalCoins, 0);
        expect(summary.totalXp, 0);
        expect(summary.settledCount, 0);
        expect(summary.streakBonus, 1.0);
        expect(summary.isStreakMilestone, false);
        expect(summary.bonusPercent, 0);
      });
    });

    group('high rewards case', () {
      test('stores large values correctly', () {
        const summary = RewardSummary(
          totalCoins: 999999,
          totalXp: 500000,
          settledCount: 100,
          streakBonus: 2.0,
          isStreakMilestone: true,
        );
        expect(summary.totalCoins, 999999);
        expect(summary.totalXp, 500000);
        expect(summary.settledCount, 100);
        expect(summary.streakBonus, 2.0);
        expect(summary.isStreakMilestone, true);
        expect(summary.bonusPercent, 100);
      });
    });
  });
}
