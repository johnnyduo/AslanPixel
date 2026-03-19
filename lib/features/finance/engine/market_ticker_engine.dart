import 'dart:math';

/// Simulates realistic market price movements for demo tickers.
///
/// Uses Brownian motion with drift to create believable price action.
/// NOT real data — for game engagement only.
class MarketTickerEngine {
  const MarketTickerEngine._();

  /// Default tickers with Thai SET + US + Crypto focus.
  static const List<TickerSeed> defaultTickers = [
    TickerSeed(symbol: 'SET', basePrice: 1420.0, volatility: 0.003, category: 'index'),
    TickerSeed(symbol: 'PTT', basePrice: 35.50, volatility: 0.008, category: 'thai'),
    TickerSeed(symbol: 'KBANK', basePrice: 145.0, volatility: 0.006, category: 'thai'),
    TickerSeed(symbol: 'BTC/USD', basePrice: 67500.0, volatility: 0.015, category: 'crypto'),
    TickerSeed(symbol: 'ETH/USD', basePrice: 3200.0, volatility: 0.018, category: 'crypto'),
    TickerSeed(symbol: 'AAPL', basePrice: 224.0, volatility: 0.008, category: 'us'),
    TickerSeed(symbol: 'NVDA', basePrice: 880.0, volatility: 0.020, category: 'us'),
    TickerSeed(symbol: 'TSLA', basePrice: 172.0, volatility: 0.025, category: 'us'),
    TickerSeed(symbol: 'XAU/USD', basePrice: 2340.0, volatility: 0.005, category: 'commodity'),
    TickerSeed(symbol: 'USD/THB', basePrice: 36.20, volatility: 0.002, category: 'fx'),
  ];

  /// Generates a price snapshot based on seed + current time.
  /// Same second -> same price (deterministic per-second).
  static TickerSnapshot generateSnapshot(TickerSeed seed, DateTime now) {
    final minuteSeed =
        '${seed.symbol}_${now.year}${now.month}${now.day}_${now.hour}${now.minute}'
            .hashCode;
    final rng = Random(minuteSeed);

    // Brownian motion: random walk with mean reversion
    final drift = (rng.nextDouble() - 0.48) * seed.volatility; // slight bullish bias
    final noise = (rng.nextDouble() - 0.5) * seed.volatility * 2;
    final change = drift + noise;
    final price = seed.basePrice * (1 + change);
    final changePercent = change * 100;

    // Generate 12-point sparkline for the "day"
    final sparkline = List.generate(12, (i) {
      final stepSeed = '${seed.symbol}_spark_$i'.hashCode + minuteSeed;
      final stepRng = Random(stepSeed);
      final stepChange = (stepRng.nextDouble() - 0.5) * seed.volatility * 1.5;
      return seed.basePrice * (1 + stepChange);
    });

    return TickerSnapshot(
      symbol: seed.symbol,
      price: double.parse(price.toStringAsFixed(_decimals(seed))),
      changePercent: double.parse(changePercent.toStringAsFixed(2)),
      sparkline: sparkline,
      category: seed.category,
      updatedAt: now,
    );
  }

  /// Generate all default ticker snapshots.
  static List<TickerSnapshot> generateAll(DateTime now) =>
      defaultTickers.map((s) => generateSnapshot(s, now)).toList();

  static int _decimals(TickerSeed seed) {
    if (seed.basePrice > 1000) return 2;
    if (seed.basePrice > 10) return 2;
    return 4;
  }
}

class TickerSeed {
  const TickerSeed({
    required this.symbol,
    required this.basePrice,
    required this.volatility,
    required this.category,
  });
  final String symbol;
  final double basePrice;
  final double volatility;
  final String category;
}

class TickerSnapshot {
  const TickerSnapshot({
    required this.symbol,
    required this.price,
    required this.changePercent,
    required this.sparkline,
    required this.category,
    required this.updatedAt,
  });
  final String symbol;
  final double price;
  final double changePercent;
  final List<double> sparkline;
  final String category;
  final DateTime updatedAt;

  bool get isPositive => changePercent >= 0;
}
