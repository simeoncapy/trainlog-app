import 'dart:async';
import 'package:flutter_inappwebview/flutter_inappwebview.dart';

class TrainlogSubmitResult {
  final bool ok;
  final dynamic payload;      // whatever saveTrip() returns (often null)
  final String? error;

  const TrainlogSubmitResult({
    required this.ok,
    this.payload,
    this.error,
  });
}

class TrainlogWebPageController {
  InAppWebViewController? _web;
  final Completer<void> _ready = Completer<void>();
  Completer<TrainlogSubmitResult>? _submitCompleter;

  void attach(InAppWebViewController web) {
    _web = web;
  }

  void markReady() {
    if (!_ready.isCompleted) _ready.complete();
  }

  void _detach() {
    _web = null;
  }

  Future<void> waitReady() => _ready.future;

  /// Called by TrainlogWebPage when JS notifies completion
  void onSaveTripDone(bool ok, dynamic payload) {
    final c = _submitCompleter;
    if (c != null && !c.isCompleted) {
      c.complete(TrainlogSubmitResult(
        ok: ok,
        payload: payload,
        error: ok ? null : (payload?.toString() ?? 'Unknown error'),
      ));
    }
  }

  /// Call saveTrip() and wait for the JS callback.
  Future<TrainlogSubmitResult> submitTrip({
    Duration timeout = const Duration(seconds: 20),
  }) async {
    await waitReady();

    final web = _web;
    if (web == null) {
      return const TrainlogSubmitResult(ok: false, error: 'WebView not available');
    }

    // prevent parallel submits
    if (_submitCompleter != null && !(_submitCompleter!.isCompleted)) {
      return const TrainlogSubmitResult(ok: false, error: 'Submit already in progress');
    }

    final completer = Completer<TrainlogSubmitResult>();
    _submitCompleter = completer;

    try {
      await web.evaluateJavascript(source: """
        (function(){
          if (typeof saveTrip !== 'function') {
            throw new Error('saveTrip() not found');
          }
          window.__flutterSubmitting = true;
          saveTrip();
          return true;
        })();
      """);
    } catch (e) {
      onSaveTripDone(false, e.toString());
    }

    return completer.future.timeout(
      timeout,
      onTimeout: () => const TrainlogSubmitResult(ok: false, error: 'Submit timeout'),
    );
  }

  void dispose() {
    _detach();
  }
}
