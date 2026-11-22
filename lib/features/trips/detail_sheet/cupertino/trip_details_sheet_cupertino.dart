import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:trainlog_app/core/data/models/trips.dart';
import 'package:trainlog_app/features/trips/detail_sheet/trip_details_actions.dart';
import 'package:trainlog_app/features/trips/detail_sheet/trip_details_sections.dart';
import 'package:trainlog_app/features/trips/detail_sheet/trip_details_common.dart';
import 'package:trainlog_app/features/trips/detail_sheet/trip_details_header.dart';

/// Trip details, iOS sheet, like Apple Maps: the header (and its close
/// cross) is pinned inside the scroll view, and the actions end the content
/// as full-width rows. Hosted by a Liquid Glass sheet that gives it a bounded
/// height and its own grab handle.
///
/// The small surfaces are a translucent system grey fill with no border,
/// like the grouped boxes and the "Now" / "Avoid" pills of Apple Maps, so the
/// glass of the sheet shows through; metric cards use Apple's ~12 pt box.
class TripDetailsCupertinoSheet extends StatelessWidget {
  const TripDetailsCupertinoSheet({
    super.key,
    required this.trip,
    this.scrollController,
    this.onClose,
  });

  final Trips trip;
  final ScrollController? scrollController;
  final VoidCallback? onClose;

  static BoxDecoration _fill(BuildContext context, BorderRadius radius) =>
      BoxDecoration(
        color: CupertinoColors.secondarySystemFill.resolveFrom(context),
        borderRadius: radius,
      );

  @override
  Widget build(BuildContext context) {
    final content = Padding(
      padding: const EdgeInsets.fromLTRB(20, 8, 20, 16),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 8),
          TripDetailsSections(trip: trip),
          const SizedBox(height: 28),
          TripDetailsActions(trip: trip),
          SizedBox(height: MediaQuery.paddingOf(context).bottom + 8),
        ],
      ),
    );

    final scrollArea = CupertinoScrollbar(
      controller: scrollController,
      child: CustomScrollView(
        controller: scrollController,
        // No explicit physics: the glass sheet installs its own so a drag
        // grows the sheet to its large detent before scrolling.
        slivers: [
          // The header is pinned inside the scroll view rather than above
          // it, so a drag on it still moves the sheet, as on Apple Maps.
          PinnedHeaderSliver(
            child: _PinnedHeader(
              child: TripDetailsHeader(trip: trip, onClose: onClose),
            ),
          ),
          SliverToBoxAdapter(child: content),
        ],
      ),
    );

    // The glass sheet shrinks through very small heights while it is swiped
    // away; below that there is nothing worth laying out.
    return TripDetailsStyle(
      fill: _fill,
      metricRadius: 12,
      closeIcon: Icons.close,
      child: LayoutBuilder(
        builder: (context, constraints) => constraints.maxHeight < 140
            ? const SizedBox.shrink()
            : Column(children: [Expanded(child: scrollArea)]),
      ),
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
