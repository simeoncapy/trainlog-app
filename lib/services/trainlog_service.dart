import 'dart:io';
import 'package:dio/dio.dart';
import 'package:cookie_jar/cookie_jar.dart';
import 'package:dio_cookie_manager/dio_cookie_manager.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as p;
import 'package:latlong2/latlong.dart';
import 'package:trainlog_app/data/models/trips.dart';
import 'package:trainlog_app/utils/text_utils.dart';

class TrainlogLoginResult {
  final bool success;
  final List<Cookie> cookies;
  final String? sessionCookieName;
  final Response? lastResponse;
  final String? failureReason;

  const TrainlogLoginResult({
    required this.success,
    required this.cookies,
    this.sessionCookieName,
    this.lastResponse,
    this.failureReason,
  });
}

class TrainlogService {
  static const String _baseUrl = 'https://trainlog.me';
  static const String _loginPath = '/login';
  static const String _userAgent = 'TrainlogApp/1.0 (+Flutter)';
  static const String _logoPath = "$_baseUrl/static/";

  final Dio _dio;
  final CookieJar _cookieJar;

  TrainlogService._(this._dio, this._cookieJar);

  static String get baseUrl => _baseUrl;

  /// Non-persistent cookies (useful for tests)
  factory TrainlogService() {
    final dio = Dio(
      BaseOptions(
        baseUrl: _baseUrl,
        followRedirects: false,
        validateStatus: (s) => s != null && s >= 200 && s < 400, // general
        headers: {'User-Agent': _userAgent},
      ),
    );
    final jar = CookieJar();
    dio.interceptors.add(CookieManager(jar));
    return TrainlogService._(dio, jar);
  }

  /// Persistent cookies (survive app restarts)
  static Future<TrainlogService> persistent() async {
    final dir = await getApplicationSupportDirectory();
    final cookieDir = p.join(dir.path, 'cookies');
    final jar = PersistCookieJar(
      storage: FileStorage(cookieDir),
      persistSession: true, // keep session cookies without Expires
    );
    final dio = Dio(
      BaseOptions(
        baseUrl: _baseUrl,
        followRedirects: false,
        validateStatus: (s) => s != null && s >= 200 && s < 400,
        headers: {'User-Agent': _userAgent},
      ),
    );
    dio.interceptors.add(CookieManager(jar));
    return TrainlogService._(dio, jar);
  }

  Future<void> clearSession() async {
    _cookieJar.deleteAll();
  }

  /// Lightweight auth check without scraping:
  /// If you're authenticated, GET /login/ typically redirects away (302).
  Future<bool> checkAuthenticated() async {
    final res = await _dio.get(
      '$_loginPath/',
      options: Options(
        followRedirects: false,
        // accept 200/302 so Dio doesn't throw
        validateStatus: (s) => s == 200 || s == 302,
      ),
    );
    if (res.statusCode == 302) {
      final loc = res.headers['location']?.first ?? '';
      return !loc.contains('/login');
    }
    // 200 means login page is still shown → not authenticated
    return false;
  }

  /// New simple login using POST /login?raw=1
  Future<TrainlogLoginResult> login({
    required String username,
    required String password,
  }) async {
    // Send credentials as x-www-form-urlencoded, no hidden fields, no CSRF
    final resp = await _dio.post(
      _loginPath,
      queryParameters: const {'raw': '1'},
      data: {
        'username': username,
        'password': password,
      },
      options: Options(
        contentType: Headers.formUrlEncodedContentType,
        headers: {
          'Origin': _baseUrl,
          'Referer': '$_baseUrl$_loginPath',
        },
        // allow 40x so we can inspect failure
        validateStatus: (s) => s != null && s >= 200 && s < 500,
        followRedirects: false,
      ),
    );

    final success = resp.statusCode == 200;

    // Grab current cookies (session should now be set on success)
    final cookies = await _cookieJar.loadForRequest(Uri.parse('$_baseUrl/'));
    final sessionCookie = _findSessionCookie(cookies);

    return TrainlogLoginResult(
      success: success,
      cookies: cookies,
      sessionCookieName: sessionCookie?.name,
      lastResponse: resp,
      failureReason:
          success ? null : (resp.statusMessage ?? 'Invalid credentials'),
    );
  }

