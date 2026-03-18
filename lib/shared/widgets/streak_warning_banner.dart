import 'dart:async';

import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:aslan_pixel/features/quests/view/quest_page.dart';

// ── StreakWarningBanner ────────────────────────────────────────────────────────

/// Displays a dismissible top banner when the user hasn't logged in today.
///
/// Reads `last_login_date` from [SharedPreferences]. If it is not today's date
/// the banner is shown with a live countdown to midnight.
///
/// Place it near the top of any scroll body — it hides itself both when
/// dismissed and when the key is absent (first install / same-day).
class StreakWarningBanner extends StatefulWidget {
  const StreakWarningBanner({
    super.key,
    this.streakDays = 0,
  });

  /// Current streak length — shown in the warning text.
  final int streakDays;

  @override
  State<StreakWarningBanner> createState() => _StreakWarningBannerState();
}

class _StreakWarningBannerState extends State<StreakWarningBanner>
    with SingleTickerProviderStateMixin {
  bool _shouldShow = false;
  bool _dismissed = false;
  Duration _remaining = Duration.zero;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _checkStreak();
  }

  Future<void> _checkStreak() async {
    final prefs = await SharedPreferences.getInstance();
    final lastLogin = prefs.getString('last_login_date');
    final todayStr = _todayString();

    if (lastLogin == null || lastLogin == todayStr) {
      // Either first launch or already checked in today → no warning.
      return;
    }

    if (!mounted) return;
    setState(() {
      _shouldShow = true;
      _remaining = _timeUntilMidnight();
    });
    _startTimer();
  }

  void _startTimer() {
    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (!mounted) return;
      final remaining = _timeUntilMidnight();
      if (remaining.isNegative) {
        setState(() => _shouldShow = false);
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

  String _todayString() {
    final now = DateTime.now();
    return '${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}';
  }

  String _countdownLabel() {
    final h = _remaining.inHours.toString().padLeft(2, '0');
    final m = (_remaining.inMinutes % 60).toString().padLeft(2, '0');
    final s = (_remaining.inSeconds % 60).toString().padLeft(2, '0');
    return 'เหลืออีก $h:$m:$s';
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (!_shouldShow || _dismissed) return const SizedBox.shrink();

    return GestureDetector(
      onTap: () => Navigator.of(context).pushNamed(QuestPage.routeName),
      child: Container(
        margin: const EdgeInsets.fromLTRB(16, 8, 16, 4),
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [Color(0xFFFF6B35), Color(0xFFFF3B30)],
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
              const Text('⚠️', style: TextStyle(fontSize: 20)),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      'เส้นทาง ${widget.streakDays} วันกำลังจะหยุด!',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 13,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 2),
                    const Text(
                      'เข้ามาเล่นก่อนเที่ยงคืน',
                      style: TextStyle(
                        color: Colors.white70,
                        fontSize: 11,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      _countdownLabel(),
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        fontFeatures: [FontFeature.tabularFigures()],
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
                  child: Icon(Icons.close_rounded, color: Colors.white70, size: 18),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
