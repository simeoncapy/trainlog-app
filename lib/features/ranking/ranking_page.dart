import 'package:country_codes_plus/country_codes_plus.dart';
import 'package:flutter/material.dart';
import 'package:flutter_inappwebview/flutter_inappwebview.dart';
import 'package:provider/provider.dart';

import 'package:trainlog_app/features/ranking/ranking_type.dart';
import 'package:trainlog_app/features/ranking/widgets/railway_coverage_view.dart';
import 'package:trainlog_app/features/ranking/widgets/ranking_filter_controls.dart';
import 'package:trainlog_app/features/ranking/widgets/ranking_list_view.dart';
import 'package:trainlog_app/features/ranking/widgets/ranking_selector_bar.dart';
import 'package:trainlog_app/features/ranking/widgets/ranking_user_position_block.dart';
import 'package:trainlog_app/l10n/app_localizations.dart';
import 'package:trainlog_app/platform/adaptive_widget.dart';
import 'package:trainlog_app/providers/ranking_provider.dart';
import 'package:trainlog_app/providers/trainlog_provider.dart';

/// Native, adaptive leaderboard entry point.
///
/// Stacks the page title + search action, the category selector, the user
/// position block, the filter controls and the ranking list. All data is
/// driven by [RankingProvider] (which fetches through the ranking API).
class RankingPage extends StatefulWidget {
  const RankingPage({super.key});

  @override
  State<RankingPage> createState() => _RankingPageState();
}

class _RankingPageState extends State<RankingPage> {
  bool _searchOpen = false;
  String _searchQuery = '';
  final _searchController = TextEditingController();

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _toggleSearch() {
    setState(() {
      _searchOpen = !_searchOpen;
      if (!_searchOpen) {
        _searchQuery = '';
        _searchController.clear();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context)!;
    final navClearance = MediaQuery.of(context).padding.bottom;

    return ChangeNotifierProvider(
      create: (ctx) => RankingProvider(ctx.read<TrainlogProvider>())..load(),
      builder: (context, _) {
        final provider = context.watch<RankingProvider>();
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
                      onPressed: _toggleSearch,
                      icon: _searchOpen ? Icons.search_off : Icons.search,
                      tooltip: loc.rankingSearchHint,
                    ),
                ],
              ),
            ),

            if (_searchOpen && !isRail)
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
                child: TextField(
                  controller: _searchController,
                  autofocus: true,
                  onChanged: (v) => setState(() => _searchQuery = v),
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
                child: RankingUserPositionBlock(provider: provider),
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
                  searchQuery: _searchQuery,
                ),
              ),
            ],
            SizedBox(height: navClearance),
          ],
        );
      },
    );
  }
}
