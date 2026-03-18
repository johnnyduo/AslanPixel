/// Aggregated result returned by [IdleTaskEngine.settleTasks].
///
/// Contains totals across all tasks that were newly settled in a single
/// settlement pass, together with streak metadata used by the UI to
/// drive dopamine reward overlays.
class RewardSummary {
  const RewardSummary({
    required this.totalCoins,
    required this.totalXp,
    required this.settledCount,
    required this.streakBonus,
    required this.isStreakMilestone,
  });

  /// Total coins earned across all settled tasks after streak multiplier.
  final int totalCoins;

  /// Total XP earned across all settled tasks (flat tier amounts).
  final int totalXp;

  /// Number of tasks that were newly settled.
  final int settledCount;

  /// The streak multiplier that was applied (e.g. 1.3 for day 3).
  final double streakBonus;

  /// True when the current streak is at a milestone day (3, 7 or 10).
  final bool isStreakMilestone;

  /// Convenience getter: percentage bonus above 1.0×, rounded to nearest int.
  /// e.g. streakBonus 1.3 → 30.
  int get bonusPercent => ((streakBonus - 1.0) * 100).round();

  @override
  String toString() => 'RewardSummary(coins: $totalCoins, xp: $totalXp, '
      'settled: $settledCount, streak: ${streakBonus}x, '
      'milestone: $isStreakMilestone)';
}
