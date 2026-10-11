import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:trainlog_app/providers/settings_provider.dart';
import 'package:trainlog_app/providers/trainlog_provider.dart';
import 'package:trainlog_app/services/api/trainlog_http_client.dart';

/// Answers `/login/` with [loginResponse], or throws a connection timeout
/// when it is null. Other requests (operator logos) get an empty JSON body.
class _FakeAdapter implements HttpClientAdapter {
  _FakeAdapter(this.loginResponse);

  final ResponseBody Function()? loginResponse;

  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<List<int>>? requestStream,
    Future<void>? cancelFuture,
  ) async {
    if (loginResponse == null) {
      throw DioException.connectionTimeout(
        timeout: TrainlogHttpClient.connectTimeout,
        requestOptions: options,
      );
    }
    if (options.path.startsWith('/login')) return loginResponse!();
    return ResponseBody.fromString('{"operators": {}}', 200, headers: {
      Headers.contentTypeHeader: [Headers.jsonContentType],
    });
  }

  @override
  void close({bool force = false}) {}
}

ResponseBody _redirectTo(String location) =>
    ResponseBody.fromString('', 302, headers: {'location': [location]});

Future<TrainlogProvider> _restore({
  required ResponseBody Function()? loginResponse,
  String? savedUsername,
}) async {
  SharedPreferences.setMockInitialValues({
    if (savedUsername != null) 'auth.username': savedUsername,
  });
  final settings = SettingsProvider();
  await settings.ready;

  final client = TrainlogHttpClient();
  client.dio.httpClientAdapter = _FakeAdapter(loginResponse);
  final auth = TrainlogProvider(client: client);

  final restore = auth.tryRestoreSession(settings: settings);
  expect(auth.isRestoringSession, isTrue);
  await restore;
  expect(auth.isRestoringSession, isFalse);
  return auth;
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('valid session restores the saved user', () async {
    final auth = await _restore(
      loginResponse: () => _redirectTo('/u/alice'),
      savedUsername: 'alice',
    );
    expect(auth.isAuthenticated, isTrue);
    expect(auth.username, 'alice');
  });

  test('server showing the login page logs out', () async {
    final auth = await _restore(
      loginResponse: () => ResponseBody.fromString('<form>', 200),
      savedUsername: 'alice',
    );
    expect(auth.isAuthenticated, isFalse);
    expect(auth.username, isNull);
  });

  test('unreachable server keeps the saved session', () async {
    final auth = await _restore(loginResponse: null, savedUsername: 'alice');
    expect(auth.isAuthenticated, isTrue);
    expect(auth.username, 'alice');
  });

  test('server error keeps the saved session', () async {
    final auth = await _restore(
      loginResponse: () => ResponseBody.fromString('', 503),
      savedUsername: 'alice',
    );
    expect(auth.isAuthenticated, isTrue);
  });

  test('unreachable server without a saved user shows the login page', () async {
    final auth = await _restore(loginResponse: null);
    expect(auth.isAuthenticated, isFalse);
    expect(auth.error, isNotNull);
  });
}
