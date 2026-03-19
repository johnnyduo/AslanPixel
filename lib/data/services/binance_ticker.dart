/// Parsed Binance 24-hour ticker statistics.
class BinanceTicker {
  const BinanceTicker({
    required this.symbol,
    required this.lastPrice,
    required this.priceChangePercent,
    required this.highPrice,
    required this.lowPrice,
    required this.volume,
    required this.quoteVolume,
  });

  final String symbol; // e.g. 'BTCUSDT'
  final double lastPrice; // e.g. 67500.0
  final double priceChangePercent; // e.g. 2.34
  final double highPrice;
  final double lowPrice;
  final double volume; // base asset volume
  final double quoteVolume; // quote asset volume (USDT)

  /// Display symbol: 'BTCUSDT' -> 'BTC/USDT'
  String get displaySymbol {
    if (symbol.endsWith('USDT')) {
      return '${symbol.substring(0, symbol.length - 4)}/USDT';
    }
    if (symbol.endsWith('BTC')) {
      return '${symbol.substring(0, symbol.length - 3)}/BTC';
    }
    return symbol;
  }

  /// True if price change is non-negative.
  bool get isPositive => priceChangePercent >= 0;

  /// Formatted price string with appropriate decimals.
  String get formattedPrice {
    if (lastPrice >= 1000) return lastPrice.toStringAsFixed(2);
    if (lastPrice >= 1) return lastPrice.toStringAsFixed(2);
    return lastPrice.toStringAsFixed(6);
  }

  /// Formatted volume string (abbreviated).
  String get formattedVolume {
    if (quoteVolume >= 1e9) {
      return '${(quoteVolume / 1e9).toStringAsFixed(1)}B';
    }
    if (quoteVolume >= 1e6) {
      return '${(quoteVolume / 1e6).toStringAsFixed(1)}M';
    }
    if (quoteVolume >= 1e3) {
      return '${(quoteVolume / 1e3).toStringAsFixed(1)}K';
    }
    return quoteVolume.toStringAsFixed(0);
  }

  factory BinanceTicker.fromJson(Map<String, dynamic> json) {
    return BinanceTicker(
      symbol: json['symbol'] as String? ?? '',
      lastPrice: double.tryParse(json['lastPrice'] as String? ?? '') ?? 0,
      priceChangePercent:
          double.tryParse(json['priceChangePercent'] as String? ?? '') ?? 0,
      highPrice: double.tryParse(json['highPrice'] as String? ?? '') ?? 0,
      lowPrice: double.tryParse(json['lowPrice'] as String? ?? '') ?? 0,
      volume: double.tryParse(json['volume'] as String? ?? '') ?? 0,
      quoteVolume: double.tryParse(json['quoteVolume'] as String? ?? '') ?? 0,
    );
  }

  Map<String, dynamic> toJson() => {
        'symbol': symbol,
        'lastPrice': lastPrice.toString(),
        'priceChangePercent': priceChangePercent.toString(),
        'highPrice': highPrice.toString(),
        'lowPrice': lowPrice.toString(),
        'volume': volume.toString(),
        'quoteVolume': quoteVolume.toString(),
      };
}
