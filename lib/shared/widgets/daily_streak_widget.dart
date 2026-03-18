import 'package:flutter/material.dart';

// ── Palette constants ────────────────────────────────────────────────────────
const _kGold = Color(0xFFF5C518);
const _kNeonGreen = Color(0xFF00F5A0);
const _kNavy = Color(0xFF0A1628);
const _kSurface = Color(0xFF0F2040);
const _kBorder = Color(0xFF1E3050);
const _kTextPrimary = Color(0xFFE8F4F8);
const _kTextSecondary = Color(0xFF6B8AAB);

/// Milestone days that trigger a full-widget gold flash.
const _kMilestoneDays = {3, 7, 30};

/// Day abbreviations (Mon=0 … Sun=6).
const _kDayLabels = ['จ', 'อ', 'พ', 'พฤ', 'ศ', 'ส', 'อา'];

// ── DailyStreakWidget ─────────────────────────────────────────────────────────

/// Displays the user's login streak with a pulsing fire emoji, day circles,
/// and milestone gold-flash.
///
/// ```dart
/// DailyStreakWidget(streakDays: 5, todayIndex: 2) // Wednesday highlighted
/// ```
class DailyStreakWidget extends StatefulWidget {
  const DailyStreakWidget({
    super.key,
    required this.streakDays,
    this.todayIndex,
    this.onTap,
  });

  /// Number of consecutive login days.
  final int streakDays;

  /// Which day-circle index (0=Mon … 6=Sun) is "today". Defaults to the
  /// current weekday derived from [DateTime.now].
  final int? todayIndex;

  /// Called when the widget is tapped; typically shows a reward info sheet.
  final VoidCallback? onTap;

  @override
  State<DailyStreakWidget> createState() => _DailyStreakWidgetState();
}

class _DailyStreakWidgetState extends State<DailyStreakWidget>
    with TickerProviderStateMixin {
  // Fire emoji pulse: 1.0 → 1.15 → 1.0, 1.5 s loop.
  late final AnimationController _fireCtrl;
  late final Animation<double> _fireScale;

  // Gold-flash for milestone days: 0.5 s one-shot.
  late final AnimationController _flashCtrl;
  late final Animation<double> _flashAlpha;

  // Today-circle glow pulse: 1.0 → 1.2 → 1.0.
  late final AnimationController _todayGlowCtrl;
  late final Animation<double> _todayGlow;

  @override
  void initState() {
    super.initState();

    _fireCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    )..repeat(reverse: true);

    _fireScale = Tween<double>(begin: 1.0, end: 1.15).animate(
      CurvedAnimation(parent: _fireCtrl, curve: Curves.easeInOut),
    );

    _flashCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
    );

    _flashAlpha = Tween<double>(begin: 0.0, end: 0.35).animate(
      CurvedAnimation(parent: _flashCtrl, curve: Curves.easeOut),
    );

    _todayGlowCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    )..repeat(reverse: true);

    _todayGlow = Tween<double>(begin: 0.6, end: 1.0).animate(
      CurvedAnimation(parent: _todayGlowCtrl, curve: Curves.easeInOut),
    );

    // Trigger flash on milestone days when widget is first shown.
    if (_kMilestoneDays.contains(widget.streakDays)) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          _flashCtrl.forward().then((_) {
            if (mounted) _flashCtrl.reverse();
          });
        }
      });
    }
  }

  @override
  void didUpdateWidget(DailyStreakWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.streakDays != widget.streakDays &&
        _kMilestoneDays.contains(widget.streakDays)) {
      _flashCtrl
          .forward()
          .then((_) => mounted ? _flashCtrl.reverse() : null);
    }
  }

  @override
  void dispose() {
    _fireCtrl.dispose();
    _flashCtrl.dispose();
    _todayGlowCtrl.dispose();
    super.dispose();
  }

  int get _todayDayIndex {
    if (widget.todayIndex != null) return widget.todayIndex!;
    // DateTime.weekday: 1=Mon … 7=Sun → convert to 0-based index.
    return (DateTime.now().weekday - 1).clamp(0, 6);
  }

  @override
  Widget build(BuildContext context) {
    final today = _todayDayIndex;

    return GestureDetector(
      onTap: widget.onTap ?? () => _showStreakSheet(context),
      child: AnimatedBuilder(
        animation: Listenable.merge([_flashAlpha, _fireScale, _todayGlow]),
        builder: (context, _) {
          return Stack(
            children: [
              // ── Base card ──────────────────────────────────────────────
              Container(
                margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                padding: const EdgeInsets.fromLTRB(16, 14, 16, 14),
                decoration: BoxDecoration(
                  color: _kSurface,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(
                    color: _kGold.withValues(alpha: 0.25),
                    width: 1.5,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: _kGold.withValues(alpha: 0.07),
                      blurRadius: 12,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // ── Header row ───────────────────────────────────────
                    Row(
                      children: [
                        // Pulsing fire emoji
                        Transform.scale(
                          scale: _fireScale.value,
                          child: const Text(
                            '🔥',
                            style: TextStyle(fontSize: 28),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                '${widget.streakDays} วันติดต่อกัน!',
                                style: const TextStyle(
                                  color: _kGold,
                                  fontSize: 17,
                                  fontWeight: FontWeight.w800,
                                  letterSpacing: 0.3,
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                'แตะเพื่อดูรางวัล',
                                style: TextStyle(
                                  color: _kTextSecondary
                                      .withValues(alpha: 0.8),
                                  fontSize: 11,
                                ),
                              ),
                            ],
                          ),
                        ),
                        Icon(
                          Icons.chevron_right_rounded,
                          color: _kGold.withValues(alpha: 0.5),
                          size: 20,
                        ),
                      ],
                    ),
                    const SizedBox(height: 14),
                    // ── Day circles row ──────────────────────────────────
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: List.generate(7, (index) {
                        final isCompleted = index < today;
                        final isToday = index == today;
                        final isFuture = index > today;
                        return _DayCircle(
                          label: _kDayLabels[index],
                          isCompleted: isCompleted,
                          isToday: isToday,
                          isFuture: isFuture,
                          todayGlowAlpha: isToday ? _todayGlow.value : 0.0,
                        );
                      }),
                    ),
                  ],
                ),
              ),
              // ── Gold flash overlay (milestone) ─────────────────────────
              if (_flashAlpha.value > 0.0)
                Positioned.fill(
                  child: Container(
                    margin:
                        const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                    decoration: BoxDecoration(
                      color: _kGold.withValues(alpha: _flashAlpha.value),
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                ),
            ],
          );
        },
      ),
    );
  }

  void _showStreakSheet(BuildContext context) {
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: _kNavy,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => _StreakRewardSheet(streakDays: widget.streakDays),
    );
  }
}

