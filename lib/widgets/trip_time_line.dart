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
  final operatorName = Uri.decodeComponent(trip.operatorName);
  final lineName = Uri.decodeComponent(trip.lineName);
  final distance = "${(trip.tripLength / 1000).round()} km";
  final duration = formatDuration(trip.manualTripDuration ?? trip.estimatedTripDuration);

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
          child: Stack(
            children: [
              Positioned(
                top: 0,
                child: SizedBox(
                  width: MediaQuery.of(context).size.width - 150, // Adjust to available width
                  child: Text(
                    trip.originStation,
                    style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
                    softWrap: true,
                    overflow: TextOverflow.visible,
                  ),
                ),
              ),
              Positioned(
                top: timelineHeight * 0.4,
                child: Row(
                  children: [
                    const Placeholder(
                      fallbackHeight: 24,
                      fallbackWidth: 24,
                      color: Colors.grey,
                      strokeWidth: 1.5,
                    ),
                    const SizedBox(width: 4),
                    Column(
                      children: [
                        Text(
                          lineName,
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          '$duration - $distance',
                          style: TextStyle(color: Theme.of(context).colorScheme.secondary),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              Positioned(
                bottom: 0,
                child: SizedBox(
                  width: MediaQuery.of(context).size.width - 200, // Adjust to available width
                  child: Text(
                    trip.destinationStation,
                    style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
                    softWrap: true,
                    overflow: TextOverflow.visible,
                  ),
                ),
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

  Widget _buildStopInfo({required String time, required String label, String? date}) {
    return Row(
      children: [
        SizedBox(
          width: 50,
          child: Text(time, style: const TextStyle(fontSize: 12)),
        ),
        Text(
          '${date != null ? '$date  ' : ''}$label',
          style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
        ),
      ],
    );
  }

  String formatDuration(double? minutes) {
    if (minutes == null || minutes.isNaN) return '';
    final int mins = minutes.round();
    final int hours = mins ~/ 60;
    final int remMins = mins % 60;
    return '${hours > 0 ? '${hours}h ' : ''}${remMins}min';
  }
}
