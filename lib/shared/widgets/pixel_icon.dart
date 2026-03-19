import 'package:flutter/material.dart';

/// A pixel art icon widget that loads PNG sprites from assets/sprites/ui/.
/// Use this instead of Material Icons throughout the app.
class PixelIcon extends StatelessWidget {
  const PixelIcon(
    this.name, {
    super.key,
    this.size = 24,
    this.color,
  });

  /// Icon name matching the asset file (without .png extension).
  /// e.g., 'coin' loads 'assets/sprites/ui/coin_icon.png'
  final String name;
  final double size;
  final Color? color;

  // All available pixel icon names
  static const String coin = 'coin';
  static const String star = 'star';
  static const String quest = 'quest';
  static const String xp = 'xp';
  static const String lock = 'lock';
  static const String arrowRight = 'arrow_right';
  static const String home = 'home';
  static const String world = 'world';
  static const String chart = 'chart';
  static const String social = 'social';
  static const String profile = 'profile';
  static const String trophy = 'trophy';
  static const String fire = 'fire';
  static const String heart = 'heart';
  static const String bell = 'bell';
  static const String settings = 'settings';
  static const String store = 'store';
  static const String sword = 'sword';
  static const String shield = 'shield';
  static const String potion = 'potion';

  @override
  Widget build(BuildContext context) {
    return Image.asset(
      'assets/sprites/ui/${name}_icon.png',
      width: size,
      height: size,
      color: color,
      colorBlendMode: color != null ? BlendMode.srcIn : null,
      filterQuality: FilterQuality.none, // Keep pixel art crisp!
      errorBuilder: (_, __, ___) => Icon(
        Icons.circle_outlined,
        size: size,
        color: color ?? Colors.white54,
      ),
    );
  }
}
