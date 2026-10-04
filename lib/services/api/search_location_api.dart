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

  /// Languages Photon can return names in, besides English.
  static const _photonLanguages = {'fr', 'de', 'it'};

  /// Non-Latin scripts of app languages Photon cannot translate to: for those
  /// users the local name is kept when it is written in their own script.
  static final Map<String, RegExp> _languageScripts = {
    'ja': RegExp(r'[぀-ヿ㐀-䶿一-鿿]'),
    'zh': RegExp(r'[㐀-䶿一-鿿]'),
    'ko': RegExp(r'[가-힯ᄀ-ᇿ]'),
    'ru': RegExp(r'[Ѐ-ӿ]'),
    'uk': RegExp(r'[Ѐ-ӿ]'),
    'el': RegExp(r'[Ͱ-Ͽ]'),
    'ar': RegExp(r'[؀-ۿ]'),
    'he': RegExp(r'[֐-׿]'),
    'th': RegExp(r'[฀-๿]'),
  };

  /// Letters outside the Latin script (Greek, Cyrillic, Arabic, Indic, CJK,
  /// kana, hangul...).
  static final _nonLatinLetter = RegExp(
    r'[Ͱ-᷿ἀ-῿⺀-퟿豈-﫿ｦ-ﾟ]',
  );

  /// Address fields localised by Photon, chosen one by one in
  /// [pickLocalizedFeature].
  static const _localizedFields = [
    'name', 'street', 'locality', 'district', 'city', 'state', 'country',
  ];

  /// Results with the same name and country closer than this are merged
  /// (e.g. the JR, Metro and Tobu objects of one station).
  static const _duplicateMeters = 1000;

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
  /// Names come in English (Latin script), like the station search. When
  /// [languageCode] (the app language) is not English, the same requests also
  /// run in that language (or with local names for non-Latin-script
  /// languages) and the best name is picked per field, see
  /// [pickLocalizedFeature].
  Future<List<LocationSearchResult>> search(
    String query, {
    LatLngBounds? visibleBounds,
    String? languageCode,
    int limit = 15,
  }) async {
    final q = query.trim();
    if (q.isEmpty) return [];

    final bbox = visibleBounds == null ? null : _localBbox(visibleBounds);
    final secondLang = _secondaryPhotonLanguage(languageCode);

    Future<List<Map<String, dynamic>>> fetch({String? box, String? lang}) {
      return _stations.fetchAutocompleteFeatures(
        q: q,
        limit: box == null ? 10 : 8,
        bbox: box,
        lang: lang,
      );
    }

    Future<List<Map<String, dynamic>>> none() => Future.value(const []);

    final enLocalF = bbox == null ? none() : fetch(box: bbox, lang: 'en');
    final enGlobalF = fetch(lang: 'en');
    final secLocalF =
        bbox == null || secondLang == null ? none() : fetch(box: bbox, lang: secondLang);
    final secGlobalF = secondLang == null ? none() : fetch(lang: secondLang);
    final airportsF = _stations.fetchAirports(q);

    final english = [...await enLocalF, ...await enGlobalF];
    final secondary = [...await secLocalF, ...await secGlobalF];
    final airports = (await airportsF)
        .map(LocationSearchResult.fromAirportJson)
        .whereType<LocationSearchResult>()
        .toList();

    final photon = combineLanguages(
      english: english,
      secondary: secondary,
      languageCode: languageCode,
    )
        .map(LocationSearchResult.fromPhotonFeature)
        .whereType<LocationSearchResult>()
        .toList();

    return mergeResults(
      photon: photon,
      airports: airports,
      airportsFirst: _iataPattern.hasMatch(q),
      limit: limit,
    );
  }

  /// The extra Photon language to query for [languageCode], or `null` when
  /// English names are enough.
  static String? _secondaryPhotonLanguage(String? languageCode) {
    if (languageCode == null || languageCode == 'en') return null;
    if (_photonLanguages.contains(languageCode)) return languageCode;
    if (_languageScripts.containsKey(languageCode)) return 'default';
    return null;
  }

  static bool isLatinScript(String text) => !_nonLatinLetter.hasMatch(text);

  static String _osmKeyOf(Map<String, dynamic> feature) {
    final props = feature['properties'];
    if (props is! Map) return '';
    final id = props['osm_id'];
    return id == null ? '' : '${props['osm_type'] ?? ''}$id';
  }

  /// Pairs each English feature with the same OSM object in [secondary] and
  /// keeps the best localised version (see [pickLocalizedFeature]). Order
  /// follows [english]; objects only found in [secondary] come after.
  /// Duplicated features (same OSM object) are dropped.
  static List<Map<String, dynamic>> combineLanguages({
    required List<Map<String, dynamic>> english,
    required List<Map<String, dynamic>> secondary,
    String? languageCode,
  }) {
    final secondaryByKey = <String, Map<String, dynamic>>{};
    for (final f in secondary) {
      final key = _osmKeyOf(f);
      if (key.isNotEmpty) secondaryByKey.putIfAbsent(key, () => f);
    }

    final seen = <String>{};
    final out = <Map<String, dynamic>>[];
    for (final f in english) {
      final key = _osmKeyOf(f);
      if (key.isNotEmpty && !seen.add(key)) continue;
      out.add(pickLocalizedFeature(f, secondaryByKey[key], languageCode));
    }
    for (final f in secondary) {
      final key = _osmKeyOf(f);
      if (key.isNotEmpty && !seen.add(key)) continue;
      out.add(pickLocalizedFeature(null, f, languageCode));
    }
    return out;
  }

  /// Merges the English and user-language versions of one Photon feature,
  /// field by field ([_localizedFields]):
  /// - for a non-Latin-script app language (e.g. Japanese), the local value
  ///   when it is written in that script, otherwise the English one;
  /// - for other languages, the user-language value unless it is not in Latin
  ///   script while the English one is (Photon falls back to the local name
  ///   when no translation exists).
  ///
  /// The server's `"<city> - "` name prefix is removed from each version
  /// first, since the city may come from the other version.
  static Map<String, dynamic> pickLocalizedFeature(
    Map<String, dynamic>? english,
    Map<String, dynamic>? secondary,
    String? languageCode,
  ) {
    final base = english ?? secondary!;
    final enProps = _cleanedProps(english);
    final secProps = _cleanedProps(secondary);
    final userScript = _languageScripts[languageCode];

    final props = <String, dynamic>{...?secProps, ...?enProps};
    for (final field in _localizedFields) {
      final en = (enProps?[field] as Object?)?.toString();
      final sec = (secProps?[field] as Object?)?.toString();
      if (en == null || en.isEmpty) {
        if (sec != null) props[field] = sec;
        continue;
      }
      if (sec == null || sec.isEmpty) continue;

      final useSecondary = userScript != null
          ? userScript.hasMatch(sec)
          : isLatinScript(sec) || !isLatinScript(en);
      props[field] = useSecondary ? sec : en;
    }

    return {...base, 'properties': props};
  }

  static Map<String, dynamic>? _cleanedProps(Map<String, dynamic>? feature) {
    final raw = feature?['properties'];
    if (raw is! Map) return null;
    final props = Map<String, dynamic>.from(raw);
    final name = props['name'];
    if (name is String) {
      props['name'] = LocationSearchResult.cleanServerName(
        name,
        (props['city'] as Object?)?.toString() ?? '',
      );
    }
    return props;
  }

  /// Merges Photon and airport results:
  /// - same OSM object twice, then same place under several OSM objects
  ///   (see [mergeDuplicates]), are kept once;
  /// - a Photon airport close to an airport-API result is replaced in place
  ///   by the latter (it carries the IATA code);
  /// - remaining airport results go first when [airportsFirst] (the query
  ///   looks like an IATA code), last otherwise.
  static List<LocationSearchResult> mergeResults({
    required List<LocationSearchResult> photon,
    required List<LocationSearchResult> airports,
    bool airportsFirst = false,
    int limit = 15,
  }) {
    const distance = Distance();
    const sameAirportMeters = 2000;

    final seen = <String>{};
    final unique = mergeDuplicates([
      for (final r in photon)
        if (seen.add(r.dedupeKey)) r,
    ]);

    final remainingAirports = <LocationSearchResult>[];
    for (final airport in airports) {
      if (!seen.add(airport.dedupeKey)) continue;
      final index = unique.indexWhere((r) =>
          r.category == LocationCategory.airport &&
          r.source == LocationSearchSource.photon &&
          distance.as(LengthUnit.Meter, r.point, airport.point) <= sameAirportMeters);
      if (index >= 0) {
        unique[index] = airport;
      } else {
        remainingAirports.add(airport);
      }
    }

    final merged = airportsFirst
        ? [...remainingAirports, ...unique]
        : [...unique, ...remainingAirports];
    return merged.take(limit).toList();
  }

  /// Merges results that are the same place mapped as several OSM objects
  /// (e.g. one station per operator, its platforms and building): same name,
  /// same country, same kind of place and closer than [_duplicateMeters].
  ///
  /// The merged entry takes the rank of the first one and the most specific
  /// category of the group (a station rather than an address).
  static List<LocationSearchResult> mergeDuplicates(
    List<LocationSearchResult> results,
  ) {
    const distance = Distance();
    final out = <LocationSearchResult>[];

    for (final r in results) {
      final index = out.indexWhere((o) =>
          _normalizedName(o.name) == _normalizedName(r.name) &&
          o.countryCode == r.countryCode &&
          _family(o.category) == _family(r.category) &&
          distance.as(LengthUnit.Meter, o.point, r.point) <= _duplicateMeters);
      if (index < 0) {
        out.add(r);
      } else if (_priority(r.category) < _priority(out[index].category)) {
        out[index] = r;
      }
    }
    return out;
  }

  static String _normalizedName(String name) =>
      name.trim().toLowerCase().replaceAll(RegExp(r'[\s\-‐-―・]+'), ' ');

  /// Only places of the same family can be merged: a station and a district
  /// sharing a name stay apart.
  static int _family(LocationCategory c) => switch (c) {
        LocationCategory.city ||
        LocationCategory.district ||
        LocationCategory.region =>
          1,
        LocationCategory.street => 2,
        _ => 0,
      };

  /// Lower is more specific.
  static int _priority(LocationCategory c) => switch (c) {
        LocationCategory.railStation ||
        LocationCategory.metro ||
        LocationCategory.tram ||
        LocationCategory.busStop ||
        LocationCategory.ferry ||
        LocationCategory.airport ||
        LocationCategory.aerialway =>
          0,
        LocationCategory.other => 2,
        LocationCategory.address => 3,
        _ => 1,
      };

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
