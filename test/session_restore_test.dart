import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:trainlog_app/providers/settings_provider.dart';
import 'package:trainlog_app/providers/trainlog_provider.dart';
import 'package:trainlog_app/services/api/session_expiry.dart';
import 'package:trainlog_app/services/api/trainlog_http_client.dart';

import 'fake_trainlog_server.dart';

class _Setup {
  _Setup(this.auth, this.adapter);
  final TrainlogProvider auth;
  final FakeAdapter adapter;
}

Future<_Setup> _restore({Handler? handler, String? savedUsername}) async {
  SharedPreferences.setMockInitialValues({
    if (savedUsername != null) 'auth.username': savedUsername,
  });
  final settings = SettingsProvider();
  await settings.ready;

  final adapter = FakeAdapter(handler);
  final client = TrainlogHttpClient();
  client.dio.httpClientAdapter = adapter;
  final auth = TrainlogProvider(client: client);

  final restore = auth.tryRestoreSession(settings: settings);
  expect(auth.isRestoringSession, isTrue);
  await restore;
  expect(auth.isRestoringSession, isFalse);
  return _Setup(auth, adapter);
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('startup', () {
    test('valid session restores the saved user', () async {
      final s = await _restore(handler: fakeServer(signedIn: () => true), savedUsername: 'alice');
      expect(s.auth.isAuthenticated, isTrue);
      expect(s.auth.sessionExpired, isFalse);
      expect(s.auth.username, 'alice');
    });

    test('expired session keeps the saved user, flagged expired', () async {
      final s = await _restore(handler: fakeServer(signedIn: () => false), savedUsername: 'alice');
      expect(s.auth.isAuthenticated, isTrue);
      expect(s.auth.sessionExpired, isTrue);
      expect(s.auth.username, 'alice');
    });

    test('login page without a saved user shows the login page', () async {
      final s = await _restore(handler: fakeServer(signedIn: () => false));
      expect(s.auth.isAuthenticated, isFalse);
      expect(s.auth.username, isNull);
    });

    test('unreachable server keeps the saved session', () async {
      final s = await _restore(handler: null, savedUsername: 'alice');
      expect(s.auth.isAuthenticated, isTrue);
      expect(s.auth.sessionExpired, isFalse);
      expect(s.auth.username, 'alice');
    });

    test('server error keeps the saved session', () async {
      final s = await _restore(
        handler: (_) => ResponseBody.fromString('', 503),
        savedUsername: 'alice',
      );
      expect(s.auth.isAuthenticated, isTrue);
      expect(s.auth.sessionExpired, isFalse);
    });

    test('unreachable server without a saved user shows the login page', () async {
      final s = await _restore(handler: null);
      expect(s.auth.isAuthenticated, isFalse);
      expect(s.auth.error, isNotNull);
    });
  });

  group('expiry while signed in', () {
    test('a user request sent to the login page marks the session expired and asks to log in', () async {
      var signedIn = true;
      final s = await _restore(handler: fakeServer(signedIn: () => signedIn), savedUsername: 'alice');
      final prompts = <void>[];
      final sub = s.auth.loginPrompts.listen(prompts.add);

      signedIn = false;
      await expectLater(
        s.auth.get('/u/alice/something'),
        throwsA(isA<DioException>().having((e) => e.error, 'error', isA<SessionExpiredException>())),
      );
      await Future<void>.delayed(Duration.zero);

      expect(s.auth.isAuthenticated, isTrue);
      expect(s.auth.sessionExpired, isTrue);
      expect(prompts, hasLength(1));
      await sub.cancel();
    });

    test('a background request marks the session expired without asking to log in', () async {
      var signedIn = true;
      final s = await _restore(handler: fakeServer(signedIn: () => signedIn), savedUsername: 'alice');
      final prompts = <void>[];
      final sub = s.auth.loginPrompts.listen(prompts.add);

      signedIn = false;
      await expectLater(
        runInBackground(() => s.auth.get('/u/alice/something')),
        throwsA(isA<DioException>()),
      );
      await Future<void>.delayed(Duration.zero);

      expect(s.auth.sessionExpired, isTrue);
      expect(prompts, isEmpty);

      // The banner can still open the sheet.
      s.auth.requestLogin();
      await Future<void>.delayed(Duration.zero);
      expect(prompts, hasLength(1));
      await sub.cancel();
    });

    test('a 401 counts as an expired session', () async {
      final s = await _restore(handler: fakeServer(signedIn: () => true), savedUsername: 'alice');
      s.adapter.handler = (_) => ResponseBody.fromString('', 401);
      await expectLater(s.auth.get('/u/alice/something'), throwsA(isA<DioException>()));
      expect(s.auth.sessionExpired, isTrue);
    });

    test('requests while logged out are not a session expiry', () async {
      final s = await _restore(handler: fakeServer(signedIn: () => false));
      await expectLater(s.auth.get('/u/alice/something'), throwsA(isA<DioException>()));
      expect(s.auth.sessionExpired, isFalse);
      expect(s.auth.isAuthenticated, isFalse);
    });
  });

  group('log in again', () {
    test('wrong password keeps the user signed in with an expired session', () async {
      final s = await _restore(handler: fakeServer(signedIn: () => false), savedUsername: 'alice');
      expect(await s.auth.reLogin('wrong'), ReLoginFailure.credentials);
      expect(s.auth.isAuthenticated, isTrue);
      expect(s.auth.sessionExpired, isTrue);
      expect(s.auth.username, 'alice');
    });

    test('network error is reported as such', () async {
      final s = await _restore(handler: fakeServer(signedIn: () => false), savedUsername: 'alice');
      s.adapter.handler = null;
      expect(await s.auth.reLogin('secret'), ReLoginFailure.network);
      expect(s.auth.isAuthenticated, isTrue);
      expect(s.auth.sessionExpired, isTrue);
    });

    test('right password restores the session', () async {
      var signedIn = false;
      final s = await _restore(handler: fakeServer(signedIn: () => signedIn), savedUsername: 'alice');
      final generation = s.auth.sessionGeneration;
      signedIn = true;
      expect(await s.auth.reLogin('secret'), isNull);
      expect(s.auth.isAuthenticated, isTrue);
      expect(s.auth.sessionExpired, isFalse);
      expect(s.auth.username, 'alice');
      expect(s.auth.sessionGeneration, generation + 1);
    });
  });

  group('revalidation after an unreachable startup', () {
    test('confirmed session', () async {
      final s = await _restore(handler: null, savedUsername: 'alice');
      s.adapter.handler = fakeServer(signedIn: () => true);
      expect(await s.auth.revalidateSession(), isTrue);
      expect(s.auth.sessionExpired, isFalse);
      // Only once.
      expect(await s.auth.revalidateSession(), isFalse);
    });

    test('expired session shows the banner without asking to log in', () async {
      final s = await _restore(handler: null, savedUsername: 'alice');
      final prompts = <void>[];
      final sub = s.auth.loginPrompts.listen(prompts.add);
      s.adapter.handler = fakeServer(signedIn: () => false);
      expect(await s.auth.revalidateSession(), isFalse);
      await Future<void>.delayed(Duration.zero);
      expect(s.auth.isAuthenticated, isTrue);
      expect(s.auth.sessionExpired, isTrue);
      expect(prompts, isEmpty);
      await sub.cancel();
    });

    test('still unreachable: tries again next time', () async {
      final s = await _restore(handler: null, savedUsername: 'alice');
      expect(await s.auth.revalidateSession(), isFalse);
      s.adapter.handler = fakeServer(signedIn: () => true);
      expect(await s.auth.revalidateSession(), isTrue);
    });

    test('nothing to do after a confirmed startup', () async {
      final s = await _restore(handler: fakeServer(signedIn: () => true), savedUsername: 'alice');
      expect(await s.auth.revalidateSession(), isFalse);
    });
  });
}
