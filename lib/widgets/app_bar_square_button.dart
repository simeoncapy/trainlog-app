import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:trainlog_app/utils/platform_utils.dart';

/// A small square (or circular) icon button used in app bars and page headers.
class AppBarSquareButton extends StatelessWidget {
  const AppBarSquareButton({
    super.key,
    required this.icon,
    required this.onPressed,
    this.tooltip = '',
    this.size = 38,
    this.iconSize = 20,
    this.circle = false,
  });

  final IconData icon;
  final VoidCallback onPressed;
  final String tooltip;
  final double size;
  final double iconSize;

  /// When true, renders with a fully circular border radius.
  final bool circle;

  @override
  Widget build(BuildContext context) {
    final radius = BorderRadius.circular(circle ? size / 2 : 10);

    if (AppPlatform.isApple) {
      return CupertinoButton(
        padding: EdgeInsets.zero,
        onPressed: onPressed,
        child: Container(
          width: size,
          height: size,
          decoration: BoxDecoration(
            color: CupertinoColors.systemFill.resolveFrom(context),
            borderRadius: radius,
          ),
          child: Icon(icon, size: iconSize, color: CupertinoTheme.of(context).primaryColor),
        ),
      );
    }

    final cs = Theme.of(context).colorScheme;
    return Tooltip(
      message: tooltip,
      child: InkWell(
        onTap: onPressed,
        borderRadius: radius,
        child: Container(
          width: size,
          height: size,
          decoration: BoxDecoration(
            color: cs.surface,
            borderRadius: radius,
            border: Border.all(color: cs.outlineVariant),
          ),
          child: Icon(icon, size: iconSize, color: cs.onSurface),
        ),
      ),
    );
  }
}
