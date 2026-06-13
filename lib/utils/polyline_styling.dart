import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';

import 'package:trainlog_app/data/models/polyline_entry.dart';
import 'package:trainlog_app/data/models/polyline_filter_state.dart';
import 'package:trainlog_app/data/models/trips.dart';
import 'package:trainlog_app/providers/settings_provider.dart';
import 'package:trainlog_app/utils/date_utils.dart';

/// Pure (stateless) polyline styling, filtering and sorting helpers.
///
/// Everything here is a static function of its inputs — no provider state — so
/// the logic is unit-testable in isolation. The [PolylineProvider] owns the
/// state and calls into these helpers, passing the current selection / palette
/// / "now" as parameters.
class PolylineStyling {
  PolylineStyling._();

  // Rendering constants
  static const Color ongoingColor = Colors.red;
  static const Color futureDashColor = Colors.white;
  static const double dashLen = 20.0;
  static const double gapLen = 20.0;

  /// A trip is still considered "ongoing" (red) for this long after its
  /// scheduled arrival. The flip scheduler must use the same grace so the
  /// ongoing→past transition is actually scheduled at end + grace.
  static const Duration ongoingEndGrace = Duration(minutes: 1);

  // ============================================================================
  // Temporal predicates
  // ============================================================================

  static bool isFutureUtc(DateTime? utcStart, DateTime nowUtc) {
    return utcStart != null && utcStart.isAfter(nowUtc);
  }

  static bool isOngoing(PolylineEntry e, DateTime nowUtc) {
    if (!e.hasTimeRange) return false;

    final start = e.utcStartDate;
    final end = e.utcEndDate;
    if (start == null || end == null) return false;

    final inclusiveEnd = end.add(ongoingEndGrace);

    return !nowUtc.isBefore(start) && !nowUtc.isAfter(inclusiveEnd);
  }

  // ============================================================================
  // Polyline creation
  // ============================================================================

  static Polyline<Object> createPolyline(
    List<LatLng>? path,
    Trips trip,
    Map<VehicleType, Color> palette,
  ) {
    return PolylineTools.createPolyline(
      path ?? trip.pathPoints ?? PolylineTools.decodePath(trip.path),
      palette[trip.vehicleType] ?? Colors.black,
    );
  }

  static PolylineEntry createPolylineEntry(Polyline<Object> polyline, Trips trip) {
    return PolylineEntry(
      polyline: polyline,
      type: trip.vehicleType,
      startDate: trip.startDate,
      creationDate: trip.creationDate,
      utcStartDate: trip.utcStartDate,
      utcEndDate: trip.utcEndDate,
      hasTimeRange: PolylineTools.hasClockPart(trip.startDate.toIso8601String()) &&
          PolylineTools.hasClockPart(trip.endDate.toIso8601String()),
      isFuture: trip.utcStartDate != null && trip.utcStartDate!.isAfter(DateTime.now().toUtc()),
      tripId: int.parse(trip.uid),
    );
  }

  // ============================================================================
  // Restyling
  // ============================================================================

  static PolylineEntry restyleEntry(
    PolylineEntry e,
    Map<VehicleType, Color> palette,
    DateTime nowUtc,
  ) {
    final ongoing = isOngoing(e, nowUtc);
    final isFuture = !ongoing && isFutureUtc(e.utcStartDate, nowUtc);

    final baseColor = ongoing ? ongoingColor : (palette[e.type] ?? e.polyline.color);

    final base = Polyline(
      points: e.polyline.points,
      color: baseColor,
      strokeWidth: e.polyline.strokeWidth,
      borderColor: Colors.black,
      borderStrokeWidth: 1.0,
      pattern: const StrokePattern.solid(),
    );

    return PolylineEntry(
      polyline: base,
      type: e.type,
      startDate: e.startDate,
      creationDate: e.creationDate,
      utcStartDate: e.utcStartDate,
      utcEndDate: e.utcEndDate,
      hasTimeRange: e.hasTimeRange,
      isFuture: isFuture,
      tripId: e.tripId,
    );
  }

