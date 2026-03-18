import 'package:flutter/material.dart';

/// Semantic color system for Aslan Pixel — pixel-art finance aesthetic.
/// Palette: deep navy background, neon green accent, gold brand, cyber purple.
///
/// Usage: `final colors = AppColors.of(context);`
class AppColorScheme {
  // ── Backgrounds ──
  final Color background;
  final Color backgroundSecondary;
  final Color backgroundTertiary;
  final Color surface;
  final Color surfaceElevated;
  final Color scaffoldBackground;

  // ── Text ──
  final Color textPrimary;
  final Color textSecondary;
  final Color textTertiary;
  final Color textDisabled;
  final Color textOnPrimary;

  // ── Borders & Dividers ──
  final Color border;
  final Color borderSubtle;
  final Color divider;

  // ── Brand ──
  final Color primary;       // neon green — main CTA
  final Color primaryLight;
  final Color primaryDark;
  final Color accent;        // gold — rewards, coins, special items
  final Color cyber;         // cyber purple — AI agents, premium

  // ── Status ──
  final Color error;
  final Color warning;
  final Color success;
  final Color profit;        // green PnL
  final Color loss;          // red PnL

  // ── Semantic Surfaces ──
  final Color cardBackground;
  final Color inputBackground;
  final Color inputBorder;
  final Color shimmerBase;
  final Color shimmerHighlight;

  // ── Shadows ──
  final Color shadow;
  final Color shadowMedium;

  // ── Navigation ──
  final Color bottomNavBackground;
  final Color bottomNavSelected;
  final Color bottomNavUnselected;

  // ── Status Indicators ──
  final Color statusWaiting;
  final Color statusCancelled;
  final Color statusCompleted;

  // ── Chart ──
  final Color chartBackground;
  final Color chartGrid;
  final Color chartText;
  final Color chartCrosshair;

  // ── Pixel Game ──
  final Color gameBackground;   // backdrop for Flame game widget
  final Color gameSurface;      // tile default color
  final Color agentGlow;        // glow around active agent

  // ── AppBar ──
  final Color appBarBackground;
  final Color appBarForeground;
  final Color appBarBorder;

  // ── Icon ──
  final Color iconDefault;
  final Color iconOnSurface;

  const AppColorScheme({
    required this.background,
    required this.backgroundSecondary,
    required this.backgroundTertiary,
    required this.surface,
    required this.surfaceElevated,
    required this.scaffoldBackground,
    required this.textPrimary,
    required this.textSecondary,
    required this.textTertiary,
    required this.textDisabled,
    required this.textOnPrimary,
    required this.border,
    required this.borderSubtle,
    required this.divider,
    required this.primary,
    required this.primaryLight,
    required this.primaryDark,
    required this.accent,
    required this.cyber,
    required this.error,
    required this.warning,
    required this.success,
    required this.profit,
    required this.loss,
    required this.cardBackground,
    required this.inputBackground,
    required this.inputBorder,
    required this.shimmerBase,
    required this.shimmerHighlight,
    required this.shadow,
    required this.shadowMedium,
    required this.bottomNavBackground,
    required this.bottomNavSelected,
    required this.bottomNavUnselected,
    required this.statusWaiting,
    required this.statusCancelled,
    required this.statusCompleted,
    required this.chartBackground,
    required this.chartGrid,
    required this.chartText,
    required this.chartCrosshair,
    required this.gameBackground,
    required this.gameSurface,
    required this.agentGlow,
    required this.appBarBackground,
    required this.appBarForeground,
    required this.appBarBorder,
    required this.iconDefault,
    required this.iconOnSurface,
  });

  /// Dark scheme — primary. Deep navy pixel world aesthetic.
  static const dark = AppColorScheme(
    background: Color(0xFF0a1628),          // deep navy
    backgroundSecondary: Color(0xFF0d1f3c),
    backgroundTertiary: Color(0xFF111e35),
    surface: Color(0xFF162040),             // card surface
    surfaceElevated: Color(0xFF1c2a4e),
    scaffoldBackground: Color(0xFF0a1628),

    textPrimary: Color(0xFFe8f4ff),
    textSecondary: Color(0xFFa8c4e0),
    textTertiary: Color(0xFF6b8aab),
    textDisabled: Color(0xFF3d5a78),
    textOnPrimary: Color(0xFF0a1628),       // dark text on neon green

    border: Color(0xFF1e3050),
    borderSubtle: Color(0xFF162040),
    divider: Color(0xFF1e3050),

    primary: Color(0xFF00f5a0),             // neon green
    primaryLight: Color(0xFF66ffcc),
    primaryDark: Color(0xFF00c77d),
    accent: Color(0xFFf5c518),              // gold / coins
    cyber: Color(0xFF7b2fff),               // cyber purple / AI

    error: Color(0xFFff4d4f),
    warning: Color(0xFFfaad14),
    success: Color(0xFF52c41a),
    profit: Color(0xFF00f5a0),              // same as primary for consistency
    loss: Color(0xFFff4d4f),

    cardBackground: Color(0xFF162040),
    inputBackground: Color(0xFF0d1f3c),
    inputBorder: Color(0xFF1e3050),
    shimmerBase: Color(0xFF162040),
    shimmerHighlight: Color(0xFF1c2a4e),

    shadow: Color(0x33000000),
    shadowMedium: Color(0x4D000000),

    bottomNavBackground: Color(0xFF0a1628),
    bottomNavSelected: Color(0xFF00f5a0),
    bottomNavUnselected: Color(0xFF3d5a78),

    statusWaiting: Color(0xFFfaad14),
    statusCancelled: Color(0xFFff4d4f),
    statusCompleted: Color(0xFF52c41a),

    chartBackground: Color(0xFF0d1f3c),
    chartGrid: Color(0xFF1e3050),
    chartText: Color(0xFF6b8aab),
    chartCrosshair: Color(0xFFe8f4ff),

    gameBackground: Color(0xFF081020),      // darkest — Flame backdrop
    gameSurface: Color(0xFF162040),
    agentGlow: Color(0xFF00f5a0),

    appBarBackground: Color(0xFF0a1628),
    appBarForeground: Color(0xFFe8f4ff),
    appBarBorder: Color(0xFF1e3050),

    iconDefault: Color(0xFF3d5a78),
    iconOnSurface: Color(0xFFe8f4ff),
  );

