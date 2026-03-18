import 'package:auto_size_text/auto_size_text.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import 'package:aslan_pixel/core/config/app_colors.dart';

// ─── Design Tokens ─────────────────────────────────────────────────────────

/// Standard border radii — use these instead of ad-hoc values.
class AppRadius {
  const AppRadius._();
  static const double xs = 4;
  static const double sm = 8;
  static const double md = 12;
  static const double lg = 16;
  static const double xl = 20;
  static const double pill = 100;
}

/// Standard font sizes — named scale for consistency.
class AppFontSize {
  const AppFontSize._();
  static const double caption = 10;
  static const double footnote = 11;
  static const double small = 12;
  static const double body = 14;
  static const double subtitle = 16;
  static const double title = 18;
  static const double heading = 20;
  static const double display = 28;
  static const double hero = 32;
}

// ─── Theme ─────────────────────────────────────────────────────────────────

class AppTheme {
  const AppTheme();

  /// Standard app font — IBM Plex Sans Thai for Thai language support.
  static String get fontFamily => GoogleFonts.ibmPlexSansThai().fontFamily!;

  static ThemeData lightTheme = ThemeData(
    useMaterial3: true,
    visualDensity: VisualDensity.adaptivePlatformDensity,
    colorScheme: ColorScheme.fromSeed(
      brightness: Brightness.light,
      seedColor: Colors.white,
      primary: AppColorScheme.light.primary,
    ),
    iconTheme: const IconThemeData(color: Colors.grey),
    appBarTheme: AppBarTheme(
      iconTheme: const IconThemeData(color: Colors.black),
      foregroundColor: AppColorScheme.light.appBarForeground,
      backgroundColor: AppColorScheme.light.appBarBackground,
      titleTextStyle: GoogleFonts.ibmPlexSansThai(
        fontSize: 20,
        fontWeight: FontWeight.w600,
        color: AppColorScheme.light.appBarForeground,
      ),
      shadowColor: AppColorScheme.light.appBarBorder,
      shape: Border(
        bottom: BorderSide(
          color: AppColorScheme.light.appBarBorder,
          width: 0.1,
        ),
      ),
      elevation: 0.1,
    ),
    primaryColor: AppColorScheme.light.surface,
    cardTheme: CardThemeData(color: AppColorScheme.light.cardBackground),
    textTheme: TextTheme(
      displayLarge: GoogleFonts.ibmPlexSansThai(
        fontSize: 32,
        fontWeight: FontWeight.w700,
        color: AppColorScheme.light.textPrimary,
      ),
      displayMedium: GoogleFonts.ibmPlexSansThai(
        fontSize: 28,
        fontWeight: FontWeight.w600,
        color: AppColorScheme.light.textPrimary,
      ),
      headlineLarge: GoogleFonts.ibmPlexSansThai(
        fontSize: 24,
        fontWeight: FontWeight.w600,
        color: AppColorScheme.light.textPrimary,
      ),
      headlineMedium: GoogleFonts.ibmPlexSansThai(
        fontSize: 20,
        fontWeight: FontWeight.w600,
        color: AppColorScheme.light.textPrimary,
      ),
      titleLarge: GoogleFonts.ibmPlexSansThai(
        fontSize: 18,
        fontWeight: FontWeight.w500,
        color: AppColorScheme.light.textPrimary,
      ),
      titleMedium: GoogleFonts.ibmPlexSansThai(
        fontSize: 16,
        fontWeight: FontWeight.w500,
        color: AppColorScheme.light.textPrimary,
      ),
      bodyLarge: GoogleFonts.ibmPlexSansThai(
        fontSize: 16,
        fontWeight: FontWeight.w400,
        color: AppColorScheme.light.textPrimary,
      ),
      bodyMedium: GoogleFonts.ibmPlexSansThai(
        fontSize: 14,
        fontWeight: FontWeight.w400,
        color: AppColorScheme.light.textPrimary,
      ),
      bodySmall: GoogleFonts.ibmPlexSansThai(
        fontSize: 12,
        fontWeight: FontWeight.w400,
        color: AppColorScheme.light.textPrimary,
      ),
      labelLarge: GoogleFonts.ibmPlexSansThai(
        fontSize: 14,
        fontWeight: FontWeight.w500,
        color: AppColorScheme.light.textPrimary,
      ),
    ),
    dividerColor: AppColorScheme.light.divider,
    buttonTheme: ButtonThemeData(buttonColor: AppColorScheme.light.primary),
    fontFamily: GoogleFonts.ibmPlexSansThai().fontFamily,
    primaryTextTheme: TextTheme(
      bodyLarge: GoogleFonts.ibmPlexSansThai(
        color: AppColorScheme.light.textSecondary,
      ),
    ),
    bottomAppBarTheme: BottomAppBarThemeData(
      color: AppColorScheme.light.bottomNavBackground,
    ),
  );

