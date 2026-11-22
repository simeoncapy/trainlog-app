import 'package:flutter/material.dart';

/// ThemeExtension that supplies colours for the tabs selector.
class AppTabColors extends ThemeExtension<AppTabColors> {
  final Color tabBackground;
  final Color selectedBackground;
  final Color onSelected;
  final Color? _onBackground;

  /// Returns [onSelected] when no specific background text colour is defined.
  Color get onBackground => _onBackground ?? onSelected;

  const AppTabColors({
    required this.tabBackground,
    required this.selectedBackground,
    required this.onSelected,
    Color? onBackground,
  }) : _onBackground = onBackground;

  @override
  AppTabColors copyWith({
    Color? tabBackground,
    Color? selectedBackground,
    Color? onSelected,
    Color? onBackground,
  }) =>
      AppTabColors(
        tabBackground: tabBackground ?? this.tabBackground,
        selectedBackground: selectedBackground ?? this.selectedBackground,
        onSelected: onSelected ?? this.onSelected,
        onBackground: onBackground ?? _onBackground,
      );

  @override
  AppTabColors lerp(ThemeExtension<AppTabColors>? other, double t) {
    if (other is! AppTabColors) return this;

    return AppTabColors(
      tabBackground: Color.lerp(tabBackground, other.tabBackground, t)!,
      selectedBackground: Color.lerp(selectedBackground, other.selectedBackground, t)!,
      onSelected: Color.lerp(onSelected, other.onSelected, t)!,
      onBackground: Color.lerp(_onBackground, other._onBackground, t),
    );
  }
}