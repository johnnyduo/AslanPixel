import 'dart:math' as math;

import 'package:flutter/material.dart';

import 'package:aslan_pixel/shared/widgets/animated_coin_counter.dart';
import 'package:aslan_pixel/shared/widgets/pixel_icon.dart';

// ── Palette ──────────────────────────────────────────────────────────────────
const _kNavy = Color(0xFF0a1628);
const _kSurface = Color(0xFF162040);
const _kSurfaceElevated = Color(0xFF1c2a4e);
const _kBorder = Color(0xFF1e3050);
const _kGold = Color(0xFFf5c518);
const _kNeonGreen = Color(0xFF00f5a0);
const _kTextPrimary = Color(0xFFe8f4ff);
const _kTextSecondary = Color(0xFFa8c4e0);
const _kXpBlue = Color(0xFF4fc3f7);

/// Full-screen reward overlay displayed when idle tasks complete.
///
/// Features:
/// - Animated scale-in card with coin-rain backdrop.
/// - [AnimatedCoinCounter] counting up from 0.
/// - XP progress bar that fills in.
/// - Streak indicator banner for consecutive-day bonuses.
/// - "รับรางวัล!" dismiss button with scale-out.
///
/// Show via [showDialog]:
/// ```dart
/// showDialog(
///   context: context,
///   barrierDismissible: false,
///   barrierColor: Colors.black54,
///   builder: (_) => RewardPopup(
///     coins: 250,
///     xp: 120,
///     streakDays: 3,
///   ),
/// );
/// ```
class RewardPopup extends StatefulWidget {
  const RewardPopup({
    super.key,
    required this.coins,
    required this.xp,
    this.streakDays = 0,
  });

  final int coins;
  final int xp;

  /// Consecutive days the user has collected rewards.
  /// 0 means no streak; 3, 7, 10 are milestone days.
  final int streakDays;

  @override
  State<RewardPopup> createState() => _RewardPopupState();
}

