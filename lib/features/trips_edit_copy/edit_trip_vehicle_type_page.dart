import 'package:flutter/material.dart';
import 'package:trainlog_app/data/models/trips.dart';
import 'package:trainlog_app/l10n/app_localizations.dart';
import 'package:trainlog_app/widgets/error_banner.dart';
import 'package:trainlog_app/widgets/primary_action_button.dart';
import 'package:trainlog_app/widgets/trip_form/vehicle_type_grid.dart';

/// Isolated "Change vehicle type" page of the edit form.
///
/// Changing the vehicle type is not part of the form submission — it is its
/// own update, which the banner spells out — so the page is pushed on top of
/// the form and pops with the picked [VehicleType] (or null when cancelled).
///
/// UI only for now: applying the change (vehicle material and seat resets)
/// is left to the caller once the API supports it.
class EditTripVehicleTypePage extends StatefulWidget {
  const EditTripVehicleTypePage({super.key, required this.currentType});

  /// Vehicle type the trip currently has, pre-selected and flagged in the grid.
  final VehicleType currentType;

  @override
  State<EditTripVehicleTypePage> createState() =>
      _EditTripVehicleTypePageState();
}

class _EditTripVehicleTypePageState extends State<EditTripVehicleTypePage> {
  late VehicleType _selected = widget.currentType;

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context)!;

    return Scaffold(
      appBar: AppBar(title: Text(loc.editTripChangeVehicleTypeTitle)),
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 12, 24, 0),
              child: ErrorBanner(
                message: loc.editTripChangeVehicleTypeWarning,
                severity: ErrorSeverity.warning,
              ),
            ),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(24, 16, 24, 16),
                child: VehicleTypeGrid(
                  selected: _selected,
                  currentType: widget.currentType,
                  currentLabel: loc.editTripVehicleTypeCurrent,
                  onSelected: (type) => setState(() => _selected = type),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              child: PrimaryActionButton(
                label: loc.editTripUpdateVehicleTypeButton,
                onPressed: () => Navigator.of(context).pop(_selected),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
