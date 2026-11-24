import 'package:flutter/material.dart';
import 'package:trainlog_app/core/data/models/trips.dart';
import 'package:trainlog_app/features/trips/detail_sheet/cupertino/trip_details_sheet_cupertino.dart';
import 'package:trainlog_app/features/trips/detail_sheet/material/trip_details_sheet_material.dart';
import 'package:trainlog_app/ui/design.dart';

/// Redesigned trip details bottom sheet.
///
/// Opened when a user taps a trip path on the map or a trip in the list/table
/// views (via `showAdaptiveTripBottomSheet`). The sheet is composed of small,
/// independent sub-widgets living in this folder so each section can evolve
/// (and degrade gracefully on missing data) on its own.
///
/// Picks [TripDetailsMaterialSheet] (header scrolling with the content,
/// actions pinned in a footer) or [TripDetailsCupertinoSheet] (header pinned
/// in the scroll view, actions ending the content, hosted by a Liquid Glass
/// sheet that gives it a bounded height and its own grab handle).
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
  Widget build(BuildContext context) => PlatformView(
    material: (_) => TripDetailsMaterialSheet(
      trip: trip,
      scrollController: scrollController,
      onClose: onClose,
    ),
    cupertino: (_) => TripDetailsCupertinoSheet(
      trip: trip,
      scrollController: scrollController,
      onClose: onClose,
    ),
  );
}
