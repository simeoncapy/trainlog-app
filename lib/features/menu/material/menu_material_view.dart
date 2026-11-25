import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:trainlog_app/features/menu/menu_actions.dart';
import 'package:trainlog_app/features/menu/menu_block.dart';
import 'package:trainlog_app/features/menu/menu_controller.dart';
import 'package:trainlog_app/features/menu/menu_item_data.dart';
import 'package:trainlog_app/features/menu/menu_parts.dart';
import 'package:trainlog_app/features/menu/menu_summary_card.dart';
import 'package:trainlog_app/l10n/app_localizations.dart';
import 'package:trainlog_app/navigation/nav_models.dart';
import 'package:trainlog_app/ui/tokens/app_colors.dart';
import 'package:trainlog_app/utils/platform_utils.dart';

/// The "You" menu on Android: a full-screen page replacing the legacy
/// Drawer.
class MenuMaterialView extends StatelessWidget {
  const MenuMaterialView({super.key, required this.actions});

  final MenuActions actions;

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context)!;

    return Scaffold(
      // Uses the theme's scaffoldBackgroundColor directly (beige in light,
      // deep dark in dark — set correctly in AppTheme).
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            MenuTopBar(onClose: actions.onClose, onSettings: actions.onSettingsTap),
            Expanded(
              child: SingleChildScrollView(
                controller: actions.scrollController,
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    const SizedBox(height: 8),
                    const MenuSummaryCard(),
                    const SizedBox(height: 24),
                    _SectionHeader(label: loc.menuExploreSectionTitle),
                    const SizedBox(height: 12),
                    ExploreGrid(onPageTap: actions.onPageTap),
                    const SizedBox(height: 24),
                    _SectionHeader(label: loc.menuMenuSectionTitle),
                    const SizedBox(height: 8),
                    _menuBlock(context, loc),
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

  Widget _menuBlock(BuildContext context, AppLocalizations loc) {
    final cs = Theme.of(context).colorScheme;
    final newMessageCount = context.select(
      (AppMenuController c) => c.newMessageCount,
    );
    return MenuBlock(items: [
      MenuItemData(
        icon: AdaptiveIcons.inbox,
        iconBg: AppColors.amber,
        label: loc.menuInboxTitle,
        badgeCount: newMessageCount,
        onTap: actions.onInboxTap,
      ),
      MenuItemData(
        icon: AdaptiveIcons.ok,
        iconBg: AppColors.blue,
        label: loc.trainglogStatusPageTitle,
        onTap: actions.onTrainlogStatusTap,
      ),
      MenuItemData(
        icon: AdaptiveIcons.info,
        iconBg: AppColors.navy,
        label: loc.menuAboutTitle,
        onTap: () => actions.onPageTap(AppPageId.about),
      ),
      MenuItemData(
        icon: AdaptiveIcons.logout,
        iconBg: cs.error,
        label: loc.logoutButton,
        labelColor: cs.error,
        isDestructive: true,
        onTap: actions.onLogout,
      ),
    ]);
  }
}

// ── Section header ────────────────────────────────────────────────────────────

class _SectionHeader extends StatelessWidget {
  final String label;

  const _SectionHeader({required this.label});

  @override
  Widget build(BuildContext context) {
    // Android shows section titles in capitals; the ARB keeps their case.
    return Text(
      label.toUpperCase(),
      style: TextStyle(
        fontSize: 11,
        fontWeight: FontWeight.w700,
        letterSpacing: 1.2,
        color: Theme.of(context).colorScheme.onSurfaceVariant,
      ),
    );
  }
}
