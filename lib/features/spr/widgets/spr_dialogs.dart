import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:trainlog_app/app/theme/app_theme.dart';
import 'package:trainlog_app/data/models/trips.dart';
import 'package:trainlog_app/l10n/app_localizations.dart';
import 'package:trainlog_app/platform/adaptive_button.dart';
import 'package:trainlog_app/platform/adaptive_dialog.dart';
import 'package:trainlog_app/providers/pre_record_provider.dart';
import 'package:trainlog_app/providers/settings_provider.dart';
import 'package:trainlog_app/utils/map_color_palette.dart';
import 'package:trainlog_app/utils/number_formatter.dart';

/// Lets the user disambiguate within the rail family (train/metro/rail).
/// Returns null when dismissed.
Future<VehicleType?> showRailDisambiguationDialog(BuildContext context) async {
  final loc = AppLocalizations.of(context)!;

  return AdaptiveDialog.showCustom<VehicleType>(
    context: context,
    barrierDismissible: false,
    builder: (ctx) {
      final theme = Theme.of(ctx);
      return Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              loc.prerecorderSelectRailType,
              style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            for (final type in [VehicleType.train, VehicleType.metro, VehicleType.rail])
              ListTile(
                leading: type.icon(),
                title: Text(type.label(context)),
                onTap: () => AdaptiveDialog.pop(ctx, type),
              ),
            const SizedBox(height: 8),
            SizedBox(
              width: double.infinity,
              child: AdaptiveButton.build(
                context: ctx,
                type: AdaptiveButtonType.secondary,
                onPressed: () => AdaptiveDialog.pop(ctx, null),
                label: Text(MaterialLocalizations.of(ctx).cancelButtonLabel),
              ),
            ),
          ],
        ),
      );
    },
  );
}

/// Full vehicle type picker, used when both selected records have an
/// unknown type. Returns null when dismissed.
Future<VehicleType?> showVehicleTypePickerDialog(BuildContext context) async {
  final loc = AppLocalizations.of(context)!;
  VehicleType? selected;

  return AdaptiveDialog.showCustom<VehicleType>(
    context: context,
    barrierDismissible: false,
    builder: (ctx) {
      final theme = Theme.of(ctx);
      return StatefulBuilder(
        builder: (ctx, setDialogState) => Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                loc.prerecorderSelectVehicleType,
                style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),
              DropdownButtonFormField<VehicleType>(
                decoration: InputDecoration(
                  labelText: loc.addTripTransportationMode,
                  border: const OutlineInputBorder(),
                ),
                initialValue: selected,
                items: VehicleType.values
                    .where((v) => v != VehicleType.unknown && v != VehicleType.poi)
                    .map(
                      (type) => DropdownMenuItem(
                        value: type,
                        child: Row(
                          children: [
                            type.icon(),
                            const SizedBox(width: 8),
                            Text(type.label(context)),
                          ],
                        ),
                      ),
                    )
                    .toList(),
                onChanged: (v) => setDialogState(() => selected = v),
              ),
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                child: AdaptiveButton.build(
                  context: ctx,
                  type: AdaptiveButtonType.primary,
                  onPressed: selected != null
                      ? () => AdaptiveDialog.pop(ctx, selected)
                      : null,
                  label: Text(MaterialLocalizations.of(ctx).okButtonLabel),
                ),
              ),
              const SizedBox(height: 8),
              SizedBox(
                width: double.infinity,
                child: AdaptiveButton.build(
                  context: ctx,
                  type: AdaptiveButtonType.secondary,
                  onPressed: () => AdaptiveDialog.pop(ctx, null),
                  label: Text(MaterialLocalizations.of(ctx).cancelButtonLabel),
                ),
              ),
            ],
          ),
        ),
      );
    },
  );
}

/// Lets the user pick among several nearby station candidates, or declare
/// the station unknown. Returns null when dismissed (tap outside).
Future<StationChoice?> showStationSelectionDialog(
  BuildContext context,
  List<StationCandidate> stations,
) async {
  final loc = AppLocalizations.of(context)!;
  final settings = context.read<SettingsProvider>();
  final palette = MapColorPaletteHelper.getPalette(settings.mapColorPalette);

  return AdaptiveDialog.showCustom<StationChoice>(
    context: context,
    maxWidth: 500,
    maxHeightFactor: 0.6,
    barrierDismissible: true, // tap outside => null
    builder: (ctx) {
      final theme = Theme.of(ctx); // ok even in Cupertino pages

      return Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Text(
              loc.prerecorderSelectStation,
              style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
              textAlign: TextAlign.center,
            ),
          ),
          Padding(
            padding: const EdgeInsets.only(left: 8, right: 8, bottom: 4),
            child: Text(loc.prerecorderStationsFound(stations.length)),
          ),
          Expanded(
            child: ListView.separated(
              itemCount: stations.length,
              separatorBuilder: (ctx, _) => Divider(
                height: 1,
                indent: 16,
                endIndent: 16,
                color: theme.colorScheme.outline,
              ),
              itemBuilder: (ctx, index) {
                final (name, address, type, distance) = stations[index];
                final typeColor = palette[type] ?? theme.colorScheme.primary;

                return InkWell(
                  onTap: () => AdaptiveDialog.pop(ctx, (name, address, type)),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    child: Row(
                      children: [
                        Container(
                          width: 36,
                          height: 36,
                          decoration: BoxDecoration(
                            color: typeColor,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Center(
                            child: IconTheme(
                              data: const IconThemeData(color: Colors.white, size: 20),
                              child: type.icon(),
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                name ?? '',
                                style: theme.textTheme.titleMedium?.copyWith(
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              const SizedBox(height: 2),
                              Row(
                                children: [
                                  Icon(
                                    Icons.location_on,
                                    size: 12,
                                    color: theme.colorScheme.primary,
                                  ),
                                  const SizedBox(width: 3),
                                  Text(
                                    loc.prerecorderAway(formatNumber(ctx, distance)),
                                    style: AppTheme.monoFont.copyWith(
                                      fontSize: 11,
                                      fontWeight: FontWeight.w500,
                                      color: theme.colorScheme.onSurface
                                          .withValues(alpha: 0.7),
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(16),
            child: SizedBox(
              width: double.infinity,
              child: AdaptiveButton.build(
                context: ctx,
                type: AdaptiveButtonType.primary,
                onPressed: () => AdaptiveDialog.pop(
                  ctx,
                  (null, null, VehicleType.unknown),
                ),
                label: Text(loc.prerecorderUnknownStation),
              ),
            ),
          ),
        ],
      );
    },
  );
}
