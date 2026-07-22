import 'package:flutter/material.dart';
import 'package:trainlog_app/app/theme/app_colors.dart';
import 'package:trainlog_app/app/theme/app_theme.dart';
import 'package:trainlog_app/data/models/trips.dart';
import 'package:trainlog_app/features/trips/detail_sheet/trip_details_common.dart';
import 'package:trainlog_app/utils/date_utils.dart';
import 'package:trainlog_app/utils/polyline_styling.dart';

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

  /// Whether the trip is in the future (departure UTC is after now UTC). An
  /// ongoing trip — already departed but not yet arrived — is treated as past,
  /// keeping the connecting line solid.
  bool get _isFuture =>
      PolylineStyling.isFutureUtc(trip.utcStartDate, DateTime.now().toUtc());

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
                  scheduled: trip.hasDepartureDelay && trip.departureDelayInMinutes != 0
                      ? _time(context, trip.startDatetime)
                      : null,
                  delta: trip.departureDelayFormatted,
                  isLate: (trip.departureDelay ?? 0) > 0,
                ),
                _TimeBlock(
                  main: _time(context, trip.realEndDate),
                  scheduled: trip.hasArrivalDelay && trip.arrivalDelayInMinutes != 0
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
                child: ConstrainedBox(
                  constraints: const BoxConstraints(minHeight: 40),
                  child: _isFuture
                      // Future trips show a dashed connecting line: white dashes
                      // over the route colour, matching the map's future style.
                      ? CustomPaint(
                          size: const Size(5, double.infinity),
                          painter: _DashedLinePainter(
                            color: PolylineStyling.futureDashColor,
                            backgroundColor: color,
                          ),
                        )
                      : Container(width: 5, color: color),
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

/// Paints a vertical dashed line, used for the connecting line of future trips.
///
/// A solid [backgroundColor] line is drawn first (the route colour), then the
/// [color] dashes on top — mirroring the map's future-trip styling of white
/// dashes over the route colour.
class _DashedLinePainter extends CustomPainter {
  final Color color;
  final Color? backgroundColor;
  final double dashLength;
  final double gapLength;

  const _DashedLinePainter({
    required this.color,
    this.backgroundColor,
    this.dashLength = 6,
    this.gapLength = 10,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final x = size.width / 2;

    if (backgroundColor != null) {
      final bgPaint = Paint()
        ..color = backgroundColor!
        ..strokeWidth = 5;
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), bgPaint);
    }

    final paint = Paint()
      ..color = color
      ..strokeWidth = 5
      ..strokeCap = StrokeCap.round;

    double y = 0;
    while (y < size.height) {
      final end = (y + dashLength).clamp(0.0, size.height);
      canvas.drawLine(Offset(x, y), Offset(x, end), paint);
      y += dashLength + gapLength;
    }
  }

  @override
  bool shouldRepaint(_DashedLinePainter oldDelegate) =>
      oldDelegate.color != color ||
      oldDelegate.backgroundColor != backgroundColor ||
      oldDelegate.dashLength != dashLength ||
      oldDelegate.gapLength != gapLength;
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
