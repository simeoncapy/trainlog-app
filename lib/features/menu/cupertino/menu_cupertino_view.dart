import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart' show Scaffold, Theme;
import 'package:provider/provider.dart';
import 'package:trainlog_app/features/menu/menu_actions.dart';
import 'package:trainlog_app/features/menu/menu_controller.dart';
import 'package:trainlog_app/features/menu/menu_explore_card.dart';
import 'package:trainlog_app/features/menu/menu_parts.dart';
import 'package:trainlog_app/features/menu/menu_summary_card.dart';
import 'package:trainlog_app/l10n/app_localizations.dart';
import 'package:trainlog_app/navigation/nav_models.dart';
import 'package:trainlog_app/ui/cupertino/app_grouped_list.dart';
import 'package:trainlog_app/ui/cupertino/liquid_glass.dart';
import 'package:trainlog_app/ui/tokens/app_colors.dart';
import 'package:trainlog_app/ui/tokens/app_theme.dart';
import 'package:trainlog_app/utils/platform_utils.dart';

/// The "You" menu on iOS, in a sheet: the profile card, the Explore grid,
/// then inset grouped lists (the package's rows), Log out in a section of
/// its own at the bottom, as in Apple's apps.
class MenuCupertinoView extends StatelessWidget {
  const MenuCupertinoView({super.key, required this.actions});

  final MenuActions actions;

