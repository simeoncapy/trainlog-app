import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:trainlog_app/features/menu/menu_explore_card.dart';
import 'package:trainlog_app/features/menu/menu_summary_card.dart';
import 'package:trainlog_app/app/app_colors.dart';
import 'package:trainlog_app/l10n/app_localizations.dart';
import 'package:trainlog_app/navigation/nav_models.dart';
import 'package:trainlog_app/providers/settings_provider.dart';
import 'package:trainlog_app/providers/trainlog_provider.dart';
import 'package:trainlog_app/providers/trips_provider.dart';
import 'package:trainlog_app/utils/platform_utils.dart';

/// Full-screen menu replacing the legacy Drawer on Android.
/// Provides a clean entry point for iOS (wire up from the iOS shell when ready).
class FullScreenMenuPage extends StatelessWidget {
  final VoidCallback onClose;
  final VoidCallback onSettingsTap;
  final void Function(AppPageId id) onPageTap;
  final VoidCallback onInboxTap;
  final VoidCallback onTrainlogStatusTap;

  const FullScreenMenuPage({
    super.key,
    required this.onClose,
    required this.onSettingsTap,
    required this.onPageTap,
    required this.onInboxTap,
    required this.onTrainlogStatusTap,
  });

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
            _TopBar(onClose: onClose, onSettings: onSettingsTap, loc: loc),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    const SizedBox(height: 8),
                    const MenuSummaryCard(),
                    const SizedBox(height: 24),
                    _SectionHeader(label: loc.menuExploreSectionTitle),
                    const SizedBox(height: 12),
                    _ExploreGrid(onPageTap: onPageTap, loc: loc),
                    const SizedBox(height: 24),
                    _SectionHeader(label: loc.menuMenuSectionTitle),
                    const SizedBox(height: 8),
                    _MenuBlock(
                      loc: loc,
                      onInboxTap: onInboxTap,
                      onTrainlogStatusTap: onTrainlogStatusTap,
                      onAboutTap: () => onPageTap(AppPageId.about),
                      onLogout: () async {
                        final settings = context.read<SettingsProvider>();
                        final trips = context.read<TripsProvider>();
                        final scaffMsg = ScaffoldMessenger.of(context);
                        onClose();
                        await context.read<TrainlogProvider>().logout(settings, trips);
                        scaffMsg.showSnackBar(
                          SnackBar(content: Text(loc.loggedOut)),
                        );
                      },
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

// ── Top bar ───────────────────────────────────────────────────────────────────

class _TopBar extends StatelessWidget {
  final VoidCallback onClose;
  final VoidCallback onSettings;
  final AppLocalizations loc;

  const _TopBar({
    required this.onClose,
    required this.onSettings,
    required this.loc,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;

    Widget squareBtn({required IconData icon, required VoidCallback onTap, String? tooltip}) {
      return Tooltip(
        message: tooltip ?? '',
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(10),
          child: Container(
            width: 38,
            height: 38,
            decoration: BoxDecoration(
              color: cs.surface,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: cs.outlineVariant, width: 1),
            ),
            child: Icon(icon, color: cs.onSurface, size: 20),
          ),
        ),
      );
    }

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
      child: Row(
        children: [
          squareBtn(
            icon: Icons.keyboard_arrow_down,
            onTap: onClose,
            tooltip: MaterialLocalizations.of(context).closeButtonTooltip,
          ),
          Expanded(
            child: Text(
              loc.menuYouTitle,
              textAlign: TextAlign.center,
              style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w700),
            ),
          ),
          squareBtn(
            icon: Icons.settings_outlined,
            onTap: onSettings,
            tooltip: loc.menuSettingsTitle,
          ),
        ],
      ),
    );
  }
}

// ── Section header ────────────────────────────────────────────────────────────

class _SectionHeader extends StatelessWidget {
  final String label;

  const _SectionHeader({required this.label});

  @override
  Widget build(BuildContext context) {
    return Text(
      label,
      style: TextStyle(
        fontSize: 11,
        fontWeight: FontWeight.w700,
        letterSpacing: 1.2,
        color: Theme.of(context).colorScheme.onSurfaceVariant,
      ),
    );
  }
}

