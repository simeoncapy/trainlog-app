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
  final ValueChanged<bool>? onLoading;
  final ValueChanged<bool>? onRoutingError;
  final TrainlogWebPageController? controller;

  const TrainlogWebPage({
    super.key,
    required this.trainlogPage,
    this.publicPage = false,
    this.query,
    this.initialPostForm,
    this.routerToggleValue,
    this.onRouteInfoChanged,
    this.onLoading,
    this.onRoutingError,
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
  bool _lastLoadingState = false;
  bool _lastRoutingErrorState = false;

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
      _hideElement(controller, 'div.leaflet-control-container');

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

  void _setLoading(bool v) {
    if (v == _lastLoadingState) return;
    _lastLoadingState = v;
    widget.onLoading?.call(v);
  }

  Future<void> _bindSpinnerObserver(InAppWebViewController controller) async {
    await controller.evaluateJavascript(source: r"""
      (function () {
        if (window.__flutterSpinnerObserverInstalled) return;
        window.__flutterSpinnerObserverInstalled = true;

        function isSpinnerVisible() {
          const el = document.querySelector('div.spinner-container');
          if (!el) return false;

          // visible if it takes space and not display:none/visibility:hidden
          const style = window.getComputedStyle(el);
          if (style.display === 'none' || style.visibility === 'hidden' || style.opacity === '0') return false;

          // offsetParent is null for display:none, but also for fixed in some cases;
          // so combine checks.
          const hasBox = !!(el.offsetWidth || el.offsetHeight || el.getClientRects().length);
          return hasBox;
        }

        let last = null;
        let scheduled = false;

        function notifyIfChanged() {
          const now = isSpinnerVisible();
          if (last === now) return;
          last = now;
          window.flutter_inappwebview.callHandler('spinnerLoadingChanged', now);
        }

        function scheduleCheck() {
          if (scheduled) return;
          scheduled = true;
          setTimeout(function () {
            scheduled = false;
            notifyIfChanged();
          }, 50);
        }

        // Initial check
        notifyIfChanged();

        // Watch DOM changes
        const obs = new MutationObserver(scheduleCheck);
        obs.observe(document.documentElement, {
          childList: true,
          subtree: true,
          attributes: true,
          attributeFilter: ['class', 'style']
        });

        // Also watch for CSS changes that don't trigger attribute mutation
        window.addEventListener('load', scheduleCheck);
        window.addEventListener('resize', scheduleCheck);
      })();
    """);
  }

  void _setRoutingError(bool v) {
    if (v == _lastRoutingErrorState) return;
    _lastRoutingErrorState = v;
    debugPrint('🧠 Routing error state changed: $v');
    widget.onRoutingError?.call(v);
  }

  Future<void> _bindRoutingErrorObserver(InAppWebViewController controller) async {
    await controller.evaluateJavascript(source: r"""
      (function () {
        if (window.__flutterRoutingErrorObserverInstalled) return;
        window.__flutterRoutingErrorObserverInstalled = true;

        function isRoutingErrorPresent() {
          const el = document.querySelector('h4#routing-error');
          if (!el) return false;

          const text = (el.textContent || '').trim();
          return text.length > 0;
        }

        let last = null;
        let scheduled = false;

        function notifyIfChanged() {
          const now = isRoutingErrorPresent();
          if (last === now) return;
          last = now;
          window.flutter_inappwebview.callHandler('routingErrorChanged', now);
        }

        function scheduleCheck() {
          if (scheduled) return;
          scheduled = true;
          setTimeout(function () {
            scheduled = false;
            notifyIfChanged();
          }, 50);
        }

        // Initial check
        notifyIfChanged();

        const obs = new MutationObserver(scheduleCheck);
        obs.observe(document.documentElement, {
          childList: true,
          subtree: true,
          characterData: true,
          attributes: true
        });

        window.addEventListener('load', scheduleCheck);
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
      onLoadStart: (controller, url) {
        // Earliest signal: navigation started (before page is shown)
        _setLoading(true);
        _setRoutingError(false);
      },

      onProgressChanged: (controller, progress) {
        // Optional: some sites finish loadStop but still render; progress helps.
        // You can keep it simple, or use it as a fallback.
        // Example: when progress is 100, don't force false; let spinner observer decide.
        // If you want: if (progress < 100) _setLoading(true);
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
          handlerName: 'spinnerLoadingChanged',
          callback: (args) {
            final isLoading = args.isNotEmpty && args.first == true;

            // prevent spamming Flutter with the same state
            if (isLoading == _lastLoadingState) return null;
            _lastLoadingState = isLoading;

            widget.onLoading?.call(isLoading);
            return null;
          },
        );

        controller.addJavaScriptHandler(
          handlerName: 'routingErrorChanged',
          callback: (args) {
            final hasError = args.isNotEmpty && args.first == true;
            _setRoutingError(hasError);
            return null;
          },
        );

      },
      onLoadStop: (controller, _) async {
        if (!mounted) return;

        await _bindSpinnerObserver(controller);

        if (isRouter) {
          // Bind JS bridge + extract info
          await _bindRouterBridge(controller);
          widget.controller?.markReady();
          await _hideRouterUi(controller);
          await _bindRoutingErrorObserver(controller);          
        } else {
          await _hideNavbar(controller);
        }

        try {
          final result = await controller.evaluateJavascript(source: """
            (function () {
              const el = document.querySelector('div.spinner-container');
              if (!el) return false;
              const style = window.getComputedStyle(el);
              if (style.display === 'none' || style.visibility === 'hidden' || style.opacity === '0') return false;
              return !!(el.offsetWidth || el.offsetHeight || el.getClientRects().length);
            })();
          """);
          final spinnerVisible = result == true;
          _setLoading(spinnerVisible); // false if spinner not visible
        } catch (_) {
          // If we can't evaluate, fall back to "loaded"
          _setLoading(false);
        }
      },
      onReceivedError: (controller, request, error) => _setLoading(false),
      onReceivedHttpError: (controller, request, errorResponse) => _setLoading(false),

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
