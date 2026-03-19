import 'dart:async';

import 'package:flutter/material.dart';

import 'package:aslan_pixel/features/quests/view/quest_page.dart';

// ── StreakWarningBanner ────────────────────────────────────────────────────────

/// Displays a pulsing amber/red countdown banner when the user's streak is
/// about to expire.
///
/// Shows the banner when within 4 hours of midnight and the user hasn't been
/// active today. Accepts [streakDays] and [lastActiveAt] to determine
/// visibility without requiring SharedPreferences.
///
/// Place it near the top of any scroll body -- it hides itself when the
/// streak is safe or the countdown reaches zero.
class StreakWarningBanner extends StatefulWidget {
  const StreakWarningBanner({
    super.key,
    this.streakDays = 0,
    this.lastActiveAt,
  });

  /// Current streak length -- shown in the warning text.
  final int streakDays;

  /// Last time the user was active. If null or today, the banner is hidden.
  /// If provided and not today, the banner shows when within 4 hours of
  /// midnight.
  final DateTime? lastActiveAt;

  @override
  State<StreakWarningBanner> createState() => _StreakWarningBannerState();
}

class _StreakWarningBannerState extends State<StreakWarningBanner>
    with SingleTickerProviderStateMixin {
  bool _dismissed = false;
  Duration _remaining = Duration.zero;
  Timer? _timer;
  late final AnimationController _pulseController;
  late final Animation<double> _pulseAnimation;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    )..repeat(reverse: true);
    _pulseAnimation = Tween<double>(begin: 0.85, end: 1.0).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );
    _remaining = _timeUntilMidnight();
    if (_shouldShow) _startTimer();
  }

  bool get _shouldShow {
    if (_dismissed) return false;
    if (widget.streakDays <= 0) return false;

    // If lastActiveAt is provided, check if the user was already active today.
    if (widget.lastActiveAt != null) {
      final now = DateTime.now();
      final last = widget.lastActiveAt!;
      if (last.year == now.year &&
          last.month == now.month &&
          last.day == now.day) {
        return false; // Already active today -- streak is safe.
      }
    }

    // Only show within 4 hours of midnight.
    final remaining = _timeUntilMidnight();
    return remaining.inHours < 4 && !remaining.isNegative;
  }

  void _startTimer() {
    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (!mounted) return;
      final remaining = _timeUntilMidnight();
      if (remaining.isNegative) {
        setState(() {});
        _timer?.cancel();
        return;
      }
      setState(() => _remaining = remaining);
    });
  }

  Duration _timeUntilMidnight() {
    final now = DateTime.now();
    final midnight = DateTime(now.year, now.month, now.day + 1);
    return midnight.difference(now);
  }

  String _countdownLabel() {
    final h = _remaining.inHours.toString().padLeft(2, '0');
    final m = (_remaining.inMinutes % 60).toString().padLeft(2, '0');
    final s = (_remaining.inSeconds % 60).toString().padLeft(2, '0');
    return '$h:$m:$s';
  }

  @override
  void dispose() {
    _timer?.cancel();
    _pulseController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (!_shouldShow) return const SizedBox.shrink();

    return AnimatedBuilder(
      animation: _pulseAnimation,
      builder: (context, child) {
        return Opacity(
          opacity: _pulseAnimation.value,
          child: child,
        );
      },
      child: GestureDetector(
        onTap: () => Navigator.of(context).pushNamed(QuestPage.routeName),
        child: Container(
          margin: const EdgeInsets.fromLTRB(16, 8, 16, 4),
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [Color(0xFFFF8C00), Color(0xFFFF3B30)],
              begin: Alignment.centerLeft,
              end: Alignment.centerRight,
            ),
            borderRadius: BorderRadius.circular(12),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFFFF3B30).withValues(alpha: 0.35),
                blurRadius: 10,
                offset: const Offset(0, 3),
              ),
            ],
          ),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(14, 10, 10, 10),
            child: Row(
              children: [
                const Text('\u{1F525}', style: TextStyle(fontSize: 20)),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        '\u0e23\u0e31\u0e01\u0e29\u0e32 Streak! \u0e40\u0e2b\u0e25\u0e37\u0e2d\u0e2d\u0e35\u0e01 ${_countdownLabel()}',
                        // รักษา Streak! เหลืออีก HH:MM:SS
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 13,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        '${widget.streakDays} \u0e27\u0e31\u0e19\u0e15\u0e34\u0e14\u0e15\u0e48\u0e2d\u0e01\u0e31\u0e19 \u2022 \u0e40\u0e02\u0e49\u0e32\u0e21\u0e32\u0e40\u0e25\u0e48\u0e19\u0e01\u0e48\u0e2d\u0e19\u0e40\u0e17\u0e35\u0e48\u0e22\u0e07\u0e04\u0e37\u0e19',
                        // X วันติดต่อกัน • เข้ามาเล่นก่อนเที่ยงคืน
                        style: const TextStyle(
                          color: Colors.white70,
                          fontSize: 11,
                        ),
                      ),
                    ],
                  ),
                ),
                // Dismiss button
                GestureDetector(
                  onTap: () => setState(() => _dismissed = true),
                  behavior: HitTestBehavior.opaque,
                  child: const Padding(
                    padding: EdgeInsets.all(6),
                    child: Icon(
                      Icons.close_rounded,
                      color: Colors.white70,
                      size: 18,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
