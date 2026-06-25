import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'package:trainlog_app/data/models/ranking_model.dart';
import 'package:trainlog_app/features/ranking/rail_area_ranking_page.dart';
import 'package:trainlog_app/features/ranking/widgets/coverage_list_card.dart';
import 'package:trainlog_app/features/ranking/widgets/coverage_progress_ring.dart';
import 'package:trainlog_app/features/ranking/widgets/coverage_sort_controls.dart';
import 'package:trainlog_app/features/ranking/widgets/flag_image.dart';
import 'package:trainlog_app/features/ranking/widgets/rail_user_position_block.dart';
import 'package:trainlog_app/l10n/app_localizations.dart';
import 'package:trainlog_app/platform/adaptive_page_route.dart';
import 'package:trainlog_app/platform/widget/adaptive_popup.dart';
import 'package:trainlog_app/providers/railway_coverage_provider.dart';
import 'package:trainlog_app/providers/trainlog_provider.dart';
import 'package:trainlog_app/utils/number_formatter.dart';
import 'package:trainlog_app/utils/text_utils.dart';
import 'package:trainlog_app/widgets/app_steps_tab_bar.dart';

/// The Railway Coverage sub-feature: a user-position block, a Countries/Regions
/// segmented tab bar with inline sorting, and the matching list (a country list,
/// or a country dropdown + its subdivisions). Tapping a row drills into a
/// dedicated ranking page.
///
/// Owns its own [RailwayCoverageProvider]; data is fetched once on mount.
class RailwayCoverageView extends StatelessWidget {
  const RailwayCoverageView({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (ctx) =>
          RailwayCoverageProvider(ctx.read<TrainlogProvider>())..load(),
      child: const _RailwayCoverageBody(),
    );
  }
}

class _RailwayCoverageBody extends StatelessWidget {
  const _RailwayCoverageBody();

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context)!;
    final provider = context.watch<RailwayCoverageProvider>();
    final isRegions = provider.tab == RailCoverageTab.regions;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // ── User position block ───────────────────────────────────────────
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: _positionBlock(context, provider, loc),
        ),
        const SizedBox(height: 12),

        // ── Tab bar + inline sorting ──────────────────────────────────────
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Row(
            children: [
              Expanded(
                child: AppStepsTabBar(
                  fullWidth: true,
                  selectedIndex: provider.tab.index,
                  onTabChanged: (i) =>
                      provider.setTab(RailCoverageTab.values[i]),
                  tabs: [
                    AppStepsTab(label: loc.railCoverageCountriesTab),
                    AppStepsTab(label: loc.railCoverageRegionsTab),
                  ],
                ),
              ),
              const SizedBox(width: 10),
              CoverageSortControls(
                alphabetical: provider.alphabetical,
                descending: provider.descending,
                enabled: provider.sortingEnabled,
                onToggleAlphabetical: provider.toggleAlphabetical,
                onToggleDirection: provider.toggleDirection,
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),

        // ── Region country dropdown ───────────────────────────────────────
        if (isRegions) ...[
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: _RegionCountryDropdown(provider: provider),
          ),
          const SizedBox(height: 12),
        ],

        // ── List ──────────────────────────────────────────────────────────
        Expanded(child: _buildList(context, provider, loc)),
      ],
    );
  }

  Widget _positionBlock(
    BuildContext context,
    RailwayCoverageProvider provider,
    AppLocalizations loc,
  ) {
    final standing = provider.userStanding();
    final led = provider.userLedCountries();
    final flagCodes = led.take(3).map((e) => e.countryCode).toList();

    String? info;
    if (standing != null) {
      final examples = led.take(2).map((e) {
        final name = e.country(context).name;
        final pct = NumberFormatter.percent(
          e.highestPercent,
          locale: Localizations.localeOf(context),
        );
        return '$name $pct';
      }).join(', ');
      info = loc.railCoverageLeadCount(standing.ledCount);
      if (examples.isNotEmpty) info = '$info · $examples';
    }

    return RailUserPositionBlock(
      username: provider.currentUsername ?? '',
      subtitle: loc.rankingTypeRailwayCoverage,
      rank: standing?.rank,
      contenders: standing?.contenders,
      ledFlagCodes: flagCodes,
      ledMore: led.length > 3,
      infoLine: info,
    );
  }

  Widget _buildList(
    BuildContext context,
    RailwayCoverageProvider provider,
    AppLocalizations loc,
  ) {
    if (provider.isLoading) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.symmetric(vertical: 48),
          child: CircularProgressIndicator(),
        ),
      );
    }
    if (provider.error != null) {
      return Center(child: Text('Error: ${provider.error}'));
    }

    if (provider.tab == RailCoverageTab.regions) {
      if (provider.selectedCountry == null) {
        return Center(
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 48),
            child: Text(
              loc.railCoverageSelectRegion,
              style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
            ),
          ),
        );
      }
      final regions = provider.regions();
      return _CoverageList(
        entries: regions,
        currentUsername: provider.currentUsername,
        nameOf: (e) => e.code,
        flagOf: (e) => e.code,
        emptyText: loc.rankingNoData,
      );
    }

    final countries = provider.countries(context);
    return _CoverageList(
      entries: countries,
      currentUsername: provider.currentUsername,
      nameOf: (e) => e.country(context).name,
      flagOf: (e) => e.countryCode,
      emptyText: loc.rankingNoData,
    );
  }
}

