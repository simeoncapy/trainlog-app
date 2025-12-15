import 'dart:io';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter_inappwebview/flutter_inappwebview.dart';

import '../providers/trainlog_provider.dart';

/// Displays an authenticated Trainlog webpage inside a WebView.
///
/// - Builds URL as: https://trainlog.me/u/{username}/{trainlogPage}
/// - Reuses existing session cookies
/// - Removes the top navbar from the page
class TrainlogWebPage extends StatefulWidget {
  /// Page suffix, e.g.:
  ///   "stats/train"
  ///   "map"
  ///   "timeline"
  final String trainlogPage;
  final bool publicPage;

  const TrainlogWebPage({
    super.key,
    required this.trainlogPage,
    this.publicPage = false,
  });

  @override
  State<TrainlogWebPage> createState() => _TrainlogWebPageState();
}

class _TrainlogWebPageState extends State<TrainlogWebPage> {
  InAppWebViewController? _controller;
  bool _cookiesInjected = false;
  late TrainlogProvider provider;
  late String url;

  @override
  void initState() {
    super.initState();
    provider = context.read<TrainlogProvider>();
    url = provider.generateUserUrl(widget.trainlogPage, publicPage: widget.publicPage);
    _injectCookies();
  }

  /// Copy Dio cookies into the WebView cookie store
  Future<void> _injectCookies() async {
    final cookies =
        await provider.service.getCookiesForWebView(); // ← helper in service

    final cookieManager = CookieManager.instance();

    for (final c in cookies) {
      await cookieManager.setCookie(
        url: WebUri(getBaseUrl(url)),
        name: c.name,
        value: c.value,
        domain: c.domain,
        path: c.path ?? '/',
        isHttpOnly: c.httpOnly,
        isSecure: c.secure,
      );
    }

    setState(() {
      _cookiesInjected = true;
    });
  }

  /// Remove the navbar from the loaded page
  Future<void> _hideNavbar(InAppWebViewController controller) async {
    await controller.evaluateJavascript(source: """
      (function () {
        const nav = document.querySelector(
          'nav.navbar.navbar-expand-xl.navbar-light.bg-light'
        );
        if (nav) {
          nav.style.display = 'none';
        }
      })();
    """);
  }

  String getBaseUrl(String fullUrl, {bool hostOnly = false}) {
    final uri = Uri.parse(fullUrl);
    return hostOnly ? uri.host : '${uri.scheme}://${uri.host}'
          '${uri.hasPort ? ':${uri.port}' : ''}';
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<TrainlogProvider>();

    // ---- Guards -------------------------------------------------------------

    if (!provider.isAuthenticated || provider.username == null) {
      return const Center(
        child: Text('You must be logged in to view this page'),
      );
    }

    if (!_cookiesInjected) {
      return const Center(child: CircularProgressIndicator());
    }

    // ---- WebView ------------------------------------------------------------

    return InAppWebView(
      initialUrlRequest: URLRequest(url: WebUri(url)),
      initialSettings: InAppWebViewSettings(
        javaScriptEnabled: true,
        domStorageEnabled: true,
        useShouldOverrideUrlLoading: true,
        mediaPlaybackRequiresUserGesture: false,
        allowsInlineMediaPlayback: true,
        transparentBackground: false,
      ),
      onWebViewCreated: (controller) {
        _controller = controller;
      },
      onLoadStop: (controller, _) async {
        await _hideNavbar(controller);
      },
      shouldOverrideUrlLoading: (controller, action) async {
        final uri = action.request.url;
        if (uri == null) {
          return NavigationActionPolicy.ALLOW;
        }

        // Keep navigation inside trainlog.me
        if (uri.host.contains(getBaseUrl(url, hostOnly: true))) {
          return NavigationActionPolicy.ALLOW;
        }

        // Block external navigation (or open externally if you prefer)
        return NavigationActionPolicy.CANCEL;
      },
    );
  }
}
