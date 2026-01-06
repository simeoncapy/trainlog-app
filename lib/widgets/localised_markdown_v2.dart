import 'package:flutter/material.dart';
import 'package:flutter_markdown_plus/flutter_markdown_plus.dart';
import 'package:markdown/markdown.dart' as md;
import 'package:material_symbols_icons/symbols.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:trainlog_app/widgets/error_banner.dart';
import 'package:trainlog_app/l10n/app_localizations.dart';
import 'package:material_symbols_icons/symbols_map.dart';

class LocalisedMarkdownV2 extends StatefulWidget {
  final String assetBaseName;
  final bool displayToc;

  const LocalisedMarkdownV2({
    super.key,
    required this.assetBaseName,
    this.displayToc = false,
  });

  @override
  State<LocalisedMarkdownV2> createState() => _LocalisedMarkdownV2State();
}

class _LocalisedMarkdownV2State extends State<LocalisedMarkdownV2> {
  final ScrollController _scrollController = ScrollController();

  /// Heading text → GlobalKey
  final Map<String, GlobalKey> _headingKeys = {};

  // ---------------------------------------------------------------------------
  // Load markdown with language fallback
  // ---------------------------------------------------------------------------
  Future<({String data, bool isFallback})> _loadMarkdown(
    BuildContext context,
  ) async {
    final bundle = DefaultAssetBundle.of(context);
    final locale = Localizations.localeOf(context).languageCode;

    final localizedPath =
        'assets/i18n/${widget.assetBaseName}_$locale.md';
    final fallbackPath =
        'assets/i18n/${widget.assetBaseName}_en.md';

    try {
      final data = await bundle.loadString(localizedPath);
      return (data: data, isFallback: false);
    } catch (_) {
      final data = await bundle.loadString(fallbackPath);
      return (data: data, isFallback: true);
    }
  }

  // ---------------------------------------------------------------------------
  // Extract headings and register keys
  // ---------------------------------------------------------------------------
  List<({int level, String title})> _extractHeadings(String markdown) {
    final regex = RegExp(r'^(#{1,6})\s+(.+)$', multiLine: true);
    final headings = <({int level, String title})>[];

    for (final m in regex.allMatches(markdown)) {
      final title = m.group(2)!.trim();
      final level = m.group(1)!.length;

      headings.add((level: level, title: title));
      _headingKeys.putIfAbsent(title, () => GlobalKey());
    }
    return headings;
  }

  // ---------------------------------------------------------------------------
  // Scroll to a heading
  // ---------------------------------------------------------------------------
  void _scrollToHeading(String title) {
    final key = _headingKeys[title];
    final ctx = key?.currentContext;
    if (ctx == null) return;

    Scrollable.ensureVisible(
      ctx,
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeInOut,
      alignment: 0.1,
    );
  }

  // ---------------------------------------------------------------------------
  // TOC widget
  // ---------------------------------------------------------------------------
  Widget _buildToc(
    BuildContext context,
    List<({int level, String title})> headings,
  ) {
    if (headings.isEmpty) return const SizedBox();

    final theme = Theme.of(context);
    final loc = AppLocalizations.of(context)!;

    return ExpansionTile(
      initiallyExpanded: true,
      tilePadding: const EdgeInsets.symmetric(horizontal: 16),
      childrenPadding: const EdgeInsets.only(bottom: 8),
      title: Align(
        alignment: Alignment.centerLeft,
        child: Text(
          loc.tableOfContents,
          textAlign: TextAlign.left,
          style: theme.textTheme.titleMedium,
        ),
      ),
      children: headings.map((h) {
        return Padding(
          padding: EdgeInsets.only(
            left: 16.0 * (h.level - 1),
            right: 16,
            top: 4,
            bottom: 4,
          ),
          child: Align(
            alignment: Alignment.centerLeft,
            child: InkWell(
              onTap: () => _scrollToHeading(h.title),
              child: Text(
                h.title,
                textAlign: TextAlign.left,
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: theme.colorScheme.primary,
                ),
              ),
            ),
          ),
        );
      }).toList(),
    );
  }

  // ---------------------------------------------------------------------------
  // Markdown rendering with heading anchors
  // ---------------------------------------------------------------------------
  Widget _buildMarkdown(String markdown, ThemeData theme) {
    return MarkdownBody(
      data: markdown,
      selectable: true,
      // builders: {
      //   for (int i = 1; i <= 6; i++)
      //     'h$i': _HeadingBuilder(_headingKeys), // Not working for the moment
      // },
      onTapLink: (_, url, _) async {
        if (url == null) return;
        final uri = Uri.parse(url);
        if (await canLaunchUrl(uri)) {
          await launchUrl(uri, mode: LaunchMode.externalApplication);
        }
      },
    );
  }

  // ---------------------------------------------------------------------------
  // Build
  // ---------------------------------------------------------------------------
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final loc = AppLocalizations.of(context)!;

    return FutureBuilder<({String data, bool isFallback})>(
      future: _loadMarkdown(context),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return const SizedBox();
        }

        final result = snapshot.data!;
        final headings = widget.displayToc
            ? _extractHeadings(result.data)
            : const <({int level, String title})>[];

        return SingleChildScrollView(
          controller: _scrollController,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (result.isFallback)
                ErrorBanner(
                  severity: ErrorSeverity.info,
                  compact: true,
                  message: loc.pageNotAvailableInUserLanguage,
                ),

              if (widget.displayToc)
                _buildToc(context, headings),

              _buildMarkdown(result.data, theme),
            ],
          ),
        );
      },
    );
  }
}

// ============================================================================
// Heading builder: attaches GlobalKey to headings so TOC scrolling works
// ============================================================================
class _HeadingBuilder extends MarkdownElementBuilder {
  final Map<String, GlobalKey> headingKeys;

  _HeadingBuilder(this.headingKeys);

  @override
  Widget visitElementAfter(element, TextStyle? preferredStyle) {
    final text = element.textContent.trim();
    final key = headingKeys[text];

    return Container(
      key: key,
      alignment: Alignment.centerLeft,
      child: Text(
        text,
        style: preferredStyle,
      ),
    );
  }
}

/// Matches :icon(name):
class IconInlineSyntax extends md.InlineSyntax {
  IconInlineSyntax() : super(r':icon\(([^)]+)\):');

  @override
  bool onMatch(md.InlineParser parser, Match match) {
    final name = match.group(1)!.trim();

    final el = md.Element.empty('icon');
    el.attributes['name'] = name;

    parser.addNode(el);
    return true;
  }
}