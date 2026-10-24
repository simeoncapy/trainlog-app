import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
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

  /// Runs [source] in the page and decodes the JSON text it evaluates to, or
  /// returns null when the page is not there or the script failed.
  Future<dynamic> _evaluateJson(String source) async {
    await waitReady();
    final web = _web;
    if (web == null) return null;
    try {
      final result = await web.evaluateJavascript(source: source);
      return result is String ? jsonDecode(result) : null;
    } catch (e) {
      debugPrint('TrainlogWebPageController: script failed: $e');
      return null;
    }
  }

  /// The route currently drawn on the routing page, as its `getRouteForApp()`
  /// returns it: `{ok: true, path, waypoints, route_source, details,
  /// trip_length, estimated_trip_duration}` (`altitude`/`timestamps` too on
  /// the flight page), or `{ok: false, error}` while it is not ready
  /// (`loading`, `error`, `noRoute`). Nothing is saved.
  ///
  /// `error` is `unsupported` when the server's page predates the function.
  Future<Map<String, dynamic>?> readRoute() async {
    final result = await _evaluateJson("""
      JSON.stringify(typeof getRouteForApp === 'function'
        ? getRouteForApp()
        : { ok: false, error: 'unsupported' })
    """);
    return result is Map ? Map<String, dynamic>.from(result) : null;
  }

  /// Whether the routing page uses the new router; null when the page has no
  /// router choice (or is not loaded).
  Future<bool?> readNewRouter() async {
    final result = await _evaluateJson("""
      JSON.stringify(typeof useNewRouter === 'boolean' ? useNewRouter : null)
    """);
    return result is bool ? result : null;
  }

  /// Switches the routing page to the new router or back to the legacy one,
  /// which re-routes. Its checkbox reads "use the legacy router", hence the
  /// inverted value. Returns false when the page has no such switch.
  Future<bool> setNewRouter(bool value) async {
    final result = await _evaluateJson("""
      (function () {
        var cb = document.getElementById('newRouterToggle');
        if (!cb || typeof switchRouter !== 'function') return 'false';
        if (cb.checked !== ${!value}) {
          cb.checked = ${!value};
          switchRouter();
        }
        return 'true';
      })()
    """);
    return result == true;
  }

  /// Switches the routing page between the router and freehand drawing.
  /// Returns false when the page has no freehand mode.
  Future<bool> setFreehand(bool value) async {
    final result = await _evaluateJson("""
      (function () {
        if (typeof enterFreehand !== 'function') return 'false';
        ${value ? 'enterFreehand()' : 'exitFreehand()'};
        return 'true';
      })()
    """);
    return result == true;
  }

  void dispose() {
    _detach();
  }
}
