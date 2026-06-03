import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:trainlog_app/app/app_colors.dart';
import 'package:trainlog_app/l10n/app_localizations.dart';
import 'package:trainlog_app/navigation/nav_models.dart';
import 'package:trainlog_app/providers/settings_provider.dart';
import 'package:trainlog_app/providers/trainlog_provider.dart';
import 'package:trainlog_app/providers/trips_provider.dart';
import 'package:trainlog_app/utils/platform_utils.dart';

/// A full-screen menu that replaces the legacy Drawer on Android and provides
/// a future entry point for iOS.
class FullScreenMenuPage extends StatefulWidget {
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
  State<FullScreenMenuPage> createState() => _FullScreenMenuPageState();
}

class _FullScreenMenuPageState extends State<FullScreenMenuPage> {
  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDark ? AppColors.darkBg : AppColors.lightBg,
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _TopBar(
              onClose: widget.onClose,
              onSettings: widget.onSettingsTap,
              loc: loc,
              theme: theme,
            ),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    const SizedBox(height: 8),
                    _SummaryCard(isDark: isDark, theme: theme),
                    const SizedBox(height: 24),
                    _SectionHeader(label: loc.menuExploreSectionTitle, theme: theme),
                    const SizedBox(height: 12),
                    _ExploreGrid(onPageTap: widget.onPageTap, loc: loc),
                    const SizedBox(height: 24),
                    _SectionHeader(label: loc.menuMenuSectionTitle, theme: theme),
                    const SizedBox(height: 4),
                    _MenuList(
                      loc: loc,
                      theme: theme,
                      onInboxTap: widget.onInboxTap,
                      onTrainlogStatusTap: widget.onTrainlogStatusTap,
                      onAboutTap: () => widget.onPageTap(AppPageId.about),
                      onLogout: () async {
                        final settings = context.read<SettingsProvider>();
                        final trips = context.read<TripsProvider>();
                        final scaffMsg = ScaffoldMessenger.of(context);
                        widget.onClose();
                        await context.read<TrainlogProvider>().logout(settings, trips);
                        scaffMsg.showSnackBar(
                          SnackBar(content: Text(loc.loggedOut)),
                        );
                      },
                    ),
                    const SizedBox(height: 24),
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

// ── Top bar ──────────────────────────────────────────────────────────────────

class _TopBar extends StatelessWidget {
  final VoidCallback onClose;
  final VoidCallback onSettings;
  final AppLocalizations loc;
  final ThemeData theme;

  const _TopBar({
    required this.onClose,
    required this.onSettings,
    required this.loc,
    required this.theme,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      child: Row(
        children: [
          IconButton(
            icon: const Icon(Icons.arrow_back),
            tooltip: MaterialLocalizations.of(context).backButtonTooltip,
            onPressed: onClose,
          ),
          Expanded(
            child: Text(
              loc.menuYouTitle,
              textAlign: TextAlign.center,
              style: theme.textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          IconButton(
            icon: const Icon(Icons.settings_outlined),
            tooltip: loc.menuSettingsTitle,
            onPressed: onSettings,
          ),
        ],
      ),
    );
  }
}

// ── Summary card ─────────────────────────────────────────────────────────────

class _SummaryCard extends StatelessWidget {
  final bool isDark;
  final ThemeData theme;

  const _SummaryCard({required this.isDark, required this.theme});

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<TrainlogProvider>();
    final trips = context.watch<TripsProvider>();

    final cardBg = isDark ? AppColors.darkSurface : AppColors.lightSurface;

    return Container(
      decoration: BoxDecoration(
        color: cardBg,
        borderRadius: BorderRadius.circular(16),
      ),
      padding: const EdgeInsets.all(16),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          _AppIcon(),
          const SizedBox(width: 16),
          Expanded(
            child: _SummaryText(
              username: auth.username ?? '',
              instanceUrl: auth.instanceUrl,
              trips: trips,
              theme: theme,
              isDark: isDark,
            ),
          ),
        ],
      ),
    );
  }
}

