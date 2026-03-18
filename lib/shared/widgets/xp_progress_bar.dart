import 'dart:math' as math;

import 'package:flutter/material.dart';

// ── Palette constants ────────────────────────────────────────────────────────
const _kGold = Color(0xFFF5C518);
const _kNeonGreen = Color(0xFF00F5A0);
const _kNavy = Color(0xFF0A1628);
const _kTextSecondary = Color(0xFF6B8AAB);
const _kCyan = Color(0xFF4FC3F7);

// ── XpProgressBar ─────────────────────────────────────────────────────────────

/// Animated XP progress bar.
///
/// Pass [currentXp] and [maxXp] for the current level. When [currentXp]
/// crosses [maxXp] a level-up burst animation fires automatically.
///
/// ```dart
/// XpProgressBar(
///   level: 5,
///   currentXp: 840,
///   maxXp: 1000,
/// )
/// ```
class XpProgressBar extends StatefulWidget {
  const XpProgressBar({
    super.key,
    required this.level,
    required this.currentXp,
    required this.maxXp,
  });

  /// Current player level.
  final int level;

  /// XP accumulated within the current level.
  final int currentXp;

  /// XP required to reach the next level.
  final int maxXp;

  @override
  State<XpProgressBar> createState() => _XpProgressBarState();
}

