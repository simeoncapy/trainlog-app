import 'package:flutter/material.dart';
import 'package:trainlog_app/app/app_globals.dart';

ButtonStyle buttonStyleHelper(Color background, Color foreground)
  {
      return ButtonStyle(
        backgroundColor: WidgetStateProperty.resolveWith<Color?>((states) {
          if (states.contains(WidgetState.disabled)) {
            return background.withValues(alpha: 0.3);
          }
          return background;
        }),
        foregroundColor: WidgetStateProperty.resolveWith<Color?>((states) {
          if (states.contains(WidgetState.disabled)) {
            return foreground.withValues(alpha: 0.5);
          }
          return foreground;
        }),
      );
  }

/// Wraps [child] with the light-theme surface colour and rounded corners when
/// in dark mode. Use this around operator logos so they remain legible on dark
/// backgrounds (most logos are designed for light/white backgrounds).
Widget withOperatorLogoBg(
  BuildContext context,
  Widget child, {
  double radius = 6.0,
  EdgeInsets padding = const EdgeInsets.all(3),
}) {
  final isDark = Theme.of(context).brightness == Brightness.dark;
  if (!isDark) return child;
  return Container(
    decoration: BoxDecoration(
      color: kLightThemeSurface,
      borderRadius: BorderRadius.circular(radius),
    ),
    padding: padding,
    child: child,
  );
}