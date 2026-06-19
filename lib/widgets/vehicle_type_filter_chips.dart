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

    final theme = Theme.of(context);
    const radius = 12.0;

    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: availableTypes.map((type) {
        final selected = selectedTypes.contains(type);
        final paletteColor = colours[type];
        final brightness = paletteColor != null
            ? ThemeData.estimateBrightnessForColor(paletteColor)
            : Brightness.light;
        final selectedTextColor =
            brightness == Brightness.dark ? Colors.white : Colors.black;

        final contentColor =
            selected ? selectedTextColor : theme.colorScheme.onSurface;
        final fillColor = selected
            ? (paletteColor ?? theme.colorScheme.primary)
            : Colors.transparent;

        // Rounded-square button (not a Material pill) matching the filter sheet.
        return Material(
          color: fillColor,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(radius),
            side: selected
                ? BorderSide.none
                : BorderSide(color: theme.colorScheme.outline),
          ),
          clipBehavior: Clip.antiAlias,
          child: InkWell(
            onTap: () => onTypeToggle(type, !selected),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  IconTheme(
                    data: IconThemeData(color: contentColor, size: 18),
                    child: type.icon(),
                  ),
                  const SizedBox(width: 6),
                  Text(
                    type.label(context),
                    style: TextStyle(
                      color: contentColor,
                      fontWeight: selected ? FontWeight.w600 : FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      }).toList(),
    );
  }
}
