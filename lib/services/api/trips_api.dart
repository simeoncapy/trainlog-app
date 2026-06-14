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
    //final path = '/u/$username/getUpdatedTrips/${lastUpdate?.toIso8601String() ?? "all"}'; // New service name, waiting for backend to be updated
    final path = '/u/$username/getTripsPaths/${lastUpdate?.toIso8601String() ?? "all"}';
    try {
      final res = await _client.safeGet<Map<String, dynamic>>(path);

      final data = res.data; // already decoded JSON
      if (data == null) return IncrementalTripsResult.empty;

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
    } catch (e) {
      debugPrint('debugPrintFirstTrips: error fetching $path: $e');
    }
    return IncrementalTripsResult.empty;
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