  static ThemeData darkTheme = ThemeData(
    useMaterial3: true,
    brightness: Brightness.dark,
    visualDensity: VisualDensity.adaptivePlatformDensity,
    colorScheme: ColorScheme.fromSeed(
      brightness: Brightness.dark,
      seedColor: const Color(0xFF0a1628),
      primary: AppColorScheme.dark.primary,
    ),
    scaffoldBackgroundColor: AppColorScheme.dark.scaffoldBackground,
    iconTheme: IconThemeData(color: AppColorScheme.dark.iconDefault),
    appBarTheme: AppBarTheme(
      iconTheme: IconThemeData(color: AppColorScheme.dark.appBarForeground),
      foregroundColor: AppColorScheme.dark.appBarForeground,
      backgroundColor: AppColorScheme.dark.appBarBackground,
      titleTextStyle: GoogleFonts.ibmPlexSansThai(
        fontSize: 20,
        fontWeight: FontWeight.w600,
        color: AppColorScheme.dark.appBarForeground,
      ),
      shadowColor: AppColorScheme.dark.appBarBorder,
      shape: Border(
        bottom: BorderSide(
          color: AppColorScheme.dark.appBarBorder,
          width: 0.1,
        ),
      ),
      elevation: 0.1,
    ),
    primaryColor: AppColorScheme.dark.surfaceElevated,
    cardTheme: CardThemeData(color: AppColorScheme.dark.cardBackground),
    textTheme: TextTheme(
      displayLarge: GoogleFonts.ibmPlexSansThai(
        fontSize: 32,
        fontWeight: FontWeight.w700,
        color: AppColorScheme.dark.textPrimary,
      ),
      displayMedium: GoogleFonts.ibmPlexSansThai(
        fontSize: 28,
        fontWeight: FontWeight.w600,
        color: AppColorScheme.dark.textPrimary,
      ),
      headlineLarge: GoogleFonts.ibmPlexSansThai(
        fontSize: 24,
        fontWeight: FontWeight.w600,
        color: AppColorScheme.dark.textPrimary,
      ),
      headlineMedium: GoogleFonts.ibmPlexSansThai(
        fontSize: 20,
        fontWeight: FontWeight.w600,
        color: AppColorScheme.dark.textPrimary,
      ),
      titleLarge: GoogleFonts.ibmPlexSansThai(
        fontSize: 18,
        fontWeight: FontWeight.w500,
        color: AppColorScheme.dark.textPrimary,
      ),
      titleMedium: GoogleFonts.ibmPlexSansThai(
        fontSize: 16,
        fontWeight: FontWeight.w500,
        color: AppColorScheme.dark.textPrimary,
      ),
      bodyLarge: GoogleFonts.ibmPlexSansThai(
        fontSize: 16,
        fontWeight: FontWeight.w400,
        color: AppColorScheme.dark.textPrimary,
      ),
      bodyMedium: GoogleFonts.ibmPlexSansThai(
        fontSize: 14,
        fontWeight: FontWeight.w400,
        color: AppColorScheme.dark.textPrimary,
      ),
      bodySmall: GoogleFonts.ibmPlexSansThai(
        fontSize: 12,
        fontWeight: FontWeight.w400,
        color: AppColorScheme.dark.textPrimary,
      ),
      labelLarge: GoogleFonts.ibmPlexSansThai(
        fontSize: 14,
        fontWeight: FontWeight.w500,
        color: AppColorScheme.dark.textPrimary,
      ),
    ),
    dividerColor: AppColorScheme.dark.appBarBorder,
    buttonTheme: ButtonThemeData(buttonColor: AppColorScheme.dark.primary),
    fontFamily: GoogleFonts.ibmPlexSansThai().fontFamily,
    primaryTextTheme: TextTheme(
      bodyLarge: GoogleFonts.ibmPlexSansThai(
        color: AppColorScheme.dark.textDisabled,
      ),
    ),
    bottomAppBarTheme: BottomAppBarThemeData(
      color: AppColorScheme.dark.bottomNavBackground,
    ),
  );

