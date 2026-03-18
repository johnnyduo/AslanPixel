import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Reads and writes the user's theme preference.
/// Default is [ThemeMode.dark] — Aslan Pixel is dark-first.
class ThemeProvider {
  static const String _key = 'app_theme_mode';

  /// Load saved theme mode. Returns [ThemeMode.dark] if nothing saved.
  static Future<ThemeMode> loadThemeMode() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final saved = prefs.getString(_key);
      if (saved == 'light') return ThemeMode.light;
      if (saved == 'system') return ThemeMode.system;
      return ThemeMode.dark;
    } catch (_) {
      return ThemeMode.dark;
    }
  }

  /// Persist theme mode to SharedPreferences.
  static Future<void> saveThemeMode(ThemeMode mode) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final value = switch (mode) {
        ThemeMode.light => 'light',
        ThemeMode.system => 'system',
        _ => 'dark',
      };
      await prefs.setString(_key, value);
    } catch (_) {
      // Fail silently
    }
  }
}
