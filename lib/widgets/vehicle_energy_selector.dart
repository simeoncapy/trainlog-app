import 'package:flutter/material.dart';
import 'package:trainlog_app/l10n/app_localizations.dart';
import 'package:trainlog_app/platform/adaptive_segmented_button.dart';

enum EnergyType { auto, electric, thermic }

class VehicleEnergySelector extends StatelessWidget {
  final EnergyType value;
  final ValueChanged<EnergyType> onChanged;

  const VehicleEnergySelector({
    super.key,
    required this.value,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context)!;

    return AdaptiveSegmentedButton.build<EnergyType>(
      context: context,
      segments: [
        AdaptiveSegmentedButtonSegment(
          value: EnergyType.auto,
          label: Text(loc.auto),
          icon: const Icon(Icons.auto_awesome),
        ),
        AdaptiveSegmentedButtonSegment(
          value: EnergyType.electric,
          label: Text(loc.energyElectricShort),
          icon: const Icon(Icons.bolt),
        ),
        AdaptiveSegmentedButtonSegment(
          value: EnergyType.thermic,
          label: Text(loc.energyThermicShort),
          icon: const Icon(Icons.local_fire_department),
        ),
      ],
      selectedValue: value,
      onChanged: onChanged,
      showSelectedIcon: false,
      style: const ButtonStyle(
        visualDensity: VisualDensity(horizontal: -2, vertical: -2),
      ),
    );
  }
}
