import 'package:flutter/material.dart';
import 'package:trainlog_app/app/theme/app_theme.dart';
import 'package:trainlog_app/data/models/trips.dart';
import 'package:trainlog_app/features/trips/detail_sheet/trip_details_common.dart';
import 'package:trainlog_app/l10n/app_localizations.dart';
import 'package:trainlog_app/utils/date_utils.dart';
import 'package:trainlog_app/utils/platform_utils.dart';

/// Header row of the trip details sheet: a coloured vehicle-type tile, the line
/// name (or a localized fallback) with the departure date underneath, and a
/// trailing visibility chip.
class TripDetailsHeader extends StatelessWidget {
  final Trips trip;

  const TripDetailsHeader({super.key, required this.trip});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final routeColor = tripRouteColor(context, trip);

    // Line name when available, otherwise the existing "Trip in [vehicle]"
    // fallback format.
    final hasLine = trip.lineName.trim().isNotEmpty;
    final title = hasLine
        ? trip.lineName.trim()
        : l10n.tripsDetailTitle(trip.type.label(context).toLowerCase());

    final icon = trip.type.icon();

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Coloured vehicle-type tile.
        Container(
          width: 48,
          height: 48,
          decoration: BoxDecoration(
            color: routeColor,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(
            icon.icon,
            color: Colors.white,
            size: 26,
          ),
        ),
        const SizedBox(width: 12),
        // Title + date.
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: AppTheme.displayFont.copyWith(
                  fontSize: 20,
                  fontWeight: FontWeight.w700,
                  color: Theme.of(context).colorScheme.onSurface,
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 2),
              _DateLine(trip: trip),
            ],
          ),
        ),
        const SizedBox(width: 8),
        _VisibilityChip(trip: trip),
      ],
    );
  }
}

class _DateLine extends StatelessWidget {
  final Trips trip;

  const _DateLine({required this.trip});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final muted = AdaptiveThemeColor.onSurfaceVariant(context);

    final dateText = trip.isUnknownPastFuture
        ? l10n.tripsDetailsNoDate
        : formatDateTime(context, trip.startDatetime, hasTime: false);

    // Leading country code (e.g. "JP", "FR") shown like the design when known.
    final countries = trip.countryList;
    final countryCode = countries.isNotEmpty ? countries.first.toUpperCase() : null;

    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        if (countryCode != null) ...[
          Text(
            countryCode,
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w700,
              color: muted,
              letterSpacing: 0.5,
            ),
          ),
          const SizedBox(width: 6),
        ],
        Flexible(
          child: Text(
            dateText,
            style: TextStyle(fontSize: 13, color: muted),
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }
}

class _VisibilityChip extends StatelessWidget {
  final Trips trip;

  const _VisibilityChip({required this.trip});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final fg = AdaptiveThemeColor.onSurfaceVariant(context);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: AdaptiveThemeColor.surfaceVariant(context),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(trip.visibility.icon(), size: 14, color: fg),
          const SizedBox(width: 4),
          Text(
            trip.visibility.label(l10n),
            style: TextStyle(fontSize: 12, color: fg, fontWeight: FontWeight.w500),
          ),
        ],
      ),
    );
  }
}
