import 'package:flutter/material.dart';
import 'package:material_symbols_icons/symbols.dart';
import 'package:trainlog_app/widgets/error_banner.dart';
import 'package:trainlog_app/l10n/app_localizations.dart';
import 'package:markdown_widget/markdown_widget.dart';
import 'package:markdown/markdown.dart' as md;

class LocalisedMarkdown extends StatefulWidget {
  final String assetBaseName;
  final bool displayToc;
  final bool scrollableToc;

  const LocalisedMarkdown({
    super.key,
    required this.assetBaseName,
    this.displayToc = false,
    this.scrollableToc = false,
  });

  @override
  State<LocalisedMarkdown> createState() => _LocalisedMarkdownState();
}

class _LocalisedMarkdownState extends State<LocalisedMarkdown> {
  final tocController = TocController();

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
  // TOC widget
  // ---------------------------------------------------------------------------
  Widget _buildToc(
    BuildContext context,
  ) {
    final theme = Theme.of(context);
    final loc = AppLocalizations.of(context)!;

    return Column(
      children: [
        SizedBox(height: 8,),
        ExpansionTile(
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
          children: [
            if(widget.scrollableToc)
              SizedBox(
                height: 250,
                child: TocWidget(controller: tocController,),
              )
            else
              TocWidget(
                controller: tocController,
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
              ),
          ],
        ),
        SizedBox(height: 8,),
      ],
    );
  }

  // ---------------------------------------------------------------------------
  // Icons
  // ---------------------------------------------------------------------------
  SpanNode _iconNode(md.Element e, {required bool isSymbol}) {
    final name = (e.attributes['name'] ?? '').trim();
    final iconData = kIcons[name];

    if (iconData == null) {
      return TextNode(text: ':${isSymbol ? "sym" : "icon"}($name):');
    }

    // IMPORTANT: use the icon’s fontFamily + fontPackage so the correct glyph is drawn.
    return TextNode(
      text: String.fromCharCode(iconData.codePoint),
      style: TextStyle(
        fontFamily: iconData.fontFamily,
        package: iconData.fontPackage,
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // Style
  // ---------------------------------------------------------------------------
  MarkdownConfig  _markdownStyle(BuildContext context)
  {
    final theme = Theme.of(context);
    final base = theme.brightness == Brightness.dark
      ? MarkdownConfig.darkConfig
      : MarkdownConfig.defaultConfig;

    HeadingDivider.h2 = HeadingDivider(space: 0, height: 0, color: Colors.transparent);
    HeadingDivider.h3 = HeadingDivider(space: 0, height: 0, color: Colors.transparent);
    
      return base.copy(configs: [
      H1Config(
        style: theme.textTheme.headlineSmall!.copyWith(
          fontWeight: FontWeight.w700,
        ),
      ),
    ]);
  }

  // ---------------------------------------------------------------------------
  // Build
  // ---------------------------------------------------------------------------
  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context)!;
    final hasToc = widget.displayToc;
    final markdownGeneratorWithIcons = MarkdownGenerator(
      inlineSyntaxList: [IconOrSymbolSyntax()],
      generators: [
        SpanNodeGeneratorWithTag(
          tag: 'icon',
          generator: (e, config, visitor) => _iconNode(e, isSymbol: false),
        ),
        SpanNodeGeneratorWithTag(
          tag: 'sym',
          generator: (e, config, visitor) => _iconNode(e, isSymbol: true),
        ),
      ],
    );
  
    return FutureBuilder<({String data, bool isFallback})>(
      future: _loadMarkdown(context),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return const SizedBox();
        }

        final result = snapshot.data!;

        final markdown = MarkdownWidget(
          data: result.data,
          config: _markdownStyle(context),
          tocController: tocController,
          markdownGenerator: markdownGeneratorWithIcons,
          shrinkWrap: true,
          physics: hasToc ? null : const NeverScrollableScrollPhysics(),
        );

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (result.isFallback)
              ErrorBanner(
                severity: ErrorSeverity.info,
                compact: true,
                message: loc.pageNotAvailableInUserLanguage,
              ),
                
            if (hasToc) _buildToc(context),

            hasToc
              ? SizedBox(height: 300, child: markdown)
              : markdown,
          ],
        );
      },
    );
  }
}

class IconOrSymbolSyntax extends md.InlineSyntax {
  IconOrSymbolSyntax() : super(r':(icon|sym)\(([^)]+)\):');

  @override
  bool onMatch(md.InlineParser parser, Match match) {
    final tag = match.group(1)!; // "icon" or "sym"
    final name = match.group(2)!.trim();

    final el = md.Element.empty(tag);
    el.attributes['name'] = name;

    parser.addNode(el);
    return true;
  }
}

// Put only what you actually use (you can grow these maps over time).
final Map<String, IconData> kIcons = {
  'home': Icons.home,
  'settings': Icons.settings,
  'info': Icons.info,
  'warning': Icons.warning,
  'menu': Icons.menu,
  'my_location': Icons.my_location,
  'explore': Icons.explore,
  'frame_person_off': Symbols.frame_person_off,
  'frame_person': Symbols.frame_person,
};
