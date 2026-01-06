import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_inappwebview/flutter_inappwebview.dart';
import 'package:provider/provider.dart';

import 'package:trainlog_app/data/controllers/trainlog_web_controller.dart';
import '../providers/trainlog_provider.dart';

class TrainlogWebPage extends StatefulWidget {
  final String trainlogPage;
  final bool publicPage;
  final Map<String, String>? query;
  final Map<String, String>? initialPostForm;
  final bool? routerToggleValue;
  final ValueChanged<String>? onRouteInfoChanged;
  final TrainlogWebPageController? controller;

  const TrainlogWebPage({
    super.key,
    required this.trainlogPage,
    this.publicPage = false,
    this.query,
    this.initialPostForm,
    this.routerToggleValue,
    this.onRouteInfoChanged,
    this.controller,
  });

  @override
  State<TrainlogWebPage> createState() => _TrainlogWebPageState();
}

class _TrainlogWebPageState extends State<TrainlogWebPage> {
  InAppWebViewController? _controller;
  bool _cookiesInjected = false;
  TrainlogProvider? _provider;

  Uri? _uri;
  String? _allowedHost; // cache for quick checks
  WebUri? _cookieWebUri; // cache for cookie manager

  bool _injecting = false;

  @override
  void didUpdateWidget(covariant TrainlogWebPage oldWidget) {
    super.didUpdateWidget(oldWidget);

    // If Flutter checkbox changed, push it into the web page
    if (widget.routerToggleValue != null &&
        widget.routerToggleValue != oldWidget.routerToggleValue) {
      _setRouterToggleInPage(widget.routerToggleValue!);
    }
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();

    // Only initialize once
    if (_provider != null) return;

    _provider = context.read<TrainlogProvider>();

    final baseUrl = _provider!.generateUserUrl(
      widget.trainlogPage,
      publicPage: widget.publicPage,
    );

    final parsed = Uri.parse(baseUrl);

    final mergedQuery = <String, String>{
      ...parsed.queryParameters,
      if (widget.query != null) ...widget.query!,
    };

    _uri = parsed.replace(queryParameters: mergedQuery);
    _allowedHost = _uri!.host;

    _cookieWebUri = WebUri(
      '${_uri!.scheme}://${_uri!.host}${_uri!.hasPort ? ':${_uri!.port}' : ''}',
    );

    _injectCookies(); // fire and forget
  }

  @override
  void dispose() {
    // Avoid keeping a controller reference during teardown
    _controller = null;
    super.dispose();
  }

  Future<void> _injectCookies() async {
    if (_injecting) return;
    _injecting = true;

    final provider = _provider;
    final cookieWebUri = _cookieWebUri;
    if (provider == null || cookieWebUri == null) return;

    try {
      final cookies = await provider.service.getCookiesForWebView();
      if (!mounted) return;

      final cookieManager = CookieManager.instance();
      for (final c in cookies) {
        if (!mounted) return;
        await cookieManager.setCookie(
          url: cookieWebUri,
          name: c.name,
          value: c.value,
          domain: c.domain,
          path: c.path ?? '/',
          isHttpOnly: c.httpOnly,
          isSecure: c.secure,
        );
      }

      if (!mounted) return;
      setState(() => _cookiesInjected = true);
    } finally {
      _injecting = false;
    }
  }

  Future<void> _hideNavbar(InAppWebViewController controller) async =>
      _hideElement(controller, 'nav.navbar.navbar-expand-xl.navbar-light.bg-light');

  Future<void> _hideRouterUi(InAppWebViewController controller) async =>
      _hideElement(controller, 'leaflet-control-container');

  Future<void> _hideElement(
    InAppWebViewController controller,
    String element,
  ) async {
    if (!mounted) return;
    try {
      await controller.evaluateJavascript(source: """
        (function () {
          const el = document.querySelector('$element');
          if (el) el.style.display = 'none';
        })();
      """);
    } catch (_) {
      // WebView might be disposing; ignore
    }
  }

  Uint8List _encodeFormBody(Map<String, String> fields) {
    final body = Uri(queryParameters: fields).query;
    return Uint8List.fromList(utf8.encode(body));
  }

