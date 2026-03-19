import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

import 'package:aslan_pixel/data/services/binance_ticker.dart';

/// Fetches live crypto market data from Binance public API.
/// No API key required for public endpoints.
class BinanceService {
  BinanceService({http.Client? client}) : _client = client ?? http.Client();

  final http.Client _client;
  static const _baseUrl = 'https://api.binance.com/api/v3';

  /// Cached data with TTL
  final Map<String, _CacheEntry> _cache = {};
  static const _cacheTtl = Duration(seconds: 30);

  /// Fetches 24-hour ticker data for multiple symbols.
  /// Returns a list of [BinanceTicker] sorted by symbol name.
  Future<List<BinanceTicker>> get24hrTickers(List<String> symbols) async {
    final cacheKey = 'tickers_${symbols.join(',')}';
    final cached = _getCache(cacheKey);
    if (cached != null) return cached as List<BinanceTicker>;

    try {
      // Binance API: GET /ticker/24hr for multiple symbols
      final symbolsParam = jsonEncode(symbols);
      final uri = Uri.parse('$_baseUrl/ticker/24hr?symbols=$symbolsParam');
      final response =
          await _client.get(uri).timeout(const Duration(seconds: 8));

      if (response.statusCode != 200) {
        debugPrint('[Binance] HTTP ${response.statusCode}: ${response.body}');
        return [];
      }

      final List<dynamic> data = jsonDecode(response.body);
      final tickers = data
          .map((e) => BinanceTicker.fromJson(e as Map<String, dynamic>))
          .toList()
        ..sort((a, b) => a.symbol.compareTo(b.symbol));

      _putCache(cacheKey, tickers);
      return tickers;
    } catch (e) {
      debugPrint('[Binance] get24hrTickers error: $e');
      return [];
    }
  }

  /// Fetches kline (candlestick) data for sparkline display.
  /// Returns list of closing prices.
  Future<List<double>> getKlines({
    required String symbol,
    String interval = '1h',
    int limit = 24,
  }) async {
    final cacheKey = 'klines_${symbol}_${interval}_$limit';
    final cached = _getCache(cacheKey);
    if (cached != null) return cached as List<double>;

    try {
      final uri = Uri.parse(
        '$_baseUrl/klines?symbol=$symbol&interval=$interval&limit=$limit',
      );
      final response =
          await _client.get(uri).timeout(const Duration(seconds: 8));

      if (response.statusCode != 200) return [];

      final List<dynamic> data = jsonDecode(response.body);
      // Kline format: [openTime, open, high, low, close, volume, ...]
      // Index 4 = close price
      final closes =
          data.map((k) => double.tryParse(k[4] as String) ?? 0.0).toList();

      _putCache(cacheKey, closes);
      return closes;
    } catch (e) {
      debugPrint('[Binance] getKlines error: $e');
      return [];
    }
  }

  /// Fetches current price for a single symbol.
  Future<double?> getPrice(String symbol) async {
    try {
      final uri = Uri.parse('$_baseUrl/ticker/price?symbol=$symbol');
      final response =
          await _client.get(uri).timeout(const Duration(seconds: 5));
      if (response.statusCode != 200) return null;
      final data = jsonDecode(response.body) as Map<String, dynamic>;
      return double.tryParse(data['price'] as String? ?? '');
    } catch (e) {
      debugPrint('[Binance] getPrice error: $e');
      return null;
    }
  }

  // Cache helpers
  dynamic _getCache(String key) {
    final entry = _cache[key];
    if (entry == null || DateTime.now().isAfter(entry.expiresAt)) {
      _cache.remove(key);
      return null;
    }
    return entry.data;
  }

  void _putCache(String key, dynamic data) {
    _cache[key] =
        _CacheEntry(data: data, expiresAt: DateTime.now().add(_cacheTtl));
  }

  void dispose() => _client.close();
}

class _CacheEntry {
  const _CacheEntry({required this.data, required this.expiresAt});
  final dynamic data;
  final DateTime expiresAt;
}