  /// Light scheme — optional. Clean white with neon accents.
  static const light = AppColorScheme(
    background: Color(0xFFf0f4ff),
    backgroundSecondary: Color(0xFFe8eef8),
    backgroundTertiary: Color(0xFFdde5f5),
    surface: Color(0xFFFFFFFF),
    surfaceElevated: Color(0xFFf8faff),
    scaffoldBackground: Color(0xFFf0f4ff),

    textPrimary: Color(0xFF0a1628),
    textSecondary: Color(0xFF2a3f5f),
    textTertiary: Color(0xFF5a7a9a),
    textDisabled: Color(0xFF9ab0c8),
    textOnPrimary: Color(0xFF0a1628),

    border: Color(0xFFccd8ea),
    borderSubtle: Color(0xFFe0e9f5),
    divider: Color(0xFFe0e9f5),

    primary: Color(0xFF00c77d),             // slightly darker neon for light mode
    primaryLight: Color(0xFF66ffcc),
    primaryDark: Color(0xFF009960),
    accent: Color(0xFFc9a056),
    cyber: Color(0xFF6b1fd4),

    error: Color(0xFFff2323),
    warning: Color(0xFFfbbf23),
    success: Color(0xFF10b981),
    profit: Color(0xFF009960),
    loss: Color(0xFFff2323),

    cardBackground: Color(0xFFFFFFFF),
    inputBackground: Color(0xFFf0f4ff),
    inputBorder: Color(0xFFccd8ea),
    shimmerBase: Color(0xFFe0e0e0),
    shimmerHighlight: Color(0xFFf5f5f5),

    shadow: Color(0x14000000),
    shadowMedium: Color(0x1f000000),

    bottomNavBackground: Color(0xFFFFFFFF),
    bottomNavSelected: Color(0xFF00c77d),
    bottomNavUnselected: Color(0xFF9ab0c8),

    statusWaiting: Color(0xFFe1c363),
    statusCancelled: Color(0xFFd4444e),
    statusCompleted: Color(0xFFc5da9e),

    chartBackground: Color(0xFFFFFFFF),
    chartGrid: Color(0xFFd1d3db),
    chartText: Color(0xFF909196),
    chartCrosshair: Color(0xFF222223),

    gameBackground: Color(0xFFdde5f5),
    gameSurface: Color(0xFFe8eef8),
    agentGlow: Color(0xFF00c77d),

    appBarBackground: Color(0xFFf8faff),
    appBarForeground: Color(0xFF0a1628),
    appBarBorder: Color(0xFFccd8ea),

    iconDefault: Color(0xFF9ab0c8),
    iconOnSurface: Color(0xFF0a1628),
  );
}

/// InheritedWidget that provides [AppColorScheme] to the widget tree.
/// Place above GetMaterialApp/MaterialApp. Access via `AppColors.of(context)`.
class AppColors extends InheritedWidget {
  final AppColorScheme scheme;

  const AppColors({
    super.key,
    required this.scheme,
    required super.child,
  });

  /// Returns the current [AppColorScheme].
  /// Falls back to dark scheme if not found in tree.
  static AppColorScheme of(BuildContext context) {
    final widget = context.dependOnInheritedWidgetOfExactType<AppColors>();
    return widget?.scheme ?? AppColorScheme.dark;
  }

  @override
  bool updateShouldNotify(AppColors oldWidget) => scheme != oldWidget.scheme;
}

/// Pixel-specific named colors — use for game UI elements directly.
class PixelColor {
  const PixelColor._();
  static const neonGreen = Color(0xFF00f5a0);
  static const gold = Color(0xFFf5c518);
  static const cyberPurple = Color(0xFF7b2fff);
  static const deepNavy = Color(0xFF0a1628);
  static const pixelWhite = Color(0xFFe8f4ff);
  static const coinGold = Color(0xFFffd700);
  static const xpBlue = Color(0xFF4fc3f7);
  static const agentGreenGlow = Color(0xFF00f5a0);
}
