import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:trainlog_app/app/app_colors.dart';

import 'adaptive_widget_base.dart';

/// A full-width primary action button.
///
/// - **Material**: [FilledButton] with increased height.
/// - **Cupertino**: [CupertinoButton.filled] with a squared (low-radius)
///   border to match iOS form conventions.
class AdaptiveFilledButton extends AdaptiveWidget {
  final VoidCallback? onPressed;
  final Widget child;
  final FilledButtonColorScheme colorScheme;

  const AdaptiveFilledButton({
    super.key,
    required this.onPressed,
    required this.child,
    this.colorScheme = FilledButtonColorScheme.primary,
  });

  @override
  Widget buildMaterial(BuildContext context) {
    final (bg, fg) = FilledButtonColorScheme.resolveColors(context, colorScheme);
    return FilledButton(
      onPressed: onPressed,
      style: FilledButton.styleFrom(
        minimumSize: const Size.fromHeight(52),
        backgroundColor: bg,
        foregroundColor: fg,
        textStyle: Theme.of(context).textTheme.labelLarge?.copyWith(fontWeight: FontWeight.w600),
      ),
      child: child,
    );
  }

  @override
  Widget buildCupertino(BuildContext context) {
    final (bg, fg) = FilledButtonColorScheme.resolveColors(context, colorScheme);
    return SizedBox(
      width: double.infinity,
      child: CupertinoButton(
        onPressed: onPressed,
        color: bg,
        borderRadius: BorderRadius.circular(8),
        minimumSize: const Size.fromHeight(52),
        child: DefaultTextStyle.merge(
          style: TextStyle(fontWeight: FontWeight.w600, color: fg),
          child: child,
        ),
      ),
    );
  }
}
