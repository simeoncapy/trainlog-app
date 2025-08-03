import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:trainlog_app/data/models/trips.dart';
import 'package:trainlog_app/providers/settings_provider.dart';
import 'package:trainlog_app/utils/date_utils.dart';
import 'package:trainlog_app/utils/map_color_palette.dart';

class TripTimeline extends StatelessWidget {
  final Trips trip;

  const TripTimeline({super.key, required this.trip});

  @override
Widget build(BuildContext context) {
  final departureTime = formatDateTime(context, trip.startDatetime).replaceAll(RegExp(r" "), "\n");
  final arrivalTime = formatDateTime(context, trip.endDatetime).replaceAll(RegExp(r" "), "\n");
  //final operatorName = Uri.decodeComponent(trip.operatorName);
  final lineName = Uri.decodeComponent(trip.lineName);
  final distance = "${(trip.tripLength / 1000).round()} km";
  final durationStr = formatSecondsToHMS((trip.manualTripDuration ?? trip.estimatedTripDuration).toInt());

  final settings = context.read<SettingsProvider>();
  final palette = MapColorPaletteHelper.getPalette(settings.mapColorPalette);
  final color = palette[trip.type] ?? Colors.black;

  const double timelineHeight = 200;

  return SizedBox(
    height: timelineHeight,
    child: Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // LEFT: departure and arrival time
        SizedBox(
          width: 65,
          child: Stack(
            children: [
              Positioned(
                top: 0,
                child: Text(
                  departureTime,
                  style: const TextStyle(fontSize: 12),
                  textAlign: TextAlign.right,
                ),
              ),
              Positioned(
                bottom: 0,
                child: Text(
                  arrivalTime,
                  style: const TextStyle(fontSize: 12),
                  textAlign: TextAlign.right,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(width: 12),

        // CENTER: timeline dots + line
        Column(
          children: [
            _buildDot(context, trip.type.icon(), color),
            Expanded(child: _buildLine(color)),
            _buildDot(context, trip.type.icon(), color),
          ],
        ),
        const SizedBox(width: 8),

        // RIGHT: trip information
        Expanded(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Top: origin station
              Text(
                trip.originStation,
                style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
                softWrap: true,
                overflow: TextOverflow.visible,
              ),

              // Middle: line info
              Row(
                children: [
                  const Placeholder(
                    fallbackHeight: 24,
                    fallbackWidth: 24,
                    color: Colors.grey,
                    strokeWidth: 1.5,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          lineName,
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          '$durationStr - $distance',
                          style: TextStyle(color: Theme.of(context).colorScheme.secondary),
                        ),
                      ],
                    ),
                  ),
                ],
              ),

              // Bottom: destination station
              Text(
                trip.destinationStation,
                style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
                softWrap: true,
                overflow: TextOverflow.visible,
              ),
            ],
          ),
        ),
      ],
    ),
  );
}



  Widget _buildDot(BuildContext context, Icon icon, Color color) => Container(
      width: 40,
      height: 40,
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        shape: BoxShape.circle,
        border: Border.all(
          color: color,
          width: 3,
        ),
      ),
      child: Center(
        child: Icon(
          icon.icon,
          size: icon.size ?? 20,
          color: Theme.of(context).colorScheme.onSurface,
        ),
      ),
    );

  Widget _buildLine(Color color) => Container(
        width: 10,
        height: 100,
        color: color,
  );

  String formatSecondsToHMS(int totalSeconds, {bool withSeconds = false, bool hourEvenIfZero = false}) {
    int hours = totalSeconds ~/ 3600; // Integer division to get full hours
    int remainingSecondsAfterHours = totalSeconds % 3600; // Remaining seconds after extracting hours
    int minutes = remainingSecondsAfterHours ~/ 60; // Integer division to get full minutes
    int seconds = remainingSecondsAfterHours % 60; // Remaining seconds

    String result = "";

    if(hours != 0 || hourEvenIfZero)
    {
      result += "${hours.toString().padLeft(2, '0')} h ";
    }

    result += "${minutes.toString().padLeft(2, '0')} min";

    if(withSeconds)
    {
      result += " ${seconds.toString().padLeft(2, '0')} s";
    }

    return result;
  }
}
