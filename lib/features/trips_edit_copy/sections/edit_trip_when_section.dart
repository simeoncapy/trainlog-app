import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:trainlog_app/app/theme/app_colors.dart';
import 'package:trainlog_app/app/theme/app_theme.dart';
import 'package:trainlog_app/data/models/trip_form_model.dart';
import 'package:trainlog_app/l10n/app_localizations.dart';
import 'package:trainlog_app/utils/date_utils.dart';
import 'package:trainlog_app/widgets/trip_form/trip_form_card.dart';
import 'package:trainlog_app/widgets/trip_form/trip_form_tiles.dart';

/// Dates block of the edit form: a read-only summary of the trip schedule
/// (departure, arrival and their delay badges) behind a single chevron
/// spanning the whole card — tapping anywhere on it opens the full temporal
/// editing screen.
class EditTripWhenSection extends StatelessWidget {
  const EditTripWhenSection({
    super.key,
    required this.markerColour,
    required this.onEdit,
  });

  final Color markerColour;
  final VoidCallback onEdit;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final model = context.watch<TripFormModel>();

    return TripFormCard(
      children: [
        InkWell(
          onTap: onEdit,
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: _rows(context, model, theme),
                ),
              ),
              Padding(
                padding: const EdgeInsets.only(right: 8),
                child: Icon(
                  Icons.chevron_right,
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  /// One row per endpoint in precise mode, a single row otherwise: a date-only
  /// trip has no times to show and an unknown one only knows past from future.
  List<Widget> _rows(
    BuildContext context,
    TripFormModel model,
    ThemeData theme,
  ) {
    final loc = AppLocalizations.of(context)!;

    switch (model.dateType) {
      case DateType.precise:
        return [
          _row(
            context: context,
            label: loc.addTripDeparture,
            filledMarker: false,
            value: _dateTimeText(context, model.departureDateLocal),
            delayMinutes: model.delayDepartureMinute,
          ),
          Divider(height: 1, color: theme.dividerColor),
          _row(
            context: context,
            label: loc.addTripArrival,
            filledMarker: true,
            value: _dateTimeText(context, model.arrivalDateLocal),
            delayMinutes: model.delayArrivalMinute,
          ),
        ];
      case DateType.date:
        return [
          _row(
            context: context,
            label: loc.addTripDateTypeDate,
            filledMarker: false,
            value: model.departureDayDateOnly == null
                ? '—'
                : formatDateTime(context, model.departureDayDateOnly!,
                    hasTime: false),
          ),
        ];
      case DateType.unknown:
        return [
          _row(
            context: context,
            label: loc.addTripDateTypeUnknown,
            filledMarker: false,
            value: model.isPast ? loc.addTripPast : loc.addTripFuture,
          ),
        ];
    }
  }

  Widget _row({
    required BuildContext context,
    required String label,
    required bool filledMarker,
    required String value,
    int? delayMinutes,
  }) {
    final theme = Theme.of(context);

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 8, 12),
      child: Row(
        children: [
          RouteEndpointMarker(colour: markerColour, filled: filledMarker),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                TripFormSectionLabel(label),
                const SizedBox(height: 4),
                Text(
                  value,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
          if (delayMinutes != null) ...[
            const SizedBox(width: 8),
            _DelayBadge(minutes: delayMinutes),
          ],
        ],
      ),
    );
  }

  String _dateTimeText(BuildContext context, DateTime? date) =>
      date == null ? '—' : formatDateTime(context, date);
}

/// Delay of an endpoint, in minutes: red when late, green when early.
class _DelayBadge extends StatelessWidget {
  const _DelayBadge({required this.minutes});

  final int minutes;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    final Color colour;
    if (minutes == 0) {
      colour = theme.colorScheme.onSurfaceVariant;
    } else if (minutes > 0) {
      colour = theme.colorScheme.error;
    } else {
      colour = isDark ? AppColors.successDark : AppColors.successLight;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: colour.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        // Minutes are spelled out rather than marked with a prime symbol.
        '${minutes >= 0 ? '+' : '-'}${minutes.abs()} min',
        style: AppTheme.monoFont.copyWith(
          fontSize: 12,
          fontWeight: FontWeight.w700,
          color: colour,
        ),
      ),
    );
  }
}
