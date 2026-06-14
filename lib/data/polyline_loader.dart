import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import 'package:trainlog_app/data/models/polyline_entry.dart';
import 'package:trainlog_app/data/models/trips.dart';
import 'package:trainlog_app/data/trips_repository.dart';
import 'package:trainlog_app/providers/settings_provider.dart';

/// Reads trip paths from the database and decodes them into [PolylineEntry]
/// objects off the UI thread (via [compute]).
///
/// Stateless: callers (the provider) own load-token / cancellation handling and
/// styling. The returned entries are decoded but not yet restyled.
class PolylineLoader {
  PolylineLoader._();

  /// Loads and decodes every trip that has a path, ordered by creation date.
  static Future<List<PolylineEntry>> loadFromDb(
    TripsRepository repo,
    Map<VehicleType, Color> palette,
  ) async {
    final pathData = await repo.getPathExtendedData(PathDisplayOrder.creationDate);
    return _decode(pathData, palette);
  }

  /// Loads and decodes only the trips that have a path in the DB but whose IDs
  /// are not in [loadedIds].
  ///
  /// Returns an empty list when nothing is missing. Used by the provider's
  /// integrity check to recover polylines dropped from a stale cache or a
  /// silent decode error.
  static Future<List<PolylineEntry>> loadMissing(
    TripsRepository repo,
    Set<int> loadedIds,
    Map<VehicleType, Color> palette,
  ) async {
    // Fetch all trip IDs that have a non-empty path in the DB.
    final dbIds = (await repo.getTripIdsWithPath())
        .map((id) => int.tryParse(id))
        .whereType<int>()
        .toSet();

    final missingIds = dbIds.difference(loadedIds);
    if (missingIds.isEmpty) return const [];

    final pathData = await repo.getPathExtendedDataForIds(
      missingIds.map((id) => id.toString()).toList(),
    );
    if (pathData.isEmpty) return const [];

    return _decode(pathData, palette);
  }

  /// Shared isolate-friendly conversion + decode pipeline.
  static Future<List<PolylineEntry>> _decode(
    List<Map<String, dynamic>> pathData,
    Map<VehicleType, Color> palette,
  ) async {
    // Build isolate-friendly colour map.
    final colors = <String, int>{};
    for (final type in VehicleType.values) {
      colors[type.name] = (palette[type] ?? Colors.black).toARGB32();
    }

    // Convert entries to isolate-friendly format.
    final entries = pathData.map<Map<String, dynamic>>((raw) {
      final m = Map<String, dynamic>.from(raw);
      final typeVal = m['type'];

      if (typeVal is VehicleType) {
        m['type'] = typeVal.name;
      } else {
        m['type'] = typeVal?.toString() ?? '';
      }

      return m;
    }).toList();

    return compute(
      PolylineTools.decodePolylinesBatchIsolateFriendly,
      {'entries': entries, 'colors': colors},
    );
  }
}
