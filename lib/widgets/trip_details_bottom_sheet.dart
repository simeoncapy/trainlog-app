import 'package:flutter/material.dart';
import 'package:trainlog_app/data/models/trips.dart';
import 'package:trainlog_app/widgets/trip_time_line.dart';

class TripDetailsBottomSheet extends StatelessWidget {
  final Trips trip;

  const TripDetailsBottomSheet({super.key, required this.trip});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(24.0),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          TripTimeline(trip: trip),
          const SizedBox(height: 8),
          Text("Destination: ${trip.destinationStation}", style: Theme.of(context).textTheme.titleMedium),
        ],
      ),
    );
  }
}
