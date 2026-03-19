import 'package:aslan_pixel/features/agents/engine/simulation_engine.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('SimulationEngine', () {
    // Default params for convenience
    SimulationResult run({
      String seed = 'test-seed-42',
      StrategyArchetype strategy = StrategyArchetype.moderate,
      RiskLevel riskLevel = RiskLevel.balanced,
      MarketFocus marketFocus = MarketFocus.stocks,
      int agentLevel = 5,
      double eventModifier = 1.0,
    }) {
      return SimulationEngine.simulate(
        seed: seed,
        strategy: strategy,
        riskLevel: riskLevel,
        marketFocus: marketFocus,
        agentLevel: agentLevel,
        eventModifier: eventModifier,
      );
    }

    group('determinism', () {
      test('same seed produces identical result', () {
        final a = run(seed: 'deterministic-seed');
        final b = run(seed: 'deterministic-seed');

        expect(a.outcome, equals(b.outcome));
        expect(a.coinsEarned, equals(b.coinsEarned));
        expect(a.xpEarned, equals(b.xpEarned));
        expect(a.winProbability, equals(b.winProbability));
        expect(a.roll, equals(b.roll));
      });

      test('same seed with same params is deterministic across 100 runs', () {
        final results = List.generate(
          100,
          (_) => run(seed: 'repeat-check'),
        );

        for (final r in results) {
          expect(r.outcome, equals(results.first.outcome));
          expect(r.coinsEarned, equals(results.first.coinsEarned));
          expect(r.xpEarned, equals(results.first.xpEarned));
        }
      });

      test('different seeds produce (usually) different results', () {
        final results = List.generate(
          20,
          (i) => run(seed: 'unique-seed-$i'),
        );

        // At least some should differ in outcome or coins
        final uniqueCoins = results.map((r) => r.coinsEarned).toSet();
        expect(uniqueCoins.length, greaterThan(1));
      });
    });

    group('win probability bounds', () {
      test('winProbability is clamped between 0.45 and 0.65', () {
        // Test all combinations of strategy and risk
        for (final strategy in StrategyArchetype.values) {
          for (final risk in RiskLevel.values) {
            for (final level in [1, 5, 10, 15]) {
              final result = run(
                seed: 'prob-test',
                strategy: strategy,
                riskLevel: risk,
                agentLevel: level,
              );
              expect(
                result.winProbability,
                greaterThanOrEqualTo(0.45),
                reason:
                    'strategy=$strategy risk=$risk level=$level → ${result.winProbability}',
              );
              expect(
                result.winProbability,
                lessThanOrEqualTo(0.65),
                reason:
                    'strategy=$strategy risk=$risk level=$level → ${result.winProbability}',
              );
            }
          }
        }
      });

      test('agent level 1 has lower win probability than level 15', () {
        final low = run(seed: 'level-test', agentLevel: 1);
        final high = run(seed: 'level-test', agentLevel: 15);
        expect(high.winProbability, greaterThan(low.winProbability));
      });

      test('agent level bonus is 0.5% per level', () {
        final level1 = run(seed: 'x', agentLevel: 1);
        final level2 = run(seed: 'x', agentLevel: 2);
        expect(
          (level2.winProbability - level1.winProbability).abs(),
          closeTo(0.005, 1e-10),
        );
      });
    });

    group('strategy archetype', () {
      test('all StrategyArchetype values produce valid results', () {
        for (final strategy in StrategyArchetype.values) {
          final result = run(seed: 'strat-$strategy', strategy: strategy);
          expect(result.outcome, isA<TradeOutcome>());
          expect(result.xpEarned, greaterThan(0));
        }
      });

      test('conservative has higher win probability than aggressive', () {
        final conservative = run(
          seed: 'cmp',
          strategy: StrategyArchetype.conservative,
        );
        final aggressive = run(
          seed: 'cmp',
          strategy: StrategyArchetype.aggressive,
        );
        expect(
          conservative.winProbability,
          greaterThan(aggressive.winProbability),
        );
      });

      test('conservative wins more often than aggressive over 1000 trials',
          () {
        int conservativeWins = 0;
        int aggressiveWins = 0;

        for (var i = 0; i < 1000; i++) {
          final c = run(
            seed: 'trial-$i',
            strategy: StrategyArchetype.conservative,
          );
          final a = run(
            seed: 'trial-$i',
            strategy: StrategyArchetype.aggressive,
          );
          if (c.isWin) conservativeWins++;
          if (a.isWin) aggressiveWins++;
        }

        expect(conservativeWins, greaterThan(aggressiveWins));
      });
    });

    group('risk level', () {
      test('all RiskLevel values produce valid results', () {
        for (final risk in RiskLevel.values) {
          final result = run(seed: 'risk-$risk', riskLevel: risk);
          expect(result.outcome, isA<TradeOutcome>());
          expect(result.xpEarned, greaterThan(0));
        }
      });

      test('bold risk earns more per winning trade than calm', () {
        // Run many trades and compare average absolute coins on wins
        double calmTotal = 0;
        int calmWins = 0;
        double boldTotal = 0;
        int boldWins = 0;

        for (var i = 0; i < 1000; i++) {
          final calm = run(seed: 'rr-$i', riskLevel: RiskLevel.calm);
          final bold = run(seed: 'rr-$i', riskLevel: RiskLevel.bold);

          if (calm.isWin) {
            calmTotal += calm.coinsEarned;
            calmWins++;
          }
          if (bold.isWin) {
            boldTotal += bold.coinsEarned;
            boldWins++;
          }
        }

        // Bold average win should be higher than calm average win
        if (calmWins > 0 && boldWins > 0) {
          final calmAvg = calmTotal / calmWins;
          final boldAvg = boldTotal / boldWins;
          expect(boldAvg, greaterThan(calmAvg));
        }
      });

      test('bold risk loses more per losing trade than calm', () {
        double calmLossTotal = 0;
        int calmLosses = 0;
        double boldLossTotal = 0;
        int boldLosses = 0;

        for (var i = 0; i < 1000; i++) {
          final calm = run(seed: 'rl-$i', riskLevel: RiskLevel.calm);
          final bold = run(seed: 'rl-$i', riskLevel: RiskLevel.bold);

          if (calm.isLoss) {
            calmLossTotal += calm.coinsEarned.abs();
            calmLosses++;
          }
          if (bold.isLoss) {
            boldLossTotal += bold.coinsEarned.abs();
            boldLosses++;
          }
        }

        if (calmLosses > 0 && boldLosses > 0) {
          final calmAvg = calmLossTotal / calmLosses;
          final boldAvg = boldLossTotal / boldLosses;
          expect(boldAvg, greaterThan(calmAvg));
        }
      });
    });

    group('market focus', () {
      test('all MarketFocus values produce valid results', () {
        for (final market in MarketFocus.values) {
          final result = run(seed: 'mkt-$market', marketFocus: market);
          expect(result.outcome, isA<TradeOutcome>());
          expect(result.xpEarned, greaterThan(0));
          expect(result.winProbability, greaterThanOrEqualTo(0.45));
          expect(result.winProbability, lessThanOrEqualTo(0.65));
        }
      });
    });

    group('event modifier', () {
      test('eventModifier scales coin reward', () {
        final normal = run(seed: 'em-test', eventModifier: 1.0);
        final doubled = run(seed: 'em-test', eventModifier: 2.0);

        // Same outcome (same seed), but coins should differ by the multiplier
        expect(normal.outcome, equals(doubled.outcome));
        // The coins should be approximately 2x (rounding may cause tiny diffs)
        expect(doubled.coinsEarned, equals(normal.coinsEarned * 2));
      });

      test('eventModifier does not affect XP', () {
        final normal = run(seed: 'em-xp', eventModifier: 1.0);
        final scaled = run(seed: 'em-xp', eventModifier: 3.0);
        expect(normal.xpEarned, equals(scaled.xpEarned));
      });

      test('eventModifier does not affect win probability', () {
        final normal = run(seed: 'em-wp', eventModifier: 1.0);
        final scaled = run(seed: 'em-wp', eventModifier: 5.0);
        expect(normal.winProbability, equals(scaled.winProbability));
        expect(normal.outcome, equals(scaled.outcome));
      });
    });

    group('coin rewards', () {
      test('coins are positive on win', () {
        // Find a winning seed
        for (var i = 0; i < 100; i++) {
          final result = run(seed: 'win-search-$i');
          if (result.isWin) {
            expect(result.coinsEarned, greaterThan(0));
            return;
          }
        }
        fail('Could not find a winning trade in 100 seeds');
      });

      test('coins are negative on loss', () {
        for (var i = 0; i < 100; i++) {
          final result = run(seed: 'loss-search-$i');
          if (result.isLoss) {
            expect(result.coinsEarned, lessThan(0));
            return;
          }
        }
        fail('Could not find a losing trade in 100 seeds');
      });
    });

    group('XP rewards', () {
      test('XP is always positive regardless of outcome', () {
        for (var i = 0; i < 200; i++) {
          final result = run(seed: 'xp-check-$i');
          expect(result.xpEarned, greaterThan(0),
              reason: 'XP should be positive for seed xp-check-$i');
        }
      });

      test('winning trades give more XP than losing trades on average', () {
        double winXp = 0;
        int wins = 0;
        double lossXp = 0;
        int losses = 0;

        for (var i = 0; i < 1000; i++) {
          final result = run(seed: 'xp-avg-$i');
          if (result.isWin) {
            winXp += result.xpEarned;
            wins++;
          } else {
            lossXp += result.xpEarned;
            losses++;
          }
        }

        if (wins > 0 && losses > 0) {
          expect(winXp / wins, greaterThan(lossXp / losses));
        }
      });
    });

    group('statistical win rate (1000 simulations)', () {
      test('overall win rate is roughly between 45% and 65%', () {
        int wins = 0;
        const trials = 1000;

        for (var i = 0; i < trials; i++) {
          final result = run(seed: 'stats-$i');
          if (result.isWin) wins++;
        }

        final winRate = wins / trials;
        expect(
          winRate,
          greaterThanOrEqualTo(0.40), // slight margin for randomness
          reason: 'Win rate $winRate is below expected range',
        );
        expect(
          winRate,
          lessThanOrEqualTo(0.70), // slight margin for randomness
          reason: 'Win rate $winRate is above expected range',
        );
      });

      test('conservative+calm has highest win rate', () {
        int wins = 0;
        const trials = 1000;

        for (var i = 0; i < trials; i++) {
          final result = run(
            seed: 'high-wr-$i',
            strategy: StrategyArchetype.conservative,
            riskLevel: RiskLevel.calm,
            agentLevel: 15,
          );
          if (result.isWin) wins++;
        }

        final winRate = wins / trials;
        // Should be near 0.65 (the max)
        expect(winRate, greaterThanOrEqualTo(0.60));
      });

      test('aggressive+bold has lowest win rate', () {
        int wins = 0;
        const trials = 1000;

        for (var i = 0; i < trials; i++) {
          final result = run(
            seed: 'low-wr-$i',
            strategy: StrategyArchetype.aggressive,
            riskLevel: RiskLevel.bold,
            agentLevel: 1,
          );
          if (result.isWin) wins++;
        }

        final winRate = wins / trials;
        // Should be near 0.45 (the min)
        expect(winRate, lessThanOrEqualTo(0.50));
      });
    });

    group('SimulationResult', () {
      test('isWin returns true for profit outcome', () {
        final result = SimulationResult(
          outcome: TradeOutcome.profit,
          coinsEarned: 30,
          xpEarned: 15,
          winProbability: 0.55,
          roll: 0.3,
        );
        expect(result.isWin, isTrue);
        expect(result.isLoss, isFalse);
      });

      test('isLoss returns true for loss outcome', () {
        final result = SimulationResult(
          outcome: TradeOutcome.loss,
          coinsEarned: -15,
          xpEarned: 7,
          winProbability: 0.55,
          roll: 0.8,
        );
        expect(result.isWin, isFalse);
        expect(result.isLoss, isTrue);
      });

      test('toString has correct format', () {
        final result = SimulationResult(
          outcome: TradeOutcome.profit,
          coinsEarned: 42,
          xpEarned: 18,
          winProbability: 0.55,
          roll: 0.1234,
        );
        final str = result.toString();
        expect(str, contains('SimulationResult('));
        expect(str, contains('outcome: TradeOutcome.profit'));
        expect(str, contains('coins: 42'));
        expect(str, contains('xp: 18'));
        expect(str, contains('winProb: 55.0%'));
        expect(str, contains('roll: 0.1234'));
      });
    });

    group('edge cases', () {
      test('empty seed does not crash', () {
        final result = run(seed: '');
        expect(result.outcome, isA<TradeOutcome>());
      });

      test('very long seed does not crash', () {
        final longSeed = 'a' * 10000;
        final result = run(seed: longSeed);
        expect(result.outcome, isA<TradeOutcome>());
      });

      test('agent level clamped below 1', () {
        final result = run(seed: 'clamp-low', agentLevel: -5);
        expect(result.winProbability, greaterThanOrEqualTo(0.45));
      });

      test('agent level clamped above 15', () {
        final result = run(seed: 'clamp-high', agentLevel: 100);
        // Should behave same as level 15
        final level15 = run(seed: 'clamp-high', agentLevel: 15);
        expect(result.winProbability, equals(level15.winProbability));
      });

      test('eventModifier of 0 produces 0 coins', () {
        final result = run(seed: 'zero-mod', eventModifier: 0.0);
        expect(result.coinsEarned, equals(0));
      });
    });
  });
}