  /// Returns theme-aware shadows. Use instead of static [shadow] for dark mode.
  static List<BoxShadow> shadowFor(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return isDark ? const [] : shadow;
  }

  static List<BoxShadow> shadowBottomFor(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return isDark ? const [] : shadowBottom;
  }

  /// Uniform card shadow — use for all card-like widgets.
  static List<BoxShadow> cardShadow(BuildContext context) {
    return [
      BoxShadow(
        color: AppColors.of(context).shadowMedium,
        blurRadius: 8,
        offset: const Offset(0, 2),
      ),
    ];
  }

  /// Light-only card shadow for use without BuildContext.
  static const List<BoxShadow> cardShadowLight = [
    BoxShadow(
      color: Color(0x0D000000), // Colors.black.withOpacity(0.05)
      blurRadius: 8,
      offset: Offset(0, 2),
    ),
  ];

  static TextStyle titleStyle = GoogleFonts.ibmPlexSansThai(
    color: AppColorScheme.light.textSecondary,
    fontSize: 16,
  );
  static TextStyle subTitleStyle = GoogleFonts.ibmPlexSansThai(
    color: AppColorScheme.light.textTertiary,
    fontSize: 12,
  );

  static TextStyle h1Style = GoogleFonts.ibmPlexSansThai(
    fontSize: 24,
    fontWeight: FontWeight.bold,
  );
  static TextStyle h2Style = GoogleFonts.ibmPlexSansThai(fontSize: 22);
  static TextStyle h3Style = GoogleFonts.ibmPlexSansThai(fontSize: 20);
  static TextStyle h4Style = GoogleFonts.ibmPlexSansThai(fontSize: 18);
  static TextStyle h5Style = GoogleFonts.ibmPlexSansThai(fontSize: 16);
  static TextStyle h6Style = GoogleFonts.ibmPlexSansThai(fontSize: 14);

  static List<BoxShadow> shadow = <BoxShadow>[
    const BoxShadow(
      color: Color(0xfff8f8f8),
      blurRadius: 10,
      spreadRadius: 15,
    ),
  ];
  static List<BoxShadow> shadowBottom = <BoxShadow>[
    const BoxShadow(
      color: Color(0xfff8f8f8),
      blurRadius: 5,
      spreadRadius: 10,
      offset: Offset(0, 1),
    ),
  ];
  static List<BoxShadow> shadowBottomOnly = <BoxShadow>[
    const BoxShadow(
      color: Color(0xfff8f8f8),
      blurRadius: 2,
      spreadRadius: 5,
      offset: Offset(0, 1),
    ),
  ];

  static EdgeInsets padding = const EdgeInsets.symmetric(
    horizontal: 20,
    vertical: 10,
  );
  static EdgeInsets hPadding = const EdgeInsets.symmetric(horizontal: 10);

  static double fullWidth(BuildContext context) {
    return MediaQuery.of(context).size.width;
  }

  static double fullHeight(BuildContext context) {
    return MediaQuery.of(context).size.height;
  }
}

// ─── Text Helpers ───────────────────────────────────────────────────────────

Text headerText(
  String title, {
  int? fontSize = 22,
  Color? color,
  bool? alignEnd = false,
  bool isBold = true,
  int? maxLine,
}) {
  return Text(
    title,
    textAlign: alignEnd! ? TextAlign.end : TextAlign.start,
    maxLines: maxLine,
    style: GoogleFonts.ibmPlexSansThai(
      color: color ?? AppColorScheme.dark.textPrimary,
      fontSize: fontSize?.toDouble(),
      fontWeight: isBold ? FontWeight.w600 : FontWeight.normal,
    ),
  );
}

