import 'package:flutter/material.dart';
import 'package:trainlog_app/features/menu/menu_explore_card.dart';
import 'package:trainlog_app/l10n/app_localizations.dart';
import 'package:trainlog_app/navigation/nav_models.dart';
import 'package:trainlog_app/ui/adaptive/adaptive_widget.dart';
import 'package:trainlog_app/ui/tokens/app_colors.dart';
import 'package:trainlog_app/utils/platform_utils.dart';

// Parts of the "You" menu shared by its Material and iOS views.

/// ✕, the "You" title and the settings button.
class MenuTopBar extends StatelessWidget {
  final VoidCallback onClose;
  final VoidCallback onSettings;

  const MenuTopBar({
    super.key,
    required this.onClose,
    required this.onSettings,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final loc = AppLocalizations.of(context)!;

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
      child: Row(
        children: [
          AdaptiveAppBarSquareButton(
            icon: AdaptiveIcons.sheetClose,
            onPressed: onClose,
            tooltip: MaterialLocalizations.of(context).closeButtonTooltip,
          ),
          Expanded(
            child: Text(
              loc.menuYouTitle,
              textAlign: TextAlign.center,
              style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w700),
            ),
          ),
          AdaptiveAppBarSquareButton(
            icon: Icons.settings_outlined,
            onPressed: onSettings,
            tooltip: loc.menuSettingsTitle,
          ),
        ],
      ),
    );
  }
}

/// The Explore grid: two columns of compact cards (icon, label, chevron).
/// [style] gives the cards' look per design.
class ExploreGrid extends StatelessWidget {
  final void Function(AppPageId id) onPageTap;
  final ExploreCardStyle style;

  const ExploreGrid({
    super.key,
    required this.onPageTap,
    this.style = const ExploreCardStyle(),
  });

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context)!;
    final items = [
      ExploreCardData(
        id: AppPageId.dashboard,
        icon: AdaptiveIcons.dashboard,
        label: loc.menuDashboardTitle,
        color: AppColors.amber,
        subtitle: null,
      ),
      ExploreCardData(
        id: AppPageId.tags,
        icon: AdaptiveIcons.tags,
        label: loc.menuTagsTitle,
        color: AppColors.blue,
        subtitle: null,
      ),
      ExploreCardData(
        id: AppPageId.tickets,
        icon: AdaptiveIcons.tickets,
        label: loc.menuTicketsTitle,
        color: AppColors.early,
        subtitle: null,
      ),
      ExploreCardData(
        id: AppPageId.smartPrerecorder,
        icon: AdaptiveIcons.smartPrerecorder,
        label: loc.menuSmartPrerecorderTitle,
        color: AppColors.violet,
        subtitle: null,
      ),
    ];
    final hasSubtitle = items.any((d) => d.subtitle != null);

    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 520),
        child: GridView(
          shrinkWrap: true,
          padding: EdgeInsets.zero,
          physics: const NeverScrollableScrollPhysics(),
          // Compact: the label on one line (two when long), taller only when
          // a card has a subtitle.
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 2,
            crossAxisSpacing: 12,
            mainAxisSpacing: 12,
            mainAxisExtent: hasSubtitle ? 84 : 64,
          ),
          children: [
            for (final d in items)
              ExploreCard(data: d, style: style, onTap: () => onPageTap(d.id)),
          ],
        ),
      ),
    );
  }
}
