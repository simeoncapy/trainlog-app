import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:trainlog_app/data/models/trips.dart';
import 'package:trainlog_app/providers/settings_provider.dart';
import 'package:trainlog_app/utils/map_color_palette.dart';

/// Two-column grid of large selectable vehicle category cards.
///
/// Unselected cards show their icon in the vehicle colour from the user's map
/// colour palette; the selected card is filled with the theme primary colour.
/// Used by the first step of the add-trip wizard and by the isolated
/// "Change vehicle type" page of the edit form.
class VehicleTypeGrid extends StatelessWidget {
  const VehicleTypeGrid({
    super.key,
    required this.selected,
    required this.onSelected,
    this.currentLabel,
    this.currentType,
  });

  /// Vehicle categories offered by the picker: every vehicle type a trip can
  /// be created with.
  static final List<VehicleType> vehicleTypes = VehicleType.values
      .where((v) => v != VehicleType.unknown && v != VehicleType.poi)
      .toList();

  final VehicleType? selected;
  final ValueChanged<VehicleType> onSelected;

  /// Caption marking [currentType] as the type the trip already has (e.g.
  /// "CURRENT"). Ignored when [currentType] is null.
  final String? currentLabel;
  final VehicleType? currentType;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final settings = context.watch<SettingsProvider>();
    final colours = MapColorPaletteHelper.getPalette(settings.mapColorPalette);

    return GridView.count(
      crossAxisCount: 2,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      mainAxisSpacing: 12,
      crossAxisSpacing: 12,
      childAspectRatio: 1.6,
      children: [
        for (final type in vehicleTypes)
          VehicleTypeCard(
            type: type,
            colour: colours[type] ?? theme.colorScheme.primary,
            selected: selected == type,
            caption: (currentType != null && currentType == type)
                ? currentLabel
                : null,
            onTap: () => onSelected(type),
          ),
      ],
    );
  }
}

/// One selectable vehicle category card of a [VehicleTypeGrid].
class VehicleTypeCard extends StatelessWidget {
  const VehicleTypeCard({
    super.key,
    required this.type,
    required this.colour,
    required this.selected,
    required this.onTap,
    this.caption,
  });

  final VehicleType type;
  final Color colour;
  final bool selected;
  final VoidCallback onTap;

  /// Small uppercase caption under the label (e.g. the current vehicle type).
  final String? caption;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    const radius = 16.0;

    // Selected cards fill with the theme primary colour; the vehicle palette
    // colour is only used for the icon of unselected cards.
    final contentColor = selected ? cs.onPrimary : cs.onSurface;
    final iconColor = selected ? cs.onPrimary : colour;

    return Material(
      color: selected ? cs.primary : theme.cardColor,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(radius),
        side: selected ? BorderSide.none : BorderSide(color: cs.outline),
      ),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            IconTheme(
              data: IconThemeData(color: iconColor, size: 28),
              child: type.icon(),
            ),
            const SizedBox(height: 8),
            Flexible(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 12),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      type.label(context),
                      textAlign: TextAlign.center,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: theme.textTheme.labelLarge?.copyWith(
                        color: contentColor,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    if (caption != null)
                      Text(
                        caption!.toUpperCase(),
                        textAlign: TextAlign.center,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: theme.textTheme.labelSmall?.copyWith(
                          color: contentColor.withValues(alpha: 0.8),
                          fontWeight: FontWeight.w600,
                          letterSpacing: 1.2,
                        ),
                      ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
