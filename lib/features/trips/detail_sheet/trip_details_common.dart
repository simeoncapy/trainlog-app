import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:trainlog_app/data/models/trips.dart';
import 'package:trainlog_app/providers/settings_provider.dart';
import 'package:trainlog_app/utils/map_color_palette.dart';

/// Resolves the route/vehicle palette colour for [trip] using the user's
/// selected map colour palette. Falls back to the theme primary colour when the
/// palette has no entry for the trip's vehicle type.
Color tripRouteColor(BuildContext context, Trips trip) {
  final settings = context.read<SettingsProvider>();
  final palette = MapColorPaletteHelper.getPalette(settings.mapColorPalette);
  return palette[trip.type] ?? Theme.of(context).colorScheme.primary;
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
