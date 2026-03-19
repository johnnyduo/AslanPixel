import 'package:flutter/services.dart';

/// Centralized haptic feedback for dopamine moments.
class HapticService {
  const HapticService._();

  /// Light tap -- button press, menu selection.
  static Future<void> lightTap() => HapticFeedback.lightImpact();

  /// Medium tap -- quest complete, agent return.
  static Future<void> mediumTap() => HapticFeedback.mediumImpact();

  /// Heavy tap -- level-up, achievement unlock, big reward.
  static Future<void> heavyTap() => HapticFeedback.heavyImpact();

  /// Selection tick -- toggle, switch, picker.
  static Future<void> selectionTick() => HapticFeedback.selectionClick();

  /// Success pattern -- double vibration for wins.
  static Future<void> successPattern() async {
    await HapticFeedback.mediumImpact();
    await Future<void>.delayed(const Duration(milliseconds: 100));
    await HapticFeedback.heavyImpact();
  }

  /// Coin collect -- light series for reward claiming.
  static Future<void> coinCollect() async {
    for (var i = 0; i < 3; i++) {
      await HapticFeedback.lightImpact();
      await Future<void>.delayed(const Duration(milliseconds: 60));
    }
  }
}
