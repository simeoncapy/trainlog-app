import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:trainlog_app/ui/tokens/app_colors.dart';
import 'package:trainlog_app/core/data/models/trips.dart';
import 'package:trainlog_app/core/providers/settings_provider.dart';
import 'package:trainlog_app/utils/map_color_palette.dart';

/// Resolves the route/vehicle palette colour for [trip] using the user's
/// selected map colour palette. Falls back to the theme primary colour when the
/// palette has no entry for the trip's vehicle type.
Color tripRouteColor(BuildContext context, Trips trip) {
  final settings = context.read<SettingsProvider>();
  final palette = MapColorPaletteHelper.getPalette(settings.mapColorPalette);
  return palette[trip.type] ?? Theme.of(context).colorScheme.primary;
}

/// Adaptive fill colour for the small surfaces in the sheet (metric cards,
/// pills, chips, the notes box). Kept explicit so it stays visible on both the
/// light (paper) and dark (navy) sheet backgrounds — the iOS system fills were
/// too faint against the translucent Cupertino card.
Color detailSurfaceColor(BuildContext context) {
  final isDark = Theme.of(context).brightness == Brightness.dark;
  return isDark ? AppColors.darkElevated : AppColors.lightSunken;
}

/// Hairline border that pairs with [detailSurfaceColor].
Color detailBorderColor(BuildContext context) {
  final isDark = Theme.of(context).brightness == Brightness.dark;
  return isDark ? Colors.white.withValues(alpha: 0.08) : AppColors.lightLine;
}

/// How the sections of the sheet look in the design that hosts them. The
/// Material sheet uses the defaults; the iOS sheet provides its own above
/// its content.
class TripDetailsStyle extends InheritedWidget {
  const TripDetailsStyle({
    super.key,
    required super.child,
    this.fill,
    this.metricRadius = 16,
    this.closeIcon = Icons.keyboard_arrow_down,
  });

  /// Background of the small surfaces; null for the default (solid surface
  /// with a hairline border).
  final BoxDecoration Function(BuildContext context, BorderRadius radius)?
  fill;

  /// Corner radius of the metric cards.
  final double metricRadius;

  /// Icon of the header's close button.
  final IconData closeIcon;

  static const _defaults = TripDetailsStyle(child: SizedBox.shrink());

  static TripDetailsStyle of(BuildContext context) =>
      context.dependOnInheritedWidgetOfExactType<TripDetailsStyle>() ??
      _defaults;

  @override
  bool updateShouldNotify(TripDetailsStyle old) =>
      fill != old.fill ||
      metricRadius != old.metricRadius ||
      closeIcon != old.closeIcon;
}

/// Background of the small surfaces in the sheet (metric cards, duration
/// pill, visibility chip, notes box), from [TripDetailsStyle]. [capsule]
/// gives the fully rounded pill shape.
BoxDecoration detailFillDecoration(
  BuildContext context, {
  double radius = 12,
  bool capsule = false,
}) {
  final borderRadius = BorderRadius.circular(capsule ? 999 : radius);
  final fill = TripDetailsStyle.of(context).fill;
  if (fill != null) return fill(context, borderRadius);
  return BoxDecoration(
    color: detailSurfaceColor(context),
    borderRadius: borderRadius,
    border: Border.all(color: detailBorderColor(context)),
  );
}

/// Muted foreground colour for secondary text/icons inside the sheet.
Color detailMutedColor(BuildContext context) {
  final isDark = Theme.of(context).brightness == Brightness.dark;
  return isDark ? AppColors.darkText2 : AppColors.lightText3;
}

/// Small uppercase amber/primary section header used throughout the redesigned
/// trip details sheet (e.g. "DETAILS", "OPERATOR", "TICKET").
class TripDetailsSectionHeader extends StatelessWidget {
  final String label;

  const TripDetailsSectionHeader(this.label, {super.key});

  @override
  Widget build(BuildContext context) {
    return Text(
      label.toUpperCase(),
      style: TextStyle(
        color: Theme.of(context).colorScheme.primary,
        fontWeight: FontWeight.w700,
        fontSize: 12,
        letterSpacing: 1.1,
      ),
    );
  }
}

