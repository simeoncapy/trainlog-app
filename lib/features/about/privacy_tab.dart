import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:flutter_html/flutter_html.dart';
import 'package:http/http.dart' as http;

class _HtmlCache {
  static final Map<Uri, String> _cache = {};

  static String? get(Uri url) => _cache[url];

  static void put(Uri url, String html) {
    _cache[url] = html;
  }

  static void remove(Uri url) {
    _cache.remove(url);
  }

  static void clear() => _cache.clear();
}


class PrivacyHtmlTab extends StatefulWidget {
  final Uri url;
  const PrivacyHtmlTab({super.key, required this.url});

  @override
  State<PrivacyHtmlTab> createState() => _PrivacyHtmlTabState();
}

class _PrivacyHtmlTabState extends State<PrivacyHtmlTab> {
  late Future<String> _htmlFuture;

  @override
  void initState() {
    super.initState();
    _htmlFuture = _fetchHtml();
  }

  @override
  void didUpdateWidget(covariant PrivacyHtmlTab oldWidget) {
    super.didUpdateWidget(oldWidget);

    // 🔁 Reload only if URL changed (language change)
    if (oldWidget.url != widget.url) {
      _htmlFuture = _fetchHtml();
    }
  }

  Future<String> _fetchHtml() async {
    // Try cache first
    final cached = _HtmlCache.get(widget.url);
    if (cached != null) {
      return cached;
    }

    // Fetch from network
    final res = await http.get(widget.url);
    if (res.statusCode != 200) {
      throw Exception('Failed to load: ${res.statusCode}');
    }

    // Save to cache
    _HtmlCache.put(widget.url, res.body);

    return res.body;
  }

  Future<void> _forceReload() async {
    // Clear cache for this URL
    _HtmlCache.remove(widget.url);

    // Recreate the future
    setState(() {
      _htmlFuture = _fetchHtml();
    });

    // Await completion so RefreshIndicator knows when to stop
    await _htmlFuture;
  }


  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return FutureBuilder<String>(
      future: _htmlFuture,
      builder: (context, snap) {
        if (snap.connectionState != ConnectionState.done) {
          return const Center(child: CircularProgressIndicator());
        }
        if (snap.hasError) {
          return Padding(
            padding: const EdgeInsets.only(
              top: 0, left: 8, right: 8, bottom: 16),
            child: Text('Error: ${snap.error}'),
          );
        }

        return RefreshIndicator(
          onRefresh: _forceReload,
          child: SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.only(
              top: 0, left: 8, right: 8, bottom: 16),
            child: SelectionArea(
              child: Html(
                data: snap.data!,
                style: {
                  ".tldr": isDark
                      ? Style(
                          backgroundColor: Theme.of(context)
                              .colorScheme
                              .primaryContainer,
                          color: Theme.of(context)
                              .colorScheme
                              .onPrimaryContainer,
                        )
                      : Style(),
                  ".content-wrapper": Style(
                    padding: HtmlPaddings.zero,
                    margin: Margins.zero,
                  ),
                },
                onLinkTap: (url, _, __) async {
                  if (url == null) return;
                  final uri = Uri.parse(url);
                  if (await canLaunchUrl(uri)) {
                    await launchUrl(
                      uri,
                      mode: LaunchMode.externalApplication,
                    );
                  }
                },
              ),
            ),
          ),
        );
      },
    );
  }
}

