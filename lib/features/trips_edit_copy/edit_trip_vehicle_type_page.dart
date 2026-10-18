import 'package:flutter/material.dart';
import 'package:trainlog_app/data/models/trips.dart';
import 'package:trainlog_app/l10n/app_localizations.dart';
import 'package:trainlog_app/widgets/primary_action_button.dart';
import 'package:trainlog_app/widgets/trip_form/vehicle_type_grid.dart';

/// Isolated "Change vehicle type" page of the edit form.
///
/// The page is pushed on top of the form and pops with the picked
/// [VehicleType] (or null when cancelled). Nothing is sent from here: the
/// type change is applied when the whole edit is saved.
class EditTripVehicleTypePage extends StatefulWidget {
  const EditTripVehicleTypePage({
    super.key,
    required this.currentType,
    this.selectedType,
    this.restrictToTransformable = true,
  });

  /// Vehicle type the trip is stored with, flagged as "current" in the grid.
  final VehicleType currentType;

  /// Vehicle type picked so far in the form, pre-selected in the grid.
  /// Defaults to [currentType].
  final VehicleType? selectedType;

  /// Whether only the types [currentType] can be changed into are offered
  /// (see [VehicleType.canTransform]). The other ones are greyed out.
  final bool restrictToTransformable;

  @override
  State<EditTripVehicleTypePage> createState() =>
      _EditTripVehicleTypePageState();
}

class _EditTripVehicleTypePageState extends State<EditTripVehicleTypePage> {
  late VehicleType _selected = widget.selectedType ?? widget.currentType;

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context)!;

    return Scaffold(
      appBar: AppBar(title: Text(loc.editTripChangeVehicleTypeTitle)),
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(24, 16, 24, 16),
                child: VehicleTypeGrid(
                  selected: _selected,
                  currentType: widget.currentType,
                  currentLabel: loc.editTripVehicleTypeCurrent,
                  isEnabled: widget.restrictToTransformable
                      ? (type) =>
                          VehicleType.canTransform(widget.currentType, type)
                      : null,
                  onSelected: (type) => setState(() => _selected = type),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              child: PrimaryActionButton(
                label: loc.validateButton,
                onPressed: () => Navigator.of(context).pop(_selected),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