// ── _DayCircle ────────────────────────────────────────────────────────────────

class _DayCircle extends StatelessWidget {
  const _DayCircle({
    required this.label,
    required this.isCompleted,
    required this.isToday,
    required this.isFuture,
    required this.todayGlowAlpha,
  });

  final String label;
  final bool isCompleted;
  final bool isToday;
  final bool isFuture;
  final double todayGlowAlpha;

  @override
  Widget build(BuildContext context) {
    Color bgColor;
    Color borderColor;
    Widget inner;

    if (isCompleted) {
      bgColor = _kNeonGreen.withValues(alpha: 0.18);
      borderColor = _kNeonGreen;
      inner = const Icon(Icons.check_rounded, color: _kNeonGreen, size: 14);
    } else if (isToday) {
      bgColor = _kGold.withValues(alpha: 0.2);
      borderColor = _kGold;
      inner = Text(
        label,
        style: const TextStyle(
          color: _kGold,
          fontSize: 10,
          fontWeight: FontWeight.w800,
        ),
      );
    } else {
      bgColor = Colors.transparent;
      borderColor = _kBorder;
      inner = Text(
        label,
        style: TextStyle(
          color: _kTextSecondary.withValues(alpha: 0.5),
          fontSize: 10,
        ),
      );
    }

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 34,
          height: 34,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: bgColor,
            border: Border.all(color: borderColor, width: 1.5),
            boxShadow: isToday
                ? [
                    BoxShadow(
                      color: _kGold.withValues(alpha: todayGlowAlpha * 0.6),
                      blurRadius: 10,
                      spreadRadius: 1,
                    ),
                  ]
                : null,
          ),
          alignment: Alignment.center,
          child: inner,
        ),
        const SizedBox(height: 4),
        if (!isCompleted && !isToday)
          Text(
            label,
            style: TextStyle(
              color: _kTextSecondary.withValues(alpha: 0.35),
              fontSize: 9,
            ),
          )
        else
          const SizedBox(height: 12),
      ],
    );
  }
}

// ── _StreakRewardSheet ────────────────────────────────────────────────────────

class _StreakRewardSheet extends StatelessWidget {
  const _StreakRewardSheet({required this.streakDays});

  final int streakDays;

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(24, 20, 24, 28),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: _kBorder,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 20),
            const Text(
              '🔥 รางวัล Streak',
              style: TextStyle(
                color: _kGold,
                fontSize: 20,
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'เข้าสู่ระบบติดต่อกัน $streakDays วัน',
              style: const TextStyle(color: _kTextSecondary, fontSize: 14),
            ),
            const SizedBox(height: 24),
            _MilestoneRow(day: 3, label: 'วัน 3', reward: '+50 🪙', achieved: streakDays >= 3),
            const SizedBox(height: 12),
            _MilestoneRow(day: 7, label: 'วัน 7', reward: '+150 🪙 + ไอเทมพิเศษ', achieved: streakDays >= 7),
            const SizedBox(height: 12),
            _MilestoneRow(day: 30, label: 'วัน 30', reward: '+500 🪙 + Badge ตำนาน', achieved: streakDays >= 30),
            const SizedBox(height: 28),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: _kGold,
                  foregroundColor: _kNavy,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                onPressed: () => Navigator.of(context).pop(),
                child: const Text(
                  'เข้าใจแล้ว!',
                  style: TextStyle(fontWeight: FontWeight.w800, fontSize: 15),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _MilestoneRow extends StatelessWidget {
  const _MilestoneRow({
    required this.day,
    required this.label,
    required this.reward,
    required this.achieved,
  });

  final int day;
  final String label;
  final String reward;
  final bool achieved;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 36,
          height: 36,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: achieved
                ? _kGold.withValues(alpha: 0.2)
                : _kBorder.withValues(alpha: 0.5),
            border: Border.all(
              color: achieved ? _kGold : _kBorder,
              width: 1.5,
            ),
          ),
          alignment: Alignment.center,
          child: Icon(
            achieved ? Icons.check_circle_rounded : Icons.lock_outline_rounded,
            color: achieved ? _kGold : _kTextSecondary,
            size: 18,
          ),
        ),
        const SizedBox(width: 14),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: TextStyle(
                  color: achieved ? _kGold : _kTextSecondary,
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                ),
              ),
              Text(
                reward,
                style: TextStyle(
                  color: achieved
                      ? _kTextPrimary
                      : _kTextSecondary.withValues(alpha: 0.6),
                  fontSize: 12,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
