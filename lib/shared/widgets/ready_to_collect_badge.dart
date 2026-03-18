import 'package:flutter/material.dart';

// ── ReadyToCollectBadge ────────────────────────────────────────────────────────

/// A pulsing gold badge shown when one or more agent tasks are complete.
///
/// Shows "🎁 พร้อมเก็บ!" for a single reward, or "🎁 {count} รางวัล" for
/// multiple. Tapping fires [onTap].
///
/// Designed to be placed inside a [Stack] / [Positioned] overlay on the
/// game area:
///
/// ```dart
/// Positioned(
///   top: 16,
///   left: 0,
///   right: 0,
///   child: Center(
///     child: ReadyToCollectBadge(count: 3, onTap: _settle),
///   ),
/// )
/// ```
class ReadyToCollectBadge extends StatefulWidget {
  const ReadyToCollectBadge({
    super.key,
    required this.count,
    required this.onTap,
  });

  /// Number of completed tasks ready to collect.
  final int count;

  /// Called when the badge is tapped (trigger task settlement + reward popup).
  final VoidCallback onTap;

  @override
  State<ReadyToCollectBadge> createState() => _ReadyToCollectBadgeState();
}

class _ReadyToCollectBadgeState extends State<ReadyToCollectBadge>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;
  late final Animation<double> _scale;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 700),
    )..repeat(reverse: true);

    _scale = Tween<double>(begin: 1.0, end: 1.2).animate(
      CurvedAnimation(parent: _ctrl, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  String get _label {
    if (widget.count <= 1) return '🎁 พร้อมเก็บ!';
    return '🎁 ${widget.count} รางวัล';
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: widget.onTap,
      child: AnimatedBuilder(
        animation: _scale,
        builder: (context, child) {
          return Transform.scale(
            scale: _scale.value,
            child: child,
          );
        },
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [Color(0xFFF5C518), Color(0xFFFFD700)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(30),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFFF5C518).withValues(alpha: 0.6),
                blurRadius: 16,
                spreadRadius: 2,
              ),
            ],
          ),
          child: Text(
            _label,
            style: const TextStyle(
              color: Color(0xFF0A1628),
              fontSize: 14,
              fontWeight: FontWeight.w800,
              letterSpacing: 0.3,
            ),
          ),
        ),
      ),
    );
  }
}
