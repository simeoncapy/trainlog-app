import 'dart:io';
import 'package:dio/dio.dart';
import 'package:cookie_jar/cookie_jar.dart';
import 'package:dio_cookie_manager/dio_cookie_manager.dart';
import 'package:html/parser.dart' as html;
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as p;
import 'package:cookie_jar/cookie_jar.dart';

class TrainlogLoginResult {
  final bool success;
  final List<Cookie> cookies;
  final String? sessionCookieName;
  final String? csrfToken;
  final Response? lastResponse;
  final String? failureReason;

  const TrainlogLoginResult({
    required this.success,
    required this.cookies,
    this.sessionCookieName,
    this.csrfToken,
    this.lastResponse,
    this.failureReason,
  });
}

class TrainlogAuthService {
  static const String _baseUrl = 'https://trainlog.me';
  static const String _loginPath = '/login/';
  static const String _userAgent = 'TrainlogApp/1.0 (+Flutter)';

  final Dio _dio;
  final CookieJar _cookieJar;

  TrainlogAuthService._(this._dio, this._cookieJar);

  factory TrainlogAuthService() {
    final dio = Dio(
      BaseOptions(
        baseUrl: _baseUrl,
        followRedirects: false,
        validateStatus: (s) => s != null && s >= 200 && s < 400 || s == 302,
        headers: {'User-Agent': _userAgent},
      ),
    );
    final jar = CookieJar();
    dio.interceptors.add(CookieManager(jar));
    return TrainlogAuthService._(dio, jar);
  }

  Future<void> clearSession() async => _cookieJar.deleteAll();
  Future<bool> checkAuthenticated() => _looksAuthenticated();

