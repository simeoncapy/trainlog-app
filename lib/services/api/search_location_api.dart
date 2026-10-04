import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:trainlog_app/data/models/location_search_result.dart';
import 'package:trainlog_app/services/api/stations_api.dart';

/// Free-text place search for the map (cities, streets, hotels, shops,
/// public buildings, stations, airports...).
///
/// Built on the existing Trainlog endpoints through [StationsApi]:
/// `/stationAutocomplete` (Photon, unfiltered) and `/api/airportAutocomplete`.
class SearchLocationApi {
  final StationsApi _stations;

  SearchLocationApi(this._stations);

  /// Languages Photon can return names in. Anything else is left to the
  /// server default (English).
  static const _photonLanguages = {'en', 'fr', 'de', 'it'};

  /// Above this span (in degrees) the visible area is roughly the whole world,
  /// so the extra "nearby" request is skipped.
  static const _maxLocalSpanDegrees = 60.0;

  static final _iataPattern = RegExp(r'^[A-Za-z]{3}$');

  /// Searches [query] and returns at most [limit] results.
  ///
  /// `/stationAutocomplete` cannot bias results towards a point (sending
  /// `lat`/`lon` turns it into reverse geocoding), so when [visibleBounds] is
  /// given a second request restricted to that area (slightly enlarged) runs
  /// alongside the global one, and its results come first.
  ///
  /// [languageCode] is the app language; it is only forwarded when Photon
  /// supports it.
  Future<List<LocationSearchResult>> search(
    String query, {
    LatLngBounds? visibleBounds,
    String? languageCode,
    int limit = 15,
  }) async {
    final q = query.trim();
    if (q.isEmpty) return [];

    final lang = _photonLanguages.contains(languageCode) ? languageCode : null;
    final bbox = visibleBounds == null ? null : _localBbox(visibleBounds);

    final localFuture = bbox == null
        ? Future.value(const <Map<String, dynamic>>[])
        : _stations.fetchAutocompleteFeatures(q: q, limit: 8, bbox: bbox, lang: lang);
    final globalFuture =
        _stations.fetchAutocompleteFeatures(q: q, limit: 10, lang: lang);
    final airportsFuture = _stations.fetchAirports(q);

    final local = _parseFeatures(await localFuture);
    final global = _parseFeatures(await globalFuture);
    final airports = (await airportsFuture)
        .map(LocationSearchResult.fromAirportJson)
        .whereType<LocationSearchResult>()
        .toList();

    return mergeResults(
      local: local,
      global: global,
      airports: airports,
      airportsFirst: _iataPattern.hasMatch(q),
      limit: limit,
    );
  }

  /// Merges the three result lists:
  /// - local results first, then global ones, without duplicates;
  /// - a Photon airport close to an airport-API result is replaced in place
  ///   by the latter (it carries the IATA code);
  /// - remaining airport results go first when [airportsFirst] (the query
  ///   looks like an IATA code), last otherwise.
  static List<LocationSearchResult> mergeResults({
    required List<LocationSearchResult> local,
    required List<LocationSearchResult> global,
    required List<LocationSearchResult> airports,
    bool airportsFirst = false,
    int limit = 15,
  }) {
    const distance = Distance();
    const sameAirportMeters = 2000;

    final seen = <String>{};
    final photon = <LocationSearchResult>[];
    for (final r in [...local, ...global]) {
      if (seen.add(r.dedupeKey)) photon.add(r);
    }

    final remainingAirports = <LocationSearchResult>[];
    for (final airport in airports) {
      if (!seen.add(airport.dedupeKey)) continue;
      final index = photon.indexWhere((r) =>
          r.category == LocationCategory.airport &&
          r.source == LocationSearchSource.photon &&
          distance.as(LengthUnit.Meter, r.point, airport.point) <= sameAirportMeters);
      if (index >= 0) {
        photon[index] = airport;
      } else {
        remainingAirports.add(airport);
      }
    }

    final merged = airportsFirst
        ? [...remainingAirports, ...photon]
        : [...photon, ...remainingAirports];
    return merged.take(limit).toList();
  }

  static List<LocationSearchResult> _parseFeatures(
    List<Map<String, dynamic>> features,
  ) {
    return features
        .map(LocationSearchResult.fromPhotonFeature)
        .whereType<LocationSearchResult>()
        .toList();
  }

  /// `minLon,minLat,maxLon,maxLat` of [bounds] enlarged by 50%, or `null` when
  /// the area is too large to be useful as a "nearby" filter.
  static String? _localBbox(LatLngBounds bounds) {
    final latSpan = bounds.north - bounds.south;
    final lonSpan = bounds.east - bounds.west;
    if (latSpan <= 0 || lonSpan <= 0) return null;
    if (latSpan > _maxLocalSpanDegrees || lonSpan > _maxLocalSpanDegrees) {
      return null;
    }

    final minLat = (bounds.south - latSpan / 4).clamp(-90.0, 90.0);
    final maxLat = (bounds.north + latSpan / 4).clamp(-90.0, 90.0);
    final minLon = (bounds.west - lonSpan / 4).clamp(-180.0, 180.0);
    final maxLon = (bounds.east + lonSpan / 4).clamp(-180.0, 180.0);

    String f(double v) => v.toStringAsFixed(5);
    return '${f(minLon)},${f(minLat)},${f(maxLon)},${f(maxLat)}';
  }
}
