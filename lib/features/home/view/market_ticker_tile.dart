import 'package:flutter/material.dart';

/// A single market ticker row for the Home dashboard's Market Snapshot section.
class MarketTickerTile extends StatelessWidget {
  const MarketTickerTile({
    super.key,
    required this.symbol,
    required this.changePercent,
    this.price,
  });

  final String symbol;
  final double changePercent;
  final String? price;

  static const Color _neonGreen = Color(0xFF00F5A0);
  static const Color _red = Color(0xFFFF4757);
  static const Color _textWhite = Color(0xFFE8F4F8);
  static const Color _surface = Color(0xFF0F2040);

  Color get _changeColor => changePercent >= 0 ? _neonGreen : _red;

  IconData get _arrowIcon =>
      changePercent >= 0 ? Icons.arrow_upward_rounded : Icons.arrow_downward_rounded;

  String get _changeText {
    final sign = changePercent >= 0 ? '+' : '';
    return '$sign${changePercent.toStringAsFixed(1)}%';
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: _surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: _changeColor.withValues(alpha: 0.15),
          width: 1,
        ),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        children: [
          // Symbol
          Expanded(
            child: Text(
              symbol,
              style: const TextStyle(
                color: _textWhite,
                fontWeight: FontWeight.bold,
                fontSize: 14,
                letterSpacing: 0.4,
              ),
            ),
          ),
          // Price (if provided)
          if (price != null) ...[
            Text(
              price!,
              style: TextStyle(
                color: _textWhite.withValues(alpha: 0.5),
                fontSize: 13,
              ),
            ),
            const SizedBox(width: 12),
          ],
          // Change percent + icon
          Icon(_arrowIcon, color: _changeColor, size: 15),
          const SizedBox(width: 3),
          Text(
            _changeText,
            style: TextStyle(
              color: _changeColor,
              fontWeight: FontWeight.w600,
              fontSize: 14,
            ),
          ),
        ],
      ),
    );
  }
}
