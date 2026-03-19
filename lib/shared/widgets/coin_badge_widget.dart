import 'package:flutter/material.dart';
import 'package:aslan_pixel/shared/widgets/pixel_icon.dart';

/// Compact coin amount display — gold icon + bold amount text.
class CoinBadgeWidget extends StatelessWidget {
  const CoinBadgeWidget({
    super.key,
    required this.amount,
    this.fontSize = 13,
  });

  final int amount;
  final double fontSize;

  static const Color _gold = Color(0xFFf5c518);

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        PixelIcon(
          PixelIcon.coin,
          size: fontSize + 2,
          color: _gold,
        ),
        const SizedBox(width: 3),
        Text(
          '$amount',
          style: TextStyle(
            color: _gold,
            fontSize: fontSize,
            fontWeight: FontWeight.w700,
          ),
        ),
      ],
    );
  }
}
