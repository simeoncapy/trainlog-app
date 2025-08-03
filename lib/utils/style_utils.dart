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