import 'dart:io';
import 'package:dio/dio.dart';
import 'package:cookie_jar/cookie_jar.dart';
import 'package:dio_cookie_manager/dio_cookie_manager.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as p;

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

class TrainlogAuthService {
  static const String _baseUrl = 'https://trainlog.me';
  static const String _loginPath = '/login'; // we'll add ?raw=1 via query
  static const String _userAgent = 'TrainlogApp/1.0 (+Flutter)';

  final Dio _dio;
  final CookieJar _cookieJar;

  TrainlogAuthService._(this._dio, this._cookieJar);

  /// Non-persistent cookies (useful for tests)
  factory TrainlogAuthService() {
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
    return TrainlogAuthService._(dio, jar);
  }

  /// Persistent cookies (survive app restarts)
  static Future<TrainlogAuthService> persistent() async {
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
    return TrainlogAuthService._(dio, jar);
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
}
