import 'package:flutter/material.dart';

import 'package:trainlog_app/data/models/changelog.dart';
import 'package:trainlog_app/l10n/app_localizations.dart';
import 'package:trainlog_app/platform/adaptive_button.dart';
import 'package:trainlog_app/platform/adaptive_dialog.dart';
import 'package:trainlog_app/widgets/error_banner.dart';

/// Adaptive modal window listing the changes of one or more new versions.
///
/// The title shows the newest version ("Changelog v0.4.1"). Within a version,
/// items are grouped by [ChangelogChangeType] and sorted so that features
/// come first and bug fixes last, whatever their order in the YAML file.
class ChangelogDialog extends StatelessWidget {
  /// Entries to display, newest first. Must not be empty.
  final List<ChangelogEntry> entries;

  /// True when the English changelog was shown to a non-English user.
  final bool isFallback;

  const ChangelogDialog({
    super.key,
    required this.entries,
    required this.isFallback,
  });

  static Future<void> show(
    BuildContext context, {
    required List<ChangelogEntry> entries,
    required bool isFallback,
  }) {
    if (entries.isEmpty) return Future.value();
    return AdaptiveDialog.showCustom<void>(
      context: context,
      maxHeightFactor: 0.7,
      builder: (_) => ChangelogDialog(
        entries: entries,
        isFallback: isFallback,
      ),
    );
  }

  static IconData _typeIcon(ChangelogChangeType type) {
    switch (type) {
      case ChangelogChangeType.feature:
        return Icons.auto_awesome;
      case ChangelogChangeType.minor:
        return Icons.trending_up;
      case ChangelogChangeType.other:
        return Icons.more_horiz;
      case ChangelogChangeType.fix:
        return Icons.bug_report_outlined;
    }
  }

  static String _typeLabel(AppLocalizations loc, ChangelogChangeType type) {
    switch (type) {
      case ChangelogChangeType.feature:
        return loc.changelogTypeFeature;
      case ChangelogChangeType.minor:
        return loc.changelogTypeMinor;
      case ChangelogChangeType.other:
        return loc.changelogTypeOther;
      case ChangelogChangeType.fix:
        return loc.changelogTypeFix;
    }
  }

  List<Widget> _buildEntry(
    BuildContext context,
    ChangelogEntry entry, {
    required bool showVersionHeader,
  }) {
    final loc = AppLocalizations.of(context)!;
    final theme = Theme.of(context);

    return [
      if (showVersionHeader) ...[
        Text(
          'v${entry.version}',
          style: theme.textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: 4),
      ],
      for (final group in entry.groupedChanges.entries) ...[
        Padding(
          padding: const EdgeInsets.only(top: 8, bottom: 4),
          child: Row(
            children: [
              Icon(
                _typeIcon(group.key),
                size: 18,
                color: theme.colorScheme.primary,
              ),
              const SizedBox(width: 8),
              Text(
                _typeLabel(loc, group.key),
                style: theme.textTheme.titleSmall?.copyWith(
                  color: theme.colorScheme.primary,
                ),
              ),
            ],
          ),
        ),
        for (final change in group.value)
          Padding(
            padding: const EdgeInsets.only(left: 26, bottom: 4),
            child: Text(
              '• ${change.text}',
              style: theme.textTheme.bodyMedium,
            ),
          ),
      ],
    ];
  }

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final locale = Localizations.localeOf(context).languageCode;

    return Padding(
      padding: const EdgeInsets.all(20),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            loc.changelogTitle(entries.first.version),
            textAlign: TextAlign.center,
            style: theme.textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 12),
          if (isFallback && locale != 'en') ...[
            ErrorBanner(
              severity: ErrorSeverity.info,
              compact: true,
              message: loc.pageNotAvailableInUserLanguage,
            ),
            const SizedBox(height: 8),
          ],
          Flexible(
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  for (var i = 0; i < entries.length; i++) ...[
                    if (i > 0) const SizedBox(height: 12),
                    ..._buildEntry(
                      context,
                      entries[i],
                      showVersionHeader: entries.length > 1,
                    ),
                  ],
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
          Align(
            alignment: Alignment.centerRight,
            child: AdaptiveButton.build(
              context: context,
              type: AdaptiveButtonType.primary,
              onPressed: () => AdaptiveDialog.pop(context),
              label: Text(MaterialLocalizations.of(context).okButtonLabel),
            ),
          ),
        ],
      ),
    );
  }
}
