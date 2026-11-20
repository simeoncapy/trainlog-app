import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:trainlog_app/data/models/trips.dart';
import 'package:trainlog_app/platform/glass_filter_parts.dart';
import 'package:trainlog_app/providers/settings_provider.dart';
import 'package:trainlog_app/utils/map_color_palette.dart';
import 'package:trainlog_app/utils/platform_utils.dart';
import 'package:trainlog_app/widgets/vehicle_type_filter_chips.dart';

class AdaptiveVehicleTypeFilterChips extends StatelessWidget {
  final List<VehicleType> availableTypes;
  final Set<VehicleType> selectedTypes;
  final void Function(VehicleType type, bool selected) onTypeToggle;

  const AdaptiveVehicleTypeFilterChips({
    super.key,
    required this.availableTypes,
    required this.selectedTypes,
    required this.onTypeToggle,
  });

  @override
  Widget build(BuildContext context) {
    if (AppPlatform.isApple) {
      return _CupertinoVehicleTypeChips(
        availableTypes: availableTypes,
        selectedTypes: selectedTypes,
        onTypeToggle: onTypeToggle,
      );
    }
    return VehicleTypeFilterChips(
      availableTypes: availableTypes,
      selectedTypes: selectedTypes,
      onTypeToggle: onTypeToggle,
    );
  }
}

/// iOS: vehicle capsules. Selected = filled with the vehicle's map colour;
/// unselected = grey capsule whose icon keeps the map colour.
class _CupertinoVehicleTypeChips extends StatelessWidget {
  final List<VehicleType> availableTypes;
  final Set<VehicleType> selectedTypes;
  final void Function(VehicleType type, bool selected) onTypeToggle;

  const _CupertinoVehicleTypeChips({
    required this.availableTypes,
    required this.selectedTypes,
    required this.onTypeToggle,
  });

  @override
  Widget build(BuildContext context) {
    final settings = context.watch<SettingsProvider>();
    final colours = MapColorPaletteHelper.getPalette(settings.mapColorPalette);
    final fallback = CupertinoTheme.of(context).primaryColor;

    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: [
        for (final type in availableTypes)
          FilterCapsule(
            label: type.label(context),
            leading: type.icon().icon,
            leadingColor: colours[type] ?? fallback,
            selectedColor: colours[type] ?? fallback,
            selected: selectedTypes.contains(type),
            onTap: () => onTypeToggle(type, !selectedTypes.contains(type)),
          ),
      ],
    );
  }
}
