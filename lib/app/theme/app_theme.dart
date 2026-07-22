import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:trainlog_app/app/theme/app_colors.dart';
import 'package:trainlog_app/app/theme/app_nav_bar_theme.dart';
import 'package:trainlog_app/app/theme/app_tab_theme.dart';

/// Trainlog design-system themes and typography.
abstract final class AppTheme {
  // ── Typography ────────────────────────────────────────────────────────────

  /// "Hanken Grotesk" — interface & body copy.
  static TextTheme get _baseTextTheme => GoogleFonts.hankenGroteskTextTheme();

  /// "Space Grotesk" — display / headings.
  static TextStyle get displayFont => GoogleFonts.spaceGrotesk();

  /// "Space Mono" — monospaced figures (times, distances).
  static TextStyle get monoFont => GoogleFonts.spaceMono();

  // ── Light theme ───────────────────────────────────────────────────────────

  static ThemeData get light {
    const colorScheme = ColorScheme(
      brightness: Brightness.light,
      primary: AppColors.amber,
      onPrimary: AppColors.navy,
      primaryContainer: AppColors.amberSoft,
      onPrimaryContainer: AppColors.navy,
      secondary: AppColors.blue,
      onSecondary: Colors.white,
      secondaryContainer: AppColors.blueSoft,
      onSecondaryContainer: AppColors.navy,
      tertiary: AppColors.sky,
      onTertiary: Colors.white,
      error: AppColors.errorLight,
      onError: Colors.white,
      // surface = card / sheet / elevated element (white)
      surface: AppColors.lightBg,
      onSurface: AppColors.lightText,
      onSurfaceVariant: AppColors.lightText2,
      outline: AppColors.lightLine,
      outlineVariant: AppColors.amberSoft,
      shadow: AppColors.navy,
      // inverseSurface = the always-dark branded summary card background
      inverseSurface: AppColors.navy,
      onInverseSurface: AppColors.darkText,
      inversePrimary: AppColors.amberDk,
    );

    final textTheme = _baseTextTheme.apply(
      bodyColor: AppColors.lightText,
      displayColor: AppColors.lightText,
    );

    return ThemeData(
      useMaterial3: true,
      colorScheme: colorScheme,
      // scaffoldBackgroundColor = page canvas (beige)
      scaffoldBackgroundColor: AppColors.lightSurface,
      cardColor: AppColors.lightBg,
      dividerColor: AppColors.lightLine,
      textTheme: textTheme,
      appBarTheme: AppBarTheme(
        backgroundColor: AppColors.lightSurface,
        foregroundColor: AppColors.lightText,
        elevation: 0,
        // A Material AppBar overrides the status bar style set in AppRoot via
        // its own AnnotatedRegion, so keep it aligned with the light theme:
        // dark status bar icons over a transparent bar.
        systemOverlayStyle: const SystemUiOverlayStyle(
          statusBarColor: Colors.transparent,
          statusBarIconBrightness: Brightness.dark,
          statusBarBrightness: Brightness.light,
        ),
        titleTextStyle: GoogleFonts.spaceGrotesk(
          fontSize: 18,
          fontWeight: FontWeight.w600,
          color: AppColors.lightText,
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.amber,
          foregroundColor: AppColors.navy,
        ),
      ),
      floatingActionButtonTheme: const FloatingActionButtonThemeData(
        backgroundColor: AppColors.amber,
        foregroundColor: AppColors.navy,
      ),
      chipTheme: ChipThemeData(
        backgroundColor: AppColors.lightSurface,
        selectedColor: AppColors.amberSoft,
        labelStyle: TextStyle(color: AppColors.lightText),
        side: const BorderSide(color: AppColors.lightLine),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: AppColors.lightSunken,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: AppColors.lightLine),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: AppColors.lightLine),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: AppColors.blue, width: 2),
        ),
      ),
      extensions: [
        AppNavBarColors(
          background: AppColors.lightBg,
          active: AppColors.amber,
          inactive: AppColors.lightText3,
          shadow: Color(0x1F14213D), // navy @ 12 %
        ),
        AppTabColors(
          tabBackground: colorScheme.primaryContainer.withValues(alpha: 0.5), // colorScheme.surface
          selectedBackground: AppColors.lightTabSurface,
          onSelected: AppColors.lightOnTabSurface,
          //onBackground: AppColors.darkText,
        ),
      ],
    );
  }

  // ── Dark theme ────────────────────────────────────────────────────────────

  static ThemeData get dark {
    const colorScheme = ColorScheme(
      brightness: Brightness.dark,
      primary: AppColors.amber,
      onPrimary: AppColors.navy,
      primaryContainer: AppColors.amberDk,
      onPrimaryContainer: AppColors.navy,
      secondary: AppColors.sky,
      onSecondary: AppColors.navy,
      secondaryContainer: AppColors.blue,
      onSecondaryContainer: Colors.white,
      tertiary: AppColors.blueSoft,
      onTertiary: AppColors.navy,
      error: AppColors.errorDark,
      onError: Colors.white,
      surface: AppColors.darkSurface,
      onSurface: AppColors.darkText,
      onSurfaceVariant: AppColors.darkText2,
      outline: AppColors.darkLine,
      outlineVariant: AppColors.navy,
      shadow: Colors.black,
      // inverseSurface = the always-light branded summary card background
      inverseSurface: AppColors.lightBg,
      onInverseSurface: AppColors.lightText,
      inversePrimary: AppColors.amberDk,
    );

    final textTheme = _baseTextTheme.apply(
      bodyColor: AppColors.darkText,
      displayColor: AppColors.darkText,
    );

    return ThemeData(
      useMaterial3: true,
      colorScheme: colorScheme,
      scaffoldBackgroundColor: AppColors.darkBg,
      cardColor: AppColors.darkSurface,
      dividerColor: AppColors.darkLine,
      textTheme: textTheme,
      appBarTheme: AppBarTheme(
        backgroundColor: AppColors.darkBg,
        foregroundColor: AppColors.darkText,
        elevation: 0,
        // A Material AppBar overrides the status bar style set in AppRoot via
        // its own AnnotatedRegion, so keep it aligned with the dark theme:
        // light status bar icons over a transparent bar.
        systemOverlayStyle: const SystemUiOverlayStyle(
          statusBarColor: Colors.transparent,
          statusBarIconBrightness: Brightness.light,
          statusBarBrightness: Brightness.dark,
        ),
        titleTextStyle: GoogleFonts.spaceGrotesk(
          fontSize: 18,
          fontWeight: FontWeight.w600,
          color: AppColors.darkText,
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.amber,
          foregroundColor: AppColors.navy,
        ),
      ),
      floatingActionButtonTheme: const FloatingActionButtonThemeData(
        backgroundColor: AppColors.amber,
        foregroundColor: AppColors.navy,
      ),
      chipTheme: ChipThemeData(
        backgroundColor: AppColors.darkSurface,
        selectedColor: AppColors.darkElevated,
        labelStyle: TextStyle(color: AppColors.darkText),
        side: const BorderSide(color: AppColors.darkLine),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: AppColors.darkElevated,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: AppColors.darkLine),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: AppColors.darkLine),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: AppColors.sky, width: 2),
        ),
      ),
      extensions: [
        const AppNavBarColors(
          background: AppColors.darkElevated,
          active: AppColors.amber,
          inactive: AppColors.darkText3,
          shadow: Color(0x66000000), // black @ 40 %
        ),
        AppTabColors(
          tabBackground: colorScheme.secondary.withValues(alpha: 0.1),
          selectedBackground: AppColors.darkTabSurface,
          onSelected: AppColors.darkOnTabSurface,
          //onBackground: AppColors.darkText,
        ),
      ],
    );
  }

  /// Light-theme surface colour — used as logo background in dark mode so
  /// operator logos (designed for light backgrounds) remain legible.
  static const Color operatorLogoBg = AppColors.lightSurface;
}