  Future<TrainlogLoginResult> login({
    required String username,
    required String password,
  }) async {
    // 1) GET /login/ → gather cookies + hidden inputs
    final loginGet = await _dio.get(_loginPath);
    final hidden = _extractHiddenInputs(loginGet.data?.toString() ?? '');

    // Save pre-login session to detect rotation
    final preCookies =
        await _cookieJar.loadForRequest(Uri.parse('$_baseUrl/'));
    final preSession = _findSessionCookie(preCookies)?.value;

    // Try to find CSRF in hidden inputs or cookies
    final initialCookies =
        await _cookieJar.loadForRequest(Uri.parse('$_baseUrl$_loginPath'));
    final csrfCookie = initialCookies.firstWhere(
      (c) => c.name.toLowerCase().contains('csrf'),
      orElse: () => Cookie('', ''),
    );
    final csrfToken = hidden.entries
            .firstWhere(
              (e) => e.key.toLowerCase().contains('csrf'),
              orElse: () => const MapEntry('', ''),
            )
            .value ??
        (csrfCookie.name.isNotEmpty ? csrfCookie.value : null);

    // Build form (don’t let hidden fields override creds)
    hidden.removeWhere(
      (k, _) => k.toLowerCase() == 'username' || k.toLowerCase() == 'password',
    );
    final form = <String, dynamic>{
      ...hidden,
      'username': username,
      'password': password,
    };

    // 2) POST exactly as x-www-form-urlencoded
    final loginPost = await _dio.post(
      _loginPath,
      data: form,
      options: Options(
        contentType: Headers.formUrlEncodedContentType,
        headers: {
          'Origin': _baseUrl,
          'Referer': '$_baseUrl$_loginPath',
          if (csrfToken != null) 'X-CSRFToken': csrfToken,
        },
      ),
    );

    // 3) Success heuristic #1: redirect away from /login/
    final location = loginPost.headers['location']?.first;
    final redirectedAway =
        loginPost.statusCode == 302 &&
        location != null &&
        !location.contains('/login');

    // Follow once if redirected (keeps cookies in jar)
    if (redirectedAway) {
      await _dio.get(location);
    }

    // 4) Heuristic #2: session rotation
    final postCookies =
        await _cookieJar.loadForRequest(Uri.parse('$_baseUrl/'));
    final postSession = _findSessionCookie(postCookies)?.value;
    final rotated = postSession != null &&
        postSession.isNotEmpty &&
        postSession != preSession;

    // 5) Heuristic #3 (strict): /login/ must NOT still show the form
    final loginCheck = await _dio.get(
      _loginPath,
      options: Options(followRedirects: false, validateStatus: (s) => s == 200 || s == 302),
    );
    // If we’re logged in, sites usually redirect off /login/ or render a page without the form
    final loginPageStillVisible =
        (loginCheck.statusCode == 200) &&
        _pageContainsLoginForm(loginCheck.data?.toString() ?? '');

    final success = !loginPageStillVisible && (redirectedAway || rotated);

    String? failureReason;
    if (!success) {
      // Try to extract a visible error from the latest page we have
      final body = (loginCheck.data?.toString() ??
          loginPost.data?.toString() ??
          '');
      failureReason = _extractPossibleError(body);
    }

    return TrainlogLoginResult(
      success: success,
      cookies: postCookies,
      sessionCookieName: _findSessionCookie(postCookies)?.name,
      csrfToken: csrfToken,
      lastResponse: loginPost,
      failureReason: failureReason,
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

  /// Build a service whose cookies persist across restarts.
  static Future<TrainlogAuthService> persistent() async {
    final dir = await getApplicationSupportDirectory();
    final cookieDir = p.join(dir.path, 'cookies'); // e.g., .../Application Support/cookies
    final jar = PersistCookieJar(
      storage: FileStorage(cookieDir),
      persistSession: true, // keep session cookies (no Expires) across restarts
    );

    final dio = Dio(
      BaseOptions(
        baseUrl: _baseUrl,
        followRedirects: false,
        validateStatus: (s) => s != null && (s == 302 || (s >= 200 && s < 400)),
        headers: {'User-Agent': _userAgent},
      ),
    );
    dio.interceptors.add(CookieManager(jar));
    return TrainlogAuthService._(dio, jar);
  }

  Future<String?> fetchUsernameViaApi() async {
    // TODO: call Trainlog’s API endpoint that returns the current user.
    // Example (adjust path & field names to the real API):
    try {
      final res = await _dio.get(
        '/api/me', // <-- replace with the real endpoint
        options: Options(headers: {'Accept': 'application/json'}),
      );
      if (res.statusCode == 200 && res.data is Map) {
        final data = res.data as Map;
        final u = (data['username'] ?? data['user'] ?? data['name'])?.toString();
        if (u != null && u.trim().isNotEmpty) return u.trim();
      }
    } catch (_) {
      // Swallow errors; we’ll just show no name if not available.
    }
    return null;
  }

  // ---- helpers ----

  bool _pageContainsLoginForm(String htmlText) {
    final doc = html.parse(htmlText);
    // The page at /login/ shows username/password inputs and a submit labeled "Log in"
    final hasForm = doc.querySelector('form[action="/login/"]') != null;
    final hasUser = doc.querySelector('input#username, input[name="username"]') != null;
    final hasPass = doc.querySelector('input#password, input[name="password"]') != null;
    return hasForm && hasUser && hasPass;
  }

  String? _extractPossibleError(String body) {
    final doc = html.parse(body);
    final cand = doc
            .querySelector('.error, .alert, .invalid-feedback')
            ?.text
            .trim() ??
        RegExp(r'(Invalid|Incorrect|Wrong|failed|error)[^<\n]+',
                caseSensitive: false)
            .firstMatch(body)
            ?.group(0)
            ?.trim();
    return (cand != null && cand.isNotEmpty) ? cand : null;
  }

  Cookie? _findSessionCookie(List<Cookie> cookies) {
    for (final c in cookies) {
      final n = c.name.toLowerCase();
      if (n.contains('session') || n.contains('auth') || n.contains('jwt')) {
        return c;
      }
    }
    return null;
  }

  Map<String, String> _extractHiddenInputs(String htmlText) {
    final doc = html.parse(htmlText);
    final inputs = doc.querySelectorAll('input[type="hidden"]');
    final map = <String, String>{};
    for (final el in inputs) {
      final name = el.attributes['name']?.trim();
      final value = el.attributes['value']?.trim() ?? '';
      if (name != null && name.isNotEmpty) map[name] = value;
    }
    return map;
  }

  String? _firstMatch(RegExp re, String s) {
    final m = re.firstMatch(s);
    return m == null ? null : m.group(0);
  }

  Future<bool> _looksAuthenticated() async {
    // Check the login page behavior without following redirects.
    final res = await _dio.get(
      _loginPath,
      options: Options(
        followRedirects: false,
        validateStatus: (s) => s == 200 || s == 302,
      ),
    );

    final location = res.headers['location']?.first;
    final redirectedAway = res.statusCode == 302 &&
        location != null &&
        !location.contains('/login');

    final body = res.data?.toString() ?? '';
    final loginFormVisible =
        (res.statusCode == 200) && _pageContainsLoginForm(body);

    // If redirected off /login and no form visible → likely authenticated.
    if (redirectedAway && !loginFormVisible) return true;

    // Consider authenticated only if the login form isn't visible anymore AND we have a logout signal,
    // or we were redirected away from /login.
    return (!loginFormVisible) || redirectedAway;
  }
}
