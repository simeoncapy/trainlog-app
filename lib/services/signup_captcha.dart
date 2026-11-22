import 'dart:async';
import 'dart:convert';

import 'package:altcha_lib/algorithms.dart' show adaptiveDeriveKey;
import 'package:altcha_lib/altcha_lib.dart';
// Only needed while useFastPbkdf2 exists (see below)
import 'package:trainlog_app/utils/fast_pbkdf2.dart';

/// Gets the signup captcha solved in the background, so it is usually ready
/// by the time the user has filled in the form.
///
/// Trainlog protects its signup with ALTCHA, an invisible proof-of-work
/// captcha (the website solves it in the browser the same way): the server
/// sends a signed challenge (`GET /signup/challenge`), the client searches
/// for the counter that solves it, and posts challenge + solution as the
/// `altcha` form field. The protocol is handled by `package:altcha_lib`
/// (from the ALTCHA authors).
///
/// Call [prepare] when the signup page opens, then [payload] on submit. A
/// solved challenge is single use on the server: call [reset] after each
/// signup attempt so the next one starts from a fresh challenge.
class SignupCaptcha {
  SignupCaptcha(this._fetchChallenge);

  final Future<Challenge> Function() _fetchChallenge;

  /// true: compute PBKDF2 with the faster implementation of
  /// lib/utils/fast_pbkdf2.dart (about twice as fast, see the explanation
  /// there). false: use altcha_lib's own PBKDF2 only.
  ///
  /// To drop the custom code for good: set to false, then delete this
  /// constant, the `fast_pbkdf2.dart` import above, lib/utils/fast_pbkdf2.dart
  /// and the "fast PBKDF2" test group in test/signup_test.dart, and use
  /// `adaptiveDeriveKey` directly in [solveInBackground].
  static const bool useFastPbkdf2 = true;

  /// The server refuses a solution posted less than 3 s after its challenge
  /// was issued (a person can't fill the form that fast). Keep a margin.
  static const Duration minFillTime = Duration(seconds: 4);

  /// Parallel solver isolates (on the web, altcha_lib solves on the main
  /// thread instead, yielding regularly so the page stays responsive).
  static const int _workers = 4;
  static const Duration _solveTimeout = Duration(seconds: 90);

  Future<String>? _pending;
  DateTime? _fetchedAt;
  Challenge? _challenge;

  /// Starts fetching and solving a challenge, unless one is already on its
  /// way. Errors are kept for [payload].
  void prepare() {
    if (_pending != null && !_isExpired(_challenge)) return;
    final future = _solveNew();
    // Avoid an "unhandled error" report while nobody awaits it yet
    future.catchError((_) => '');
    _pending = future;
  }

  /// The solved `altcha` field. Waits for the background work if needed.
  Future<String> payload() async {
    prepare();
    try {
      final result = await _pending!;
      final wait = _fetchedAt!.add(minFillTime).difference(DateTime.now());
      if (wait > Duration.zero) await Future<void>.delayed(wait);
      return result;
    } catch (_) {
      // Don't keep a failed attempt (e.g. no network): the next call retries
      _pending = null;
      rethrow;
    }
  }

  /// Drops the current challenge and starts solving a new one.
  void reset() {
    _pending = null;
    _challenge = null;
    prepare();
  }

  Future<String> _solveNew() async {
    final challenge = await _fetchChallenge();
    _challenge = challenge;
    _fetchedAt = DateTime.now();
    final solution = await solveInBackground(challenge);
    if (solution == null) {
      throw StateError('Signup captcha could not be solved');
    }
    return buildPayload(challenge, solution);
  }

  /// Solves [challenge] with altcha_lib's multi-isolate solver.
  static Future<Solution?> solveInBackground(Challenge challenge) {
    return solveChallengeIsolates(
      challenge: challenge,
      deriveKey: useFastPbkdf2 ? fastPbkdf2DeriveKey : adaptiveDeriveKey,
      concurrency: _workers,
      timeout: _solveTimeout,
    );
  }

  /// The value of the `altcha` form field: the challenge, exactly as signed
  /// by the server, and its solution, as base64 JSON.
  static String buildPayload(Challenge challenge, Solution solution) {
    final json = jsonEncode({
      'challenge': challenge.toJson(),
      'solution': solution.toJson(),
    });
    return base64.encode(utf8.encode(json));
  }

  static bool _isExpired(Challenge? challenge) {
    final expiresAt = challenge?.parameters.expiresAt;
    if (expiresAt == null) return false;
    return DateTime.now().millisecondsSinceEpoch / 1000 >= expiresAt;
  }
}
