import 'package:flutter/material.dart';

/// A card representing a prediction market event.
/// Used in the Home dashboard's Prediction section.
class PredictionCard extends StatelessWidget {
  const PredictionCard({
    super.key,
    required this.symbol,
    required this.questionTh,
    required this.coinCost,
    this.onJoin,
  });

  final String symbol;
  final String questionTh;
  final int coinCost;
  final VoidCallback? onJoin;

  static const Color _surface = Color(0xFF0F2040);
  static const Color _neonGreen = Color(0xFF00F5A0);
  static const Color _gold = Color(0xFFF5C518);
  static const Color _textWhite = Color(0xFFE8F4F8);

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: _surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: _neonGreen.withValues(alpha: 0.18),
          width: 1,
        ),
      ),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header row: symbol + coin cost badge
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              // Symbol chip
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: _neonGreen.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  symbol,
                  style: const TextStyle(
                    color: _neonGreen,
                    fontWeight: FontWeight.bold,
                    fontSize: 13,
                    letterSpacing: 0.5,
                  ),
                ),
              ),
              // Coin cost badge
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.monetization_on, color: _gold, size: 16),
                  const SizedBox(width: 4),
                  Text(
                    '$coinCost',
                    style: const TextStyle(
                      color: _gold,
                      fontWeight: FontWeight.bold,
                      fontSize: 13,
                    ),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 10),
          // Question text
          Text(
            questionTh,
            style: const TextStyle(
              color: _textWhite,
              fontSize: 14,
              height: 1.45,
            ),
          ),
          const SizedBox(height: 12),
          // Footer row: countdown + join button
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.schedule,
                    size: 14,
                    color: _textWhite.withValues(alpha: 0.45),
                  ),
                  const SizedBox(width: 4),
                  Text(
                    'เหลือ 2 วัน',
                    style: TextStyle(
                      color: _textWhite.withValues(alpha: 0.45),
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
              OutlinedButton(
                onPressed: onJoin,
                style: OutlinedButton.styleFrom(
                  foregroundColor: _neonGreen,
                  side: const BorderSide(color: _neonGreen, width: 1.2),
                  padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 6),
                  minimumSize: Size.zero,
                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                child: const Text(
                  'เข้าร่วม',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    letterSpacing: 0.3,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
