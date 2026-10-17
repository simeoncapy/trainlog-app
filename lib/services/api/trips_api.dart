import 'dart:convert';
import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:trainlog_app/data/models/trips.dart';
import 'package:trainlog_app/services/api/trainlog_http_client.dart';
import 'package:trainlog_app/utils/date_utils.dart';

enum EditCopy { edit, copy }

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

/// Parsed `/u/<user>/{edit,copy}/<id>` payload.
class TripEditCopyData {
  /// The trip shaped for the form that is about to be shown: the same trip as
  /// [serverTrip] in [EditCopy.edit], carrying the route as the editor works
  /// on it; in [EditCopy.copy] the uid and the created/last-modified stamps
  /// are stripped because it becomes a new trip.
  final Trips formTrip;

  /// The trip as the server currently stores it, always keyed on the requested
  /// trip id — this is what the local cache should be refreshed with.
  ///
  /// It carries no path. The endpoint describes a trip's route as `wplist`,
  /// the editable waypoint list, which on a trip nobody re-routed is just its
  /// two endpoints — writing that over the stored geometry would turn the trip
  /// into a straight line on the map. Whoever caches this trip keeps the
  /// geometry it already holds (see [TripEditCopyService.load]).
  final Trips serverTrip;

  /// `last_modified` the server reported for the trip, when it sent one.
  final DateTime? serverLastModified;

  /// True when the server's copy is newer than the `lastUpdate` the caller
  /// passed in. Null when either side has no timestamp to compare.
  final bool? hasBeenEdited;

  const TripEditCopyData({
    required this.formTrip,
    required this.serverTrip,
    required this.serverLastModified,
    required this.hasBeenEdited,
  });
}

/// What `patchTrip` reported back: the columns the server actually applied and
/// the keys it did not recognise.
///
/// [ignored] is not an error — the backend reports unknown keys rather than
/// refusing the whole payload, so a client sending a field that this backend
/// version predates is told about it instead of being broken by it.
class TripPatchResult {
  final int tripId;

  /// Columns the server applied, as it spelled them back.
  final List<String> patched;

  /// Keys the payload carried that name no column and no route field.
  final List<String> ignored;

  const TripPatchResult({
    required this.tripId,
    required this.patched,
    required this.ignored,
  });

  /// Nothing was sent: the caller had no changes to save.
  bool get isEmpty => patched.isEmpty;

  factory TripPatchResult.fromJson(Map<String, dynamic> json, int tripId) {
    List<String> strings(dynamic value) => value is List
        ? value.map((e) => e.toString()).toList()
        : const <String>[];

    return TripPatchResult(
      tripId: TripsApi._i(json['trip_id']) ?? tripId,
      patched: strings(json['patched']),
      ignored: strings(json['ignored']),
    );
  }

  @override
  String toString() =>
      'TripPatchResult(trip $tripId, patched: $patched, ignored: $ignored)';
}

/// A `patchTrip` call the server refused: a bad payload (400), a trip that is
/// not the caller's or no longer exists (404), a session that has expired (a
/// redirect to the login page), or a server-side failure.
class TripPatchException implements Exception {
  final String message;
  final int? statusCode;

  const TripPatchException(this.message, {this.statusCode});

  @override
  String toString() => 'TripPatchException($statusCode): $message';
}

