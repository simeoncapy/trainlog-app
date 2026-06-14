import 'package:flutter/material.dart';
import 'package:trainlog_app/app/theme/app_theme.dart';
import 'package:trainlog_app/data/models/trips.dart';
import 'package:trainlog_app/features/trips/detail_sheet/trip_details_common.dart';
import 'package:trainlog_app/utils/date_utils.dart';
import 'package:trainlog_app/utils/platform_utils.dart';

/// Redesigned route timeline for the trip details sheet.
///
/// Shows departure/arrival times (with delay annotations), the origin and
/// destination station names and a central duration pill. The connecting line
/// is painted using the trip's route/vehicle palette colour. When the trip
/// spans more than one day, the short arrival date is rendered above the
/// arrival time.
///
/// NOTE: the legacy [TripTimeline] widget is intentionally left untouched; this
/// is a separate presentation tailored to the new sheet.
class TripDetailsTimeline extends StatelessWidget {
  final Trips trip;

  const TripDetailsTimeline({super.key, required this.trip});

  bool get _showTimes => !trip.isUnknownPastFuture && !trip.isDateOnly;

  String? _time(BuildContext context, DateTime dt) {
    if (!_showTimes) return null;
    return formatDateTime(context, dt, timeOnly: true);
  }

  bool get _crossesDay {
    if (!_showTimes) return false;
    final s = trip.startDatetime;
    final e = trip.endDatetime;
    return s.year != e.year || s.month != e.month || s.day != e.day;
  }

  @override
  Widget build(BuildContext context) {
    final color = tripRouteColor(context, trip);

    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // LEFT: times + delays.
          SizedBox(
            width: 64,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                _TimeBlock(
                  main: _time(context, trip.realStartDate),
                  scheduled: trip.hasDepartureDelay
                      ? _time(context, trip.startDatetime)
                      : null,
                  delta: trip.departureDelayFormatted,
                  isLate: (trip.departureDelay ?? 0) > 0,
                ),
                _TimeBlock(
                  main: _time(context, trip.realEndDate),
                  scheduled: trip.hasArrivalDelay
                      ? _time(context, trip.endDatetime)
                      : null,
                  delta: trip.arrivalDelayFormatted,
                  isLate: (trip.arrivalDelay ?? 0) > 0,
                  // Multi-day trips show the arrival date above the time.
                  topLabel: _crossesDay
                      ? formatDateTime(context, trip.endDatetime, hasTime: false)
                      : null,
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),

          // CENTER: dots + connecting line.
          Column(
            children: [
              _dot(context, trip.type.icon(), color),
              Expanded(
                child: Container(width: 8, color: color),
              ),
              _dot(context, trip.type.icon(), color),
            ],
          ),
          const SizedBox(width: 12),

          // RIGHT: stations + duration pill.
          Expanded(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  trip.originStation,
                  style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                  softWrap: true,
                ),
                if (!trip.isUnknownPastFuture)
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    child: _DurationPill(trip: trip),
                  ),
                Text(
                  trip.destinationStation,
                  style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                  softWrap: true,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _dot(BuildContext context, Icon icon, Color color) => Container(
        width: 36,
        height: 36,
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surface,
          shape: BoxShape.circle,
          border: Border.all(color: color, width: 3),
        ),
        child: Icon(
          icon.icon,
          size: 18,
          color: Theme.of(context).colorScheme.onSurface,
        ),
      );
}

class _TimeBlock extends StatelessWidget {
  final String? main;
  final String? scheduled;
  final String? delta;
  final bool isLate;
  final String? topLabel;

  const _TimeBlock({
    required this.main,
    this.scheduled,
    this.delta,
    this.isLate = false,
    this.topLabel,
  });

  @override
  Widget build(BuildContext context) {
    if (main == null) return const SizedBox.shrink();

    final deltaColor = isLate
        ? Theme.of(context).colorScheme.error
        : Theme.of(context).colorScheme.tertiary;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        if (topLabel != null)
          Text(
            topLabel!,
            style: TextStyle(
              fontSize: 11,
              color: AdaptiveThemeColor.onSurfaceVariant(context),
            ),
            textAlign: TextAlign.right,
          ),
        Text(
          main!,
          style: AppTheme.monoFont.copyWith(
            fontSize: 18,
            fontWeight: FontWeight.w700,
          ),
          textAlign: TextAlign.right,
          softWrap: false,
        ),
        if (scheduled != null)
          Text.rich(
            TextSpan(children: [
              TextSpan(
                text: scheduled,
                style: AppTheme.monoFont.copyWith(
                  fontSize: 11,
                  decoration: TextDecoration.lineThrough,
                  color: AdaptiveThemeColor.onSurfaceVariant(context),
                ),
              ),
              if (delta != null)
                TextSpan(
                  text: '  $delta',
                  style: AppTheme.monoFont.copyWith(
                    fontSize: 11,
                    color: deltaColor,
                    fontWeight: FontWeight.w700,
                  ),
                ),
            ]),
            textAlign: TextAlign.right,
          ),
      ],
    );
  }
}

class _DurationPill extends StatelessWidget {
  final Trips trip;

  const _DurationPill({required this.trip});

  @override
  Widget build(BuildContext context) {
    final realDuration = trip.realDuration;
    final showReal = realDuration != null &&
        ((realDuration - trip.duration).inSeconds / 60).round() != 0;
    final late = realDuration != null && realDuration > trip.duration;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: AdaptiveThemeColor.surfaceVariant(context),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.schedule,
            size: 14,
            color: AdaptiveThemeColor.onSurfaceVariant(context),
          ),
          const SizedBox(width: 6),
          Flexible(
            child: Text.rich(
              TextSpan(children: [
                TextSpan(
                  text: showReal
                      ? trip.realDurationFormatted
                      : trip.durationFormatted,
                  style: AppTheme.monoFont.copyWith(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: showReal
                        ? (late
                            ? Theme.of(context).colorScheme.error
                            : Theme.of(context).colorScheme.tertiary)
                        : Theme.of(context).colorScheme.onSurface,
                  ),
                ),
                if (showReal)
                  TextSpan(
                    text: '  ${trip.durationFormatted}',
                    style: AppTheme.monoFont.copyWith(
                      fontSize: 12,
                      decoration: TextDecoration.lineThrough,
                      color: AdaptiveThemeColor.onSurfaceVariant(context),
                    ),
                  ),
              ]),
            ),
          ),
        ],
      ),
    );
  }
}
