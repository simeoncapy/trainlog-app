import 'package:flutter/material.dart';
import 'package:trainlog_app/data/models/trips.dart';
import 'package:trainlog_app/features/trips/detail_sheet/trip_details_actions.dart';
import 'package:trainlog_app/features/trips/detail_sheet/trip_details_header.dart';
import 'package:trainlog_app/features/trips/detail_sheet/trip_details_metadata.dart';
import 'package:trainlog_app/features/trips/detail_sheet/trip_details_metrics.dart';
import 'package:trainlog_app/features/trips/detail_sheet/trip_details_ticket.dart';
import 'package:trainlog_app/features/trips/detail_sheet/trip_details_timeline.dart';
import 'package:trainlog_app/utils/platform_utils.dart';

/// Redesigned trip details bottom sheet.
///
/// Opened when a user taps a trip path on the map or a trip in the list/table
/// views (via `showAdaptiveTripBottomSheet`). The sheet is composed of small,
/// independent sub-widgets living in this folder so each section can evolve
/// (and degrade gracefully on missing data) on its own.
class TripDetailsBottomSheet extends StatelessWidget {
  final Trips trip;

  const TripDetailsBottomSheet({super.key, required this.trip});

  @override
  Widget build(BuildContext context) {
    final hasMetrics = trip.tripLength > 0;
    final hasTicket = trip.price != null;

    final content = Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        TripDetailsHeader(trip: trip),
        const SizedBox(height: 20),
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
        const SizedBox(height: 24),
        TripDetailsActions(trip: trip),
        AppPlatform.bottomPadding(context, offset: 8),
      ],
    );

    // iOS: the sheet is already hosted in a scrollable Cupertino card, so just
    // pad horizontally. Android/Material: provide our own scroll view.
    if (AppPlatform.isApple) {
      return Padding(
        padding: const EdgeInsets.fromLTRB(20, 4, 20, 0),
        child: content,
      );
    }

    return SingleChildScrollView(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: content,
      ),
    );
  }
}
