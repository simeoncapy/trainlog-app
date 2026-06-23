import 'package:flutter/material.dart';
import 'package:trainlog_app/platform/widget/adaptive_widget_base.dart';

/// A small square (or circular) icon button used in app bars and page headers.
class AdaptiveAppBarSquareButton extends AdaptiveWidget {
  const AdaptiveAppBarSquareButton({
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

  BorderRadius get _radius => BorderRadius.circular(circle ? size / 2 : 10);

  @override
  Widget buildMaterial(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Tooltip(
      message: tooltip,
      child: InkWell(
        onTap: onPressed,
        borderRadius: _radius,
        child: Container(
          width: size,
          height: size,
          decoration: BoxDecoration(
            color: cs.surface,
            borderRadius: _radius,
            border: Border.all(color: cs.outline),
          ),
          child: Icon(icon, size: iconSize, color: cs.onSurface),
        ),
      ),
    );
  }

  @override
  Widget buildCupertino(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return GestureDetector(
      onTap: onPressed,
      child: Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          color: cs.surface,
          borderRadius: _radius,
          border: Border.all(color: cs.outline),
        ),
        child: Icon(icon, size: iconSize, color: cs.onSurface),
      ),
    );
  }
}
