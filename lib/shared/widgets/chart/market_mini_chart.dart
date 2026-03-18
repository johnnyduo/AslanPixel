import 'package:flutter/material.dart';

import 'package:aslan_pixel/shared/widgets/chart/animated_sparkline.dart';

/// Compact market row showing a symbol, change percentage, and a sparkline.
///
/// Designed to be placed inside a card or list tile — transparent background.
///
/// ```dart
/// MarketMiniChart(
///   symbol: 'PTT',
///   changePercent: 1.34,
///   history: [100, 101, 99, 103, 105],
/// )
/// ```
class MarketMiniChart extends StatelessWidget {
  const MarketMiniChart({
    super.key,
    required this.symbol,
    required this.changePercent,
    required this.history,
  });

  final String symbol;
  final double changePercent;
  final List<double> history;

  static const _profit = Color(0xFF00f5a0); // neon green
  static const _loss = Color(0xFFff4d4f);
  static const _textPrimary = Color(0xFFe8f4ff);
  // ignore: unused_field
  static const _textSecondary = Color(0xFF6b8aab);

  @override
  Widget build(BuildContext context) {
    final isPositive = changePercent >= 0;
    final changeColor = isPositive ? _profit : _loss;
    final sign = isPositive ? '+' : '';
    final changeText = '$sign${changePercent.toStringAsFixed(2)}%';

    return SizedBox(
      height: 56,
      child: Row(
        children: [
          // ── Symbol + change ───────────────────────────────────────────────
          Expanded(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  symbol,
                  style: const TextStyle(
                    color: _textPrimary,
                    fontSize: 13,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 0.3,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 2),
                Text(
                  changeText,
                  style: TextStyle(
                    color: changeColor,
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
          // ── Sparkline ─────────────────────────────────────────────────────
          SizedBox(
            width: 80,
            child: AnimatedSparkline(
              values: history,
              lineColor: changeColor,
              height: 32,
              strokeWidth: 1.5,
            ),
          ),
        ],
      ),
    );
  }
}
