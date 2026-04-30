import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:trainlog_app/data/models/trips.dart';
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

    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: availableTypes.map((type) {
        final selected = selectedTypes.contains(type);
        final backgroundColor = colours[type];
        final brightness = backgroundColor != null
            ? ThemeData.estimateBrightnessForColor(backgroundColor)
            : Brightness.light;
        final contentColor =
            brightness == Brightness.dark ? CupertinoColors.white : CupertinoColors.black;

        final bgColor = selected
            ? (backgroundColor ?? CupertinoTheme.of(context).primaryColor)
            : CupertinoColors.tertiarySystemFill.resolveFrom(context);
        final fgColor = selected
            ? contentColor
            : CupertinoColors.secondaryLabel.resolveFrom(context);

        return GestureDetector(
          onTap: () => onTypeToggle(type, !selected),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
            decoration: BoxDecoration(
              color: bgColor,
              borderRadius: BorderRadius.circular(20),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                IconTheme(
                  data: IconThemeData(color: fgColor, size: 16),
                  child: type.icon(),
                ),
                const SizedBox(width: 5),
                Text(
                  type.label(context),
                  style: TextStyle(
                    color: fgColor,
                    fontSize: 14,
                    fontWeight: selected ? FontWeight.w600 : FontWeight.normal,
                  ),
                ),
              ],
            ),
          ),
        );
      }).toList(),
    );
  }
}