// ── Explore 2×2 grid ──────────────────────────────────────────────────────────

class _ExploreGrid extends StatelessWidget {
  final void Function(AppPageId id) onPageTap;
  final AppLocalizations loc;

  const _ExploreGrid({required this.onPageTap, required this.loc});

  @override
  Widget build(BuildContext context) {
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

    return GridView.count(
      crossAxisCount: 2,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisSpacing: 12,
      mainAxisSpacing: 12,
      childAspectRatio: 1.15,
      children: items
          .map((d) => ExploreCard(data: d, onTap: () => onPageTap(d.id)))
          .toList(),
    );
  }
}

// ── Menu block (single grouped list) ─────────────────────────────────────────

class _MenuBlock extends StatelessWidget {
  final AppLocalizations loc;
  final VoidCallback onInboxTap;
  final VoidCallback onTrainlogStatusTap;
  final VoidCallback onAboutTap;
  final VoidCallback onLogout;

  const _MenuBlock({
    required this.loc,
    required this.onInboxTap,
    required this.onTrainlogStatusTap,
    required this.onAboutTap,
    required this.onLogout,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    final items = <_MenuItemData>[
      _MenuItemData(
        icon: AdaptiveIcons.inbox,
        iconBg: AppColors.amber,
        label: loc.menuInboxTitle,
        onTap: onInboxTap,
      ),
      _MenuItemData(
        icon: AdaptiveIcons.ok,
        iconBg: AppColors.blue,
        label: loc.trainglogStatusPageTitle,
        onTap: onTrainlogStatusTap,
      ),
      _MenuItemData(
        icon: AdaptiveIcons.info,
        iconBg: Colors.grey,
        label: loc.menuAboutTitle,
        onTap: onAboutTap,
      ),
      _MenuItemData(
        icon: AdaptiveIcons.logout,
        iconBg: cs.error,
        label: loc.logoutButton,
        labelColor: cs.error,
        onTap: onLogout,
        isDestructive: true,
      ),
    ];

    return Container(
      decoration: BoxDecoration(
        color: cs.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: cs.outlineVariant, width: 1),
      ),
      child: Column(
        children: [
          for (int i = 0; i < items.length; i++) ...[
            _MenuTile(
              data: items[i],
              isFirst: i == 0,
              isLast: i == items.length - 1,
            ),
            if (i < items.length - 1)
              Divider(
                height: 1,
                thickness: 1,
                indent: 16 + 28 + 12, // align with label start
                endIndent: 0,
                color: cs.outlineVariant,
              ),
          ],
        ],
      ),
    );
  }
}

class _MenuItemData {
  final IconData icon;
  final Color iconBg;
  final String label;
  final Color? labelColor;
  final VoidCallback onTap;
  final bool isDestructive;

  const _MenuItemData({
    required this.icon,
    required this.iconBg,
    required this.label,
    required this.onTap,
    this.labelColor,
    this.isDestructive = false,
  });
}

class _MenuTile extends StatelessWidget {
  final _MenuItemData data;
  final bool isFirst;
  final bool isLast;

  const _MenuTile({
    required this.data,
    required this.isFirst,
    required this.isLast,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final resolvedTextColor = data.labelColor ?? cs.onSurface;

    return InkWell(
      onTap: data.onTap,
      borderRadius: BorderRadius.vertical(
        top: isFirst ? const Radius.circular(14) : Radius.zero,
        bottom: isLast ? const Radius.circular(14) : Radius.zero,
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Row(
          children: [
            Container(
              width: 28,
              height: 28,
              decoration: BoxDecoration(
                color: data.iconBg,
                borderRadius: BorderRadius.circular(6),
              ),
              child: Icon(data.icon, color: Colors.white, size: 15),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                data.label,
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w500,
                  color: resolvedTextColor,
                ),
              ),
            ),
            if (!data.isDestructive)
              Icon(Icons.chevron_right, size: 20, color: cs.onSurfaceVariant),
          ],
        ),
      ),
    );
  }
}
