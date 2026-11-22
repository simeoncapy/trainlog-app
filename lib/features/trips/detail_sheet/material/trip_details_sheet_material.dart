import 'package:flutter/material.dart';
import 'package:trainlog_app/core/data/models/trips.dart';
import 'package:trainlog_app/features/trips/detail_sheet/trip_details_actions.dart';
import 'package:trainlog_app/features/trips/detail_sheet/trip_details_sections.dart';
import 'package:trainlog_app/features/trips/detail_sheet/trip_details_common.dart';
import 'package:trainlog_app/features/trips/detail_sheet/trip_details_header.dart';

/// Trip details, Material sheet: grab handle, the header scrolling with the
/// content, and the actions pinned in a footer. The sheet sizes to its
/// content.
class TripDetailsMaterialSheet extends StatelessWidget {
  const TripDetailsMaterialSheet({
    super.key,
    required this.trip,
    this.scrollController,
    this.onClose,
  });

  final Trips trip;
  final ScrollController? scrollController;
  final VoidCallback? onClose;

  @override
  Widget build(BuildContext context) {
    final content = Padding(
      padding: const EdgeInsets.fromLTRB(20, 8, 20, 16),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          TripDetailsHeader(trip: trip, onClose: onClose),
          const SizedBox(height: 20),
          TripDetailsSections(trip: trip),
        ],
      ),
    );

    // Pinned action footer (does not scroll).
    final footer = Container(
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        border: Border(top: BorderSide(color: detailBorderColor(context))),
      ),
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
      child: SafeArea(top: false, child: TripDetailsActions(trip: trip)),
    );

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

    // The sheet sizes to its content with the footer pinned beneath the
    // scroll area.
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        handle,
        Flexible(child: SingleChildScrollView(child: content)),
        footer,
      ],
    );
  }
}
