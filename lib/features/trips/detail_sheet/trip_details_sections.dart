import 'package:flutter/material.dart';
import 'package:trainlog_app/core/data/models/trips.dart';
import 'package:trainlog_app/features/trips/detail_sheet/trip_details_common.dart';
import 'package:trainlog_app/features/trips/detail_sheet/trip_details_metadata.dart';
import 'package:trainlog_app/features/trips/detail_sheet/trip_details_metrics.dart';
import 'package:trainlog_app/features/trips/detail_sheet/trip_details_notes.dart';
import 'package:trainlog_app/features/trips/detail_sheet/trip_details_ticket.dart';
import 'package:trainlog_app/features/trips/detail_sheet/trip_details_timeline.dart';

/// The sections of the sheet between its header and its actions, the same
/// on both designs: timeline, metrics, details, ticket and notes (those
/// without data are left out).
class TripDetailsSections extends StatelessWidget {
  const TripDetailsSections({super.key, required this.trip});

  final Trips trip;

  @override
  Widget build(BuildContext context) {
    final style = TripDetailsStyle.of(context);
    // iOS also lists the duration with the stats.
    final hasMetrics =
        trip.tripLength > 0 ||
        (!style.durationInTimeline && !trip.isUnknownPastFuture);
    final hasTicket = trip.price != null;
    final hasNotes = (trip.notes?.trim().isNotEmpty ?? false);
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        TripDetailsTimeline(trip: trip),
        if (hasMetrics) ...[
          const SizedBox(height: 20),
          TripDetailsMetrics(trip: trip),
        ],
        const SizedBox(height: 20),
        TripDetailsMetadata(trip: trip),
        if (hasTicket) ...[
          const SizedBox(height: 20),
          TripDetailsTicket(trip: trip),
        ],
        if (hasNotes) ...[
          const SizedBox(height: 20),
          TripDetailsNotes(trip: trip),
        ],
      ],
    );
  }
}
