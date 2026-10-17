import 'dart:io';
import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:latlong2/latlong.dart';
import 'package:trainlog_app/data/models/trips.dart';
import 'package:trainlog_app/services/api/trainlog_http_client.dart';
import 'package:trainlog_app/utils/text_utils.dart';

typedef StationResult = ({
  String name,
  String displayName,
  LatLng coords,
  String address,
  bool isManual,
});

/// Station lookup domain: manual stations, OSM/airport autocomplete and
/// reverse-geocoding stations from coordinates.
class StationsApi {
  final TrainlogHttpClient _client;

  StationsApi(this._client);

  // ----------------------------
  // Shared private fetcher
  // ----------------------------
  Future<Map<String, dynamic>> _fetchRawManualStations(
    String username,
    VehicleType type,
  ) async {
    final path = '/u/$username/getManAndOps/${type.toShortString()}';
    Map<String, dynamic>? data;

    try{
        final res = await _client.safeGet<Map<String, dynamic>>(path);
        data = res.data;
    } on DioException catch (e) {
      if (e.error is HttpException &&
          e.error.toString().contains("Connection closed before full header was received")) {
        // Already got data earlier → ignore.
        return {};
      }
      rethrow; // other real errors
    }

    if (data == null || data['manualStations'] == null) {
      return {};
    }

    return data['manualStations'] as Map<String, dynamic>;
  }

  Future<Map<String, List<(LatLng, String)>>> fetchAllManualStations(
    String username,
    VehicleType type,
  ) async {
    final manual = await _fetchRawManualStations(username, type);
    final result = <String, List<(LatLng, String)>>{};

    manual.forEach((name, entry) {
      final coords = entry[0];
      final latLng = LatLng(coords[0] as double, coords[1] as double);

      result.putIfAbsent(name, () => []);
      result[name]!.add((latLng, "@manual@"));
    });

    return result;
  }

  double _toDouble(dynamic v) {
    if (v is num) return v.toDouble();
    if (v is String) return double.tryParse(v) ?? 0.0;
    throw Exception("Invalid coordinate type: $v");
  }

  Future<List<StationResult>> fetchAllManualStationsSuffixed(
    String username,
    VehicleType type,
  ) async {
    final manual = await _fetchRawManualStations(username, type);
    final seen = <String>{};
    final result = <StationResult>[];

    for (final entry in manual.entries) {
      final baseName = entry.key;
      final coords = entry.value[0];

      final latLng = LatLng(
        _toDouble(coords[0]),
        _toDouble(coords[1]),
      );

      var displayName = baseName;

      // Handle suffixing
      if (seen.contains(displayName)) {
        int suffixIndex = 0;
        while (true) {
          final candidate =
              "$baseName (${String.fromCharCode(97 + suffixIndex)})";
          if (!seen.contains(candidate)) {
            displayName = candidate;
            break;
          }
          suffixIndex++;
        }
      }

      seen.add(displayName);
      result.add((
        name: baseName,
        displayName: displayName,
        coords: latLng,
        address: "@manual@",
        isManual: true,
      ));
    }

    return result;
  }

  /// `osm_tag` filters sent to `/stationAutocomplete` for each vehicle type.
  /// An empty list means no filter: Photon then returns any kind of place.
  static List<String> _osmTagsFor(VehicleType type) {
    switch (type) {
      case VehicleType.aerialway:
        return const ['aerialway:station'];
      case VehicleType.bus:
        return const ['amenity:bus_station', 'highway:bus_stop'];
      case VehicleType.ferry:
        return const ['amenity:ferry_terminal'];
      case VehicleType.helicopter:
        return const ['aeroway:helipad', 'aeroway:heliport', 'aeroway:aerodrome'];
      case VehicleType.metro:
        return const ['railway:station', 'railway:subway_entrance'];
      case VehicleType.train:
      case VehicleType.rail:
      case VehicleType.funicular:
        return const ['railway:halt', 'railway:station'];
      case VehicleType.tram:
        return const ['railway:tram_stop', 'railway:station', 'railway:halt'];
      default:
        return const [];
    }
  }

