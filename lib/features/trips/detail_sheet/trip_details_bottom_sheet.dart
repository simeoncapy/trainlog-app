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
/// stay pinned to the bottom regardless of scrolling. On iOS the sheet is
/// hosted by a Liquid Glass sheet (see `showAdaptiveTripBottomSheet`) that
/// gives it a bounded height and its own grab handle.
class TripDetailsBottomSheet extends StatelessWidget {
  final Trips trip;
  final ScrollController? scrollController;

  /// Closes the sheet. Defaults to popping the sheet's route.
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
      padding: const EdgeInsets.fromLTRB(20, 8, 20, 16),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // iOS pins the header (and its close button) above the scroll
          // area, like Apple Maps; Android scrolls it with the content.
          if (!isApple) ...[
            TripDetailsHeader(trip: trip, onClose: onClose),
            const SizedBox(height: 20),
          ] else
            const SizedBox(height: 8),
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
          // iOS: the actions end the content as full-width rows, like an
          // Apple Maps sheet, instead of a pinned footer.
          if (isApple) ...[
            const SizedBox(height: 28),
            TripDetailsActions(trip: trip),
            SizedBox(height: MediaQuery.paddingOf(context).bottom + 8),
          ],
        ],
      ),
    );

    final Widget scrollArea = isApple
        ? CupertinoScrollbar(
            controller: scrollController,
            child: CustomScrollView(
              controller: scrollController,
              // No explicit physics: the glass sheet installs its own so a
              // drag grows the sheet to its large detent before scrolling.
              slivers: [
                // The header is pinned inside the scroll view rather than
                // above it, so a drag on it still moves the sheet, as on
                // Apple Maps.
                PinnedHeaderSliver(
                  child: _PinnedHeader(
                    child: TripDetailsHeader(trip: trip, onClose: onClose),
                  ),
                ),
                SliverToBoxAdapter(child: content),
              ],
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

    // Grab handle. On iOS the hosting glass sheet already provides one, so
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

    final column = Column(
      // iOS hosts us inside a bounded card → fill it; Material lets the sheet
      // size to its content with the footer pinned beneath the scroll area.
      mainAxisSize: isApple ? MainAxisSize.max : MainAxisSize.min,
      children: [
        if (!isApple) handle,
        isApple ? Expanded(child: scrollArea) : Flexible(child: scrollArea),
        if (!isApple) footer,
      ],
    );
    if (!isApple) return column;

    // The glass sheet shrinks through very small heights while it is swiped
    // away; below the footer's own height there is nothing worth laying out
    // (and the pinned footer would overflow).
    return LayoutBuilder(
      builder: (context, constraints) => constraints.maxHeight < 140
          ? const SizedBox.shrink()
          : column,
    );
  }
}

/// iOS pinned header of the trip sheet. Once the content scrolls under it,
/// it gets the sheet's opaque surface and a hairline so the rows passing
/// beneath don't show through or end in a hard cut.
class _PinnedHeader extends StatelessWidget {
  final Widget child;

  const _PinnedHeader({required this.child});

  @override
  Widget build(BuildContext context) {
    final position = Scrollable.maybeOf(context)?.position;
    final padded = Padding(
      padding: const EdgeInsets.fromLTRB(20, 8, 20, 8),
      child: child,
    );
    if (position == null) return padded;

    return ListenableBuilder(
      listenable: position,
      builder: (context, child) {
        final scrolled = position.hasPixels && position.pixels > 0;
        return AnimatedContainer(
          duration: const Duration(milliseconds: 150),
          decoration: BoxDecoration(
            color: scrolled
                ? Theme.of(context).colorScheme.surface
                : Colors.transparent,
            border: Border(
              bottom: BorderSide(
                color: scrolled
                    ? detailBorderColor(context)
                    : Colors.transparent,
                width: 0.5,
              ),
            ),
          ),
          child: child,
        );
      },
      child: padded,
    );
  }
}
