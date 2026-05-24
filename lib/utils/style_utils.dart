import 'package:flutter/material.dart';

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

/// Wraps [child] with a white background and rounded corners when in dark mode.
/// Use this around operator logos so they remain legible on dark backgrounds.
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
      color: Colors.white,
      borderRadius: BorderRadius.circular(radius),
    ),
    padding: padding,
    child: child,
  );
}