  /// Raw GeoJSON `features` of `/stationAutocomplete` (a Photon proxy on the
  /// Trainlog server). Every parameter is forwarded to Photon as is.
  ///
  /// Never send `lat`/`lon` here: when both are present the server switches to
  /// Photon's reverse geocoding and ignores [q]. Use [bbox]
  /// (`minLon,minLat,maxLon,maxLat`) to restrict results to an area instead.
  ///
  /// Returns an empty list on any error (the server answers 500 when Photon
  /// times out).
  Future<List<Map<String, dynamic>>> fetchAutocompleteFeatures({
    required String q,
    int? limit,
    List<String> osmTags = const [],
    String? bbox,
    String? lang,
  }) async {
    try {
      final res = await _client.safeGet<Map<String, dynamic>>(
        '/stationAutocomplete',
        query: {
          'q': q,
          if (limit != null) 'limit': limit,
          if (osmTags.isNotEmpty) 'osm_tag': osmTags,
          if (bbox != null) 'bbox': bbox,
          if (lang != null) 'lang': lang,
        },
      );
      final features = res.data?['features'];
      if (features is! List) return [];
      return features.whereType<Map<String, dynamic>>().toList();
    } on Exception catch (e) {
      debugPrint('🛑 fetchAutocompleteFeatures failed: $e');
      return [];
    }
  }

  /// Raw entries of `/api/airportAutocomplete/<query>`.
  /// Returns an empty list on any error.
  Future<List<Map<String, dynamic>>> fetchAirports(String query) async {
    try {
      final res = await _client.safeGet<List<dynamic>>(
        '/api/airportAutocomplete/${Uri.encodeComponent(query)}',
      );
      return (res.data ?? const [])
          .whereType<Map<String, dynamic>>()
          .toList();
    } on Exception catch (e) {
      debugPrint('🛑 fetchAirports failed: $e');
      return [];
    }
  }

  Future<List<StationResult>> fetchStations(
    String query,
    VehicleType type,
  ) async {
    try {
      if (type == VehicleType.plane) {
        return _airportListGenerator(await fetchAirports(query));
      }

      final features = await fetchAutocompleteFeatures(
        q: query,
        osmTags: _osmTagsFor(type),
      );
      return _stationListGenerator({'features': features});
    } on Exception catch (e) {
      debugPrint('🛑 fetchStations failed: $e');
      return [];
    }
  }

  List<StationResult> _airportListGenerator(List<dynamic> airports) {
    final result = <StationResult>[];

    for (final raw in airports) {
      final entry = raw as Map<String, dynamic>;

      final country = entry['iso_country'] as String? ?? "";
      final city = entry['city'] as String? ?? "";
      final name = entry['name'] as String? ?? "";
      final iata = entry['iata'] as String? ?? "";
      final lat = entry['latitude'] as num?;
      final lng = entry['longitude'] as num?;

      if (lat == null || lng == null) continue;

      final displayName = "${countryCodeToEmoji(country)} $name ($iata)";

      result.add((
        name: displayName,
        displayName: displayName,
        coords: LatLng(lat.toDouble(), lng.toDouble()),
        address: city,
        isManual: false,
      ));
    }

    return result;
  }

  List<StationResult> _stationListGenerator(
    Map<String, dynamic> data,
  ) {
    final features = data["features"] as List<dynamic>? ?? [];
    final result = <StationResult>[];

    for (final f in features) {
      final feature = f as Map<String, dynamic>;

      // --- Coordinates ---
      final coords = feature["geometry"]["coordinates"] as List<dynamic>;
      final lng = coords[0] as num;
      final lat = coords[1] as num;

      final latLng = LatLng(lat.toDouble(), lng.toDouble());

      // --- Properties ---
      final props = feature["properties"] as Map<String, dynamic>;

      final countryCode = props["countrycode"] as String? ?? "";
      final stationName = props["name"] as String? ?? "";
      final homonymy = props["homonymy_order"] as String? ?? "";

      final street = props["street"] as String? ?? "";
      final locality = props["locality"] as String? ?? "";
      final district = props["district"] as String? ?? "";
      final city = props["city"] as String? ?? "";

      final emoji = countryCodeToEmoji(countryCode);
      final name = "$emoji $stationName";
      final displayName = "$emoji $stationName$homonymy";

      // --- Address string ---
      final parts = [
        street,
        locality,
        district,
        city,
      ].where((e) => e.trim().isNotEmpty).toList();

      final address = parts.join(", ");

      result.add((
        name: name,
        displayName: displayName,
        coords: latLng,
        address: address,
        isManual: false,
      ));
    }

    return result;
  }

  Future<(String? name, String? address, VehicleType type, double distance)> findStationFromCoordinate(
    double lat,
    double long, {
    int distanceLimitMeters = 500,
    bool returnUniqueEvenIfOutOfRange = true,
    }
  ) async {
    final results = await findStationsFromCoordinate(
      lat,
      long,
      distanceLimitMeters: distanceLimitMeters,
      returnUniqueEvenIfOutOfRange: returnUniqueEvenIfOutOfRange
    );

    if (results.isEmpty) {
      return (null, null, VehicleType.unknown, 0.0);
    }
    return results.first;
  }

