import 'dart:async';

import 'package:dio/dio.dart';

/// Thrown (wrapped in a [DioException]) when the server answers a request by
/// sending the user to the login page: the session cookie has expired.
class SessionExpiredException implements Exception {
  const SessionExpiredException();

  @override
  String toString() => 'Session expired';
}

const Object _backgroundZoneKey = #trainlogBackgroundRequest;
const String _backgroundExtraKey = 'trainlog.background';

/// [Options.extra] key for requests that must never be treated as a session
/// expiry: the login and session-check requests, where a redirect to the
/// login page is an expected answer.
const String skipSessionCheckExtraKey = 'trainlog.skipSessionCheck';

/// Runs [body] with every request it makes flagged as background work (sync,
/// logo or news fetches...). An expired session found by such a request
/// shows the banner but never opens the login sheet by itself: only actions
/// the user started do.
Future<T> runInBackground<T>(Future<T> Function() body) =>
    runZoned(body, zoneValues: {_backgroundZoneKey: true});

/// Spots expired sessions on any request to the Trainlog server and reports
/// them through [onSessionExpired]. The request then fails with a
/// [SessionExpiredException] instead of handing the login page HTML to code
/// expecting JSON or CSV.
class SessionExpiryInterceptor extends Interceptor {
  SessionExpiryInterceptor(this.onSessionExpired);

  final void Function({required bool background}) onSessionExpired;

  @override
  void onRequest(RequestOptions options, RequestInterceptorHandler handler) {
    // Captured here: this runs in the zone of the caller.
    if (Zone.current[_backgroundZoneKey] == true) {
      options.extra[_backgroundExtraKey] = true;
    }
    handler.next(options);
  }

  @override
  void onResponse(Response response, ResponseInterceptorHandler handler) {
    if (_isSessionExpired(response)) {
      handler.reject(_expired(response), true);
      return;
    }
    handler.next(response);
  }

  @override
  void onError(DioException err, ErrorInterceptorHandler handler) {
    final response = err.response;
    // Already reported by onResponse (rejections come back through here).
    if (err.error is SessionExpiredException) {
      handler.next(err);
      return;
    }
    if (response != null && _isSessionExpired(response)) {
      handler.next(_expired(response));
      return;
    }
    handler.next(err);
  }

  DioException _expired(Response response) {
    final options = response.requestOptions;
    onSessionExpired(background: options.extra[_backgroundExtraKey] == true);
    return DioException(
      requestOptions: options,
      response: response,
      type: DioExceptionType.badResponse,
      error: const SessionExpiredException(),
    );
  }

  static bool _isSessionExpired(Response response) {
    final options = response.requestOptions;
    if (options.extra[skipSessionCheckExtraKey] == true) return false;

    final status = response.statusCode;
    if (status == 401) return true;

    // Redirect not followed (POST, or followRedirects: false).
    if (status != null && status >= 300 && status < 400) {
      final location = response.headers.value('location');
      if (location != null && _isLoginPath(Uri.tryParse(location))) return true;
    }

    // Redirect followed: we landed on the login page.
    if (response.redirects.isNotEmpty && _isLoginPath(response.realUri)) {
      return true;
    }
    return false;
  }

  static bool _isLoginPath(Uri? uri) {
    if (uri == null) return false;
    final path = uri.path;
    return path == '/login' || path.startsWith('/login/');
  }
}
