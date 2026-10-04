import 'package:flutter_test/flutter_test.dart';
import 'package:latlong2/latlong.dart';
import 'package:trainlog_app/data/models/location_search_result.dart';
import 'package:trainlog_app/services/api/search_location_api.dart';

Map<String, dynamic> _feature({
  required String name,
  required double lat,
  required double lon,
  String? osmKey,
  String? osmValue,
  String? type,
  int? osmId,
  Map<String, dynamic> extra = const {},
}) {
  return {
    'type': 'Feature',
    'geometry': {
      'type': 'Point',
      'coordinates': [lon, lat],
    },
    'properties': {
      'name': name,
      if (osmKey != null) 'osm_key': osmKey,
      if (osmValue != null) 'osm_value': osmValue,
      if (type != null) 'type': type,
      if (osmId != null) ...{'osm_id': osmId, 'osm_type': 'N'},
      ...extra,
    },
  };
}

LocationSearchResult _photon(
  String name,
  int id, {
  LocationCategory? as,
  double lat = 48.0,
  double lon = 2.0,
}) {
  final r = LocationSearchResult.fromPhotonFeature(
    _feature(name: name, lat: lat, lon: lon, osmId: id),
  )!;
  if (as == null) return r;
  return LocationSearchResult(
    name: r.name,
    subtitle: r.subtitle,
    countryCode: r.countryCode,
    point: r.point,
    category: as,
    source: r.source,
    osmType: r.osmType,
    osmId: r.osmId,
  );
}

