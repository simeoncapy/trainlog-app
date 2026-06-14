import 'package:flutter/material.dart';
import 'package:trainlog_app/app/theme/app_colors.dart';
import 'package:trainlog_app/app/theme/app_theme.dart';
import 'package:trainlog_app/data/models/trips.dart';
import 'package:trainlog_app/features/trips/detail_sheet/trip_details_common.dart';
import 'package:trainlog_app/utils/date_utils.dart';

/// Redesigned route timeline for the trip details sheet.
///
/// Shows departure/arrival times (with delay annotations), the origin and
/// destination station names and a central duration pill. The connecting line
/// and station markers use the trip's route/vehicle palette colour: the
/// departure marker is a hollow rounded square, the arrival marker a filled
/// one. When the trip spans more than one day, the short arrival date is
/// rendered above the arrival time.
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
            width: 76,
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
          const SizedBox(width: 14),

          // CENTER: markers + connecting line.
          Column(
            children: [
              _marker(context, color, filled: false),
              Expanded(
                child: Container(
                  width: 5, 
                  color: color,
                  constraints: const BoxConstraints(minHeight: 40),
                ),
              ),
              _marker(context, color, filled: true),
            ],
          ),
          const SizedBox(width: 14),

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

  /// Rounded-square station marker. Hollow (outlined) for the departure,
  /// filled with the route colour for the arrival.
  Widget _marker(BuildContext context, Color color, {required bool filled}) {
    return Container(
      width: 22,
      height: 22,
      decoration: BoxDecoration(
        color: filled ? color : Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: color, width: 3),
      ),
    );
  }
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
        ? AppColors.late
        : AppColors.early;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.end,
      mainAxisSize: MainAxisSize.min,
      children: [
        if (topLabel != null)
          Text(
            topLabel!,
            style: TextStyle(fontSize: 10, color: detailMutedColor(context)),
          ),
        Text(
          main!,
          style: AppTheme.monoFont.copyWith(
            fontSize: 16,
            fontWeight: FontWeight.w700,
          ),
          maxLines: 1,
        ),
        if (scheduled != null)
          // Scale down so a long "hh:mm +N min" annotation never overflows the
          // fixed-width time column.
          FittedBox(
            fit: BoxFit.scaleDown,
            alignment: Alignment.centerLeft,
            child: Text.rich(
              TextSpan(children: [
                TextSpan(
                  text: scheduled,
                  style: AppTheme.monoFont.copyWith(
                    fontSize: 11,
                    decoration: TextDecoration.lineThrough,
                    color: detailMutedColor(context),
                  ),
                ),
                if (delta != null)
                  TextSpan(
                    text: ' $delta',
                    style: AppTheme.monoFont.copyWith(
                      fontSize: 11,
                      color: deltaColor,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
              ]),
              maxLines: 1,
            ),
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
    final isLate = realDuration != null && realDuration > trip.duration;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: detailSurfaceColor(context),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: detailBorderColor(context)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.schedule, size: 14, color: detailMutedColor(context)),
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
                        ? (isLate
                            ? AppColors.late
                            : AppColors.early)
                        : Theme.of(context).colorScheme.onSurface,
                  ),
                ),
                if (showReal) ...[
                  TextSpan(text: '  '),
                  TextSpan(
                    text: trip.durationFormatted,
                    style: AppTheme.monoFont.copyWith(
                      fontSize: 12,
                      decoration: TextDecoration.lineThrough,
                      color: detailMutedColor(context),
                    ),
                  ),
                ]
              ]),
              // Keep the pill on a single line: wrapping here would desync the
              // IntrinsicHeight measurement from the actual layout and overflow
              // the timeline row. Overly long values are ellipsized instead.
              maxLines: 1,
              softWrap: false,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }
}
