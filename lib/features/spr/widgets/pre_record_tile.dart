import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:trainlog_app/app/theme/app_theme.dart';
import 'package:trainlog_app/data/models/pre_record_model.dart';
import 'package:trainlog_app/l10n/app_localizations.dart';
import 'package:trainlog_app/providers/settings_provider.dart';
import 'package:trainlog_app/utils/date_utils.dart';
import 'package:trainlog_app/utils/map_color_palette.dart';
import 'package:trainlog_app/utils/platform_utils.dart';
import 'package:trainlog_app/widgets/shimmer_box.dart';

/// A single Smart Prerecorder record card: leading type icon (or spinner
/// while resolving), station name, timestamp, address/coordinates, and the
/// departure/arrival marker when selected.
class PreRecordTile extends StatelessWidget {
  final PreRecordModel record;
  final bool selected;

  /// 0 = departure, 1 = arrival, -1 = not selected.
  final int selectionIndex;
  final VoidCallback onTap;

  const PreRecordTile({
    super.key,
    required this.record,
    required this.selected,
    required this.selectionIndex,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final cs = theme.colorScheme;
    final hasCoordinates = record.lat != null && record.long != null;
    final hasStation =
        record.stationName != null && record.stationName!.trim().isNotEmpty;
    final hasAddress =
        record.address != null && record.address!.trim().isNotEmpty;
    final settings = context.read<SettingsProvider>();
    final palette = MapColorPaletteHelper.getPalette(settings.mapColorPalette);
    final typeColor = palette[record.type] ?? cs.primary;

    Widget leadingIcon;
    if (!record.loaded) {
      leadingIcon = SizedBox(
        width: 36,
        height: 36,
        child: Center(
          child: AppPlatform.isApple
              ? const CupertinoActivityIndicator()
              : const CircularProgressIndicator(strokeWidth: 3),
        ),
      );
    } else if (hasStation) {
      leadingIcon = Container(
        width: 36,
        height: 36,
        decoration: BoxDecoration(
          color: typeColor,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Center(
          child: IconTheme(
            data: const IconThemeData(color: Colors.white, size: 20),
            child: record.type.icon(),
          ),
        ),
      );
    } else {
      leadingIcon = Container(
        width: 36,
        height: 36,
        decoration: BoxDecoration(
          color: cs.primaryContainer,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Center(
          child: Icon(Icons.not_listed_location, color: cs.onPrimary, size: 20),
        ),
      );
    }

    final selectionTrailing = _selectionTrailing(loc);

    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          color: selected
              ? cs.primaryContainer
              : (isDark ? cs.surfaceContainerLow : Colors.white),
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: isDark ? 0.25 : 0.06),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            leadingIcon,
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  record.loaded
                      ? Text(
                          record.stationName ?? loc.prerecorderUnknownStation,
                          style: theme.textTheme.titleMedium
                              ?.copyWith(fontWeight: FontWeight.w600),
                        )
                      : const ShimmerBox(width: 180, height: 18),
                  const SizedBox(height: 4),
                  Text(
                    formatDateTime(context, record.dateTime),
                    style: AppTheme.monoFont.copyWith(
                      fontSize: 12,
                      fontWeight: FontWeight.w800,
                      color: cs.onSurface,
                    ),
                  ),
                  const SizedBox(height: 2),
                  hasCoordinates
                      ? Text(
                          hasAddress
                              ? record.address!
                              : '${record.lat!.toStringAsFixed(6)}, ${record.long!.toStringAsFixed(6)}',
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: cs.onSurfaceVariant,
                          ),
                        )
                      : const ShimmerBox(width: 180, height: 14),
                ],
              ),
            ),
            if (selectionTrailing != null) ...[
              const SizedBox(width: 8),
              selectionTrailing,
            ],
          ],
        ),
      ),
    );
  }

  Widget? _selectionTrailing(AppLocalizations loc) {
    if (selectionIndex == 0) {
      return Text(
        loc.departureSingleCharacter,
        style: const TextStyle(
          fontSize: 28,
          fontWeight: FontWeight.bold,
          color: Colors.green,
        ),
      );
    }

    if (selectionIndex == 1) {
      return Text(
        loc.arrivalSingleCharacter,
        style: const TextStyle(
          fontSize: 28,
          fontWeight: FontWeight.bold,
          color: Colors.red,
        ),
      );
    }

    return null;
  }
}
