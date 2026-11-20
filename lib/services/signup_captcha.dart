import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:trainlog_app/utils/altcha.dart';

/// Gets the signup captcha solved in the background, so it is usually ready
/// by the time the user has filled in the form.
///
/// Call [prepare] when the signup page opens, then [payload] on submit. A
/// solved challenge is single use on the server: call [reset] after each
/// signup attempt so the next one starts from a fresh challenge.
class SignupCaptcha {
  SignupCaptcha(this._fetchChallenge);

  final Future<AltchaChallenge> Function() _fetchChallenge;

  /// The server refuses a solution posted less than 3 s after its challenge
  /// was issued (a person can't fill the form that fast). Keep a margin.
  static const Duration minFillTime = Duration(seconds: 4);

  /// Parallel workers, each trying every [_workers]-th chunk of counters.
  static const int _workers = 4;
  static const int _chunk = 200;
  static const int _maxCounter = 10000000;

  Future<String>? _pending;
  DateTime? _fetchedAt;
  AltchaChallenge? _challenge;

  /// Starts fetching and solving a challenge, unless one is already on its
  /// way. Errors are kept for [payload].
  void prepare() {
    if (_pending != null && !(_challenge?.isExpired ?? false)) return;
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
    return buildAltchaPayload(challenge, solution);
  }

  /// Splits the counter search between background isolates, a round of
  /// [_workers] chunks at a time, and returns the lowest matching counter.
  static Future<AltchaSolution?> solveInBackground(AltchaChallenge challenge) async {
    final stopwatch = Stopwatch()..start();
    for (var base = 0; base < _maxCounter; base += _workers * _chunk) {
      final results = await Future.wait([
        for (var i = 0; i < _workers; i++)
          compute(_solveRange, <String, Object?>{
            'challenge': challenge.toJson(),
            'start': base + i * _chunk,
            'end': base + (i + 1) * _chunk,
          }),
      ]);
      for (final r in results) {
        if (r != null) {
          return AltchaSolution(
            counter: r['counter'] as int,
            derivedKey: r['derivedKey'] as String,
            timeMs: stopwatch.elapsedMilliseconds,
          );
        }
      }
      if (challenge.isExpired) return null;
    }
    return null;
  }
}

Map<String, Object?>? _solveRange(Map<String, Object?> job) {
  final challenge = AltchaChallenge.fromJson(
    Map<String, dynamic>.from(job['challenge'] as Map),
  );
  final solution = solveAltcha(
    challenge,
    counterStart: job['start'] as int,
    counterEnd: job['end'] as int,
  );
  if (solution == null) return null;
  return {'counter': solution.counter, 'derivedKey': solution.derivedKey};
}
