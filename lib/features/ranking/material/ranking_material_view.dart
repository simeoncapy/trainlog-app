import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'package:trainlog_app/features/ranking/ranking_page_controller.dart';
import 'package:trainlog_app/features/ranking/ranking_type.dart';
import 'package:trainlog_app/features/ranking/user_countries_page.dart';
import 'package:trainlog_app/features/ranking/widgets/railway_coverage_view.dart';
import 'package:trainlog_app/features/ranking/widgets/ranking_filter_controls.dart';
import 'package:trainlog_app/features/ranking/widgets/ranking_list_view.dart';
import 'package:trainlog_app/features/ranking/widgets/ranking_position_info.dart';
import 'package:trainlog_app/features/ranking/widgets/ranking_selector_bar.dart';
import 'package:trainlog_app/features/ranking/widgets/ranking_user_position_block.dart';
import 'package:trainlog_app/l10n/app_localizations.dart';
import 'package:trainlog_app/ui/adaptive/adaptive_page_route.dart';
import 'package:trainlog_app/ui/adaptive/adaptive_widget.dart';
import 'package:trainlog_app/core/providers/ranking_provider.dart';
import 'package:trainlog_app/core/providers/settings_provider.dart';
import 'package:trainlog_app/utils/map_color_palette.dart';
import 'package:trainlog_app/utils/text_utils.dart';

/// Ranking page, Material: the page title + search action, the category
/// selector, the user position block, the filter controls and the ranking
/// list. Reads [RankingProvider] (the leaderboard) and
/// [RankingPageController] (the search).
class RankingMaterialView extends StatefulWidget {
  const RankingMaterialView({super.key});

  @override
  State<RankingMaterialView> createState() => _RankingMaterialViewState();
}

class _RankingMaterialViewState extends State<RankingMaterialView> {
  final _searchController = TextEditingController();

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _toggleSearch(RankingPageController page) {
    if (page.searchOpen) _searchController.clear();
    page.toggleSearch();
  }

  /// Assembles the shared [RankingUserPositionBlock] from the [provider]'s
  /// current state (the widget itself is presentational).
  Widget _userPositionBlock(BuildContext context, RankingProvider provider) {
    final selection = provider.selection;
    final entry = provider.currentUserEntry;
    final info = RankingPositionInfo.of(context, provider);
    final palette = MapColorPaletteHelper.getPalette(
      context.watch<SettingsProvider>().mapColorPalette,
    );

    // Extra content beneath the row: the carbon info banner, or the visited
    // country flags (tappable, drilling into the full country list).
    final Object? details;
    if (info.explanation != null) {
      details = info.explanation;
    } else if (entry != null && info.countryCodes.isNotEmpty) {
      details = _VisitedCountryFlags(
        countryCodes: info.countryCodes,
        onTap: () => AdaptivePageRoute.push(
          context,
          (_) => UserCountriesPage(
            username: entry.username,
            countryCodes: info.countryCodes,
          ),
        ),
      );
    } else {
      details = null;
    }

    return RankingUserPositionBlock(
      icon: RankingPositionIcon(
        icon: selection.icon,
        color: selection.accentColor(palette),
      ),
      username: provider.currentUsername ?? '',
      subtitle: info.subtitle,
      rank: entry?.rank,
      participantCount: provider.participantCount,
      valueText: info.valueText,
      valueTooltip: info.valueTooltip,
      details: details,
    );
  }

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context)!;
    final navClearance = MediaQuery.of(context).padding.bottom;

    final provider = context.watch<RankingProvider>();
    final page = context.watch<RankingPageController>();
    final searchOpen = page.searchOpen;
    // The Railway Coverage category has its own self-contained layout
    // (tabs + lists) and hides the page-level search action — search lives
    // on its drill-down ranking pages instead.
    final isRail =
        provider.selection.type == RankingType.railwayCoverage;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // ── Title + search ────────────────────────────────────────────
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 8, 8),
          child: Row(
            children: [
              Expanded(
                child: Text(
                  loc.menuRankingTitle,
                  style:
                      Theme.of(context).textTheme.headlineMedium?.copyWith(
                            fontWeight: FontWeight.w700,
                          ),
                ),
              ),
              if (!isRail)
                AdaptiveAppBarSquareButton(
                  onPressed: () => _toggleSearch(page),
                  icon: searchOpen ? Icons.search_off : Icons.search,
                  tooltip: loc.rankingSearchHint,
                ),
            ],
          ),
        ),

        if (searchOpen && !isRail)
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
            child: TextField(
              controller: _searchController,
              autofocus: true,
              onChanged: (v) => page.query = v,
              decoration: InputDecoration(
                isDense: true,
                prefixIcon: const Icon(Icons.search),
                hintText: loc.rankingSearchHint,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ),

        // ── Selector pills ────────────────────────────────────────────
        RankingSelectorBar(
          selected: provider.selection,
          onSelected: provider.select,
          isCompact: true,
        ),
        const SizedBox(height: 12),

        // ── Body: Railway Coverage has its own layout; every other
        //    category shares the position block + filters + list. ───────
        if (isRail)
          const Expanded(child: RailwayCoverageView())
        else ...[
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: _userPositionBlock(context, provider),
          ),
          const SizedBox(height: 12),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: RankingFilterControls(provider: provider),
          ),
          const SizedBox(height: 8),
          Expanded(
            child: RankingListView(
              provider: provider,
              searchQuery: page.query,
            ),
          ),
        ],
        SizedBox(height: navClearance),
      ],
    );
  }
}

/// The country-ranking details of [RankingUserPositionBlock]: the flags of the
/// countries the user has visited (backend order — most visited first), capped
/// at two lines with an ellipsis, plus a trailing chevron. Tapping it opens the
/// user's full [UserCountriesPage].
class _VisitedCountryFlags extends StatelessWidget {
  /// ISO country codes in the backend order (by trip count, most visited
  /// first).
  final List<String> countryCodes;

  final VoidCallback onTap;

  const _VisitedCountryFlags({
    required this.countryCodes,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(10),
      child: Padding(
        padding: const EdgeInsets.only(top: 14),
        child: Row(
          children: [
            Expanded(
              child: Text(
                countryCodes.map(countryCodeToEmoji).join(' '),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontSize: 18,
                  height: 1.5,
                  letterSpacing: 2,
                  color: cs.onInverseSurface,
                ),
              ),
            ),
            const SizedBox(width: 8),
            Icon(
              Icons.chevron_right,
              color: cs.onInverseSurface.withValues(alpha: 0.7),
            ),
          ],
        ),
      ),
    );
  }
}