  static List<PolylineEntry> restyleAll(
    List<PolylineEntry> list,
    Map<VehicleType, Color> palette,
    DateTime nowUtc,
  ) {
    return list.map((e) => restyleEntry(e, palette, nowUtc)).toList();
  }

  // ============================================================================
  // Filtering
  // ============================================================================

  static List<PolylineEntry> filterBySelection(
    List<PolylineEntry> polylines, {
    required PolylineYearFilter yearFilter,
    required Set<VehicleType> selectedTypes,
    required Set<int> selectedYears,
    required List<int> availableYears,
    required DateTime nowUtc,
  }) {
    switch (yearFilter) {
      case PolylineYearFilter.past:
        return polylines.where((e) {
          return (e.utcStartDate?.isBefore(nowUtc) ?? false) &&
              selectedTypes.contains(e.type);
        }).toList();

      case PolylineYearFilter.future:
        return polylines.where((e) {
          return (e.utcStartDate?.isAfter(nowUtc) ?? false) &&
              selectedTypes.contains(e.type);
        }).toList();

      case PolylineYearFilter.all:
        final allowedYears = {...availableYears, unknownPast.year, unknownFuture.year};
        return polylines.where((e) {
          return allowedYears.contains(e.startDate?.year) &&
              selectedTypes.contains(e.type);
        }).toList();

      case PolylineYearFilter.years:
        final allowedYears = {...selectedYears, unknownPast.year, unknownFuture.year};
        return polylines.where((e) {
          return allowedYears.contains(e.startDate?.year) &&
              selectedTypes.contains(e.type);
        }).toList();
    }
  }

  // ============================================================================
  // Sorting
  // ============================================================================

  static void sortInPlace(List<PolylineEntry> list, PathDisplayOrder order) {
    switch (order) {
      case PathDisplayOrder.creationDate:
        list.sort((a, b) {
          return (a.creationDate ?? DateTime(0))
              .compareTo(b.creationDate ?? DateTime(0));
        });
        break;

      case PathDisplayOrder.tripDate:
        list.sort((a, b) {
          return (a.startDate ?? DateTime(0))
              .compareTo(b.startDate ?? DateTime(0));
        });
        break;

      case PathDisplayOrder.tripDatePlaneOver:
        final nonAir = list
            .where((e) => e.type != VehicleType.plane && e.type != VehicleType.helicopter)
            .toList()
          ..sort((a, b) {
            return (a.startDate ?? DateTime(0))
                .compareTo(b.startDate ?? DateTime(0));
          });

        final air = list
            .where((e) => e.type == VehicleType.plane || e.type == VehicleType.helicopter)
            .toList()
          ..sort((a, b) {
            return (a.creationDate ?? DateTime(0))
                .compareTo(b.creationDate ?? DateTime(0));
          });

        list
          ..clear()
          ..addAll(nonAir)
          ..addAll(air);
        break;
    }
  }

  // ============================================================================
  // Render-list construction
  // ============================================================================

  static List<Polyline<int>> toRenderPolylines(
    List<PolylineEntry> entries,
    DateTime nowUtc,
  ) {
    return entries.expand((e) {
      final base = Polyline<int>(
        points: e.polyline.points,
        color: e.polyline.color,
        strokeWidth: e.polyline.strokeWidth,
        borderColor: e.polyline.borderColor,
        borderStrokeWidth: e.polyline.borderStrokeWidth,
        pattern: e.polyline.pattern,
        hitValue: e.tripId,
      );

      if (isOngoing(e, nowUtc)) return [base];

      final isFuture = isFutureUtc(e.utcStartDate, nowUtc);
      if (isFuture) {
        final overlay = Polyline<int>(
          points: e.polyline.points,
          color: futureDashColor,
          strokeWidth: e.polyline.strokeWidth,
          pattern: StrokePattern.dashed(segments: const [dashLen, gapLen]),
          hitValue: e.tripId,
        );
        return [base, overlay];
      }

      return [base];
    }).toList();
  }
}
