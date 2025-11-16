import 'package:flutter/material.dart';
import 'package:trainlog_app/l10n/app_localizations.dart';

enum EnergyType { auto, electric, thermic }

class VehicleEnergySelector extends StatefulWidget {
  const VehicleEnergySelector({super.key});

  @override
  State<VehicleEnergySelector> createState() => _VehicleEnergySelectorState();
}

class _VehicleEnergySelectorState extends State<VehicleEnergySelector> {
  EnergyType selected = EnergyType.auto;

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context)!;
    return SegmentedButton<EnergyType>(
      segments: [
        ButtonSegment(
          value: EnergyType.auto,
          label: Text(loc.auto),
          icon: Icon(Icons.auto_awesome),
        ),
        ButtonSegment(
          value: EnergyType.electric,
          label: Text(loc.energyElectric),
          icon: Icon(Icons.bolt),
        ),
        ButtonSegment(
          value: EnergyType.thermic,
          label: Text(loc.energyThermic),
          icon: Icon(Icons.local_fire_department),
        ),
      ],
      selected: {selected},
      onSelectionChanged: (newSelection) {
        setState(() {
          selected = newSelection.first;
        });
      },
      showSelectedIcon: false,
      style: const ButtonStyle(
        visualDensity: VisualDensity(horizontal: -2, vertical: -2),
      ),
    );
  }
}
