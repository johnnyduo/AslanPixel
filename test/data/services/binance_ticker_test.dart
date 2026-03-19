import 'package:flutter_test/flutter_test.dart';
import 'package:aslan_pixel/data/services/binance_ticker.dart';

void main() {
  const sampleJson = {
    'symbol': 'BTCUSDT',
    'lastPrice': '67500.12',
    'priceChangePercent': '2.34',
    'highPrice': '68000.00',
    'lowPrice': '66000.50',
    'volume': '12345.678',
    'quoteVolume': '834000000.00',
  };

  group('BinanceTicker.fromJson', () {
    test('parses all fields correctly', () {
      final ticker = BinanceTicker.fromJson(sampleJson);

      expect(ticker.symbol, 'BTCUSDT');
      expect(ticker.lastPrice, 67500.12);
      expect(ticker.priceChangePercent, 2.34);
      expect(ticker.highPrice, 68000.00);
      expect(ticker.lowPrice, 66000.50);
      expect(ticker.volume, 12345.678);
      expect(ticker.quoteVolume, 834000000.00);
    });

    test('handles missing/null fields gracefully', () {
      final ticker = BinanceTicker.fromJson(const <String, dynamic>{});

      expect(ticker.symbol, '');
      expect(ticker.lastPrice, 0);
      expect(ticker.priceChangePercent, 0);
    });
  });

  group('displaySymbol', () {
    test('converts BTCUSDT to BTC/USDT', () {
      final ticker = BinanceTicker.fromJson(sampleJson);
      expect(ticker.displaySymbol, 'BTC/USDT');
    });

    test('converts ETHBTC to ETH/BTC', () {
      final ticker = BinanceTicker.fromJson({
        ...sampleJson,
        'symbol': 'ETHBTC',
      });
      expect(ticker.displaySymbol, 'ETH/BTC');
    });

    test('returns symbol as-is when no known suffix', () {
      final ticker = BinanceTicker.fromJson({
        ...sampleJson,
        'symbol': 'CUSTOM',
      });
      expect(ticker.displaySymbol, 'CUSTOM');
    });
  });

  group('isPositive', () {
    test('returns true for positive change', () {
      final ticker = BinanceTicker.fromJson(sampleJson);
      expect(ticker.isPositive, true);
    });

    test('returns true for zero change', () {
      final ticker = BinanceTicker.fromJson({
        ...sampleJson,
        'priceChangePercent': '0.00',
      });
      expect(ticker.isPositive, true);
    });

    test('returns false for negative change', () {
      final ticker = BinanceTicker.fromJson({
        ...sampleJson,
        'priceChangePercent': '-1.50',
      });
      expect(ticker.isPositive, false);
    });
  });

  group('formattedPrice', () {
    test('shows 2 decimals for prices >= 1000', () {
      final ticker = BinanceTicker.fromJson(sampleJson);
      expect(ticker.formattedPrice, '67500.12');
    });

    test('shows 2 decimals for prices >= 1', () {
      final ticker = BinanceTicker.fromJson({
        ...sampleJson,
        'lastPrice': '5.50',
      });
      expect(ticker.formattedPrice, '5.50');
    });

    test('shows 6 decimals for prices < 1', () {
      final ticker = BinanceTicker.fromJson({
        ...sampleJson,
        'lastPrice': '0.000123',
      });
      expect(ticker.formattedPrice, '0.000123');
    });
  });

  group('formattedVolume', () {
    test('formats billions with B suffix', () {
      final ticker = BinanceTicker.fromJson({
        ...sampleJson,
        'quoteVolume': '2500000000.00',
      });
      expect(ticker.formattedVolume, '2.5B');
    });

    test('formats millions with M suffix', () {
      final ticker = BinanceTicker.fromJson(sampleJson);
      expect(ticker.formattedVolume, '834.0M');
    });

    test('formats thousands with K suffix', () {
      final ticker = BinanceTicker.fromJson({
        ...sampleJson,
        'quoteVolume': '5500.00',
      });
      expect(ticker.formattedVolume, '5.5K');
    });

    test('formats small values without suffix', () {
      final ticker = BinanceTicker.fromJson({
        ...sampleJson,
        'quoteVolume': '500.00',
      });
      expect(ticker.formattedVolume, '500');
    });
  });

  group('toJson round-trip', () {
    test('fromJson -> toJson -> fromJson produces same values', () {
      final original = BinanceTicker.fromJson(sampleJson);
      final json = original.toJson();
      final restored = BinanceTicker.fromJson(json);

      expect(restored.symbol, original.symbol);
      expect(restored.lastPrice, original.lastPrice);
      expect(restored.priceChangePercent, original.priceChangePercent);
      expect(restored.highPrice, original.highPrice);
      expect(restored.lowPrice, original.lowPrice);
      expect(restored.volume, original.volume);
      expect(restored.quoteVolume, original.quoteVolume);
    });
  });
}
