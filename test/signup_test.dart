import 'dart:convert';

import 'package:altcha_lib/algorithms.dart' show adaptiveDeriveKey;
import 'package:altcha_lib/altcha_lib.dart';
import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:trainlog_app/core/services/api/auth_api.dart';
import 'package:trainlog_app/core/services/api/trainlog_http_client.dart';
import 'package:trainlog_app/core/services/signup_captcha.dart';
import 'package:trainlog_app/utils/fast_pbkdf2.dart';

import 'fake_trainlog_server.dart';

/// Issued and solved by the server's own library (Python `altcha` 2.3.0),
/// with the server's settings but a small counter to keep the test fast.
const _challengeJson =
    '{"parameters": {"algorithm": "PBKDF2/SHA-256", "cost": 1000, "keyLength": 32, '
    '"keyPrefix": "003931613dc0510e47dfaa4d127ada24", '
    '"nonce": "1411935c966fd99163827ae2a9724b91", '
    '"salt": "0594525f549defff2d2af37edf1bd7c7", '
    '"keySignature": "0a3ba89b340c861c34a28b43533bcbf37a97c0562253aa15dd349b4a7c5b93d6", '
    '"expiresAt": 4102444800}, '
    '"signature": "67144bd3c8094ea4d9075009f51e04f09a81c0b6e58e7ea7d29ee764cca459eb"}';
const _expectedCounter = 37;
const _expectedKey = '003931613dc0510e47dfaa4d127ada24fd15943a709b878a6f9b0957de6cae10';

Challenge get _challenge => Challenge.fromJson(jsonDecode(_challengeJson));

ResponseBody _json(Object body, int status) => ResponseBody.fromString(
      jsonEncode(body),
      status,
      headers: {Headers.contentTypeHeader: [Headers.jsonContentType]},
    );

AuthApi _api(Handler handler) {
  final client = TrainlogHttpClient()..dio.httpClientAdapter = FakeAdapter(handler);
  return AuthApi(client);
}

Future<SignupResult> _signup(AuthApi api) => api.signup(
      username: 'alice',
      password: 'secret',
      email: 'alice@example.com',
      locale: 'fr',
      altcha: 'payload',
    );

void main() {
  group('captcha (altcha_lib)', () {
    // altcha_lib's own PBKDF2 and the faster one (SignupCaptcha.useFastPbkdf2)
    for (final (name, derive) in [
      ('altcha_lib PBKDF2', adaptiveDeriveKey),
      ('fast PBKDF2', fastPbkdf2DeriveKey),
    ]) {
      test('$name: isolates find the counter the server expects', () async {
        final solution = await solveChallengeIsolates(
          challenge: _challenge,
          deriveKey: derive,
          concurrency: 4,
        );
        expect(solution?.counter, _expectedCounter);
        expect(solution?.derivedKey, _expectedKey);
      });
    }

    test('SignupCaptcha solves with the configured PBKDF2', () async {
      final solution = await SignupCaptcha.solveInBackground(_challenge);
      expect(solution?.counter, _expectedCounter);
    });

    test('payload carries the signed parameters untouched', () async {
      final challenge = _challenge;
      final solution = await SignupCaptcha.solveInBackground(challenge);
      final payload = SignupCaptcha.buildPayload(challenge, solution!);
      final decoded = jsonDecode(utf8.decode(base64.decode(payload)));
      expect(decoded['challenge'], jsonDecode(_challengeJson));
      expect(decoded['solution']['counter'], _expectedCounter);
      expect(decoded['solution']['derivedKey'], _expectedKey);
    });
  });

  // Covers lib/utils/fast_pbkdf2.dart: delete with it.
  group('fast PBKDF2', () {
    String hex(List<int> b) => b.map((x) => x.toRadixString(16).padLeft(2, '0')).join();

    test('matches RFC 7914 test vector', () {
      expect(
        hex(pbkdf2Sha256(utf8.encode('passwd'), utf8.encode('salt'), 1)),
        '55ac046e56e3089fec1691c22544b605f94185216dde0465e68b9d57c20dacbc',
      );
    });

    test('matches altcha_lib on varied inputs', () async {
      final params = _challenge.parameters;
      for (final (pwLen, saltLen, rounds) in [
        (20, 16, 1), (20, 16, 2), (20, 16, 1000), (70, 16, 3), (5, 60, 4), (0, 0, 2),
      ]) {
        final password = List<int>.generate(pwLen, (i) => (i * 37 + 11) & 0xff);
        final salt = List<int>.generate(saltLen, (i) => (i * 91 + 5) & 0xff);
        final p = ChallengeParameters.fromJson({...params.toJson(), 'cost': rounds});
        final ours = await fastPbkdf2DeriveKey(p, salt, password);
        final theirs = await adaptiveDeriveKey(p, salt, password);
        expect(hex(ours.derivedKey), hex(theirs.derivedKey),
            reason: 'password $pwLen B, salt $saltLen B, $rounds rounds');
      }
    });

    test('leaves other algorithms to altcha_lib', () async {
      final p = ChallengeParameters.fromJson(
          {..._challenge.parameters.toJson(), 'algorithm': 'SHA-256'});
      final ours = await fastPbkdf2DeriveKey(p, [1, 2], [3, 4]);
      final theirs = await adaptiveDeriveKey(p, [1, 2], [3, 4]);
      expect(hex(ours.derivedKey), hex(theirs.derivedKey));
    });
  });

  group('signup API', () {
    test('posts the form and the captcha to /signup/?raw=1', () async {
      late RequestOptions sent;
      final res = await _signup(_api((o) {
        sent = o;
        return _json({'username': 'alice'}, 200);
      }));
      expect(res.success, isTrue);
      expect(sent.method, 'POST');
      expect(sent.path, '/signup/');
      expect(sent.queryParameters['raw'], '1');
      final data = sent.data as Map;
      expect(data['altcha'], 'payload');
      expect(data['locale'], 'fr');
      expect(data['email'], 'alice@example.com');
    });

    test('returns the server message and code', () async {
      final res = await _signup(_api((_) => _json(
            {'error': "Nom d'utilisateur indisponible"},
            409,
          )));
      expect(res.success, isFalse);
      expect(res.message, "Nom d'utilisateur indisponible");
      expect(res.code, isNull);
      expect(res.isCaptchaError, isFalse);
    });

    test('flags a refused captcha', () async {
      final res = await _signup(_api((_) => _json(
            {'error': 'bot', 'code': 'captcha_replayed'},
            403,
          )));
      expect(res.isCaptchaError, isTrue);
    });

    test('a server without the JSON API is reported, not taken for success', () async {
      final res = await _signup(_api((_) => redirectTo('/signup')));
      expect(res.success, isFalse);
      expect(res.code, 'unsupported_server');
    });

    test('server errors', () async {
      final res = await _signup(_api((_) => ResponseBody.fromString('oops', 500)));
      expect(res.code, 'server_error');
    });

    test('fetches the challenge', () async {
      final api = _api((o) {
        expect(o.path, '/signup/challenge');
        return _json(jsonDecode(_challengeJson), 200);
      });
      final challenge = await api.fetchSignupChallenge();
      expect(challenge.parameters.nonce, '1411935c966fd99163827ae2a9724b91');
      expect(challenge.signature, isNotNull);
    });
  });
}
