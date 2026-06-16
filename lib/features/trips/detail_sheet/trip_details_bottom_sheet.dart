import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:trainlog_app/data/models/trips.dart';
import 'package:trainlog_app/features/trips/detail_sheet/trip_details_actions.dart';
import 'package:trainlog_app/features/trips/detail_sheet/trip_details_common.dart';
import 'package:trainlog_app/features/trips/detail_sheet/trip_details_header.dart';
import 'package:trainlog_app/features/trips/detail_sheet/trip_details_metadata.dart';
import 'package:trainlog_app/features/trips/detail_sheet/trip_details_metrics.dart';
import 'package:trainlog_app/features/trips/detail_sheet/trip_details_notes.dart';
import 'package:trainlog_app/features/trips/detail_sheet/trip_details_ticket.dart';
import 'package:trainlog_app/features/trips/detail_sheet/trip_details_timeline.dart';
import 'package:trainlog_app/utils/platform_utils.dart';

/// Redesigned trip details bottom sheet.
///
/// Opened when a user taps a trip path on the map or a trip in the list/table
/// views (via `showAdaptiveTripBottomSheet`). The sheet is composed of small,
/// independent sub-widgets living in this folder so each section can evolve
/// (and degrade gracefully on missing data) on its own.
///
/// The scrollable content and the action button row are split so the actions
/// stay pinned to the bottom regardless of scrolling. On iOS the hosting
/// draggable card supplies its [scrollController] so dragging keeps working.
class TripDetailsBottomSheet extends StatelessWidget {
  final Trips trip;
  final ScrollController? scrollController;

  /// Closes the sheet. Supplied by the iOS draggable card so the close button
  /// triggers the same animated dismissal as the swipe gesture; on Material it
  /// falls back to popping the modal route.
  final VoidCallback? onClose;

  const TripDetailsBottomSheet({
    super.key,
    required this.trip,
    this.scrollController,
    this.onClose,
  });

  @override
  Widget build(BuildContext context) {
    final isApple = AppPlatform.isApple;
    final hasMetrics = trip.tripLength > 0;
    final hasTicket = trip.price != null;
    final hasNotes = (trip.notes?.trim().isNotEmpty ?? false);

    final content = Padding(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 16),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          TripDetailsHeader(trip: trip, onClose: onClose),
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
          if (hasNotes) ...[
            const SizedBox(height: 20),
            TripDetailsNotes(trip: trip),
          ],
        ],
      ),
    );

    final Widget scrollArea = isApple
        ? CupertinoScrollbar(
            controller: scrollController,
            child: SingleChildScrollView(
              controller: scrollController,
              physics: const BouncingScrollPhysics(),
              child: content,
            ),
          )
        : SingleChildScrollView(child: content);

    // Pinned action footer (does not scroll).
    final footer = Container(
      decoration: BoxDecoration(
        color: isApple ? Colors.transparent : Theme.of(context).colorScheme.surface,
        border: Border(top: BorderSide(color: detailBorderColor(context))),
      ),
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
      child: SafeArea(
        top: false,
        child: TripDetailsActions(trip: trip),
      ),
    );

    // Grab handle. On iOS the hosting draggable card already provides one, so
    // this is only rendered for the Material sheet.
    final handle = Padding(
      padding: const EdgeInsets.only(top: 10, bottom: 2),
      child: Center(
        child: Container(
          width: 36,
          height: 5,
          decoration: BoxDecoration(
            color: detailMutedColor(context).withValues(alpha: 0.4),
            borderRadius: BorderRadius.circular(99),
          ),
        ),
      ),
    );

    return Column(
      // iOS hosts us inside a bounded card → fill it; Material lets the sheet
      // size to its content with the footer pinned beneath the scroll area.
      mainAxisSize: isApple ? MainAxisSize.max : MainAxisSize.min,
      children: [
        if (!isApple) handle,
        isApple ? Expanded(child: scrollArea) : Flexible(child: scrollArea),
        footer,
      ],
    );
  }
}
