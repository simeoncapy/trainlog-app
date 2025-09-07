import 'dart:io';
import 'package:dio/dio.dart';
import 'package:cookie_jar/cookie_jar.dart';
import 'package:dio_cookie_manager/dio_cookie_manager.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as p;
import 'dart:convert';
import 'dart:math' as math;

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
  static const String _loginPath = '/login'; // we'll add ?raw=1 via query
  static const String _userAgent = 'TrainlogApp/1.0 (+Flutter)';

  final Dio _dio;
  final CookieJar _cookieJar;

  TrainlogService._(this._dio, this._cookieJar);

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

  Future<void> clearSession() async => _cookieJar.deleteAll();

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

  // Expose authenticated requests
  Future<Response<T>> get<T>(String path, {Map<String, dynamic>? query}) =>
      _dio.get(path, queryParameters: query);

  Future<Response<T>> post<T>(String path, Map<String, dynamic> data) =>
      _dio.post(
        path,
        data: data,
        options: Options(contentType: Headers.formUrlEncodedContentType),
      );

  // (Optional) replace when you have a real endpoint
  Future<String?> fetchUsernameViaApi() async {
    // TODO: call Trainlog’s real endpoint to get the current user
    // Example:
    // final res = await _dio.get('/api/me', options: Options(headers: {'Accept': 'application/json'}));
    // if (res.statusCode == 200 && res.data is Map) return (res.data['username'] as String?)?.trim();
    return null;
  }

  Future<String> fetchAllTripsData(String username) async {
    final path = '/$username/export';
    try {
      final res = await _dio.get<String>(
        path,
        options: Options(
          followRedirects: true,     // follow harmless redirects
          maxRedirects: 5,
          responseType: ResponseType.plain, // get raw CSV as String
          headers: {'Accept': 'text/csv, text/plain;q=0.9, */*;q=0.8'},
          validateStatus: (s) => s != null && s >= 200 && s < 400,
        ),
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

    /// Debug helper: fetch all trips for a user and print the first [limit] rows.
  /// URL shape: https://trainlog.me/<username>/getTripsPaths/all
  Future<void> debugPrintFirstTrips(String username, {int limit = 10}) async {
    final path = '/$username/export';
    try {
      final res = await _dio.get<String>(
        path,
        options: Options(
          followRedirects: true,     // follow harmless redirects
          maxRedirects: 5,
          responseType: ResponseType.plain, // get raw CSV as String
          headers: {'Accept': 'text/csv, text/plain;q=0.9, */*;q=0.8'},
          validateStatus: (s) => s != null && s >= 200 && s < 400,
        ),
      );

      // If we still ended at a redirect, check if it's a login redirect
      if (res.statusCode != null && res.statusCode! >= 300 && res.statusCode! < 400) {
        final loc = res.headers['location']?.first ?? '';
        if (loc.contains('/login')) {
          print('debugPrintFirstTrips: redirected to login → not authenticated');
          return;
        }
      }

      final csv = res.data ?? '';
      if (csv.isEmpty) {
        print('debugPrintFirstTrips: (empty response)');
        return;
      }

      _printFirstCsvLines(csv, limit: limit);
    } catch (e) {
      print('debugPrintFirstTrips: error fetching $path: $e');
    }
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

  /// Prints the header + first [limit] non-empty lines without splitting the whole CSV.
  /// Handles CRLF and trims trailing \r. (Does not attempt full CSV quoting rules.)
  void _printFirstCsvLines(String body, {int limit = 10}) {
    int pos = 0;

    // Header
    int next = body.indexOf('\n', pos);
    if (next == -1) {
      final headerOnly = _trimCr(body);
      print('[header] $headerOnly');
      print('debugPrintFirstTrips: printed 0/0 line(s)');
      return;
    }
    String header = _trimCr(body.substring(pos, next)).replaceFirst('\uFEFF', ''); // strip BOM if present
    print('[header] $header');
    pos = next + 1;

    // First N lines
    int printed = 0;
    while (printed < limit && pos < body.length) {
      next = body.indexOf('\n', pos);
      String line;
      if (next == -1) {
        line = _trimCr(body.substring(pos));
        pos = body.length;
      } else {
        line = _trimCr(body.substring(pos, next));
        pos = next + 1;
      }
      if (line.isEmpty) continue;
      printed++;
      print('[$printed] $line');
    }

    // Try to estimate remaining lines cheaply (scan a small tail window)
    int remainingEstimate = 0;
    if (pos < body.length) {
      final tail = body.substring(pos, math.min(body.length, pos + 64 * 1024));
      remainingEstimate = '\n'.allMatches(tail).length;
      if (tail.isNotEmpty && !tail.endsWith('\n')) remainingEstimate += 1;
    }

    print('debugPrintFirstTrips: printed $printed line(s)${remainingEstimate > 0 ? " (+ ~$remainingEstimate more…)" : ""}');
  }

  String _trimCr(String s) {
    // Drop trailing \r if CRLF
    if (s.isNotEmpty && s.codeUnitAt(s.length - 1) == 13) {
      return s.substring(0, s.length - 1);
    }
    return s;
  }
}