class _XpProgressBarState extends State<XpProgressBar>
    with TickerProviderStateMixin {
  // Fill progress: 0.0 → 1.0.
  late final AnimationController _fillCtrl;
  late Animation<double> _fillAnim;

  // Level-up burst (bar turns gold + overshoots to 1.2).
  late final AnimationController _levelUpCtrl;
  late final Animation<double> _levelUpAlpha;
  late final Animation<double> _burstScale;

  // Particle system controller.
  late final AnimationController _particleCtrl;

  bool _isLevelUp = false;
  int _displayLevel = 1;
  double _targetProgress = 0.0;

  @override
  void initState() {
    super.initState();
    _displayLevel = widget.level;
    _targetProgress = _safeProgress(widget.currentXp, widget.maxXp);

    _fillCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 700),
    );
    _fillAnim = Tween<double>(begin: 0.0, end: _targetProgress).animate(
      CurvedAnimation(parent: _fillCtrl, curve: Curves.easeOut),
    );
    _fillCtrl.forward();

    _levelUpCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    );
    _levelUpAlpha = TweenSequence<double>([
      TweenSequenceItem(tween: Tween(begin: 0.0, end: 1.0), weight: 20),
      TweenSequenceItem(tween: Tween(begin: 1.0, end: 1.0), weight: 40),
      TweenSequenceItem(tween: Tween(begin: 1.0, end: 0.0), weight: 40),
    ]).animate(CurvedAnimation(parent: _levelUpCtrl, curve: Curves.easeInOut));

    _burstScale = TweenSequence<double>([
      TweenSequenceItem(tween: Tween(begin: 1.0, end: 1.2), weight: 30),
      TweenSequenceItem(tween: Tween(begin: 1.2, end: 0.0), weight: 70),
    ]).animate(CurvedAnimation(parent: _levelUpCtrl, curve: Curves.easeInOut));

    _particleCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    );
  }

  @override
  void didUpdateWidget(XpProgressBar oldWidget) {
    super.didUpdateWidget(oldWidget);
    final newProgress = _safeProgress(widget.currentXp, widget.maxXp);
    final leveledUp = widget.level > oldWidget.level;

    if (leveledUp) {
      _triggerLevelUp(newProgress);
    } else if (newProgress != _targetProgress) {
      _animateTo(newProgress);
    }
  }

  double _safeProgress(int xp, int max) {
    if (max <= 0) return 0.0;
    return (xp / max).clamp(0.0, 1.0);
  }

  void _animateTo(double target) {
    final from = _fillAnim.value;
    _targetProgress = target;
    _fillCtrl.reset();
    _fillAnim = Tween<double>(begin: from, end: target).animate(
      CurvedAnimation(parent: _fillCtrl, curve: Curves.easeOut),
    );
    _fillCtrl.forward();
  }

  void _triggerLevelUp(double resetProgress) {
    setState(() {
      _isLevelUp = true;
      _displayLevel = widget.level;
    });
    // First overshoot to 1.0 then reset.
    final from = _fillAnim.value;
    _fillCtrl.reset();
    _fillAnim = Tween<double>(begin: from, end: 1.0).animate(
      CurvedAnimation(parent: _fillCtrl, curve: Curves.easeOut),
    );
    _fillCtrl.forward().then((_) {
      if (!mounted) return;
      _levelUpCtrl.forward().then((_) {
        if (!mounted) return;
        setState(() => _isLevelUp = false);
        _levelUpCtrl.reset();
        _animateTo(resetProgress);
      });
      _particleCtrl
        ..reset()
        ..forward();
    });
  }

  @override
  void dispose() {
    _fillCtrl.dispose();
    _levelUpCtrl.dispose();
    _particleCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final nextLevel = _displayLevel + 1;
    final remaining = (widget.maxXp - widget.currentXp).clamp(0, widget.maxXp);

    return LayoutBuilder(
      builder: (context, constraints) {
        final barWidth = constraints.maxWidth - 32; // 16 padding each side

        return Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ── Labels row ──────────────────────────────────────────────
              Row(
                children: [
                  // Level badge
                  _LevelBadge(level: _displayLevel),
                  const SizedBox(width: 10),
                  Expanded(
                    child: AnimatedBuilder(
                      animation: _fillCtrl,
                      builder: (context, _) {
                        final pct = (_fillAnim.value * 100).toStringAsFixed(0);
                        return Text(
                          '$pct% สู่ Lv $nextLevel',
                          style: const TextStyle(
                            color: _kTextSecondary,
                            fontSize: 11,
                          ),
                        );
                      },
                    ),
                  ),
                  Text(
                    '$remaining XP',
                    style: TextStyle(
                      color: _kTextSecondary.withValues(alpha: 0.7),
                      fontSize: 11,
                    ),
                  ),
                  const SizedBox(width: 6),
                  Text(
                    'Lv $nextLevel',
                    style: const TextStyle(
                      color: _kTextSecondary,
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              // ── Progress bar track ──────────────────────────────────────
              Stack(
                clipBehavior: Clip.none,
                children: [
                  // Track
                  Container(
                    height: 10,
                    width: barWidth,
                    decoration: BoxDecoration(
                      color: _kNavy,
                      borderRadius: BorderRadius.circular(5),
                      border: Border.all(
                          color: _kNeonGreen.withValues(alpha: 0.1)),
                    ),
                  ),
                  // Animated fill
                  AnimatedBuilder(
                    animation: Listenable.merge(
                        [_fillAnim, _levelUpAlpha, _burstScale]),
                    builder: (context, _) {
                      final fillColor = _isLevelUp
                          ? Color.lerp(_kNeonGreen, _kGold,
                              _levelUpAlpha.value)!
                          : _kNeonGreen;
                      final fillWidth =
                          (_fillAnim.value * barWidth).clamp(0.0, barWidth);
                      return Container(
                        height: 10,
                        width: fillWidth,
                        decoration: BoxDecoration(
                          color: fillColor,
                          borderRadius: BorderRadius.circular(5),
                          boxShadow: [
                            BoxShadow(
                              color: fillColor.withValues(alpha: 0.55),
                              blurRadius: 8,
                            ),
                          ],
                        ),
                      );
                    },
                  ),
                  // Particle burst (only during level up)
                  if (_isLevelUp)
                    AnimatedBuilder(
                      animation: _particleCtrl,
                      builder: (context, _) {
                        return CustomPaint(
                          size: Size(barWidth, 10),
                          painter: _ParticlePainter(
                            progress: _particleCtrl.value,
                            origin: Offset(barWidth / 2, 5),
                          ),
                        );
                      },
                    ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }
}

// ── _LevelBadge ───────────────────────────────────────────────────────────────

class _LevelBadge extends StatelessWidget {
  const _LevelBadge({required this.level});

  final int level;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 38,
      height: 38,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: _kGold.withValues(alpha: 0.15),
        border: Border.all(color: _kGold, width: 1.5),
        boxShadow: [
          BoxShadow(
            color: _kGold.withValues(alpha: 0.25),
            blurRadius: 8,
          ),
        ],
      ),
      alignment: Alignment.center,
      child: Text(
        'Lv\n$level',
        textAlign: TextAlign.center,
        style: const TextStyle(
          color: _kGold,
          fontSize: 9,
          fontWeight: FontWeight.w800,
          height: 1.2,
        ),
      ),
    );
  }
}

// ── _ParticlePainter ──────────────────────────────────────────────────────────

/// Shoots 14 small dots outward from [origin] with random angles.
class _ParticlePainter extends CustomPainter {
  _ParticlePainter({
    required this.progress,
    required this.origin,
  });

  final double progress;
  final Offset origin;

  static final _rng = math.Random(42);
  static final List<double> _angles = List.generate(
    14,
    (i) => _rng.nextDouble() * 2 * math.pi,
  );
  static final List<double> _speeds = List.generate(
    14,
    (i) => 18.0 + _rng.nextDouble() * 28.0,
  );
  static final List<Color> _colors = [
    _kNeonGreen,
    _kGold,
    _kCyan,
    const Color(0xFF7B2FFF),
  ];

  @override
  void paint(Canvas canvas, Size size) {
    if (progress <= 0.0 || progress >= 1.0) return;

    final opacity = (1.0 - progress).clamp(0.0, 1.0);

    for (var i = 0; i < _angles.length; i++) {
      final dist = _speeds[i] * progress;
      final dx = math.cos(_angles[i]) * dist;
      final dy = math.sin(_angles[i]) * dist;
      final center = origin + Offset(dx, dy);
      final radius = (3.0 * (1.0 - progress)).clamp(0.5, 3.0);
      final color = _colors[i % _colors.length].withValues(alpha: opacity);
      canvas.drawCircle(center, radius, Paint()..color = color);
    }
  }

  @override
  bool shouldRepaint(_ParticlePainter oldDelegate) =>
      oldDelegate.progress != progress;
}
