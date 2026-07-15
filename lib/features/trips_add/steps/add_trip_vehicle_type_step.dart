import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:trainlog_app/app/theme/app_colors.dart';
import 'package:trainlog_app/app/theme/app_theme.dart';
import 'package:trainlog_app/data/models/trip_form_model.dart';
import 'package:trainlog_app/data/models/trips.dart';
import 'package:trainlog_app/l10n/app_localizations.dart';
import 'package:trainlog_app/providers/settings_provider.dart';
import 'package:trainlog_app/utils/map_color_palette.dart';

/// Step 1 of the "Add Trip" wizard: vehicle type selection.
///
/// Shows a bold headline, a muted instruction subtitle and a two-column grid
/// of large selectable cards, one per vehicle category. The selected card is
/// filled with the vehicle colour from the user's map colour palette.
class AddTripVehicleTypeStep extends StatelessWidget {
  const AddTripVehicleTypeStep({super.key});

  /// Vehicle categories offered by the picker, in display order.
  static const List<VehicleType> vehicleTypes = [
    VehicleType.train,
    VehicleType.metro,
    VehicleType.tram,
    VehicleType.bus,
    VehicleType.ferry,
    VehicleType.plane,
    VehicleType.car,
    VehicleType.aerialway,
  ];

  /// Groups of vehicle types sharing the same station kind: switching within
  /// a group keeps the already selected departure/arrival stations.
  static const similarVehicleTypes = [
    {VehicleType.train, VehicleType.metro, VehicleType.funicular, VehicleType.rail},
  ];

  void _selectType(TripFormModel model, VehicleType type) {
    if (type == model.vehicleType) return;

    final keepStations = similarVehicleTypes.any(
      (group) => group.contains(type) && group.contains(model.vehicleType),
    );

    model.setVehicleType(type);

    if (keepStations) return;

    // Station kind changed: reset departure/arrival in the model.
    model.setDeparture(
      name: null,
      lat: null,
      long: null,
      address: null,
      geoMode: false,
    );
    model.setArrival(
      name: null,
      lat: null,
      long: null,
      address: null,
      geoMode: false,
    );
  }

  @override
  Widget build(BuildContext context) {
    final model = context.watch<TripFormModel>();
    final settings = context.watch<SettingsProvider>();
    final colours = MapColorPaletteHelper.getPalette(settings.mapColorPalette);

    final theme = Theme.of(context);
    final loc = AppLocalizations.of(context)!;

    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(24, 8, 24, 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            loc.addTripVehicleTypeTitle,
            style: AppTheme.displayFont.copyWith(
              fontSize: 26,
              fontWeight: FontWeight.w700,
              color: theme.colorScheme.onSurface,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            loc.addTripVehicleTypeSubtitle,
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 20),
          GridView.count(
            crossAxisCount: 2,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            mainAxisSpacing: 12,
            crossAxisSpacing: 12,
            childAspectRatio: 1.75,
            children: [
              for (final type in vehicleTypes)
                _VehicleTypeCard(
                  type: type,
                  colour: colours[type] ?? theme.colorScheme.primary,
                  selected: model.vehicleType == type,
                  onTap: () => _selectType(model, type),
                ),
            ],
          ),
        ],
      ),
    );
  }
}

/// One selectable vehicle category card of the grid.
class _VehicleTypeCard extends StatelessWidget {
  const _VehicleTypeCard({
    required this.type,
    required this.colour,
    required this.selected,
    required this.onTap,
  });

  final VehicleType type;
  final Color colour;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    const radius = 16.0;

    // On a filled card, use navy or white depending on the fill brightness.
    final onColour = ThemeData.estimateBrightnessForColor(colour) == Brightness.dark
        ? Colors.white
        : AppColors.navy;

    final contentColor = selected ? onColour : theme.colorScheme.onSurface;
    final iconColor = selected ? onColour : colour;

    return Material(
      color: selected ? colour : theme.cardColor,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(radius),
        side: selected
            ? BorderSide.none
            : BorderSide(color: theme.colorScheme.outline),
      ),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(10),
                border: Border.all(
                  color: selected
                      ? onColour.withValues(alpha: 0.55)
                      : theme.colorScheme.outline,
                ),
              ),
              child: IconTheme(
                data: IconThemeData(color: iconColor, size: 22),
                child: Center(child: type.icon()),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              type.label(context),
              style: theme.textTheme.labelLarge?.copyWith(
                color: contentColor,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
