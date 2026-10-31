import 'package:flutter/material.dart';
import 'package:trainlog_app/app/theme/app_theme.dart';
import 'package:trainlog_app/data/models/trips.dart';
import 'package:trainlog_app/l10n/app_localizations.dart';
import 'package:trainlog_app/widgets/trip_form/trip_form_card.dart';

/// Station block of the Geolog note page: the single station of the Geolog
/// behind a chevron opening the search among the stations around it, with
/// the Geolog coordinates written right under it.
class GeologNoteStationSection extends StatelessWidget {
  const GeologNoteStationSection({
    super.key,
    required this.stationName,
    required this.type,
    required this.colour,
    required this.lat,
    required this.long,
    required this.onSearch,
  });

  /// Null for an unknown station.
  final String? stationName;
  final VehicleType type;

  /// Vehicle colour from the user's map palette.
  final Color colour;

  final double? lat;
  final double? long;

  final VoidCallback onSearch;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final loc = AppLocalizations.of(context)!;
    final hasStation = stationName != null && stationName!.trim().isNotEmpty;
    final hasCoordinates = lat != null && long != null;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        TripFormCard(
          children: [
            InkWell(
              onTap: hasCoordinates ? onSearch : null,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(12, 12, 8, 12),
                child: Row(
                  children: [
                    Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        color: colour.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: IconTheme(
                        data: IconThemeData(color: colour, size: 22),
                        child: Center(
                          child: hasStation
                              ? type.icon()
                              : const Icon(Icons.not_listed_location),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          TripFormSectionLabel(loc.geologNoteSectionStation),
                          const SizedBox(height: 2),
                          Text(
                            hasStation
                                ? stationName!
                                : loc.prerecorderUnknownStation,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: theme.textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          const SizedBox(height: 4),
                          // The Geolog position, under the station field.
                          Row(
                            children: [
                              Icon(
                                Icons.location_on,
                                size: 12,
                                color: theme.colorScheme.onSurfaceVariant,
                              ),
                              const SizedBox(width: 3),
                              Expanded(
                                child: Text(
                                  hasCoordinates
                                      ? '${lat!.toStringAsFixed(6)}, ${long!.toStringAsFixed(6)}'
                                      : '—',
                                  style: AppTheme.monoFont.copyWith(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w500,
                                    color: theme.colorScheme.onSurfaceVariant,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    if (hasCoordinates)
                      Icon(
                        Icons.search,
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                  ],
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Text(
          loc.geologNoteStationHelper,
          style: theme.textTheme.bodySmall?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
          ),
        ),
      ],
    );
  }
}
