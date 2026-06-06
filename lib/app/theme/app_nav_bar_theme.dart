import 'package:flutter/material.dart';

/// ThemeExtension that supplies colours for the floating bottom nav bar.
/// Consumed by AdaptiveBottomNavBar via Theme.of(context).extension<AppNavBarColors>().
class AppNavBarColors extends ThemeExtension<AppNavBarColors> {
  final Color background;
  final Color active;
  final Color inactive;
  final Color shadow;

  const AppNavBarColors({
    required this.background,
    required this.active,
    required this.inactive,
    required this.shadow,
  });

  @override
  AppNavBarColors copyWith({
    Color? background,
    Color? active,
    Color? inactive,
    Color? shadow,
  }) =>
      AppNavBarColors(
        background: background ?? this.background,
        active: active ?? this.active,
        inactive: inactive ?? this.inactive,
        shadow: shadow ?? this.shadow,
      );

  @override
  AppNavBarColors lerp(ThemeExtension<AppNavBarColors>? other, double t) {
    if (other is! AppNavBarColors) return this;
    return AppNavBarColors(
      background: Color.lerp(background, other.background, t)!,
      active: Color.lerp(active, other.active, t)!,
      inactive: Color.lerp(inactive, other.inactive, t)!,
      shadow: Color.lerp(shadow, other.shadow, t)!,
    );
  }
}
