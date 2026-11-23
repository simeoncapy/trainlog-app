import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:trainlog_app/core/data/models/trips.dart';
import 'package:trainlog_app/features/trips/detail_sheet/trip_details_actions.dart';
import 'package:trainlog_app/features/trips/detail_sheet/trip_details_sections.dart';
import 'package:trainlog_app/features/trips/detail_sheet/trip_details_common.dart';
import 'package:trainlog_app/features/trips/detail_sheet/trip_details_header.dart';
import 'package:trainlog_app/ui/cupertino/liquid_glass.dart';
import 'package:trainlog_app/ui/cupertino/scroll_edge_blur.dart';

/// Trip details, iOS sheet, like Apple Maps: the header (and its close
/// cross) is pinned inside the scroll view, and the actions are a row of
/// tiles pinned under the content, as on Android. Hosted by a Liquid Glass sheet that gives it a bounded
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

  /// The visibility chip: a Liquid Glass capsule as tall as the round close
  /// button beside it, so the two line up.
  static Widget _glassChip(BuildContext context, Widget content) => SizedBox(
    height: 40,
    child: LiquidGlass(
      padding: const EdgeInsets.symmetric(horizontal: 12),
      child: Center(widthFactor: 1, child: content),
    ),
  );

  @override
  Widget build(BuildContext context) {
    final content = Padding(
      padding: const EdgeInsets.fromLTRB(20, 8, 20, 16),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 12),
          TripDetailsSections(trip: trip),
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
    // The actions stay at the bottom of the sheet, under the scrolling
    // content, as on Android.
    final footer = Padding(
      padding: EdgeInsets.fromLTRB(
        16,
        10,
        16,
        MediaQuery.paddingOf(context).bottom + 10,
      ),
      child: TripDetailsActions(trip: trip),
    );

    return TripDetailsStyle(
      fill: _fill,
      metricRadius: 12,
      closeIcon: Icons.close,
      chip: _glassChip,
      durationPill: false,
      metricCards: false,
      capsTitles: false,
      child: LayoutBuilder(
        builder: (context, constraints) => constraints.maxHeight < 220
            ? const SizedBox.shrink()
            : Column(
              children: [
                Expanded(
                  child: Stack(
                    children: [
                      scrollArea,
                      // The content frosts as it reaches the actions.
                      const Positioned(
                        left: 0,
                        right: 0,
                        bottom: 0,
                        height: 24,
                        child: ScrollEdgeBlur(edge: ScrollEdge.bottom),
                      ),
                    ],
                  ),
                ),
                footer,
              ],
            ),
      ),
    );
  }
}

/// iOS pinned header of the trip sheet. It stays transparent; once the
/// content scrolls under it, that content is frosted with the iOS 26 scroll
/// edge blur (strong at the top, dissolving a little below the header).
class _PinnedHeader extends StatelessWidget {
  final Widget child;

  const _PinnedHeader({required this.child});

  /// How far the blur dissolves below the header.
  static const double _fade = 8;

  @override
  Widget build(BuildContext context) {
    final position = Scrollable.maybeOf(context)?.position;
    final padded = Padding(
      // Ends right under the date: the gap before the timeline belongs to
      // the content, so the blurred band stays the header's height.
      padding: const EdgeInsets.fromLTRB(20, 8, 20, 4),
      child: child,
    );
    if (position == null) return padded;

    return ListenableBuilder(
      listenable: position,
      builder: (context, child) {
        final scrolled = position.hasPixels && position.pixels > 0;
        return Stack(
          clipBehavior: Clip.none,
          children: [
            Positioned(
              top: 0,
              left: 0,
              right: 0,
              bottom: -_fade,
              child: ScrollEdgeBlur(
                edge: ScrollEdge.top,
                visible: scrolled,
                tint: Theme.of(context).colorScheme.surface,
              ),
            ),
            child!,
          ],
        );
      },
      child: padded,
    );
  }
}
