import 'package:flutter/material.dart';
//import 'package:flutter_markdown_plus/flutter_markdown_plus.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:trainlog_app/widgets/error_banner.dart';
import 'package:trainlog_app/l10n/app_localizations.dart';
import 'package:markdown_widget/markdown_widget.dart';

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
  // Build
  // ---------------------------------------------------------------------------
  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context)!;
    final hasToc = widget.displayToc;
  
    return FutureBuilder<({String data, bool isFallback})>(
      future: _loadMarkdown(context),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return const SizedBox();
        }

        final result = snapshot.data!;

        final markdown = MarkdownWidget(
          data: result.data,
          tocController: tocController,
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