  Future<List<Cookie>> getCookiesForWebView() async {
    return _cookieJar.loadForRequest(Uri.parse(_baseUrl));
  }

  // Expose authenticated requests
  Future<Response<T>> get<T>(String path, {Map<String, dynamic>? query}) =>
      _dio.get(path, queryParameters: query);

  Future<Response<T>> post<T>(String path, Map<String, dynamic> data) =>
      _dio.post(
        path,
        data: data,
        options: Options(contentType: Headers.formUrlEncodedContentType),
      );

  Future<Response<T>> _safeGet<T>(
    String path, {
    Map<String, dynamic>? query,
    ResponseType responseType = ResponseType.json,
    bool followRedirects = true,
    int maxRedirects = 5,
    Map<String, dynamic>? headers,
    ValidateStatus? validate,
  }) {
    return _safeGetWithRetry(() {
      return _dio.get<T>(
        path,
        queryParameters: query,
        options: Options(
          followRedirects: followRedirects,
          maxRedirects: maxRedirects,
          responseType: responseType,
          headers: headers,
          validateStatus: validate ??
              (s) => s != null && s >= 200 && s < 400,
        ),
      );
    });
  }

  Future<Response<T>> _safeGetWithRetry<T>(
    Future<Response<T>> Function() request,
  ) async {
    try {
      return await request();
    } on DioException catch (e) {
      if (e.response?.statusCode == 500) {
        await Future.delayed(const Duration(milliseconds: 300));
        return await request(); // retry once
      }
      rethrow;
    }
  }

  Future<Response<T>> safePost<T>(
    String path, {
    Map<String, dynamic>? query,
    Object? data,
    String contentType = Headers.formUrlEncodedContentType,
    Map<String, dynamic>? headers,
    bool followRedirects = false,
    int maxRedirects = 5,
    ValidateStatus? validateStatus,
  }) {
    return _dio.post<T>(
      path,
      queryParameters: query,
      data: data,
      options: Options(
        contentType: contentType,
        headers: headers,
        followRedirects: followRedirects,
        maxRedirects: maxRedirects,
        validateStatus: validateStatus ?? (s) => s != null && s >= 200 && s < 500,
      ),
    );
  }

  // (Optional) replace when you have a real endpoint
  Future<String?> fetchUsernameViaApi() async {
    // TODO: call Trainlog’s real endpoint to get the current user
    // Example:
    // final res = await _dio.get('/api/me', options: Options(headers: {'Accept': 'application/json'}));
    // if (res.statusCode == 200 && res.data is Map) return (res.data['username'] as String?)?.trim();
    return null;
  }

