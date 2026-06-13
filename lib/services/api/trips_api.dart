import 'dart:convert';
import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:trainlog_app/data/models/trips.dart';
import 'package:trainlog_app/services/api/trainlog_http_client.dart';

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

  Future<List<Trips>> fetchLastUpdatedTripsData(String username, DateTime? lastUpdate) async {
    final path = '/u/$username/getTripsPaths/${lastUpdate?.toIso8601String() ?? "all"}';
    try {
      final res = await _client.safeGet<Map<String, dynamic>>(path);

      final data = res.data; // already decoded JSON
      if (data == null) return [];

      final rawTrips = data["trips"];
      if (rawTrips is! List) return [];

      // Parse per-trip so a single malformed trip is skipped (and logged with
      // its raw payload) instead of dropping the whole incremental batch.
      final out = <Trips>[];
      for (final json in rawTrips) {
        final tripData = json['trip'] as Map<String, dynamic>;
        final path = json['path'];
        try {
          out.add(Trips.fromJson(
            {...tripData, 'path': path},
            pathAsGooglePolyline: false,
          ));
        } catch (e) {
          debugPrint('⚠️ Skipping trip that failed to parse: $e');
          debugPrint('   raw trip: $tripData');
        }
      }
      return out;

    } catch (e) {
      debugPrint('debugPrintFirstTrips: error fetching $path: $e');
    }
    return [];
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
