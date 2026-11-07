import 'package:flutter/cupertino.dart' show CupertinoIcons;
import 'package:flutter/material.dart';
import 'package:trainlog_app/platform/liquid_glass.dart';
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
    // iOS 26: header controls are round glass buttons. Material icons are
    // mapped to their SF-style counterparts where the look differs a lot.
    return GlassIconButton(
      icon: _cupertinoIcon(icon),
      onPressed: onPressed,
      tooltip: tooltip,
      size: size + 4,
      iconSize: iconSize,
    );
  }

  static IconData _cupertinoIcon(IconData icon) {
    if (icon == Icons.chevron_left) return CupertinoIcons.chevron_back;
    if (icon == Icons.close) return CupertinoIcons.xmark;
    if (icon == Icons.keyboard_arrow_down) return CupertinoIcons.chevron_down;
    if (icon == Icons.settings_outlined) return CupertinoIcons.gear;
    if (icon == Icons.search) return CupertinoIcons.search;
    if (icon == Icons.search_off) return CupertinoIcons.clear;
    if (icon == Icons.table_chart_outlined) return CupertinoIcons.table;
    if (icon == Icons.view_agenda_outlined) return CupertinoIcons.rectangle_grid_1x2;
    return icon;
  }
}
