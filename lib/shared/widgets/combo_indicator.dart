import 'package:flutter/material.dart';

// ── Palette ──────────────────────────────────────────────────────────────────
const _kGold = Color(0xFFf5c518);
const _kSurfaceElevated = Color(0xFF1c2a4e);
const _kBorder = Color(0xFF1e3050);

/// Persistent combo multiplier indicator shown on the home screen.
///
/// Displays the current streak multiplier with a fire emoji and pulsing glow
/// when the multiplier is greater than 1.0.
///
/// Hidden when [streakDays] is 0.
///
/// ```dart
/// ComboIndicator(streakDays: 5, multiplier: 1.5)
/// ```
class ComboIndicator extends StatefulWidget {
  const ComboIndicator({
    super.key,
    required this.streakDays,
    required this.multiplier,
  });

  final int streakDays;
  final double multiplier;

  @override
  State<ComboIndicator> createState() => _ComboIndicatorState();
}

class _ComboIndicatorState extends State<ComboIndicator>
    with SingleTickerProviderStateMixin {
  late final AnimationController _glowController;
  late final Animation<double> _glowAnimation;

  @override
  void initState() {
    super.initState();
    _glowController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1400),
    );
    _glowAnimation = Tween<double>(begin: 0.3, end: 0.7).animate(
      CurvedAnimation(parent: _glowController, curve: Curves.easeInOut),
    );
    if (widget.multiplier > 1.0) {
      _glowController.repeat(reverse: true);
    }
  }

  @override
  void didUpdateWidget(ComboIndicator oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.multiplier > 1.0 && !_glowController.isAnimating) {
      _glowController.repeat(reverse: true);
    } else if (widget.multiplier <= 1.0 && _glowController.isAnimating) {
      _glowController.stop();
    }
  }

  @override
  void dispose() {
    _glowController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (widget.streakDays <= 0) return const SizedBox.shrink();

    final multiplierText = 'x${widget.multiplier.toStringAsFixed(1)}';
    final hasBoost = widget.multiplier > 1.0;

    return AnimatedBuilder(
      animation: _glowAnimation,
      builder: (context, child) {
        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
          decoration: BoxDecoration(
            color: _kSurfaceElevated,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: hasBoost
                  ? _kGold.withValues(alpha: _glowAnimation.value)
                  : _kBorder,
            ),
            boxShadow: hasBoost
                ? [
                    BoxShadow(
                      color: _kGold.withValues(alpha: _glowAnimation.value * 0.4),
                      blurRadius: 8,
                      spreadRadius: 1,
                    ),
                  ]
                : null,
          ),
          child: child,
        );
      },
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Text('\u{1F525}', style: TextStyle(fontSize: 14)),
          const SizedBox(width: 4),
          Text(
            multiplierText,
            style: const TextStyle(
              color: _kGold,
              fontSize: 13,
              fontWeight: FontWeight.w800,
              fontFeatures: [FontFeature.tabularFigures()],
            ),
          ),
        ],
      ),
    );
  }
}
