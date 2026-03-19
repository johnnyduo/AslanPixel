import 'package:aslan_pixel/features/finance/data/models/price_alert_model.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('PriceAlertModel', () {
    test('shouldTrigger returns true when price crosses above target', () {
      final alert = PriceAlertModel(
        symbol: 'BTC/USD',
        targetPrice: 70000.0,
        direction: 'above',
        createdAt: DateTime(2026, 3, 19),
      );

      expect(alert.shouldTrigger(70000.0), isTrue);
      expect(alert.shouldTrigger(75000.0), isTrue);
      expect(alert.shouldTrigger(69999.0), isFalse);
    });

    test('shouldTrigger returns true when price crosses below target', () {
      final alert = PriceAlertModel(
        symbol: 'SET',
        targetPrice: 1400.0,
        direction: 'below',
        createdAt: DateTime(2026, 3, 19),
      );

      expect(alert.shouldTrigger(1400.0), isTrue);
      expect(alert.shouldTrigger(1350.0), isTrue);
      expect(alert.shouldTrigger(1401.0), isFalse);
    });

    test('shouldTrigger returns false when already triggered', () {
      final alert = PriceAlertModel(
        symbol: 'BTC/USD',
        targetPrice: 70000.0,
        direction: 'above',
        createdAt: DateTime(2026, 3, 19),
        triggered: true,
      );

      expect(alert.shouldTrigger(80000.0), isFalse);
    });

    test('copyWith works correctly', () {
      final alert = PriceAlertModel(
        symbol: 'ETH/USD',
        targetPrice: 3500.0,
        direction: 'above',
        createdAt: DateTime(2026, 3, 19),
      );

      expect(alert.triggered, isFalse);

      final triggered = alert.copyWith(triggered: true);
      expect(triggered.triggered, isTrue);
      expect(triggered.symbol, equals('ETH/USD'));
      expect(triggered.targetPrice, equals(3500.0));
      expect(triggered.direction, equals('above'));
      expect(triggered.createdAt, equals(DateTime(2026, 3, 19)));
    });

    test('copyWith without arguments returns equivalent model', () {
      final alert = PriceAlertModel(
        symbol: 'PTT',
        targetPrice: 40.0,
        direction: 'below',
        createdAt: DateTime(2026, 3, 19),
      );

      final copy = alert.copyWith();
      expect(copy.symbol, equals(alert.symbol));
      expect(copy.targetPrice, equals(alert.targetPrice));
      expect(copy.direction, equals(alert.direction));
      expect(copy.triggered, equals(alert.triggered));
    });
  });
}
