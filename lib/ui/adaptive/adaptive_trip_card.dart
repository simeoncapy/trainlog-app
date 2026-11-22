import 'package:flutter/material.dart';
import 'package:trainlog_app/core/data/models/trips.dart';
import 'package:trainlog_app/ui/adaptive/adaptive_sheet.dart';
import 'package:trainlog_app/utils/platform_utils.dart'; // for AppPlatform.isApple
import 'package:trainlog_app/features/trips/detail_sheet/trip_details_bottom_sheet.dart';

/// Call this everywhere.
Future<void> showAdaptiveTripBottomSheet(
  BuildContext context, {
  required Trips trip,
}) {
  if (AppPlatform.isApple) {
    return _showTripCardCupertino(context, trip: trip);
  }
  return _showTripSheetMaterial(context, trip: trip);
}

/// Material version (your current one).
Future<void> _showTripSheetMaterial(
  BuildContext context, {
  required Trips trip,
}) {
  return showModalBottomSheet<void>(
    context: context,
    useSafeArea: true,
    isScrollControlled: true,
    backgroundColor: Theme.of(context).colorScheme.surface,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
    ),
    // The sheet manages its own scrolling and pins the action row at the bottom.
    builder: (ctx) => TripDetailsBottomSheet(trip: trip),
  );
}

/// Apple: an iOS 26 Liquid Glass sheet. It opens at a glass medium detent
/// over the map and can be pulled up to an opaque large detent; swiping down
/// past the medium detent dismisses it. The details keep their action row
/// pinned below the scrolling content.
Future<void> _showTripCardCupertino(
  BuildContext context, {
  required Trips trip,
}) {
  return showAppleDetentSheet<void>(
    context: context,
    halfSize: 0.55,
    builder: (ctx) => TripDetailsBottomSheet(trip: trip),
  );
}
