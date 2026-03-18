import 'package:flutter/material.dart';
import 'package:aslan_pixel/core/config/app_colors.dart';
import 'package:aslan_pixel/l10n/app_localizations.dart';

extension ContextExtension on BuildContext {
  /// Returns the current [AppColorScheme] from the widget tree.
  AppColorScheme get colors => AppColors.of(this);

  /// Returns the current [ThemeData].
  ThemeData get theme => Theme.of(this);

  /// Returns the current [TextTheme].
  TextTheme get textTheme => Theme.of(this).textTheme;

  /// Returns true if the current theme brightness is dark.
  bool get isDark => Theme.of(this).brightness == Brightness.dark;

  /// Returns the screen width from [MediaQuery].
  double get screenWidth => MediaQuery.of(this).size.width;

  /// Returns the screen height from [MediaQuery].
  double get screenHeight => MediaQuery.of(this).size.height;

  /// Returns the [AppLocalizations] instance for the current context.
  AppLocalizations get l10n => AppLocalizations.of(this);
}
