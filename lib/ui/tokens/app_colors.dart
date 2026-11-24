import 'package:flutter/material.dart';

/// Trainlog design-system colour constants.
/// Mirrors the "Full palette — light & dark" spec.
abstract final class AppColors {
  // ── Brand & accent (shared across both themes) ──────────────────────────

  /// Amber · primary  #FBA311  --amber
  static const Color amber = Color(0xFFFBA311);

  /// Amber pressed  #E08C00  --amber-dk
  static const Color amberDk = Color(0xFFE08C00);

  /// Amber tint  #FFF1D6  --amber-soft
  static const Color amberSoft = Color(0xFFFFF1D6);

  /// Navy · ink  #14213D  --navy
  static const Color navy = Color(0xFF14213D);

  /// Blue · accent  #3772FF  --blue
  static const Color blue = Color(0xFF3772FF);

  /// Blue tint  #E7EEFF  --blue-soft
  static const Color blueSoft = Color(0xFFE7EEFF);

  /// Sky · accent/dark  #6E9BFF  --sky
  static const Color sky = Color(0xFF6E9BFF);

  // ── Light theme surfaces ─────────────────────────────────────────────────

  /// Base / Paper  --bg (light)
  static const Color lightBg = Color(0xFFFFFFFF);

  /// Surface  --surface (light)
  static const Color lightSurface = Color(0xFFF5F4F0);

  /// Sunken  --sunken (light)
  static const Color lightSunken = Color(0xFFEEECE8);

  /// Tab surface  --tab-surface (light)
  static const Color lightTabSurface = Color(0xFFE5E5EA);

  // ── Light theme text ─────────────────────────────────────────────────────

  /// Primary text (light)  --text
  static const Color lightText = navy;

  /// Secondary text (light)  --text-2
  static const Color lightText2 = Color(0xFF4A5568);

  /// Tertiary text (light)  --text-3
  static const Color lightText3 = Color(0xFF718096);

  /// Hairline / border (light)  #E7E3D9  --line
  static const Color lightLine = Color(0xFFE7E3D9);

  /// Tab on surface  --tab-on-surface (light)
  static const Color lightOnTabSurface = Color(0xFF3A3A3C);

  // ── Dark theme surfaces ──────────────────────────────────────────────────

  /// Base  --bg (dark)
  static const Color darkBg = Color(0xFF0E1117);

  /// Surface  --surface (dark)
  static const Color darkSurface = Color(0xFF161C27);

  /// Elevated  --elevated (dark)
  static const Color darkElevated = Color(0xFF1E2533);

  /// Tab surface  --tab-surface (dark)
  static const Color darkTabSurface = Color(0xFF3A3A3C);

  // ── Dark theme text ──────────────────────────────────────────────────────

  /// Primary text (dark)  --text
  static const Color darkText = Color(0xFFF0F2F5);

  /// Secondary text (dark)  --text-2
  static const Color darkText2 = Color(0xFFA0AEC0);

  /// Tertiary text (dark)  --text-3
  static const Color darkText3 = Color(0xFF718096);

  /// Hairline / border (dark)  rgba(255,255,255,.09)  --line
  static const Color darkLine = Color(0x17FFFFFF);

  /// Tab on surface  --tab-on-surface (dark)
  static const Color darkOnTabSurface = Color(0xFFEEEEF0);

  // ── Semantic ─────────────────────────────────────────────────────────────

  /// Success / early — light  #1E9E5A
  static const Color successLight = Color(0xFF1E9E5A);

  /// Success / early — dark  #43C788
  static const Color successDark = Color(0xFF43C788);

  /// Error / late — light  #E5484D
  static const Color errorLight = Color(0xFFE5484D);

  /// Error / late — dark  #FF6B70
  static const Color errorDark = Color(0xFFFF6B70);

  /// Warning — light  #E08C00
  static const Color warningLight = amberDk;

  /// Warning — dark  #FBA311
  static const Color warningDark = amber;

  // ── Transport mode colours (data-viz, shared) ────────────────────────────

  /// Train
  static const Color modeTrain = Color(0xFFFBA311);

  /// Metro
  static const Color modeMetro = Color(0xFF3772FF);

  /// Tram
  static const Color modeTram = Color(0xFF00B896);

  /// Bus
  static const Color modeBus = Color(0xFF9B59B6);

  /// Ferry
  static const Color modeFerry = Color(0xFF00BCD4);

  /// Air / plane
  static const Color modeAir = Color(0xFFE91E8C);

  /// Walk
  static const Color modeWalk = Color(0xFF9E9E9E);

  // ── Extra accent colours ─────────────────────────────────────────────────

  /// Violet · accent  #7C3AED
  static const Color violet = Color(0xFF7C3AED);

  /// Violet tint  #EDE9FE
  static const Color violetSoft = Color(0xFFEDE9FE);

  /// Early / success (shared alias for green)
  static const Color early = successLight;

  static const Color late = errorLight;
}


enum FilledButtonColorScheme { 
  primary, 
  secondary, 
  tertiary, 
  error, 
  warn, 
  success,
  floating;

  static (Color?, Color?) resolveColors(BuildContext context, FilledButtonColorScheme colorScheme) {
    final cs = Theme.of(context).colorScheme;
    final isLight = Theme.of(context).brightness == Brightness.light;
    return switch (colorScheme) {
      FilledButtonColorScheme.primary => (cs.primary, cs.onPrimary),
      FilledButtonColorScheme.secondary => (cs.secondary, cs.onSecondary),
      FilledButtonColorScheme.tertiary => (cs.tertiary, cs.onTertiary),
      FilledButtonColorScheme.error => (cs.error, cs.onError),
      FilledButtonColorScheme.warn => (isLight ? AppColors.warningLight : AppColors.warningDark, 
                                       isLight ? AppColors.navy : AppColors.navy),
      FilledButtonColorScheme.success => (isLight ? AppColors.successLight : AppColors.successDark, 
                                          isLight ? AppColors.navy : AppColors.navy),
      FilledButtonColorScheme.floating => (isLight ? AppColors.lightBg : AppColors.darkElevated,
                                           isLight ? AppColors.navy : AppColors.darkText),
    };
  }  
}