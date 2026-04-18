import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_inappwebview/flutter_inappwebview.dart';
import 'package:provider/provider.dart';

import 'package:trainlog_app/data/controllers/trainlog_web_controller.dart';
import 'package:trainlog_app/data/models/trips.dart';
import '../providers/trainlog_provider.dart';

class TripRoutingData{
  String? text;
  final double? distanceM;
  final double? durationS;

  TripRoutingData({
    this.text,
    this.distanceM,
    this.durationS,
  });
}

class TrainlogRouterPage extends StatefulWidget {
  final String tripData;
  final VehicleType vehicleType;
  final bool isNewRouter;
  final TrainlogWebPageController controller;
  final ValueChanged<TripRoutingData>? onRouteInfoChanged;
  final ValueChanged<bool>? onLoading;
  final ValueChanged<bool>? onRoutingError;

  const TrainlogRouterPage({
    super.key,
    required this.tripData,
    required this.vehicleType,
    required this.isNewRouter,
    required this.controller,
    this.onRouteInfoChanged,
    this.onLoading,
    this.onRoutingError,
  });

  @override
  State<TrainlogRouterPage> createState() => _TrainlogRouterPageState();
}

class _TrainlogRouterPageState extends State<TrainlogRouterPage> {
  InAppWebViewController? _webController;
  TrainlogProvider? _provider;

  Uri? _uri;
  String? _allowedHost;
  WebUri? _cookieWebUri;

  bool _cookiesInjected = false;
  bool _injecting = false;

  bool _lastLoadingState = false;
  bool _lastRoutingErrorState = false;

  void resetRoutingError() {
    _lastRoutingErrorState = false;
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_provider != null) return;

    _provider = context.read<TrainlogProvider>();

    final baseUrl = _provider!.generateUserUrl(
      widget.vehicleType.isAir() ? 'air_routing/${widget.vehicleType.toShortString()}' : 'routing',
      publicPage: false,
    );

    final parsed = Uri.parse(baseUrl);
    _uri = parsed.replace(queryParameters: {
      ...parsed.queryParameters,
      'type': widget.vehicleType.toShortString(),
      'fromApp': 'true',
    });

    _allowedHost = _uri!.host;
    _cookieWebUri = WebUri(
      '${_uri!.scheme}://${_uri!.host}${_uri!.hasPort ? ':${_uri!.port}' : ''}',
    );

    _injectCookies();
  }

  @override
  void didUpdateWidget(covariant TrainlogRouterPage oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.isNewRouter != oldWidget.isNewRouter) {
      _lastRoutingErrorState = false;
      _setRouterToggle(widget.isNewRouter);
    }
  }

  @override
  void dispose() {
    _webController = null;
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

  URLRequest _buildInitialRequest() {
    final uri = _uri;
    if (uri == null) return URLRequest(url: WebUri('about:blank'));

    final body = Uri(queryParameters: {'trip_data': widget.tripData}).query;
    return URLRequest(
      url: WebUri(uri.toString()),
      method: 'POST',
      body: Uint8List.fromList(utf8.encode(body)),
      headers: const {'Content-Type': 'application/x-www-form-urlencoded'},
    );
  }

  Future<void> _setRouterToggle(bool value) async {
    final c = _webController;
    if (c == null) return;

    await c.evaluateJavascript(source: """
      (function () {
        const cb = document.getElementById('newRouterToggle');
        if (!cb || cb.checked === $value) return;
        cb.checked = $value;
        switchRouter();
      })();
    """);
  }

  void _setLoading(bool v) {
    if (v == _lastLoadingState) return;
    _lastLoadingState = v;
    widget.onLoading?.call(v);
  }

  void _setRoutingError(bool v) {
    if (v == _lastRoutingErrorState) return;
    _lastRoutingErrorState = v;
    widget.onRoutingError?.call(v);
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<TrainlogProvider>();

    if (!provider.isAuthenticated || provider.username == null) {
      return const Center(child: Text('You must be logged in to view this page'));
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
      onConsoleMessage: (_, msg) => debugPrint('🗺️ JS: ${msg.message}'),
      onLoadStart: (_, __) {
        _setLoading(true);
        _setRoutingError(false);
      },
      onWebViewCreated: (controller) {
        _webController = controller;
        widget.controller.attach(controller);

        controller.addJavaScriptHandler(
          handlerName: 'routingEvent',
          callback: (args) {
            if (args.isEmpty || args.first is! Map) return null;
            final payload = Map<String, dynamic>.from(args.first as Map);

            switch (payload['event'] as String?) {
              case 'loading':
                _setLoading(payload['isLoading'] == true);

              case 'routeInfo':
                widget.onRouteInfoChanged?.call(TripRoutingData(
                  text: payload['text']?.toString() ?? '',
                  distanceM: num.tryParse(payload['distanceM'].toString())?.toDouble(),
                  durationS: num.tryParse(payload['durationS'].toString())?.toDouble(),
                ));

              case 'routingError':
                _setRoutingError(true);
                _setLoading(false);

              case 'saveTripDone':
                debugPrint('🗺️ Save trip done: ${payload['ok']}, data: ${payload['trip']}');
                widget.controller.onSaveTripDone(
                  payload['ok'] == true,
                  payload['trip'],
                );

              case 'saveError':
                widget.controller.onSaveTripDone(false, payload['message']);
            }

            return null;
          },
        );
      },
      onLoadStop: (controller, _) async {
        if (!mounted) return;
        widget.controller.markReady();
      },
      onReceivedError: (_, __, ___) => _setLoading(false),
      onReceivedHttpError: (_, __, ___) => _setLoading(false),
      shouldOverrideUrlLoading: (_, action) async {
        if (!mounted) return NavigationActionPolicy.CANCEL;
        final uri = action.request.url;
        if (uri == null) return NavigationActionPolicy.CANCEL;
        if (_allowedHost != null && uri.host == _allowedHost) {
          return NavigationActionPolicy.ALLOW;
        }
        return NavigationActionPolicy.CANCEL;
      },
    );
  }
}