void main() {
  group('categorize', () {
    test('points of interest', () {
      expect(categorize('tourism', 'hotel', 'house'), LocationCategory.hotel);
      expect(categorize('tourism', 'museum', 'house'), LocationCategory.tourism);
      expect(categorize('shop', 'supermarket', 'house'), LocationCategory.shop);
      expect(categorize('amenity', 'townhall', 'house'), LocationCategory.publicBuilding);
      expect(categorize('amenity', 'restaurant', 'house'), LocationCategory.food);
      expect(categorize('amenity', 'hospital', 'house'), LocationCategory.health);
    });

    test('transport', () {
      expect(categorize('railway', 'station', 'house'), LocationCategory.railStation);
      expect(categorize('railway', 'tram_stop', 'house'), LocationCategory.tram);
      expect(categorize('highway', 'bus_stop', 'house'), LocationCategory.busStop);
      expect(categorize('aeroway', 'aerodrome', 'house'), LocationCategory.airport);
      expect(categorize('amenity', 'ferry_terminal', 'house'), LocationCategory.ferry);
    });

    test('areas and addresses', () {
      expect(categorize('place', 'city', 'city'), LocationCategory.city);
      expect(categorize('place', 'village', 'city'), LocationCategory.city);
      expect(categorize('place', 'suburb', 'district'), LocationCategory.district);
      expect(categorize('place', 'country', 'country'), LocationCategory.region);
      expect(categorize('boundary', 'administrative', 'city'), LocationCategory.city);
      expect(categorize('boundary', 'administrative', 'state'), LocationCategory.region);
      expect(categorize('highway', 'residential', 'street'), LocationCategory.street);
      expect(categorize('building', 'yes', 'house'), LocationCategory.address);
      expect(categorize('man_made', 'tower', 'other'), LocationCategory.other);
      expect(categorize(null, null, null), LocationCategory.other);
    });
  });

  group('fromPhotonFeature', () {
    test('strips the server city prefix and builds the subtitle', () {
      final r = LocationSearchResult.fromPhotonFeature(_feature(
        name: 'Paris - Hôtel Ritz',
        lat: 48.868,
        lon: 2.329,
        osmKey: 'tourism',
        osmValue: 'hotel',
        type: 'house',
        osmId: 42,
        extra: {
          'city': 'Paris',
          'street': 'Place Vendôme',
          'housenumber': '15',
          'country': 'France',
          'countrycode': 'fr',
        },
      ))!;

      expect(r.name, 'Hôtel Ritz');
      expect(r.subtitle, 'Place Vendôme 15, Paris, France');
      expect(r.countryCode, 'FR');
      expect(r.category, LocationCategory.hotel);
      expect(r.point, const LatLng(48.868, 2.329));
      expect(r.dedupeKey, 'N42');
    });

    test('parses the Photon extent', () {
      final r = LocationSearchResult.fromPhotonFeature(_feature(
        name: 'Paris',
        lat: 48.85,
        lon: 2.35,
        osmKey: 'place',
        osmValue: 'city',
        type: 'city',
        extra: {
          'extent': [2.22, 48.90, 2.47, 48.81],
        },
      ))!;

      expect(r.category, LocationCategory.city);
      expect(r.extent!.west, 2.22);
      expect(r.extent!.east, 2.47);
      expect(r.extent!.north, 48.90);
      expect(r.extent!.south, 48.81);
    });

    test('rejects features without coordinates', () {
      expect(
        LocationSearchResult.fromPhotonFeature({'properties': {'name': 'x'}}),
        isNull,
      );
    });
  });

  group('mergeResults', () {
    final cdg = LocationSearchResult.fromAirportJson({
      'name': 'Charles de Gaulle',
      'iata': 'CDG',
      'city': 'Paris',
      'iso_country': 'FR',
      'latitude': 49.0097,
      'longitude': 2.5479,
    })!;

    test('same OSM object kept once, in order', () {
      final merged = SearchLocationApi.mergeResults(
        photon: [_photon('A', 1), _photon('B', 2), _photon('B', 2), _photon('C', 3)],
        airports: const [],
      );
      expect(merged.map((r) => r.name), ['A', 'B', 'C']);
    });

    test('a Photon airport is replaced in place by the IATA result', () {
      final photonCdg = LocationSearchResult.fromPhotonFeature(_feature(
        name: 'Aéroport Paris-Charles de Gaulle',
        lat: 49.0090,
        lon: 2.5470,
        osmKey: 'aeroway',
        osmValue: 'aerodrome',
        osmId: 10,
      ))!;
      final merged = SearchLocationApi.mergeResults(
        photon: [_photon('A', 1), photonCdg, _photon('C', 3)],
        airports: [cdg],
      );
      expect(merged.map((r) => r.name), ['A', 'Charles de Gaulle (CDG)', 'C']);
    });

    test('airports go first for IATA-like queries, last otherwise', () {
      final photon = [_photon('A', 1)];
      expect(
        SearchLocationApi.mergeResults(
          photon: photon, airports: [cdg], airportsFirst: true,
        ).first.iata,
        'CDG',
      );
      expect(
        SearchLocationApi.mergeResults(
          photon: photon, airports: [cdg],
        ).last.iata,
        'CDG',
      );
    });

    test('limit is applied', () {
      final merged = SearchLocationApi.mergeResults(
        photon: [for (var i = 0; i < 20; i++) _photon('P$i', i)],
        airports: const [],
        limit: 5,
      );
      expect(merged, hasLength(5));
    });
  });

  group('mergeDuplicates', () {
    test('one station mapped by several operators becomes one entry', () {
      final merged = SearchLocationApi.mergeDuplicates([
        _photon('Kita-Senju', 1, as: LocationCategory.address, lat: 35.7497, lon: 139.8048),
        _photon('Kita-Senju', 2, as: LocationCategory.railStation, lat: 35.7490, lon: 139.8050),
        _photon('Kita-Senju', 3, as: LocationCategory.railStation, lat: 35.7502, lon: 139.8040),
        _photon('Minami-Senju', 4, as: LocationCategory.railStation, lat: 35.7330, lon: 139.7990),
      ]);
      expect(merged.map((r) => r.name), ['Kita-Senju', 'Minami-Senju']);
      expect(merged.first.category, LocationCategory.railStation);
    });

    test('same name far away or of another kind stays separate', () {
      final merged = SearchLocationApi.mergeDuplicates([
        _photon('Springfield', 1, as: LocationCategory.railStation, lat: 39.80, lon: -89.65),
        _photon('Springfield', 2, as: LocationCategory.railStation, lat: 42.10, lon: -72.59),
        _photon('Springfield', 3, as: LocationCategory.city, lat: 39.80, lon: -89.65),
      ]);
      expect(merged, hasLength(3));
    });
  });

  group('language choice', () {
    Map<String, dynamic> kitaSenju(String name, String city, String country) =>
        _feature(
          name: name,
          lat: 35.749,
          lon: 139.805,
          osmKey: 'railway',
          osmValue: 'station',
          osmId: 99,
          extra: {'city': city, 'country': country, 'countrycode': 'JP'},
        );

    final en = kitaSenju('Kita-Senju', 'Tokyo', 'Japan');
    final local = kitaSenju('北千住', '東京都', '日本');
    final fr = kitaSenju('北千住', 'Tokyo', 'Japon');

    String nameOf(Map<String, dynamic> f) => f['properties']['name'];
    String countryOf(Map<String, dynamic> f) => f['properties']['country'];

    test('French user: Latin names, French where translated', () {
      final f = SearchLocationApi.pickLocalizedFeature(en, fr, 'fr');
      expect(nameOf(f), 'Kita-Senju');
      expect(countryOf(f), 'Japon');
    });

    test('Japanese user: Japanese names', () {
      final f = SearchLocationApi.pickLocalizedFeature(en, local, 'ja');
      expect(nameOf(f), '北千住');
      expect(countryOf(f), '日本');
    });

    test('Japanese user abroad: English when no Japanese name', () {
      final paris = _feature(
        name: 'Gare du Nord', lat: 48.88, lon: 2.35, osmId: 5,
        extra: {'city': 'Paris'},
      );
      final f = SearchLocationApi.pickLocalizedFeature(paris, paris, 'ja');
      expect(nameOf(f), 'Gare du Nord');
    });

    test('local name kept when there is no Latin version', () {
      final f = SearchLocationApi.pickLocalizedFeature(local, fr, 'fr');
      expect(nameOf(f), '北千住');
    });

    test('server city prefix removed before choosing', () {
      final prefixed = _feature(
        name: 'Tokyo - Kita-Senju', lat: 35.749, lon: 139.805, osmId: 7,
        extra: {'city': 'Tokyo'},
      );
      final f = SearchLocationApi.pickLocalizedFeature(prefixed, null, 'fr');
      expect(nameOf(f), 'Kita-Senju');
    });

    test('combineLanguages pairs by OSM object and keeps English order', () {
      final other = _feature(name: 'Senju', lat: 35.75, lon: 139.80, osmId: 100);
      final combined = SearchLocationApi.combineLanguages(
        english: [en],
        secondary: [other, fr],
        languageCode: 'fr',
      );
      expect(combined.map(nameOf), ['Kita-Senju', 'Senju']);
      expect(countryOf(combined.first), 'Japon');
    });
  });
}