  URLRequest _buildInitialRequest() {
    final uri = _uri;
    if (uri == null) {
      return URLRequest(url: WebUri('about:blank'));
    }

    final postForm = widget.initialPostForm;
    if (postForm == null) {
      return URLRequest(url: WebUri(uri.toString()));
    }

    return URLRequest(
      url: WebUri(uri.toString()),
      method: 'POST',
      body: _encodeFormBody(postForm),
      headers: const {
        'Content-Type': 'application/x-www-form-urlencoded',
      },
    );
  }

  Future<void> _setRouterToggleInPage(bool value) async {
    final c = _controller;
    if (c == null) return;

    final v = value ? 'true' : 'false';

    await c.evaluateJavascript(source: """
      (function () {
        const cb = document.getElementById('newRouterToggle');
        if (!cb) return;
        if (cb.checked === $v) return;
        cb.checked = $v;
      })();
    """);

    if (_controller != null) {
      _controller?.evaluateJavascript(source: 'switchRouter();');
    }
  }

  Future<void> _bindRouterBridge(InAppWebViewController controller) async {
    await controller.evaluateJavascript(source: r"""
      (function () {
        if (window.__flutterBridgeInstalled) return;
        window.__flutterBridgeInstalled = true;

        const MAX_TRIES = 80;
        let tries = 0;

        function readRouteInfo() {
          const i = document.querySelector('#sidebar p i');
          const txt = i ? (i.textContent || '').trim() : '';
          window.flutter_inappwebview.callHandler('routeInfoChanged', txt);
        }

        function installPostHook() {
          if (!window.$ || typeof $.post !== 'function') return false;
          if (window.__flutterPostHooked) return true;
          window.__flutterPostHooked = true;

          const origPost = $.post.bind($);

          $.post = function () {
            try {
              const arg0 = arguments[0];

              // Your code uses $.post({ url, data, success, error })
              const opts = (arg0 && typeof arg0 === 'object') ? arg0 : null;
              const url = opts && typeof opts.url === 'string' ? opts.url : '';

              const isSaveTrip = url.includes('/saveTrip');

              if (isSaveTrip) {
                const origSuccess = opts.success;
                const origError = opts.error;

                opts.success = function (res, status, xhr) {
                  // Only notify Flutter if Flutter initiated a submit
                  if (window.__flutterSubmitting) {
                    window.__flutterSubmitting = false;
                    window.flutter_inappwebview.callHandler('saveTripDone', true, {
                      status: xhr ? xhr.status : null,
                      statusText: xhr ? xhr.statusText : null,
                      response: res ?? null
                    });
                  }
                  if (origSuccess) return origSuccess.apply(this, arguments);
                };

                opts.error = function (xhr, status, err) {
                  if (window.__flutterSubmitting) {
                    window.__flutterSubmitting = false;
                    window.flutter_inappwebview.callHandler('saveTripDone', false, {
                      status: xhr ? xhr.status : null,
                      statusText: xhr ? xhr.statusText : null,
                      error: err ? ('' + err) : (status ? ('' + status) : null),
                      responseText: xhr ? (xhr.responseText || null) : null
                    });
                  }
                  if (origError) return origError.apply(this, arguments);
                };
              }
            } catch (e) {
              // ignore hook errors
            }

            return origPost.apply(this, arguments);
          };

          return true;
        }

        function bind() {
          const sidebar = document.getElementById('sidebar');
          const hooked = installPostHook();

          if (!sidebar || !hooked) {
            tries++;
            if (tries < MAX_TRIES) return setTimeout(bind, 100);
            return;
          }

          // initial info + observer
          readRouteInfo();
          if (!sidebar.__flutterObserver) {
            const obs = new MutationObserver(function () { readRouteInfo(); });
            obs.observe(sidebar, { subtree: true, childList: true, characterData: true });
            sidebar.__flutterObserver = obs;
          }
        }

        bind();
      })();
    """);
  }

