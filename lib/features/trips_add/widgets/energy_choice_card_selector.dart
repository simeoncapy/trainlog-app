import 'package:flutter/material.dart';
import 'package:trainlog_app/features/trips_add/widgets/choice_card_selector.dart';
import 'package:trainlog_app/l10n/app_localizations.dart';
import 'package:trainlog_app/widgets/vehicle_energy_selector.dart';

/// Energy type of a trip as a row of [ChoiceCardSelector] cards
/// (Auto / Electric / Fuel).
///
/// The card row is the trip form flavour of the selector — the segmented
/// [VehicleEnergySelector] stays the compact one used outside the forms.
/// Shared by the add-trip ticket step and the edit/duplicate ticket section.
class EnergyChoiceCardSelector extends StatelessWidget {
  const EnergyChoiceCardSelector({
    super.key,
    required this.value,
    required this.onChanged,
  });

  final EnergyType value;
  final ValueChanged<EnergyType> onChanged;

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context)!;

    return ChoiceCardSelector<EnergyType>(
      options: [
        ChoiceCardOption(
          value: EnergyType.auto,
          icon: Icons.auto_awesome,
          label: loc.auto,
        ),
        ChoiceCardOption(
          value: EnergyType.electric,
          icon: Icons.bolt,
          label: loc.energyElectric,
        ),
        ChoiceCardOption(
          value: EnergyType.thermic,
          icon: Icons.local_fire_department,
          label: loc.energyThermic,
        ),
      ],
      value: value,
      onChanged: onChanged,
    );
  }
}
