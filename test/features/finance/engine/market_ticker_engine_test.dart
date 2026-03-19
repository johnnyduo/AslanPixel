import 'package:aslan_pixel/features/finance/engine/market_ticker_engine.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('MarketTickerEngine', () {
    test('defaultTickers has 10 symbols', () {
      expect(MarketTickerEngine.defaultTickers.length, 10);
    });

    test('generateSnapshot returns valid price (positive, near basePrice)', () {
      final seed = MarketTickerEngine.defaultTickers.first; // SET
      final now = DateTime(2026, 3, 19, 10, 30);
      final snapshot = MarketTickerEngine.generateSnapshot(seed, now);

      expect(snapshot.price, greaterThan(0));
      // Price should be within 10% of base price
      expect(snapshot.price, greaterThan(seed.basePrice * 0.9));
      expect(snapshot.price, lessThan(seed.basePrice * 1.1));
    });

    test('deterministic: same seed+time produces same price', () {
      final seed = MarketTickerEngine.defaultTickers[3]; // BTC/USD
      final now = DateTime(2026, 3, 19, 14, 45);
      final snapshot1 = MarketTickerEngine.generateSnapshot(seed, now);
      final snapshot2 = MarketTickerEngine.generateSnapshot(seed, now);

      expect(snapshot1.price, equals(snapshot2.price));
      expect(snapshot1.changePercent, equals(snapshot2.changePercent));
      expect(snapshot1.sparkline, equals(snapshot2.sparkline));
    });

    test('different minutes produce different prices (not static)', () {
      final seed = MarketTickerEngine.defaultTickers[6]; // NVDA
      final time1 = DateTime(2026, 3, 19, 10, 0);
      final time2 = DateTime(2026, 3, 19, 10, 1);
      final snapshot1 = MarketTickerEngine.generateSnapshot(seed, time1);
      final snapshot2 = MarketTickerEngine.generateSnapshot(seed, time2);

      // Different minutes should (almost certainly) produce different prices
      expect(snapshot1.price != snapshot2.price, isTrue);
    });

    test('changePercent is reasonable (-5% to +5%)', () {
      final now = DateTime(2026, 3, 19, 12, 0);
      final snapshots = MarketTickerEngine.generateAll(now);

      for (final snapshot in snapshots) {
        expect(snapshot.changePercent, greaterThanOrEqualTo(-5.0));
        expect(snapshot.changePercent, lessThanOrEqualTo(5.0));
      }
    });

    test('sparkline has 12 data points', () {
      final seed = MarketTickerEngine.defaultTickers[0];
      final now = DateTime(2026, 3, 19, 9, 0);
      final snapshot = MarketTickerEngine.generateSnapshot(seed, now);

      expect(snapshot.sparkline.length, 12);
      for (final point in snapshot.sparkline) {
        expect(point, greaterThan(0));
      }
    });

    test('generateAll returns 10 snapshots', () {
      final now = DateTime(2026, 3, 19, 15, 30);
      final snapshots = MarketTickerEngine.generateAll(now);

      expect(snapshots.length, 10);
    });

    test('includes Thai SET symbols (PTT, KBANK)', () {
      final symbols =
          MarketTickerEngine.defaultTickers.map((t) => t.symbol).toList();
      expect(symbols, contains('PTT'));
      expect(symbols, contains('KBANK'));
    });

    test('includes crypto (BTC, ETH)', () {
      final symbols =
          MarketTickerEngine.defaultTickers.map((t) => t.symbol).toList();
      expect(symbols, contains('BTC/USD'));
      expect(symbols, contains('ETH/USD'));
    });

    test('categories are valid (index, thai, crypto, us, commodity, fx)', () {
      const validCategories = {'index', 'thai', 'crypto', 'us', 'commodity', 'fx'};
      for (final ticker in MarketTickerEngine.defaultTickers) {
        expect(validCategories.contains(ticker.category), isTrue,
            reason: '${ticker.symbol} has invalid category: ${ticker.category}');
      }
    });

    test('isPositive returns correct value based on changePercent', () {
      final now = DateTime(2026, 3, 19, 11, 0);
      final snapshots = MarketTickerEngine.generateAll(now);

      for (final snapshot in snapshots) {
        expect(snapshot.isPositive, equals(snapshot.changePercent >= 0));
      }
    });
  });
}