  /// Continuous corners of the Explore cards, as the grouped sections'.
  static const _cardStyle = ExploreCardStyle(radius: 20, bordered: false);

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context)!;

    return Scaffold(
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            MenuTopBar(
              onClose: actions.onClose,
              onSettings: actions.onSettingsTap,
            ),
            Expanded(
              child: SingleChildScrollView(
                controller: actions.scrollController,
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    const SizedBox(height: 8),
                    _ProfileCard(onShare: actions.onShareProfile),
                    const SizedBox(height: 24),
                    _SectionTitle(loc.menuExploreSectionTitle),
                    ExploreGrid(
                      onPageTap: actions.onPageTap,
                      style: _cardStyle,
                    ),
                    const SizedBox(height: 24),
                    _SectionTitle(loc.menuMenuSectionTitle),
                    _MenuSection(actions: actions),
                    const SizedBox(height: 24),
                    AppGroupedSection(
                      children: [
                        AppListTile(
                          onTap: actions.onLogout,
                          boldTitle: false,
                          title: SizedBox(
                            width: double.infinity,
                            child: Text(
                              loc.logoutButton,
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                color: CupertinoColors.systemRed.resolveFrom(
                                  context,
                                ),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 32),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// The profile on iOS, light like the grouped sections under it (as the
/// account card atop iOS Settings): the logo, the name in the display font,
/// "18 trips · server" (the server only when not trainlog.me), and a glass
/// button sharing the public profile.
class _ProfileCard extends StatelessWidget {
  const _ProfileCard({required this.onShare});

  final VoidCallback onShare;

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context)!;
    final menu = context.watch<AppMenuController>();
    final text = Theme.of(context).textTheme;
    final secondary = CupertinoColors.secondaryLabel.resolveFrom(context);
    final count = menu.tripCount;
    final server = menu.customServer;
    final detail = text.bodyMedium?.copyWith(color: secondary);

    return DecoratedBox(
      decoration: ShapeDecoration(
        color: Theme.of(context).colorScheme.surface,
        shape: const RoundedSuperellipseBorder(
          borderRadius: BorderRadius.all(Radius.circular(26)),
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(14, 14, 12, 14),
        child: Row(
          children: [
            const TrainlogProfileIcon(size: 52),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    menu.username,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: AppTheme.displayFont.copyWith(
                      fontSize: text.titleLarge?.fontSize,
                      color: CupertinoColors.label.resolveFrom(context),
                    ),
                  ),
                  if (count != null || server != null) ...[
                    const SizedBox(height: 2),
                    Text.rich(
                      TextSpan(
                        children: [
                          if (count != null) ...[
                            TextSpan(
                              text: '$count',
                              style: AppTheme.monoFont.copyWith(
                                fontSize: detail?.fontSize,
                                fontWeight: FontWeight.w700,
                                color: CupertinoTheme.of(context).primaryColor,
                              ),
                            ),
                            TextSpan(text: ' ${loc.menuTripCountLabel(count)}'),
                          ],
                          if (count != null && server != null)
                            const TextSpan(text: ' · '),
                          if (server != null) TextSpan(text: server),
                        ],
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: detail,
                    ),
                  ],
                ],
              ),
            ),
            const SizedBox(width: 8),
            GlassIconButton(
              icon: AdaptiveIcons.share,
              onPressed: onShare,
              tooltip: loc.menuShareProfile,
              size: 40,
              iconSize: 19,
              color: CupertinoTheme.of(context).primaryColor,
            ),
          ],
        ),
      ),
    );
  }
}

/// A section title as elsewhere on iOS: as written in the ARB, Space Grotesk
/// bold, amber.
class _SectionTitle extends StatelessWidget {
  const _SectionTitle(this.label);

  final String label;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(4, 0, 4, 10),
      child: Text(
        label,
        style: AppTheme.displayFont.copyWith(
          fontSize: Theme.of(context).textTheme.titleMedium?.fontSize,
          color: CupertinoTheme.of(context).primaryColor,
        ),
      ),
    );
  }
}

/// Inbox (with its unread count), Trainlog status and About.
class _MenuSection extends StatelessWidget {
  const _MenuSection({required this.actions});

  final MenuActions actions;

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context)!;
    final unread = context.select((AppMenuController c) => c.newMessageCount);

    AppListTile row({
      required IconData icon,
      required Color color,
      required String label,
      required VoidCallback onTap,
      int? badge,
    }) {
      return AppListTile(
        onTap: onTap,
        boldTitle: false,
        leading: _IconTile(icon: icon, color: color),
        title: Text(label),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if ((badge ?? 0) > 0) ...[
              _Badge(count: badge!),
              const SizedBox(width: 8),
            ],
            AppListTile.chevron,
          ],
        ),
      );
    }

    return AppGroupedSection(
      dividerIndent: 16 + 30 + 14,
      children: [
        row(
          icon: AdaptiveIcons.inbox,
          color: AppColors.amber,
          label: loc.menuInboxTitle,
          onTap: actions.onInboxTap,
          badge: unread,
        ),
        row(
          icon: AdaptiveIcons.ok,
          color: AppColors.blue,
          label: loc.trainglogStatusPageTitle,
          onTap: actions.onTrainlogStatusTap,
        ),
        row(
          icon: AdaptiveIcons.info,
          color: // Navy vanishes on a dark surface: sky blue in dark mode.
          Theme.of(context).brightness == Brightness.dark
              ? AppColors.sky
              : AppColors.navy,
          label: loc.menuAboutTitle,
          onTap: () => actions.onPageTap(AppPageId.about),
        ),
      ],
    );
  }
}

/// The white glyph on a coloured rounded square, as in iOS Settings.
class _IconTile extends StatelessWidget {
  const _IconTile({required this.icon, required this.color});

  final IconData icon;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: ShapeDecoration(
        color: color,
        shape: const RoundedSuperellipseBorder(
          borderRadius: BorderRadius.all(Radius.circular(8)),
        ),
      ),
      child: SizedBox.square(
        dimension: 30,
        child: Icon(icon, color: CupertinoColors.white, size: 17),
      ),
    );
  }
}

/// Unread count: a red capsule, as on iOS.
class _Badge extends StatelessWidget {
  const _Badge({required this.count});

  final int count;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: ShapeDecoration(
        color: CupertinoColors.systemRed.resolveFrom(context),
        shape: const StadiumBorder(),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
        child: Text(
          count > 99 ? '99+' : '$count',
          style: Theme.of(context).textTheme.labelMedium?.copyWith(
            color: CupertinoColors.white,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    );
  }
}
