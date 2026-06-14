import 'dart:convert';
import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:trainlog_app/data/models/trips.dart';
import 'package:trainlog_app/services/api/trainlog_http_client.dart';

/// Result of an incremental `getTripsPaths` sync.
class IncrementalTripsResult {
  /// Trips changed since the requested timestamp, each paired with the payload
  /// keys it carried so the repository can merge only the provided fields.
  final List<TripUpdate> updates;

  /// Full set of trip IDs the server currently lists for the user, used for
  /// deletion detection. Empty when the endpoint did not send `idList` — an
  /// empty list MUST be treated as "unknown" and must not trigger deletions.
  final List<int> serverTripIds;

  /// Server-provided sync cursor (`lastLocal`), or null when absent.
  final DateTime? lastLocal;

  const IncrementalTripsResult({
    required this.updates,
    required this.serverTripIds,
    required this.lastLocal,
  });

  /// The parsed trips only (e.g. for the polyline partial-update path).
  List<Trips> get trips => updates.map((u) => u.trip).toList();

  static const IncrementalTripsResult empty =
      IncrementalTripsResult(updates: [], serverTripIds: [], lastLocal: null);
}

/// Trip data domain: fetching the user's trip exports/paths and deleting trips.
class TripsApi {
  final TrainlogHttpClient _client;

  TripsApi(this._client);

  Future<String> fetchAllTripsData(String username) async {
    final path = '/u/$username/export';
    try {
      final res = await _client.safeGet<String>(
        path,
        responseType: ResponseType.plain,
        headers: {
          'Accept': 'text/csv, text/plain;q=0.9, */*;q=0.8',
        },
      );

      // If we still ended at a redirect, check if it's a login redirect
      if (res.statusCode != null && res.statusCode! >= 300 && res.statusCode! < 400) {
        final loc = res.headers['location']?.first ?? '';
        if (loc.contains('/login')) {
          debugPrint('Not conected: redirected to login → not authenticated');
          return "";
        }
      }

      final csv = res.data ?? '';
      if (csv.isEmpty) {
        debugPrint('debugPrintFirstTrips: (empty response)');
        return "";
      }
      return csv;
    } catch (e) {
      debugPrint('debugPrintFirstTrips: error fetching $path: $e');
    }
    return '';
  }

  Future<IncrementalTripsResult> fetchLastUpdatedTripsData(String username, DateTime? lastUpdate) async {
    final cursor = lastUpdate?.toIso8601String() ?? "all";

    // Prefer the newer `getUpdatedTrips` endpoint (returns the full trip data,
    // not just the path subset). It is not deployed on every backend yet, so
    // fall back to the legacy `getTripsPaths` when it yields no usable
    // response. Both endpoints return the same JSON shape, so parsing is
    // shared — only the path differs.
    final fromNew =
        await _fetchIncrementalTrips('/u/$username/getUpdatedTrips/$cursor');
    if (fromNew != null) return fromNew;

    debugPrint('getUpdatedTrips unavailable, falling back to getTripsPaths');
    final fromLegacy =
        await _fetchIncrementalTrips('/u/$username/getTripsPaths/$cursor');
    return fromLegacy ?? IncrementalTripsResult.empty;
  }

  /// Fetches and parses an incremental-trips payload from [path].
  ///
  /// Returns null when the endpoint produced no usable response — a network
  /// error, a null body, or a body that is not an incremental-trips payload
  /// (e.g. a 404/login page when the endpoint does not exist) — signalling the
  /// caller to fall back to another endpoint. A valid payload with zero changed
  /// trips is NOT null (it is a legitimate "nothing changed" result).
  Future<IncrementalTripsResult?> _fetchIncrementalTrips(String path) async {
    try {
      final res = await _client.safeGet<Map<String, dynamic>>(path);
      final data = res.data; // already decoded JSON
      if (data == null) return null;

      // A real incremental payload carries `trips` and/or `idList`. Anything
      // else (an error object, an HTML login redirect decoded loosely, …)
      // means the endpoint isn't serving this contract → fall back.
      if (!data.containsKey('trips') && !data.containsKey('idList')) {
        return null;
      }

      return _parseIncrementalTrips(data);
    } catch (e) {
      debugPrint('error fetching $path: $e');
      return null;
    }
  }

  IncrementalTripsResult _parseIncrementalTrips(Map<String, dynamic> data) {
    // ---- Changed trips ----------------------------------------------------
    // Parse per-trip so a single malformed trip is skipped (and logged with
    // its raw payload) instead of dropping the whole incremental batch. Keep
    // the payload's keys so the repository merges only the provided fields.
    final updates = <TripUpdate>[];
    final rawTrips = data["trips"];
    if (rawTrips is List) {
      for (final json in rawTrips) {
        final tripData = json['trip'] as Map<String, dynamic>;
        final path = json['path'];
        try {
          final trip = Trips.fromJson(
            {...tripData, 'path': path},
            pathAsGooglePolyline: false,
          );
          updates.add(TripUpdate(
            trip: trip,
            sourceKeys: tripData.keys.toSet(),
            hasPath: path != null,
          ));
        } catch (e) {
          debugPrint('⚠️ Skipping trip that failed to parse: $e');
          debugPrint('   raw trip: $tripData');
        }
      }
    }

    // ---- Full set of the user's current trip IDs (for deletion detection)--
    final serverTripIds = <int>[];
    final rawIds = data["idList"];
    if (rawIds is List) {
      for (final id in rawIds) {
        final parsed = id is int ? id : int.tryParse(id.toString());
        if (parsed != null) serverTripIds.add(parsed);
      }
    }

    // ---- Server-side sync cursor -----------------------------------------
    final rawLastLocal = data["lastLocal"];
    final lastLocal =
        rawLastLocal == null ? null : DateTime.tryParse(rawLastLocal.toString());

    return IncrementalTripsResult(
      updates: updates,
      serverTripIds: serverTripIds,
      lastLocal: lastLocal,
    );
  }

  Future<bool> deleteTrip(String username, int tripId) =>
    deleteTrips(username, [tripId]);

  Future<bool> deleteTrips(String username, List<int> tripIds) async {
    if (tripIds.isEmpty) return false;
    final path = '/u/$username/deleteTrip';

    debugPrint("Deleting trip(s) $tripIds for user $username");

    // Python expects: request.form["tripId"] to be a JSON string
    // e.g. "123" or "[1,2,3]"
    final tripIdJson = tripIds.length == 1
        ? jsonEncode(tripIds.first)
        : jsonEncode(tripIds);

    final r = await _client.safePost(
      path,
      data: {
        "tripId": tripIdJson,
      },
      // Important: send as form, not JSON
      contentType: Headers.formUrlEncodedContentType,
      headers: {'Accept': 'application/json'},
      followRedirects: false,
      validateStatus: (s) => s != null && s < 500,
    );

    final code = r.statusCode ?? 0;
    final ok = code >= 200 && code < 300;

    if (!ok) {
      debugPrint('deleteTrips failed: $code ${r.statusMessage}');
    }

    return ok;
  }
}