class _AppIcon extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      width: 56,
      height: 56,
      decoration: const BoxDecoration(
        color: AppColors.navy,
        shape: BoxShape.circle,
      ),
      padding: const EdgeInsets.all(4),
      child: Container(
        decoration: BoxDecoration(
          color: AppColors.amber,
          shape: BoxShape.circle,
        ),
        padding: const EdgeInsets.all(6),
        child: SvgPicture.asset(
          'assets/icon/trainlog_icon_foreground_only.svg',
          colorFilter: const ColorFilter.mode(AppColors.navy, BlendMode.srcIn),
        ),
      ),
    );
  }
}

class _SummaryText extends StatelessWidget {
  final String username;
  final String instanceUrl;
  final TripsProvider trips;
  final ThemeData theme;
  final bool isDark;

  const _SummaryText({
    required this.username,
    required this.instanceUrl,
    required this.trips,
    required this.theme,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    final textSecondary = isDark ? AppColors.darkText2 : AppColors.lightText2;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          username,
          style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 2),
        Text(
          instanceUrl,
          style: GoogleFonts.spaceMono(
            fontSize: 11,
            color: textSecondary,
          ),
          overflow: TextOverflow.ellipsis,
        ),
        const SizedBox(height: 4),
        _TripCountText(trips: trips, theme: theme, textSecondary: textSecondary),
      ],
    );
  }
}

class _TripCountText extends StatefulWidget {
  final TripsProvider trips;
  final ThemeData theme;
  final Color textSecondary;

  const _TripCountText({
    required this.trips,
    required this.theme,
    required this.textSecondary,
  });

  @override
  State<_TripCountText> createState() => _TripCountTextState();
}

class _TripCountTextState extends State<_TripCountText> {
  int? _count;

  @override
  void initState() {
    super.initState();
    _loadCount();
  }

  Future<void> _loadCount() async {
    final c = await widget.trips.repository?.count();
    if (mounted) setState(() => _count = c);
  }

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context)!;
    if (_count == null) return const SizedBox.shrink();
    return Text(
      loc.menuTripCount(_count!),
      style: widget.theme.textTheme.bodySmall?.copyWith(color: widget.textSecondary),
    );
  }
}

// ── Section header ────────────────────────────────────────────────────────────

class _SectionHeader extends StatelessWidget {
  final String label;
  final ThemeData theme;

  const _SectionHeader({required this.label, required this.theme});

  @override
  Widget build(BuildContext context) {
    final isDark = theme.brightness == Brightness.dark;
    return Text(
      label,
      style: theme.textTheme.labelSmall?.copyWith(
        fontWeight: FontWeight.w700,
        letterSpacing: 1.2,
        color: isDark ? AppColors.darkText3 : AppColors.lightText3,
      ),
    );
  }
}

// ── Explore grid ──────────────────────────────────────────────────────────────

class _ExploreGrid extends StatelessWidget {
  final void Function(AppPageId id) onPageTap;
  final AppLocalizations loc;

  const _ExploreGrid({required this.onPageTap, required this.loc});

  @override
  Widget build(BuildContext context) {
    final items = [
      _ExploreCardData(
        id: AppPageId.dashboard,
        icon: AdaptiveIcons.dashboard,
        label: loc.menuDashboardTitle,
        color: AppColors.amber,
        subtitle: null,
      ),
      _ExploreCardData(
        id: AppPageId.tags,
        icon: AdaptiveIcons.tags,
        label: loc.menuTagsTitle,
        color: AppColors.blue,
        subtitle: null,
      ),
      _ExploreCardData(
        id: AppPageId.tickets,
        icon: AdaptiveIcons.tickets,
        label: loc.menuTicketsTitle,
        color: AppColors.early,
        subtitle: null,
      ),
      _ExploreCardData(
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
      childAspectRatio: 1.4,
      children: items
          .map((d) => _ExploreCard(data: d, onTap: () => onPageTap(d.id)))
          .toList(),
    );
  }
}

class _ExploreCardData {
  final AppPageId id;
  final IconData icon;
  final String label;
  final Color color;
  final _ExploreSubtitle? subtitle;

