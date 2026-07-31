import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:trainlog_app/app/theme/app_theme.dart';
import 'package:trainlog_app/data/models/trip_form_model.dart';
import 'package:trainlog_app/data/models/trips.dart';
import 'package:trainlog_app/l10n/app_localizations.dart';
import 'package:trainlog_app/widgets/trip_form/vehicle_type_grid.dart';

/// Step 1 of the "Add Trip" wizard: vehicle type selection.
///
/// Shows a bold headline, a muted instruction subtitle and the shared
/// [VehicleTypeGrid] of large selectable cards, one per vehicle category.
class AddTripVehicleTypeStep extends StatelessWidget {
  const AddTripVehicleTypeStep({super.key});

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
          VehicleTypeGrid(
            selected: model.vehicleType,
            onSelected: (type) => _selectType(model, type),
          ),
        ],
      ),
    );
  }
}
