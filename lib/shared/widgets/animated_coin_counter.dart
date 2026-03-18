import 'package:flutter/material.dart';

/// Animated coin counter that smoothly transitions from [fromAmount] to [toAmount].
///
/// Uses TweenAnimationBuilder for smooth number animation over [duration].
/// Renders with a gold coin icon prefix and neon-green text.
class AnimatedCoinCounter extends StatelessWidget {
  const AnimatedCoinCounter({
    super.key,
    required this.toAmount,
    this.fromAmount = 0,
    this.duration = const Duration(milliseconds: 800),
    this.fontSize = 16,
    this.showIcon = true,
  });

  final int toAmount;
  final int fromAmount;
  final Duration duration;
  final double fontSize;
  final bool showIcon;

  static const Color _gold = Color(0xFFF5C518);

  @override
  Widget build(BuildContext context) {
    return TweenAnimationBuilder<double>(
      tween: Tween<double>(
        begin: fromAmount.toDouble(),
        end: toAmount.toDouble(),
      ),
      duration: duration,
      curve: Curves.easeOut,
      builder: (context, value, _) {
        return Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (showIcon) ...[
              Icon(
                Icons.monetization_on_rounded,
                color: _gold,
                size: fontSize + 2,
              ),
              const SizedBox(width: 4),
            ],
            Text(
              value.round().toString(),
              style: TextStyle(
                color: _gold,
                fontSize: fontSize,
                fontWeight: FontWeight.w700,
                fontFeatures: const [FontFeature.tabularFigures()],
              ),
            ),
          ],
        );
      },
    );
  }
}
