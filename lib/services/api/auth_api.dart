import 'package:dio/dio.dart';
import 'package:cookie_jar/cookie_jar.dart';
import 'package:flutter/foundation.dart';
import 'package:trainlog_app/services/api/trainlog_http_client.dart';

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

/// Authentication and session domain: login, signup, session checks and the
/// cookie helpers used by the WebView shells.
class AuthApi {
  static const String _loginPath = '/login';
  static const String _signupPath = '/signup';

  final TrainlogHttpClient _client;

  AuthApi(this._client);

  String get _baseUrl => _client.baseUrl;

  Future<void> clearSession() async {
    _client.cookieJar.deleteAll();
  }

  /// Lightweight auth check without scraping:
  /// If you're authenticated, GET /login/ typically redirects away (302).
  Future<bool> checkAuthenticated() async {
    final res = await _client.dio.get(
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
    final resp = await _client.dio.post(
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
    final cookies = await _client.cookieJar.loadForRequest(Uri.parse('$_baseUrl/'));
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

  Future<(bool, String?)> signup({
    required String username,
    required String password,
    required String email,
    required String locale,
  }) async {
    final resp = await _client.dio.post(
      _signupPath,
      data: {
        'username': username,
        'password': password,
        'email': email,
        'fromApp': 'true',
        'locale': locale,
      },
      options: Options(
        contentType: Headers.formUrlEncodedContentType,
        headers: {
          'Origin': _baseUrl,
          'Referer': '$_baseUrl$_signupPath',
        },
        validateStatus: (s) => s != null && s >= 200 && s <= 503,
        followRedirects: false,
      ),
    );

    debugPrint('Signup response: ${resp.statusCode} ${resp.statusMessage} ${resp.data}');
    String? message = resp.data is Map<String, dynamic>
        ? resp.data["error"] as String?
        : null;
    if ((resp.statusCode ?? 0) >= 500) message = "Server error, please try again later.";
    return (resp.statusCode == 200, message);
  }

  Future<List<Cookie>> getCookiesForWebView() async {
    return _client.cookieJar.loadForRequest(Uri.parse(_baseUrl));
  }

  // (Optional) replace when you have a real endpoint
  Future<String?> fetchUsernameViaApi() async {
    // TODO: call Trainlog’s real endpoint to get the current user
    // Example:
    // final res = await _client.dio.get('/api/me', options: Options(headers: {'Accept': 'application/json'}));
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
