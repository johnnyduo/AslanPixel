import 'dart:math';

/// Deterministic demo trading simulation engine.
///
/// Pure Dart — no Firebase, no Flutter dependencies.
/// LLM generates logEntry flavor text only — never controls outcomes.
class SimulationEngine {
  const SimulationEngine._();

  /// Runs a single simulated trade.
  ///
  /// The outcome is 100% deterministic: same inputs → same result.
  /// Win rate ranges 45–65% based on [riskLevel] and [agentLevel].
  static SimulationResult simulate({
    required String seed,
    required StrategyArchetype strategy,
    required RiskLevel riskLevel,
    required MarketFocus marketFocus,
    required int agentLevel,
    double eventModifier = 1.0,
  }) {
    final hash = _hashSeed(seed);
    final rng = Random(hash);

    // Win probability: base 50% + agent level bonus (0.5% per level, max 7.5%)
    // + strategy modifier + risk modifier
    const baseProb = 0.50;
    final agentBonus = (agentLevel.clamp(1, 15) * 0.005);
    final strategyMod = _strategyModifier(strategy);
    final riskMod = _riskModifier(riskLevel);
    final winProbability =
        (baseProb + agentBonus + strategyMod + riskMod).clamp(0.45, 0.65);

    final roll = rng.nextDouble();
    final isWin = roll < winProbability;

    // Reward calculation
    final riskMultiplier = _riskRewardMultiplier(riskLevel);
    final baseCoins = isWin
        ? (20 + rng.nextInt(30)) // 20-49 coins on win
        : -(10 + rng.nextInt(15)); // -10 to -24 coins on loss
    final coins = (baseCoins * riskMultiplier * eventModifier).round();
    final xp = isWin ? (10 + rng.nextInt(20)) : (5 + rng.nextInt(5));

    // Streak: simple pass-through (tracked externally)
    final outcome = isWin ? TradeOutcome.profit : TradeOutcome.loss;

    return SimulationResult(
      outcome: outcome,
      coinsEarned: coins,
      xpEarned: xp,
      winProbability: winProbability,
      roll: roll,
    );
  }

  static int _hashSeed(String seed) {
    // Consistent hash for determinism
    var hash = 0;
    for (var i = 0; i < seed.length; i++) {
      hash = (hash * 31 + seed.codeUnitAt(i)) & 0x7FFFFFFF;
    }
    return hash;
  }

  static double _strategyModifier(StrategyArchetype strategy) {
    switch (strategy) {
      case StrategyArchetype.conservative:
        return 0.05; // higher win rate but lower reward
      case StrategyArchetype.moderate:
        return 0.0;
      case StrategyArchetype.aggressive:
        return -0.05; // lower win rate but higher reward
    }
  }

  static double _riskModifier(RiskLevel riskLevel) {
    switch (riskLevel) {
      case RiskLevel.calm:
        return 0.05;
      case RiskLevel.balanced:
        return 0.0;
      case RiskLevel.bold:
        return -0.05;
    }
  }

  static double _riskRewardMultiplier(RiskLevel riskLevel) {
    switch (riskLevel) {
      case RiskLevel.calm:
        return 0.7; // lower risk, lower reward
      case RiskLevel.balanced:
        return 1.0;
      case RiskLevel.bold:
        return 1.5; // higher risk, higher reward
    }
  }
}

enum StrategyArchetype { conservative, moderate, aggressive }

enum RiskLevel { calm, balanced, bold }

enum MarketFocus { crypto, fx, stocks, mixed }

enum TradeOutcome { profit, loss }

class SimulationResult {
  const SimulationResult({
    required this.outcome,
    required this.coinsEarned,
    required this.xpEarned,
    required this.winProbability,
    required this.roll,
  });

  final TradeOutcome outcome;
  final int coinsEarned;
  final int xpEarned;
  final double winProbability;
  final double roll;

  bool get isWin => outcome == TradeOutcome.profit;
  bool get isLoss => outcome == TradeOutcome.loss;

  @override
  String toString() => 'SimulationResult('
      'outcome: $outcome, coins: $coinsEarned, xp: $xpEarned, '
      'winProb: ${(winProbability * 100).toStringAsFixed(1)}%, '
      'roll: ${roll.toStringAsFixed(4)})';
}
