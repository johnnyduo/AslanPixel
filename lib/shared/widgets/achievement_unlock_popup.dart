import 'dart:async';

import 'package:flutter/material.dart';

import 'package:aslan_pixel/core/utils/haptic_service.dart';
import 'package:aslan_pixel/features/profile/data/models/badge_model.dart';
import 'package:aslan_pixel/shared/widgets/confetti_overlay.dart';

// ── Palette ──────────────────────────────────────────────────────────────────
const _kNavy = Color(0xFF0a1628);
const _kSurface = Color(0xFF162040);
const _kGold = Color(0xFFf5c518);
const _kNeonGreen = Color(0xFF00f5a0);
const _kTextSecondary = Color(0xFFa8c4e0);
const _kCyberPurple = Color(0xFF7b2fff);

/// Maps badge category strings to display labels and colours.
const _kCategoryMeta = <String, ({String label, Color color})>{
  'trading': (label: 'Trading', color: _kGold),
  'social': (label: 'Social', color: _kNeonGreen),
  'game': (label: 'Game', color: _kCyberPurple),
  'special': (label: 'Special', color: Color(0xFFFF6B9D)),
};

/// Full-screen celebration modal when a badge/achievement is unlocked.
///
/// Shows badge emoji at 3x size, name in gold, description in Thai,
/// confetti burst, and haptic feedback.
///
/// Usage:
/// ```dart
/// showDialog(
///   context: context,
///   barrierDismissible: false,
///   barrierColor: Colors.black54,
///   builder: (_) => AchievementUnlockPopup(badge: myBadge),
/// );
/// ```
class AchievementUnlockPopup extends StatefulWidget {
  const AchievementUnlockPopup({super.key, required this.badge});

  final BadgeModel badge;

  @override
  State<AchievementUnlockPopup> createState() =>
      _AchievementUnlockPopupState();
}

class _AchievementUnlockPopupState extends State<AchievementUnlockPopup>
    with SingleTickerProviderStateMixin {
  late final AnimationController _cardController;
  late final Animation<double> _cardScale;
  Timer? _autoDismissTimer;
  bool _dismissing = false;

  @override
  void initState() {
    super.initState();

    // Scale-in animation.
    _cardController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 450),
    );
    _cardScale = CurvedAnimation(
      parent: _cardController,
      curve: Curves.elasticOut,
    );
    _cardController.forward();

    // Haptic feedback on show.
    HapticService.heavyTap();

    // Confetti burst after a brief delay.
    Future.delayed(const Duration(milliseconds: 200), () {
      if (mounted) ConfettiOverlay.burst(context);
    });

    // Auto-dismiss after 5 seconds.
    _autoDismissTimer = Timer(const Duration(seconds: 5), _dismiss);
  }

  @override
  void dispose() {
    _autoDismissTimer?.cancel();
    _cardController.dispose();
    super.dispose();
  }

  void _dismiss() {
    if (_dismissing) return;
    _dismissing = true;
    _autoDismissTimer?.cancel();
    _cardController.reverse().then((_) {
      if (mounted) Navigator.of(context).pop();
    });
  }

  @override
  Widget build(BuildContext context) {
    final badge = widget.badge;
    final categoryMeta =
        _kCategoryMeta[badge.category] ?? _kCategoryMeta['special']!;

    return Material(
      type: MaterialType.transparency,
      child: Center(
        child: ScaleTransition(
          scale: _cardScale,
          child: Container(
            margin: const EdgeInsets.symmetric(horizontal: 28),
            padding: const EdgeInsets.fromLTRB(24, 32, 24, 24),
            decoration: BoxDecoration(
              color: _kSurface,
              borderRadius: BorderRadius.circular(24),
              border: Border.all(color: _kGold, width: 2),
              boxShadow: [
                BoxShadow(
                  color: _kGold.withValues(alpha: 0.25),
                  blurRadius: 40,
                  spreadRadius: 6,
                ),
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // ── Badge emoji at 3x size ──────────────────────────────
                Container(
                  width: 88,
                  height: 88,
                  decoration: BoxDecoration(
                    color: _kGold.withValues(alpha: 0.12),
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: _kGold.withValues(alpha: 0.5),
                      width: 2,
                    ),
                  ),
                  alignment: Alignment.center,
                  child: Text(
                    badge.iconEmoji,
                    style: const TextStyle(fontSize: 40),
                  ),
                ),
                const SizedBox(height: 16),

                // ── "Achievement Unlocked" label ────────────────────────
                const Text(
                  'ปลดล็อกแล้ว!',
                  style: TextStyle(
                    color: _kTextSecondary,
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    letterSpacing: 0.5,
                  ),
                ),
                const SizedBox(height: 8),

                // ── Badge name in gold ──────────────────────────────────
                Text(
                  badge.nameTh.isNotEmpty ? badge.nameTh : badge.name,
                  style: const TextStyle(
                    color: _kGold,
                    fontSize: 22,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 0.3,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 6),

                // ── Description in Thai ─────────────────────────────────
                Text(
                  badge.descriptionTh.isNotEmpty
                      ? badge.descriptionTh
                      : badge.description,
                  style: const TextStyle(
                    color: _kTextSecondary,
                    fontSize: 13,
                    height: 1.4,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 14),

                // ── Category chip ───────────────────────────────────────
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 5,
                  ),
                  decoration: BoxDecoration(
                    color: categoryMeta.color.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: categoryMeta.color.withValues(alpha: 0.4),
                    ),
                  ),
                  child: Text(
                    categoryMeta.label,
                    style: TextStyle(
                      color: categoryMeta.color,
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
                const SizedBox(height: 24),

                // ── Dismiss button ──────────────────────────────────────
                SizedBox(
                  width: double.infinity,
                  height: 48,
                  child: ElevatedButton(
                    onPressed: _dismiss,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: _kNeonGreen,
                      foregroundColor: _kNavy,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                      elevation: 0,
                    ),
                    child: const Text(
                      '\u0e40\u0e22\u0e35\u0e48\u0e22\u0e21!', // เยี่ยม!
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
          ),
        ),
      ),
    );
  }
}