  Future<String> fetchAllTripsData(String username) async {
    final path = '/u/$username/export';
    try {
      final res = await _safeGet<String>(
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
          print('Not conected: redirected to login → not authenticated');
          return "";
        }
      }

      final csv = res.data ?? '';
      if (csv.isEmpty) {
        print('debugPrintFirstTrips: (empty response)');
        return "";
      }
      return csv;
    } catch (e) {
      print('debugPrintFirstTrips: error fetching $path: $e');
    }
    return '';
  }

  Future<Map<String, String>> fetchAllOperatorLogosUrl(String username) async {
    final path = '/u/$username/getManAndOps/train';

    final res = await _safeGet<Map<String, dynamic>>(path);

    final data = res.data; // already decoded JSON
    if (data == null) return {};

    final ops = data['operators'];
    if (ops is! Map) return {}; // not present or wrong shape

    final out = <String, String>{};
    ops.forEach((k, v) {
      final key = k?.toString().trim();
      final val = v?.toString().trim();
      if (key != null && key.isNotEmpty && val != null && val.isNotEmpty) {
        out[key] = _prefixLogo(_logoPath, val);
      }
    });
    return out;
  }

  Future<Map<String, dynamic>> fetchStatsByVehicle(String username, VehicleType type, int? year) async {
    final path = year == null
        ? '/u/$username/getStats/${type.toShortString()}'
        : '/u/$username/getStats/$year/${type.toShortString()}';

    final res = await _safeGet<Map<String, dynamic>>(path);

    final data = res.data; // already decoded JSON
    if (data == null) return {};

    return data;
  }


  // ---- helpers ----
  Cookie? _findSessionCookie(List<Cookie> cookies) {
    for (final c in cookies) {
      final n = c.name.toLowerCase();
      if (n.contains('session') || n.contains('auth') || n.contains('jwt')) {
        return c;
      }
    }
    return null;
  }

  String _prefixLogo(String base, String path) {
    if (path.isEmpty) return path;

    final p = path.toLowerCase();
    // Don't touch absolute or data URLs
    if (p.startsWith('http://') || p.startsWith('https://') || p.startsWith('data:')) {
      return path;
    }

    // Ensure base ends with a slash, then resolve relative path
    final baseWithSlash = base.endsWith('/') ? base : '$base/';
    final rel = path.startsWith('/') ? path.substring(1) : path;
    return Uri.parse(baseWithSlash).resolve(rel).toString();
  }

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
        final res = await _safeGet<Map<String, dynamic>>(path);
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

  Future<Map<String, (LatLng, String)>> fetchAllManualStationsSuffixed(
    String username,
    VehicleType type,
  ) async {
    final manual = await _fetchRawManualStations(username, type);
    final result = <String, (LatLng, String)>{};

    for (final entry in manual.entries) {
      final baseName = entry.key;
      final coords = entry.value[0];

      final latLng = LatLng(
        _toDouble(coords[0]),
        _toDouble(coords[1]),
      );

      var name = baseName;

      // Handle suffixing
      if (result.containsKey(name)) {
        int suffixIndex = 0;
        while (true) {
          final candidate =
              "$baseName (${String.fromCharCode(97 + suffixIndex)})";
          if (!result.containsKey(candidate)) {
            name = candidate;
            break;
          }
          suffixIndex++;
        }
      }

      result[name] = (latLng, "@manual@");
    }

    return result;
  }

  Future<Map<String, (LatLng, String)>> fetchStations(
    String query,
    VehicleType type,
  ) async {
    String path;
    if(type == VehicleType.plane) {
      path = "/api/airportAutocomplete/";
    }
    else {
      path = "/stationAutocomplete?";
      switch (type) {
        case VehicleType.aerialway:
          path += "osm_tag=aerialway:station&q=";
          break;
        case VehicleType.bus:
          path += "osm_tag=amenity:bus_station&osm_tag=highway:bus_stop&q=";
          break;
        case VehicleType.ferry:
          path += "osm_tag=amenity:ferry_terminal&q=";
          break;
        case VehicleType.helicopter:
          path += "osm_tag=aeroway:helipad&osm_tag=aeroway:heliport&osm_tag=aeroway:aerodrome&q=";
          break;
        case VehicleType.metro:
          path += "osm_tag=railway:station&osm_tag=railway:subway_entrance&q=";
          break;
        case VehicleType.train:
          path += "osm_tag=railway:halt&osm_tag=railway:station&q=";
          break;
        case VehicleType.tram:
          path += "osm_tag=railway:tram_stop&osm_tag=railway:station&osm_tag=railway:halt&q=";
          break;
        default:
          path += "q=";
          break;
      }
    }
    path += query;

    try
    {
      if(type == VehicleType.plane) {
        final res = await _safeGet<List<dynamic>>(path);

        final data = res.data;
        if (data == null) {
          return {};
        }

        return _airportListGenerator(data);
      }
    
      final res = await _safeGet<Map<String, dynamic>>(path);

      final data = res.data;
      if (data == null) {
        return {};
      }

      return _stationListGenerator(data);
    } on Exception catch (_) {
      return {};
    }
  }

  Map<String, (LatLng, String)> _airportListGenerator(List<dynamic> airports) {
    final result = <String, (LatLng, String)>{};

    for (final raw in airports) {
      final entry = raw as Map<String, dynamic>;

      final country = entry['iso_country'] as String? ?? "";
      final city = entry['city'] as String? ?? "";
      final name = entry['name'] as String? ?? "";
      final iata = entry['iata'] as String? ?? "";
      final lat = entry['latitude'] as num?;
      final lng = entry['longitude'] as num?;

      if (lat == null || lng == null) continue;

      final key = "${countryCodeToEmoji(country)} $name ($iata)";
      final value = (LatLng(lat.toDouble(), lng.toDouble()), city);

      result[key] = value;
    }

    return result;
  }

  Map<String, (LatLng, String)> _stationListGenerator(
    Map<String, dynamic> data,
  ) {
    final features = data["features"] as List<dynamic>? ?? [];
    final result = <String, (LatLng, String)>{};

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
      final name = props["name"] as String? ?? "";
      final homonymy = props["homonymy_order"] as String? ?? "";

      final street = props["street"] as String? ?? "";
      final locality = props["locality"] as String? ?? "";
      final district = props["district"] as String? ?? "";
      final city = props["city"] as String? ?? "";

      // --- Key: "🇯🇵 Tokyo - Kita-Senju (a)" ---
      final emoji = countryCodeToEmoji(countryCode);
      final key = "$emoji $name$homonymy";

      // --- Address string ---
      final parts = [
        street,
        locality,
        district,
        city,
      ].where((e) => e.trim().isNotEmpty).toList();

      final address = parts.join(", ");

      result[key] = (latLng, address);
    }

    return result;
  }

  Future<Map<String, int>> fetchAllVisitedStations(String username, VehicleType type) async {
    final path = '/u/$username/getManAndOps/${type.toShortString()}';

    final res = await _dio.get<Map<String, dynamic>>(
      path,
      options: Options(
        followRedirects: true,
        maxRedirects: 5,
        responseType: ResponseType.json,
        validateStatus: (s) => s != null && s >= 200 && s < 400,
      ),
    );

    final data = res.data; // already decoded JSON
    if (data == null) return {};

    final ops = data['visitedStations'];
    if (ops is! Map) return {}; // not present or wrong shape

    final out = <String, int>{};
    ops.forEach((k, v) {
      final key = k?.toString().trim();
      final val = toInt(v);
      if (key != null && key.isNotEmpty && val != null) {
        out[key] = val;
      }
    });
    return out;
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
    String path = "/reverse?lon=$long&lat=$lat&lang=en&limit=10"; // TODO check limit
    final argRails = "&osm_tag=railway:halt&osm_tag=railway:station";
    final argTram = "&osm_tag=railway:tram_stop";
    final argBus = "&osm_tag=amenity:bus_station&osm_tag=highway:bus_stop";
    final argFerry = "&osm_tag=amenity:ferry_terminal";
    const nullReturn = <(String? name, String? address, VehicleType type, double distance)>[];

    final dio = Dio(
      BaseOptions(
        baseUrl: "https://photon.chiel.uk",
        followRedirects: false,
        validateStatus: (s) => s != null && s >= 200 && s < 400,
        headers: {'User-Agent': _userAgent},
      ),
    );

    final res = await dio.get<Map<String, dynamic>>(
      "$path$argRails$argTram$argBus$argFerry",
      options: Options(
        followRedirects: true,
        maxRedirects: 5,
        responseType: ResponseType.json,
        validateStatus: (s) => s != null && s >= 200 && s < 400,
      ),
    );

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
      return VehicleType.train;
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

  int? toInt(dynamic v) {
    if (v == null) return null;
    if (v is int) return v;
    if (v is double) return v.toInt();
    if (v is String) return int.tryParse(v);
    return null;
  }
}
