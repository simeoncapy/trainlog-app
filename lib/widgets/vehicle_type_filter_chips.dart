import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:trainlog_app/data/models/trips.dart';
import 'package:trainlog_app/utils/map_color_palette.dart';
import 'package:trainlog_app/providers/settings_provider.dart';

class VehicleTypeFilterChips extends StatelessWidget {
  final List<VehicleType> availableTypes;
  final Set<VehicleType> selectedTypes;
  final void Function(VehicleType type, bool selected) onTypeToggle;

  const VehicleTypeFilterChips({
    super.key,
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
        final textColor = brightness == Brightness.dark ? Colors.white : Colors.black;

        return FilterChip(
          label: Text(
            type.label(context),
            style: TextStyle(
              color: selected
                  ? textColor
                  : Theme.of(context).chipTheme.labelStyle?.color,
            ),
          ),
          avatar: IconTheme(
            data: IconThemeData(
              color: selected
                  ? textColor
                  : Theme.of(context).chipTheme.labelStyle?.color,
            ),
            child: type.icon(),
          ),
          selectedColor: backgroundColor,
          selected: selected,
          showCheckmark: false,
          onSelected: (bool isSelected) {
            onTypeToggle(type, isSelected);
          },
        );
      }).toList(),
    );
  }
}