/// The shared, unified card list of coverage rows (countries or subdivisions).
class _CoverageList extends StatelessWidget {
  final List<RailPercentageEntry> entries;
  final String? currentUsername;
  final String Function(RailPercentageEntry entry) nameOf;
  final String Function(RailPercentageEntry entry) flagOf;
  final String emptyText;

  const _CoverageList({
    required this.entries,
    required this.currentUsername,
    required this.nameOf,
    required this.flagOf,
    required this.emptyText,
  });

  @override
  Widget build(BuildContext context) {
    if (entries.isEmpty) {
      return Center(child: Text(emptyText));
    }

    final cs = Theme.of(context).colorScheme;

    return CoverageListCard(
      child: ListView.separated(
        padding: EdgeInsets.zero,
        itemCount: entries.length,
        separatorBuilder: (_, __) => Divider(
          height: 1,
          thickness: 1,
          indent: 16,
          endIndent: 16,
          color: cs.outlineVariant.withValues(alpha: 0.4),
        ),
        itemBuilder: (context, i) {
          final e = entries[i];
          final name = nameOf(e);
          return _CoverageRow(
            flagCode: flagOf(e),
            title: name,
            leaders: e.leaders.map((u) => u.username).toList(),
            percent: e.highestPercent,
            onTap: () => AdaptivePageRoute.push(
              context,
              (_) => RailAreaRankingPage(
                entry: e,
                displayName: name,
                flagCode: flagOf(e),
                currentUsername: currentUsername,
              ),
            ),
          );
        },
      ),
    );
  }
}

/// A single country/region row: flag + name, a trophy + leaders line, a circular
/// coverage ring and a navigation chevron.
class _CoverageRow extends StatelessWidget {
  final String flagCode;
  final String title;
  final List<String> leaders;
  final double percent;
  final VoidCallback onTap;

  const _CoverageRow({
    required this.flagCode,
    required this.title,
    required this.leaders,
    required this.percent,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Row(
          children: [
            FlagImage(code: flagCode, size: 34),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w700,
                          color: cs.onSurface,
                        ),
                    overflow: TextOverflow.ellipsis,
                  ),
                  if (leaders.isNotEmpty) ...[
                    const SizedBox(height: 3),
                    Row(
                      children: [
                        Icon(Icons.emoji_events, size: 13, color: cs.primary),
                        const SizedBox(width: 4),
                        Expanded(
                          child: Text(
                            leaders.join(', '),
                            style: Theme.of(context)
                                .textTheme
                                .bodySmall
                                ?.copyWith(color: cs.onSurfaceVariant),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                  ],
                ],
              ),
            ),
            const SizedBox(width: 12),
            CoverageProgressRing(percent: percent),
            const SizedBox(width: 6),
            Icon(Icons.chevron_right, color: cs.onSurfaceVariant),
          ],
        ),
      ),
    );
  }
}

/// Dropdown selector for the Regions tab: lists countries that have subdivision
/// data (alphabetical, with their flag and subdivision count). Falls back to a
/// "Select a region" placeholder until a country is chosen.
class _RegionCountryDropdown extends StatelessWidget {
  final RailwayCoverageProvider provider;

  const _RegionCountryDropdown({required this.provider});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final loc = AppLocalizations.of(context)!;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final options = provider.regionCountryOptions(context);

    RailCountryOption? selected;
    for (final o in options) {
      if (o.code == provider.selectedCountry) {
        selected = o;
        break;
      }
    }

    final label = selected == null
        ? loc.railCoverageSelectRegion
        : '${selected.name} (${loc.railCoverageRegionCount(selected.count)})';

    return AdaptivePopup<String>(
      enabled: options.isNotEmpty,
      initialValue: provider.selectedCountry,
      onSelected: provider.selectCountry,
      items: [
        for (final o in options)
          AdaptivePopupItem<String>(
            value: o.code,
            label: '${o.name} (${loc.railCoverageRegionCount(o.count)})',
            leading: Text(
              countryCodeToEmoji(o.code),
              style: const TextStyle(fontSize: 20),
            ),
          ),
      ],
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          color: isDark ? cs.surface : Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: cs.outlineVariant.withValues(alpha: 0.4),
            width: 1.2,
          ),
        ),
        child: Row(
          children: [
            if (selected != null) ...[
              Text(
                countryCodeToEmoji(selected.code),
                style: const TextStyle(fontSize: 22),
              ),
              const SizedBox(width: 10),
            ] else ...[
              Icon(Icons.public, size: 20, color: cs.onSurfaceVariant),
              const SizedBox(width: 10),
            ],
            Expanded(
              child: Text(
                label,
                style: Theme.of(context).textTheme.titleSmall?.copyWith(
                      color: selected == null
                          ? cs.onSurfaceVariant
                          : cs.onSurface,
                      fontWeight: FontWeight.w600,
                    ),
                overflow: TextOverflow.ellipsis,
              ),
            ),
            Icon(Icons.keyboard_arrow_down, color: cs.onSurfaceVariant),
          ],
        ),
      ),
    );
  }
}