  const _ExploreCardData({
    required this.id,
    required this.icon,
    required this.label,
    required this.color,
    required this.subtitle,
  });
}

class _ExploreSubtitle {
  final String number;
  final Color numberColor;
  final String text;

  const _ExploreSubtitle({
    required this.number,
    required this.numberColor,
    required this.text,
  });
}

class _ExploreCard extends StatelessWidget {
  final _ExploreCardData data;
  final VoidCallback onTap;

  const _ExploreCard({required this.data, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final cardBg = isDark ? AppColors.darkSurface : AppColors.lightSurface;

    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          color: cardBg,
          borderRadius: BorderRadius.circular(14),
        ),
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: data.color.withOpacity(0.15),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(data.icon, color: data.color, size: 20),
            ),
            const Spacer(),
            Text(
              data.label,
              style: theme.textTheme.bodyMedium?.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
            if (data.subtitle != null) ...[
              const SizedBox(height: 2),
              RichText(
                text: TextSpan(
                  children: [
                    TextSpan(
                      text: data.subtitle!.number,
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: data.subtitle!.numberColor,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    TextSpan(
                      text: ' ${data.subtitle!.text}',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: isDark ? AppColors.darkText2 : AppColors.lightText2,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

// ── Menu list ─────────────────────────────────────────────────────────────────

class _MenuList extends StatelessWidget {
  final AppLocalizations loc;
  final ThemeData theme;
  final VoidCallback onInboxTap;
  final VoidCallback onTrainlogStatusTap;
  final VoidCallback onAboutTap;
  final VoidCallback onLogout;

  const _MenuList({
    required this.loc,
    required this.theme,
    required this.onInboxTap,
    required this.onTrainlogStatusTap,
    required this.onAboutTap,
    required this.onLogout,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = theme.brightness == Brightness.dark;
    final tileColor = isDark ? AppColors.darkSurface : AppColors.lightSurface;
    final errorColor = isDark ? AppColors.errorDark : AppColors.errorLight;

    Widget tile({
      required IconData icon,
      required String label,
      required VoidCallback onTap,
      Color? iconColor,
      Color? labelColor,
    }) {
      return Container(
        margin: const EdgeInsets.symmetric(vertical: 3),
        decoration: BoxDecoration(
          color: tileColor,
          borderRadius: BorderRadius.circular(12),
        ),
        child: ListTile(
          leading: Icon(icon, color: iconColor),
          title: Text(
            label,
            style: theme.textTheme.bodyMedium?.copyWith(
              fontWeight: FontWeight.w500,
              color: labelColor,
            ),
          ),
          trailing: Icon(
            Icons.chevron_right,
            color: isDark ? AppColors.darkText3 : AppColors.lightText3,
          ),
          onTap: onTap,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
      );
    }

    return Column(
      children: [
        tile(
          icon: AdaptiveIcons.inbox,
          label: loc.menuInboxTitle,
          onTap: onInboxTap,
        ),
        tile(
          icon: AdaptiveIcons.ok,
          label: loc.trainglogStatusPageTitle,
          onTap: onTrainlogStatusTap,
        ),
        tile(
          icon: AdaptiveIcons.info,
          label: loc.menuAboutTitle,
          onTap: onAboutTap,
        ),
        Container(
          margin: const EdgeInsets.symmetric(vertical: 3),
          decoration: BoxDecoration(
            color: tileColor,
            borderRadius: BorderRadius.circular(12),
          ),
          child: ListTile(
            leading: Icon(AdaptiveIcons.logout, color: errorColor),
            title: Text(
              loc.logoutButton,
              style: theme.textTheme.bodyMedium?.copyWith(
                fontWeight: FontWeight.w500,
                color: errorColor,
              ),
            ),
            onTap: onLogout,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          ),
        ),
      ],
    );
  }
}