  //final argAirport = "&osm_tag=aeroway:aerodrome";
  Future<List<(String? name, String? address, VehicleType type, double distance)>> findStationsFromCoordinate(
      double lat,
      double long, {
      int distanceLimitMeters = 500,
      bool returnUniqueEvenIfOutOfRange = true,
  }) async {
    final limit = distanceLimitMeters > 500 ? 20 : 10;
    String path = "/stationAutocomplete?lon=$long&lat=$lat&limit=$limit";
    final argRails = "&osm_tag=railway:halt&osm_tag=railway:station";
    final argTram = "&osm_tag=railway:tram_stop";
    final argBus = "&osm_tag=amenity:bus_station&osm_tag=highway:bus_stop";
    final argFerry = "&osm_tag=amenity:ferry_terminal";
    const nullReturn = <(String? name, String? address, VehicleType type, double distance)>[];

    debugPrint("$path$argRails$argTram$argBus$argFerry");
    final res = await _client.safeGet<Map<String, dynamic>>("$path$argRails$argTram$argBus$argFerry");

    final data = res.data;
    if (data == null) {
      return nullReturn;
    }

    final features = data['features'];
    if (features is! List || features.isEmpty) {
      return nullReturn;
    }

    List<(String? name, String? address, VehicleType type, double distance)> stations = [];

    // Helper function to calculate distance
    double calculateDistance(double lat1, double long1, double lat2, double long2) {
      final userLocation = LatLng(lat1, long1);
      final stationLocation = LatLng(lat2, long2);
      final distance = Distance();
      return distance.as(LengthUnit.Meter, userLocation, stationLocation);
    }

    // Loop through the received stations and filter them
    for (var feature in features) {
      final properties = feature['properties'] as Map<String, dynamic>?;
      final geometry = feature['geometry'] as Map<String, dynamic>?;
      if (properties == null || geometry == null) continue;

      final coordinates = geometry['coordinates'] as List<dynamic>?;
      if (coordinates == null || coordinates.length < 2) continue;

      final stationLat = coordinates[1] as double;
      final stationLong = coordinates[0] as double;

      final distance = calculateDistance(lat, long, stationLat, stationLong);

      if (distance > distanceLimitMeters) {
        // If the distance is too far, skip this station.
        continue;
      }

      final rawName = properties['name']?.toString();
      final countryCode = properties['countrycode']?.toString() ?? "";
      final flag = countryCodeToEmoji(countryCode);
      String? name = rawName != null ? '$flag $rawName' : null;

      // Address construction
      final street = properties['street']?.toString() ?? '';
      final locality = properties['locality']?.toString() ?? '';
      final district = properties['district']?.toString() ?? '';
      final city = properties['city']?.toString() ?? '';
      final address = [street, locality, district, city].where((e) => e.trim().isNotEmpty).join(", ");

      // Vehicle Type Determination
      VehicleType type = _getVehicleType(properties);

      if (!stations.any((entry) => entry.$1 == name && entry.$3 == type)) {
        stations.add((name, address, type, distance));
      }
    }

    // TODO
    // if (returnUniqueEvenIfOutOfRange && stations.isEmpty) {
    //   stations.add((name, address, type, distance));
    // }

    stations.sort((a, b) => a.$4.compareTo(b.$4)); // Sorting by distance (item4 is the distance)
    return stations;
  }

  // Helper function to determine the vehicle type
  VehicleType _getVehicleType(Map<String, dynamic> properties) {
    final osmKey = properties['osm_key']?.toString();
    final osmValue = properties['osm_value']?.toString();
    if (osmKey == 'railway' && (osmValue == 'station' || osmValue == 'halt')) {
      return VehicleType.rail;
    } else if (osmKey == 'highway' && osmValue == 'bus_stop') {
      return VehicleType.bus;
    } else if (osmKey == 'railway' && osmValue == 'tram_stop') {
      return VehicleType.tram;
    } else if (osmKey == 'railway' && (osmValue == 'stop' || osmValue == 'subway_entrance')) {
      return VehicleType.metro;
    } else if (osmKey == 'amenity' && osmValue == 'ferry_terminal') {
      return VehicleType.ferry;
    } else if (osmKey == 'aerialway' && osmValue == 'station') {
      return VehicleType.plane;
    } else if (osmKey == 'aeroway' && (osmValue == 'helipad' || osmValue == 'heliport')) {
      return VehicleType.helicopter;
    } else {
      return VehicleType.unknown;
    }
  }
}
