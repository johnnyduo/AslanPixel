import 'package:flutter/material.dart';

// ── FloatingRewardText ─────────────────────────────────────────────────────────

/// Shows a "+{amount} 🪙" text that flies up 60 px and fades out.
///
/// Call [FloatingRewardText.show] anywhere you have a [BuildContext]:
/// ```dart
/// FloatingRewardText.show(context, 250);
/// // or with a specific position:
/// FloatingRewardText.show(context, 250, position: Offset(200, 400));
/// ```
class FloatingRewardText extends StatefulWidget {
  const FloatingRewardText._({
    required this.amount,
    required this.startOffset,
    required this.onDone,
  });

  final int amount;
  final Offset startOffset;
  final VoidCallback onDone;

  /// Inserts a floating reward label into the nearest [Overlay].
  ///
  /// [position] is in global coordinates. When omitted the centre of the
  /// screen is used.
  static void show(
    BuildContext context,
    int amount, {
    Offset? position,
  }) {
    final overlay = Overlay.of(context);
    final size = MediaQuery.sizeOf(context);
    final startOffset = position ?? Offset(size.width / 2, size.height / 2);

    late OverlayEntry entry;
    entry = OverlayEntry(
      builder: (_) => FloatingRewardText._(
        amount: amount,
        startOffset: startOffset,
        onDone: () => entry.remove(),
      ),
    );
    overlay.insert(entry);
  }

  @override
  State<FloatingRewardText> createState() => _FloatingRewardTextState();
}

class _FloatingRewardTextState extends State<FloatingRewardText>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;
  late final Animation<double> _dy;    // 0.0 → -60 px
  late final Animation<double> _alpha; // 1.0 → 0.0

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    );

    _dy = Tween<double>(begin: 0.0, end: -60.0).animate(
      CurvedAnimation(parent: _ctrl, curve: Curves.easeOut),
    );

    _alpha = Tween<double>(begin: 1.0, end: 0.0).animate(
      CurvedAnimation(
        parent: _ctrl,
        curve: const Interval(0.4, 1.0, curve: Curves.easeIn),
      ),
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
    return AnimatedBuilder(
      animation: _ctrl,
      builder: (context, _) {
        return Positioned(
          left: widget.startOffset.dx - 40,
          top: widget.startOffset.dy + _dy.value,
          child: IgnorePointer(
            child: Opacity(
              opacity: _alpha.value.clamp(0.0, 1.0),
              child: Text(
                '+${widget.amount} 🪙',
                style: const TextStyle(
                  color: Color(0xFFF5C518), // gold
                  fontSize: 18,
                  fontWeight: FontWeight.w800,
                  shadows: [
                    Shadow(
                      color: Color(0x99000000),
                      blurRadius: 6,
                      offset: Offset(1, 1),
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}