class _RewardPopupState extends State<RewardPopup>
    with TickerProviderStateMixin {
  // ── Card scale-in / scale-out ────────────────────────────────────────────
  late final AnimationController _cardController;
  late final Animation<double> _cardScale;

  // ── Coin rain ────────────────────────────────────────────────────────────
  late final AnimationController _rainController;

  // ── XP bar fill ─────────────────────────────────────────────────────────
  late final AnimationController _xpController;
  late final Animation<double> _xpFill;

  // ── Dismiss scale-out ────────────────────────────────────────────────────
  bool _dismissing = false;

  static const int _coinCount = 10;
  late final List<_CoinDrop> _coins;
  final math.Random _rng = math.Random(42);

  @override
  void initState() {
    super.initState();

    // ── Generate coin positions ──────────────────────────────────────────
    _coins = List.generate(_coinCount, (i) {
      return _CoinDrop(
        x: _rng.nextDouble(),
        delay: _rng.nextDouble() * 0.6,
        size: 8.0 + _rng.nextDouble() * 8.0,
        wobble: (_rng.nextDouble() - 0.5) * 0.15,
      );
    });

    // ── Card scale-in ────────────────────────────────────────────────────
    _cardController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 450),
    );
    _cardScale = CurvedAnimation(
      parent: _cardController,
      curve: Curves.elasticOut,
    );
    _cardController.forward();

    // ── Coin rain (looping) ──────────────────────────────────────────────
    _rainController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2200),
    )..repeat();

    // ── XP bar ───────────────────────────────────────────────────────────
    _xpController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    );
    _xpFill = CurvedAnimation(parent: _xpController, curve: Curves.easeOut);
    Future.delayed(const Duration(milliseconds: 300), () {
      if (mounted) _xpController.forward();
    });
  }

  @override
  void dispose() {
    _cardController.dispose();
    _rainController.dispose();
    _xpController.dispose();
    super.dispose();
  }

  // ── Dismiss with scale-out ───────────────────────────────────────────────
  void _dismiss() {
    if (_dismissing) return;
    setState(() => _dismissing = true);
    _rainController.stop();
    _cardController.reverse().then((_) {
      if (mounted) Navigator.of(context).pop();
    });
  }

  // ── Streak label ─────────────────────────────────────────────────────────
  String _streakLabel() {
    if (widget.streakDays <= 0) return '';
    final bonus = ((widget.streakDays.clamp(0, 10) * 0.1) * 100).round();
    return '🔥 ${widget.streakDays} วันติดต่อกัน! +$bonus% โบนัส';
  }

  bool get _hasStreak => widget.streakDays > 0;

  bool get _isMilestone =>
      widget.streakDays == 3 ||
      widget.streakDays == 7 ||
      widget.streakDays == 10;

  @override
  Widget build(BuildContext context) {
    return Material(
      type: MaterialType.transparency,
      child: Stack(
        children: [
          // ── Coin rain backdrop ─────────────────────────────────────────
          Positioned.fill(
            child: IgnorePointer(
              child: AnimatedBuilder(
                animation: _rainController,
                builder: (context, _) {
                  return CustomPaint(
                    painter: _CoinRainPainter(
                      progress: _rainController.value,
                      coins: _coins,
                    ),
                  );
                },
              ),
            ),
          ),

          // ── Card ───────────────────────────────────────────────────────
          Center(
            child: ScaleTransition(
              scale: _cardScale,
              child: _RewardCard(
                coins: widget.coins,
                xp: widget.xp,
                streakLabel: _streakLabel(),
                hasStreak: _hasStreak,
                isMilestone: _isMilestone,
                xpFill: _xpFill,
                onClaim: _dismiss,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ── Internal card ─────────────────────────────────────────────────────────────

class _RewardCard extends StatelessWidget {
  const _RewardCard({
    required this.coins,
    required this.xp,
    required this.streakLabel,
    required this.hasStreak,
    required this.isMilestone,
    required this.xpFill,
    required this.onClaim,
  });

  final int coins;
  final int xp;
  final String streakLabel;
  final bool hasStreak;
  final bool isMilestone;
  final Animation<double> xpFill;
  final VoidCallback onClaim;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 28),
      padding: const EdgeInsets.fromLTRB(24, 28, 24, 24),
      decoration: BoxDecoration(
        color: _kSurface,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: isMilestone ? _kGold : _kBorder,
          width: isMilestone ? 2 : 1,
        ),
        boxShadow: [
          BoxShadow(
            color: _kGold.withValues(alpha: 0.18),
            blurRadius: 32,
            spreadRadius: 4,
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // ── Trophy icon ──────────────────────────────────────────────
          Container(
            width: 72,
            height: 72,
            decoration: BoxDecoration(
              color: _kGold.withValues(alpha: 0.12),
              shape: BoxShape.circle,
              border: Border.all(color: _kGold.withValues(alpha: 0.4), width: 2),
            ),
            child: const PixelIcon(
              PixelIcon.trophy,
              size: 40,
              color: _kGold,
            ),
          ),
          const SizedBox(height: 16),

          // ── Title ────────────────────────────────────────────────────
          const Text(
            'ภารกิจสำเร็จ!',
            style: TextStyle(
              color: _kTextPrimary,
              fontSize: 22,
              fontWeight: FontWeight.w800,
              letterSpacing: 0.3,
            ),
          ),
          const SizedBox(height: 4),
          const Text(
            'ตัวแทนของคุณกลับมาพร้อมรางวัล',
            style: TextStyle(color: _kTextSecondary, fontSize: 13),
          ),
          const SizedBox(height: 24),

          // ── Coin counter ─────────────────────────────────────────────
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
            decoration: BoxDecoration(
              color: _kSurfaceElevated,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: _kGold.withValues(alpha: 0.25)),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                AnimatedCoinCounter(
                  toAmount: coins,
                  fromAmount: 0,
                  duration: const Duration(milliseconds: 1000),
                  fontSize: 32,
                  showIcon: true,
                ),
                const SizedBox(width: 8),
                const Text(
                  'เหรียญ',
                  style: TextStyle(
                    color: _kTextSecondary,
                    fontSize: 16,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),

          // ── XP bar ───────────────────────────────────────────────────
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'XP ที่ได้รับ',
                    style: TextStyle(
                      color: _kTextSecondary,
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  Text(
                    '+$xp XP',
                    style: const TextStyle(
                      color: _kXpBlue,
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 6),
              ClipRRect(
                borderRadius: BorderRadius.circular(4),
                child: Container(
                  height: 8,
                  width: double.infinity,
                  color: _kNavy,
                  child: AnimatedBuilder(
                    animation: xpFill,
                    builder: (context, _) {
                      return FractionallySizedBox(
                        alignment: Alignment.centerLeft,
                        widthFactor: xpFill.value,
                        child: Container(color: _kXpBlue),
                      );
                    },
                  ),
                ),
              ),
            ],
          ),

          // ── Streak banner ────────────────────────────────────────────
          if (hasStreak) ...[
            const SizedBox(height: 16),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 16),
              decoration: BoxDecoration(
                color: isMilestone
                    ? _kGold.withValues(alpha: 0.12)
                    : _kNeonGreen.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(
                  color: isMilestone
                      ? _kGold.withValues(alpha: 0.5)
                      : _kNeonGreen.withValues(alpha: 0.3),
                ),
              ),
              child: Text(
                streakLabel,
                style: TextStyle(
                  color: isMilestone ? _kGold : _kNeonGreen,
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                ),
                textAlign: TextAlign.center,
              ),
            ),
          ],

          const SizedBox(height: 24),

          // ── Claim button ──────────────────────────────────────────────
          SizedBox(
            width: double.infinity,
            height: 50,
            child: ElevatedButton(
              onPressed: onClaim,
              style: ElevatedButton.styleFrom(
                backgroundColor: _kNeonGreen,
                foregroundColor: _kNavy,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
                elevation: 0,
              ),
              child: const Text(
                'รับรางวัล!',
                style: TextStyle(
                  fontSize: 17,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 0.5,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ── Coin rain painter ─────────────────────────────────────────────────────────

class _CoinDrop {
  const _CoinDrop({
    required this.x,
    required this.delay,
    required this.size,
    required this.wobble,
  });

  /// Horizontal position as a fraction of screen width [0, 1].
  final double x;

  /// Animation start delay as a fraction [0, 1].
  final double delay;

  final double size;

  /// Horizontal wobble offset as a fraction of screen width.
  final double wobble;
}

class _CoinRainPainter extends CustomPainter {
  _CoinRainPainter({
    required this.progress,
    required this.coins,
  });

  final double progress;
  final List<_CoinDrop> coins;

  @override
  void paint(Canvas canvas, Size size) {
    for (final coin in coins) {
      // Offset the local progress by the coin's delay, wrapping around.
      final local = ((progress - coin.delay) % 1.0 + 1.0) % 1.0;
      final y = local * (size.height + 60) - 30;
      final x = coin.x * size.width + coin.wobble * size.width * local;
      final opacity = (local < 0.1
              ? local / 0.1
              : local > 0.85
                  ? 1.0 - (local - 0.85) / 0.15
                  : 1.0)
          .clamp(0.0, 1.0);

      final paint = Paint()
        ..color = _kGold.withValues(alpha: (opacity * 0.75))
        ..style = PaintingStyle.fill;

      canvas.drawCircle(Offset(x, y), coin.size / 2, paint);

      // Sheen highlight
      final sheenPaint = Paint()
        ..color = Colors.white.withValues(alpha: (opacity * 0.4))
        ..style = PaintingStyle.fill;
      canvas.drawCircle(
        Offset(x - coin.size * 0.15, y - coin.size * 0.15),
        coin.size * 0.2,
        sheenPaint,
      );
    }
  }

  @override
  bool shouldRepaint(_CoinRainPainter old) =>
      old.progress != progress;
}