  Future<void> _debugHookSaveTrip(InAppWebViewController c) async {
    await c.evaluateJavascript(source: r"""
      (function () {
        if (window.__flutterHookedPost) return;
        window.__flutterHookedPost = true;

        const origPost = $.post;
        $.post = function(opts) {
          try {
            if (opts && typeof opts === 'object' && opts.url && opts.url.includes('/saveTrip')) {
              const data = opts.data || {};
              window.flutter_inappwebview.callHandler('saveTripDebug', {
                url: opts.url,
                jsonPath: data.jsonPath,
                newTrip: data.newTrip
              });
            }
          } catch (e) {}
          return origPost.apply(this, arguments);
        };
      })();
    """);
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<TrainlogProvider>();
    final allowedHost = _allowedHost;
    final isRouter = widget.initialPostForm != null;

    if (!provider.isAuthenticated || provider.username == null) {
      return const Center(
        child: Text('You must be logged in to view this page'),
      );
    }

    if (!_cookiesInjected) {
      return const Center(child: CircularProgressIndicator());
    }

    return InAppWebView(
      initialUrlRequest: _buildInitialRequest(),
      initialSettings: InAppWebViewSettings(
        javaScriptEnabled: true,
        domStorageEnabled: true,
        useShouldOverrideUrlLoading: true,
        mediaPlaybackRequiresUserGesture: false,
        allowsInlineMediaPlayback: true,
        transparentBackground: false,
        isInspectable: true,
      ),
      onConsoleMessage: (controller, msg) {
        debugPrint('🧠 JS console: ${msg.message}');
      },
      onWebViewCreated: (controller) {
        _controller = controller;
        widget.controller?.attach(controller);

        controller.addJavaScriptHandler(
          handlerName: 'routeInfoChanged',
          callback: (args) {
            final text =
                args.isNotEmpty ? (args.first?.toString() ?? '') : '';
            widget.onRouteInfoChanged?.call(text);
            return null;
          },
        );

        controller.addJavaScriptHandler(
          handlerName: 'saveTripDone',
          callback: (args) {
            // args: [ok(bool), payload(any)]
            final ok = args.isNotEmpty && args.first == true;
            final payload = args.length >= 2 ? args[1] : null;
            widget.controller?.onSaveTripDone(ok, payload);
            return null;
          },
        );

        controller.addJavaScriptHandler(
          handlerName: 'saveTripDebug',
          callback: (args) {
            final m = (args.isNotEmpty && args.first is Map) ? Map<String, dynamic>.from(args.first) : {};
            debugPrint('🚀 saveTrip url=${m['url']}');

            // Print only heads (avoid giant logs)
            String head(String? s, [int n = 300]) => (s == null) ? '' : (s.length <= n ? s : '${s.substring(0, n)}...');
            debugPrint('jsonPath head: ${head(m['jsonPath']?.toString())}');
            debugPrint('newTrip head:  ${head(m['newTrip']?.toString())}');

            // Try parse and print keys/types
            try {
              final newTrip = json.decode(m['newTrip'] as String) as Map<String, dynamic>;
              debugPrint('newTrip keys: ${newTrip.keys.toList()}');
              for (final k in ['originStation','originManualLat','originManualLng','destinationStation','destinationManualLat','destinationManualLng','operator','price','currency']) {
                if (newTrip.containsKey(k)) {
                  debugPrint('  $k => ${newTrip[k]} (${newTrip[k]?.runtimeType})');
                }
              }
            } catch (e) {
              debugPrint('❌ newTrip JSON parse failed: $e');
            }

            return null;
          },
        );
      },
      onLoadStop: (controller, _) async {
        if (!mounted) return;

        if (isRouter) {
          // Bind JS bridge + extract info
          await _bindRouterBridge(controller);
          widget.controller?.markReady();
          await _hideRouterUi(controller);
        } else {
          await _hideNavbar(controller);
        }
      },
      shouldOverrideUrlLoading: (controller, action) async {
        if (!mounted) return NavigationActionPolicy.CANCEL;

        final uri = action.request.url;
        if (uri == null) return NavigationActionPolicy.ALLOW;

        // Keep navigation inside the same host
        if (allowedHost != null && uri.host == allowedHost) {
          return NavigationActionPolicy.ALLOW;
        }

        return NavigationActionPolicy.CANCEL;
      },
    );
  }
}
