import 'dart:math' as math;

import 'package:flutter/material.dart';

// ── Confetti colours ─────────────────────────────────────────────────────────
const _kConfettiColors = [
  Color(0xFF00F5A0), // neon green
  Color(0xFFF5C518), // gold
  Color(0xFF4FC3F7), // cyan
  Color(0xFF7B2FFF), // cyber purple
  Color(0xFFFF6B9D), // pink accent
];

// ── ConfettiOverlay ───────────────────────────────────────────────────────────

/// A self-removing confetti burst overlay.
///
/// ```dart
/// ConfettiOverlay.burst(context);
/// ```
///
/// 30 small squares/circles fly outward from the centre of the screen over
/// 1.5 s, then the overlay removes itself automatically.
class ConfettiOverlay extends StatefulWidget {
  const ConfettiOverlay._({required this.onDone});

  final VoidCallback onDone;

  /// Shows a confetti burst as an [OverlayEntry] anchored to the screen centre.
  static void burst(BuildContext context) {
    final overlay = Overlay.of(context);
    late OverlayEntry entry;
    entry = OverlayEntry(
      builder: (_) => ConfettiOverlay._(onDone: () => entry.remove()),
    );
    overlay.insert(entry);
  }

  @override
  State<ConfettiOverlay> createState() => _ConfettiOverlayState();
}

class _ConfettiOverlayState extends State<ConfettiOverlay>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    );
    _ctrl.forward().then((_) {
      if (mounted) widget.onDone();
    });
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.sizeOf(context);
    final origin = Offset(size.width / 2, size.height / 2);

    return IgnorePointer(
      child: AnimatedBuilder(
        animation: _ctrl,
        builder: (context, _) {
          return CustomPaint(
            size: size,
            painter: _ConfettiPainter(
              progress: _ctrl.value,
              origin: origin,
            ),
          );
        },
      ),
    );
  }
}

// ── _ConfettiPainter ──────────────────────────────────────────────────────────

/// Renders 30 confetti particles from [origin].
///
/// Each particle alternates between square and circle, has a random angle,
/// speed, size, and rotation.
class _ConfettiPainter extends CustomPainter {
  _ConfettiPainter({
    required this.progress,
    required this.origin,
  });

  final double progress;
  final Offset origin;

  static const int _count = 30;

  // Pre-seeded random data so every rebuild uses the same particle layout.
  static final _rng = math.Random(7);
  static final List<double> _angles =
      List.generate(_count, (_) => _rng.nextDouble() * 2 * math.pi);
  static final List<double> _speeds =
      List.generate(_count, (_) => 80.0 + _rng.nextDouble() * 160.0);
  static final List<double> _sizes =
      List.generate(_count, (_) => 4.0 + _rng.nextDouble() * 7.0);
  static final List<bool> _isSquare =
      List.generate(_count, (_) => _rng.nextBool());
  static final List<double> _rotations =
      List.generate(_count, (_) => _rng.nextDouble() * 2 * math.pi);
  static final List<int> _colorIndices =
      List.generate(_count, (_) => _rng.nextInt(_kConfettiColors.length));

  @override
  void paint(Canvas canvas, Size size) {
    if (progress <= 0.0 || progress >= 1.0) return;

    // Ease-out distance, ease-in fade.
    final dist = Curves.easeOut.transform(progress);
    final alpha = Curves.easeIn.transform(1.0 - progress);

    for (var i = 0; i < _count; i++) {
      final dx = math.cos(_angles[i]) * _speeds[i] * dist;
      // Add slight gravity drop.
      final dy = math.sin(_angles[i]) * _speeds[i] * dist +
          (80 * progress * progress);
      final center = origin + Offset(dx, dy);
      final halfSize = _sizes[i] / 2;
      final color =
          _kConfettiColors[_colorIndices[i]].withValues(alpha: alpha);

      final paint = Paint()..color = color;

      if (_isSquare[i]) {
        final angle = _rotations[i] + progress * 3 * math.pi;
        canvas.save();
        canvas.translate(center.dx, center.dy);
        canvas.rotate(angle);
        canvas.drawRect(
          Rect.fromCenter(
              center: Offset.zero, width: _sizes[i], height: _sizes[i]),
          paint,
        );
        canvas.restore();
      } else {
        canvas.drawCircle(center, halfSize, paint);
      }
    }
  }

  @override
  bool shouldRepaint(_ConfettiPainter oldDelegate) =>
      oldDelegate.progress != progress;
}