/// Trip data domain: fetching the user's trip exports/paths, saving trip
/// edits and deleting trips.
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


  /// Fetches the `/u/<user>/{edit,copy}/<id>` context for [tripId].
  ///
  /// [lastUpdate] is the `last_modified` of the copy the caller already has
  /// cached; it only drives [TripEditCopyData.hasBeenEdited] and never changes
  /// what the server returns. Throws when the endpoint cannot be reached or
  /// sends no body — callers that want to fall back on cached data must catch.
  Future<TripEditCopyData> fetchTripEditCopy(
    String username,
    int tripId,
    EditCopy editCopy,
    {DateTime? lastUpdate}
  ) async {
    final path = '/u/$username/${editCopy.name}/$tripId?fromApp=true';
    try {
      final res = await _client.safeGet<Map<String, dynamic>>(path);
      final data = res.data;
      if (data == null) throw Exception('No data in response');
      final trip = (data['trip'] as Map?)?.cast<String, dynamic>() ??
        const <String, dynamic>{};

      final lastModified = Trips.toDateTimeOrNull(trip['last_modified']);
      final bool? hasBeenEdited = (lastUpdate == null || lastModified == null)
          ? null
          : lastUpdate.isBefore(lastModified);

      // The form keeps `wplist` as its path: it is the route as the editor
      // works on it, and the first and last of its points are where the form
      // recovers the endpoint coordinates its date pickers need.
      final formTrip = Trips.fromJson(
        {
          ..._editCopyToTripJson(data, trip, editCopy),
          if (editCopy == EditCopy.edit) 'uid': tripId.toString(),
        },
        pathAsGooglePolyline: false,
      );

      // The copy shape strips the identity fields (a copy is a new trip), so
      // the cache-facing trip is always parsed with the edit shape and pinned
      // to the requested id — the payload describes that trip either way. Its
      // path is dropped rather than carried over: see [serverTrip].
      final serverTrip = Trips.fromJson(
        {
          ..._editCopyToTripJson(data, trip, EditCopy.edit),
          'uid': tripId.toString(),
          'path': '',
        },
        // An (empty) encoded path rather than the raw point list the payload
        // carries, since the one it carries is not this trip's geometry.
        pathAsGooglePolyline: true,
      );

      return TripEditCopyData(
        formTrip: formTrip,
        serverTrip: serverTrip,
        serverLastModified: lastModified,
        hasBeenEdited: hasBeenEdited,
      );
    } catch (e) {
      debugPrint('error fetching $path: $e');
      rethrow;
    }
  }

  /// Maps the `/u/<user>/{edit,copy}/<id>` context onto the shape expected by
  /// [Trips.fromJson]. Form (`trip*`-prefixed) values win; the nested `trip`
  /// object is only read for fields the form does not expose at all.
  Map<String, dynamic> _editCopyToTripJson(
    Map<String, dynamic> data,
    Map<String, dynamic> trip,
    EditCopy editCopy,
  ) {
    final isEdit = editCopy == EditCopy.edit;

    return <String, dynamic>{
      // A copy is a new trip: no uid, no created/last_modified.
      'uid': isEdit ? _s(data['tripId']) : null,
      'username': _s(data['username']),
      'origin_station': _s(data['origin']),
      'destination_station': _s(data['destination']),
      'start_datetime': _s(data['start_datetime']),
      'end_datetime': _s(data['end_datetime']),
      'manual_trip_duration': _manualDuration(data),
      'operator': _s(data['tripOperator']),
      'line_name': _s(data['tripLineName']),
      'type': _s(data['tripType']),
      'power_type': _s(data['power_type']) ?? _s(trip['power_type']),
      'material_type': _s(data['tripMaterialType']) ??
          _s(data['tripMaterialTypeAdvanced']),
      'seat': _s(data['tripSeat']),
      'reg': _s(data['tripReg']),
      'notes': _s(data['tripNotes']),
      'price': _d(data['tripPrice']),
      'currency': _s(data['tripCurrency']),
      'purchasing_date': _s(data['tripPurchasingDate']),
      'visibility': _s(data['tripVisibility']),
      'departure_delay': _delaySeconds(data['tripDepartureDelay']),
      'arrival_delay': _delaySeconds(data['tripArrivalDelay']),
      'path': data['wplist'],

      // --- not available as trip*-prefixed values (TODO: check if useful) ---
      'estimated_trip_duration': trip['estimated_trip_duration'],
      'trip_length': trip['trip_length'],
      'countries': trip['countries'],
      'utc_start_datetime':
          trip['utc_start_datetime'] ?? trip['utc_filtered_start_datetime'],
      'utc_end_datetime':
          trip['utc_end_datetime'] ?? trip['utc_filtered_end_datetime'],
      'waypoints': trip['waypoints'],
      'created': isEdit ? trip['created'] : null,
      'last_modified': isEdit ? trip['last_modified'] : null,
    };
  }

  /// Empty strings coming from the Jinja context (`x or ""`) mean "null".
  static String? _s(dynamic v) {
    final s = v?.toString().trim();
    return (s == null || s.isEmpty) ? null : s;
  }

  static double? _d(dynamic v) =>
      v is num ? v.toDouble() : double.tryParse(_s(v) ?? '');

  static int? _i(dynamic v) =>
      v is num ? v.toInt() : int.tryParse(_s(v) ?? '');

  /// `tripHours` / `tripMinutes` hold i18n placeholder labels when the manual
  /// duration is unset, so anything non-numeric collapses to null.
  static double? _manualDuration(Map<String, dynamic> data) {
    final h = _i(data['tripHours']);
    final m = _i(data['tripMinutes']);
    if (h == null && m == null) return null;
    return ((h ?? 0) * 3600 + (m ?? 0) * 60).toDouble();
  }

  static int? _delaySeconds(dynamic v) {
    final minutes = _i(v);
    return minutes == null ? null : minutes * 60;
  }

  /// Saves a partial edit of [tripId] through `/u/<user>/patchTrip`.
  ///
  /// [fields] is keyed on `trips` columns — the shape trips are read in — so a
  /// caller sends back a subset of what it was given. Only the keys present are
  /// written; every other column keeps its stored value, and an explicit null
  /// clears one. Values are normalised the way the endpoint expects them:
  ///
  /// * a [DateTime] becomes the local wall-clock time it carries (its UTC
  ///   marker is dropped rather than converted — `start_datetime` is local and
  ///   its UTC counterpart is derived server-side), with [unknownPast] /
  ///   [unknownFuture] going back as the -1 / 1 sentinels the column uses;
  /// * an enum becomes its name, which is how `power_type` and `visibility`
  ///   are spelled (`type` is not patchable, no more than it is through the
  ///   edit page);
  /// * lists and maps are passed on as JSON, and everything else as text.
  ///
  /// Patching a field is equivalent to opening the editor, changing that one
  /// field and pressing save — so leaving `path` out is what makes the server
  /// reuse the stored geometry instead of re-routing the trip.
  ///
  /// An empty [fields] is a no-op: nothing is sent and an empty result comes
  /// back, rather than making the server rewrite the trip with its own data.
  ///
  /// Throws [TripPatchException] when the server refused the patch.
  Future<TripPatchResult> patchTrip(
    String username,
    int tripId,
    Map<String, dynamic> fields,
  ) async {
    final payload = <String, dynamic>{
      for (final entry in fields.entries)
        if (entry.key != 'trip_id' && entry.key != 'uid')
          entry.key: _asPatchValue(entry.value),
    };
    if (payload.isEmpty) {
      debugPrint('patchTrip: nothing to patch on trip $tripId');
      return TripPatchResult(
        tripId: tripId,
        patched: const [],
        ignored: const [],
      );
    }
    payload['trip_id'] = tripId;

    final path = '/u/$username/patchTrip';
    debugPrint('Patching trip $tripId for $username: ${fields.keys.toList()}');

    try {
      final res = await _client.safePost(
        path,
        data: payload,
        contentType: Headers.jsonContentType,
        headers: {'Accept': 'application/json'},
        followRedirects: false,
      );
      return _readPatchResponse(res, tripId);
    } on TripPatchException {
      rethrow;
    } catch (e) {
      debugPrint('patchTrip failed: $e');
      throw TripPatchException('$e');
    }
  }

  /// The `patchTrip` response, or the refusal it carries.
  TripPatchResult _readPatchResponse(Response res, int tripId) {
    final code = res.statusCode ?? 0;
    final data = res.data;

    if (code < 200 || code >= 300) {
      // The endpoint reports its own refusals as {"error": "…"}; anything else
      // (a login redirect, an abort page) only carries its status.
      final error = data is Map ? data['error']?.toString() : null;
      debugPrint('patchTrip failed: $code ${error ?? res.statusMessage}');
      throw TripPatchException(
        error ?? 'HTTP $code ${res.statusMessage ?? ''}'.trim(),
        statusCode: code,
      );
    }

    if (data is! Map) {
      throw TripPatchException(
        'Unexpected patchTrip response',
        statusCode: code,
      );
    }

    final result = TripPatchResult.fromJson(
      data.cast<String, dynamic>(),
      tripId,
    );
    if (result.ignored.isNotEmpty) {
      debugPrint('patchTrip: server ignored ${result.ignored}');
    }
    return result;
  }

  /// A patch value as the endpoint reads it. See [patchTrip].
  static Object? _asPatchValue(dynamic value) {
    if (value == null) return null; // an explicit clear
    if (value is DateTime) return _asPatchDate(value);
    if (value is Enum) return value.name;
    if (value is num || value is bool || value is String) return value;
    if (value is List || value is Map) return value;
    return value.toString();
  }

  /// A trip datetime as its column holds it: the 1 / -1 "no date" sentinels,
  /// or a naive local wall-clock time with no zone marker on it.
  static Object _asPatchDate(DateTime value) {
    if (value == unknownPast) return -1;
    if (value == unknownFuture) return 1;

    String pad(int v, [int width = 2]) => v.toString().padLeft(width, '0');
    return '${pad(value.year, 4)}-${pad(value.month)}-${pad(value.day)}'
        'T${pad(value.hour)}:${pad(value.minute)}:${pad(value.second)}';
  }
}
