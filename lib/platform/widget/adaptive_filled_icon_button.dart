import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:trainlog_app/app/theme/app_colors.dart';

import 'adaptive_widget_base.dart';

class AdaptiveFilledIconButton extends AdaptiveWidget {
  final VoidCallback? onPressed;
  final Widget child;
  final FilledButtonColorScheme colorScheme;

  const AdaptiveFilledIconButton({
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
        minimumSize: const Size(44, 44),
        fixedSize: const Size(44, 44),
        padding: EdgeInsets.zero,
        backgroundColor: bg,
        foregroundColor: fg,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(0),
        ),
      ),
      child: child,
    );
  }

  @override
  Widget buildCupertino(BuildContext context) {
    final (bg, fg) = FilledButtonColorScheme.resolveColors(context, colorScheme);

    return CupertinoButton(
      padding: EdgeInsets.zero,
      minimumSize: const Size(44, 44),
      color: bg,
      borderRadius: BorderRadius.zero,
      onPressed: onPressed,
      child: IconTheme.merge(
        data: IconThemeData(color: fg),
        child: DefaultTextStyle.merge(
          style: TextStyle(color: fg),
          child: child,
        ),
      ),
    );
  }
}