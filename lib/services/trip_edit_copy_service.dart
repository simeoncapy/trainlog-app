import 'package:flutter/foundation.dart';
import 'package:trainlog_app/data/models/trips.dart';
import 'package:trainlog_app/providers/trips_provider.dart';
import 'package:trainlog_app/services/api/trips_api.dart';

/// Where the trip handed to the edit/copy page ended up coming from, and
/// therefore what (if anything) the user has to be warned about.
enum TripEditCopySource {
  /// The server copy matched the cached one — nothing to report.
  upToDate,

  /// The server held a newer version: the local cache was refreshed with it
  /// and the user should be told the data changed under them.
  refreshedFromServer,

  /// The server could not be reached, so the cached trip is used instead.
  cacheFallback,

  /// The server could not be reached and nothing was cached locally: there is
  /// no trip to show at all.
  unavailable,
}

/// Outcome of [TripEditCopyService.load].
class TripEditCopyResult {
  /// The trip to seed the page with, already shaped for [mode]. Null only when
  /// [source] is [TripEditCopySource.unavailable].
  final Trips? trip;

  final EditCopy mode;
  final TripEditCopySource source;

  const TripEditCopyResult({
    required this.trip,
    required this.mode,
    required this.source,
  });

  bool get hasTrip => trip != null;

  /// True when the user has to be told something about how this data was
  /// obtained (stale local copy, silently refreshed cache, nothing at all).
  bool get needsWarning => source != TripEditCopySource.upToDate;
}

/// Outcome of [TripEditCopyService.save].
class TripEditCopySaveResult {
  /// What the server reported applying — the columns it wrote, and any key it
  /// did not recognise.
  final TripPatchResult patch;

  /// The saved trip as the server now stores it, re-read after the patch so
  /// the columns it derives (countries, trip length, the UTC datetimes) are
  /// the server's own. Null when it could not be read back — the save still
  /// stands, and the next incremental sync brings the local copy in line.
  final Trips? saved;

  const TripEditCopySaveResult({required this.patch, required this.saved});

  /// Nothing was sent because the caller had no changes to save.
  bool get isEmpty => patch.isEmpty;

  /// True when the local cache now holds the server's version of the trip.
  bool get cacheRefreshed => saved != null;
}

/// Loads a trip for the edit/copy page, reconciling the locally cached copy
/// with the server's.
///
/// The cached copy is read first so its `last_modified` can be handed to the
/// server, then [TripsApi.fetchTripEditCopy] decides which of the two is
/// current:
///
/// 1. server not newer → the fetched trip is used as-is;
/// 2. server newer → the local cache is refreshed with the server version and
///    the caller reports [TripEditCopySource.refreshedFromServer];
/// 3. server unreachable → the cached trip is used and the caller reports
///    [TripEditCopySource.cacheFallback] (or [TripEditCopySource.unavailable]
///    when there is no cached trip either).
///
/// [save] is the way back: it writes an edit to the server and refreshes the
/// cached trip with the result. Saving a *duplicate* does not go through here
/// — a copy is a new trip, and creating one still goes through the trip
/// creation pipeline (the routing web view), not through this service.
class TripEditCopyService {
  final TripsApi _api;
  final TripsProvider _trips;

  TripEditCopyService({
    required TripsApi api,
    required TripsProvider trips,
  })  : _api = api,
        _trips = trips;

  Future<TripEditCopyResult> load({
    required String? username,
    required int tripId,
    required EditCopy mode,
  }) async {
    final cached = await _trips.getTripById(tripId);

    TripEditCopyData? remote;
    if (username != null) {
      try {
        remote = await _api.fetchTripEditCopy(
          username,
          tripId,
          mode,
          lastUpdate: cached?.lastModified,
        );
      } catch (e) {
        debugPrint('TripEditCopyService: fetching trip $tripId failed: $e');
      }
    } else {
      debugPrint('TripEditCopyService: no username, skipping remote fetch');
    }

    // Case 3: nothing came back from the server.
    if (remote == null) {
      return TripEditCopyResult(
        trip: cached == null
            ? null
            : (mode == EditCopy.copy ? _asNewCopy(cached) : cached),
        mode: mode,
        source: cached == null
            ? TripEditCopySource.unavailable
            : TripEditCopySource.cacheFallback,
      );
    }

    // `hasBeenEdited` is null when either side had no timestamp to compare: a
    // trip missing from the cache still has to be stored, anything else is
    // left alone rather than overwritten on a guess.
    final serverIsNewer = remote.hasBeenEdited ?? (cached == null);
    if (serverIsNewer) {
      await _trips.insertTrip(remote.serverTrip);
    }

    return TripEditCopyResult(
      trip: remote.formTrip,
      mode: mode,
      // Case 2 only when there was a cached version to be superseded; a trip
      // simply absent from the cache is not something to warn about.
      source: serverIsNewer && cached != null
          ? TripEditCopySource.refreshedFromServer
          : TripEditCopySource.upToDate,
    );
  }

  /// Saves an edit of [tripId] and brings the local cache in line with it.
  ///
  /// [fields] is the partial edit, keyed on `trips` columns: only the columns
  /// it carries are written, so the caller sends what the user changed and
  /// nothing else (see [TripsApi.patchTrip]). Leaving the route out is what
  /// keeps the trip's stored geometry — and the 3D flight track with it.
  ///
  /// The patch response says which columns were applied but not what the
  /// server derived from them, so the stored trip is read back and cached. A
  /// read that fails does not fail the save: it is reported through
  /// [TripEditCopySaveResult.cacheRefreshed] and the next incremental sync
  /// picks the trip up.
  ///
  /// Throws [TripPatchException] when the server refused the save, or when
  /// there is no signed-in user to save as.
  Future<TripEditCopySaveResult> save({
    required String? username,
    required int tripId,
    required Map<String, dynamic> fields,
  }) async {
    if (username == null) {
      throw const TripPatchException('No signed-in user to save the trip as');
    }

    final patch = await _api.patchTrip(username, tripId, fields);
    // Nothing was sent, so there is nothing new to read back either.
    if (patch.isEmpty) {
      return TripEditCopySaveResult(patch: patch, saved: null);
    }

    Trips? saved;
    try {
      final stored =
          await _api.fetchTripEditCopy(username, tripId, EditCopy.edit);
      saved = stored.serverTrip;
      await _trips.insertTrip(saved);
    } catch (e) {
      debugPrint(
        'TripEditCopyService: trip $tripId saved, reading it back failed: $e',
      );
    }

    return TripEditCopySaveResult(patch: patch, saved: saved);
  }

  /// Re-shapes a cached trip the way the server's copy payload would: a copy
  /// is a new trip, so the identity fields are dropped. Only needed on the
  /// offline path — a payload the server actually sent is already shaped.
  Trips _asNewCopy(Trips trip) => Trips.fromJson({
        ...trip.toJson(),
        'uid': null,
        'created': null,
        'last_modified': null,
      });
}
