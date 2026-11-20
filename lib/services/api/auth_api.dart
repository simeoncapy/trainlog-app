import 'dart:convert';

import 'package:dio/dio.dart';
import 'package:cookie_jar/cookie_jar.dart';
import 'package:trainlog_app/services/api/session_expiry.dart';
import 'package:trainlog_app/services/api/trainlog_http_client.dart';
import 'package:trainlog_app/utils/altcha.dart';

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

/// Outcome of a signup request.
class SignupResult {
  final bool success;

  /// Message from the server, already in the user's language.
  final String? message;

  /// Machine-readable reason, when there is one: `captcha_*`/`honeypot`/
  /// `no_captcha` (captcha refused, from the server), `server_error`,
  /// `unsupported_server`. Other refusals only carry [message].
  final String? code;

  const SignupResult.success()
      : success = true,
        message = null,
        code = null;

  const SignupResult.failure({this.message, this.code}) : success = false;

  bool get isCaptchaError =>
      code != null && (code!.startsWith('captcha_') || code == 'no_captcha');
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

  /// Upper bound for the server to answer the startup session check, on
  /// top of [TrainlogHttpClient.connectTimeout].
  static const Duration sessionCheckTimeout = Duration(seconds: 10);

  /// Lightweight auth check without scraping:
  /// If you're authenticated, GET /login/ typically redirects away (302).
  ///
  /// Returns false only when the server explicitly shows the login page.
  /// Network failures, timeouts and unexpected statuses throw instead, so
  /// callers can tell "logged out" apart from "server not reachable".
  Future<bool> checkAuthenticated() async {
    final res = await _client.dio.get(
      '$_loginPath/',
      options: Options(
        followRedirects: false,
        receiveTimeout: sessionCheckTimeout,
        extra: const {skipSessionCheckExtraKey: true},
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
        extra: const {skipSessionCheckExtraKey: true},
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

  /// A fresh proof-of-work challenge for the signup captcha.
  Future<AltchaChallenge> fetchSignupChallenge() async {
    final resp = await _client.dio.get(
      '$_signupPath/challenge',
      options: Options(
        responseType: ResponseType.json,
        headers: {'Accept': 'application/json'},
        extra: const {skipSessionCheckExtraKey: true},
      ),
    );
    final data = resp.data is String ? jsonDecode(resp.data as String) : resp.data;
    if (data is! Map) {
      throw const FormatException('Unexpected signup challenge response');
    }
    return AltchaChallenge.fromJson(Map<String, dynamic>.from(data));
  }

  /// Creates the account with `POST /signup/?raw=1`, which answers in JSON:
  /// `{"username": ...}` on success (the session cookie is then set), else
  /// `{"error": <localised message>, "code": <machine code>}`.
  ///
  /// [altcha] is the solved captcha payload (see [AltchaChallenge]).
  Future<SignupResult> signup({
    required String username,
    required String password,
    required String email,
    required String locale,
    required String altcha,
  }) async {
    final resp = await _client.dio.post(
      '$_signupPath/',
      queryParameters: const {'raw': '1'},
      data: {
        'username': username,
        'password': password,
        'email': email,
        'locale': locale,
        'altcha': altcha,
      },
      options: Options(
        contentType: Headers.formUrlEncodedContentType,
        responseType: ResponseType.json,
        headers: {
          'Accept': 'application/json',
          'Origin': _baseUrl,
          'Referer': '$_baseUrl$_signupPath',
        },
        validateStatus: (s) => s != null && s >= 200 && s < 600,
        followRedirects: false,
        extra: const {skipSessionCheckExtraKey: true},
      ),
    );

    final status = resp.statusCode ?? 0;
    Object? data = resp.data;
    if (data is String) {
      try {
        data = jsonDecode(data);
      } catch (_) {
        // Not JSON: an older server, or a proxy error page
      }
    }
    final body = data is Map ? data : const {};

    if (status == 200 && body['username'] is String) {
      return const SignupResult.success();
    }
    if (status >= 500) {
      return const SignupResult.failure(code: 'server_error');
    }
    final message = body['error'] as String?;
    return SignupResult.failure(
      message: message,
      // A server without the JSON API answers with an HTML page
      code: body['code'] as String? ?? (message == null ? 'unsupported_server' : null),
    );
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