Text bodyText(
  String title, {
  int? fontSize = 14,
  Color? color,
  bool isLimit = false,
}) {
  return Text(
    title,
    style: GoogleFonts.ibmPlexSansThai(
      color: color ?? AppColorScheme.dark.textPrimary,
      fontSize: fontSize?.toDouble(),
      fontWeight: FontWeight.w400,
      decoration: isLimit ? TextDecoration.none : null,
    ),
    overflow: isLimit ? TextOverflow.ellipsis : TextOverflow.visible,
  );
}

Text contentText(
  String title, {
  int? fontSize = 14,
  Color? color,
  Color? decorationColor,
  bool isLimit = false,
  bool isUnderline = false,
  int? maxLine,
  TextAlign textAlign = TextAlign.start,
  bool isBold = false,
}) {
  return Text(
    title,
    textAlign: textAlign,
    maxLines: maxLine,
    style: GoogleFonts.ibmPlexSansThai(
      color: color ?? AppColorScheme.dark.textPrimary,
      fontSize: fontSize?.toDouble(),
      fontWeight: isBold ? FontWeight.w600 : FontWeight.w400,
      decoration: isUnderline ? TextDecoration.underline : TextDecoration.none,
      decorationColor: decorationColor ?? AppColorScheme.dark.textDisabled,
    ),
    overflow: isLimit ? TextOverflow.ellipsis : TextOverflow.visible,
  );
}

AutoSizeText titleText(
  String title, {
  int? fontSize = 14,
  Color? color,
  Color? decorationColor,
  bool isLimit = false,
  bool isUnderline = false,
  int? maxLine,
  TextAlign textAlign = TextAlign.start,
  bool isBold = false,
}) {
  return AutoSizeText(
    title,
    textAlign: textAlign,
    maxLines: maxLine,
    style: GoogleFonts.ibmPlexSansThai(
      color: color ?? AppColorScheme.dark.textPrimary,
      fontSize: fontSize?.toDouble(),
      fontWeight: isBold ? FontWeight.w600 : FontWeight.w400,
      decoration: isUnderline ? TextDecoration.underline : TextDecoration.none,
      decorationColor: decorationColor ?? AppColorScheme.dark.textDisabled,
    ),
    overflow: isLimit ? TextOverflow.ellipsis : TextOverflow.visible,
  );
}

AutoSizeText smallText(
  String title, {
  int? fontSize = 14,
  Color? color,
  bool isLimit = false,
}) {
  return AutoSizeText(
    title,
    style: GoogleFonts.ibmPlexSansThai(
      color: color ?? AppColorScheme.dark.textPrimary,
      fontSize: fontSize?.toDouble(),
      fontWeight: FontWeight.w400,
    ),
    overflow: isLimit ? TextOverflow.ellipsis : TextOverflow.visible,
  );
}

AutoSizeText titleCustomText(
  String title, {
  int? fontSize = 14,
  Color? color,
  bool isLimit = false,
  FontWeight fontWeight = FontWeight.w400,
  TextAlign textAlign = TextAlign.left,
}) {
  return AutoSizeText(
    title,
    textAlign: textAlign,
    style: GoogleFonts.ibmPlexSansThai(
      color: color ?? AppColorScheme.dark.textPrimary,
      fontSize: fontSize?.toDouble(),
      fontWeight: fontWeight,
    ),
    overflow: isLimit ? TextOverflow.ellipsis : TextOverflow.visible,
  );
}

/// Standard text style helper — IBM Plex Sans Thai.
TextStyle styleWithColor({
  Color? color,
  int size = 16,
  bool? isBold = false,
  bool? underline = false,
  FontStyle? fontStyle = FontStyle.normal,
  double space = 1.0,
}) => GoogleFonts.ibmPlexSansThai(
  fontSize: size.toDouble(),
  color: color,
  fontStyle: fontStyle,
  decoration: underline! ? TextDecoration.underline : TextDecoration.none,
  fontWeight: isBold == true ? FontWeight.w600 : FontWeight.w400,
);

Divider dividerX({
  thickness = 5,
  height = 5,
  color = const Color(0xFF1e3050),
}) {
  return Divider(
    height: height.toDouble(),
    thickness: thickness.toDouble(),
    color: color,
  );
}

SizedBox spacerH({double h = 20}) => SizedBox(height: h);

SizedBox spacerW({double w = 10}) => SizedBox(width: w);
