import 'dart:convert';
import 'dart:io';

import 'package:flutter/foundation.dart';

import 'package:trainlog_app/data/models/polyline_entry.dart';
import 'package:trainlog_app/utils/cached_data_utils.dart';

/// On-disk JSON cache for the decoded polyline list.
///
/// Reading and writing the cache file is the only responsibility here; the
/// provider owns when to read/write and how to reconcile with live state.
class PolylineCache {
  PolylineCache._();

  /// Reads and decodes the cached polyline entries.
  ///
  /// Returns `null` when no cache file exists. Throws on read/parse errors so
  /// the caller can decide to fall back to the database.
  static Future<List<PolylineEntry>?> read() async {
    final cacheFile = File(AppCacheFilePath.polylines);
    if (!await cacheFile.exists()) return null;

    final cachedJson = await cacheFile.readAsString();
    return (json.decode(cachedJson) as List<dynamic>)
        .map((e) => PolylineEntry.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  /// Encodes and writes [list] to the cache file. Failures are logged and
  /// swallowed — a failed cache write should never break the UI.
  static Future<void> write(List<PolylineEntry> list) async {
    try {
      final encoded = json.encode(list.map((e) => e.toJson()).toList());
      final cacheFile = File(AppCacheFilePath.polylines);
      await cacheFile.writeAsString(encoded);
    } catch (e) {
      debugPrint('Failed to write polyline cache: $e');
    }
  }
}
