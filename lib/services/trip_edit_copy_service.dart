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
