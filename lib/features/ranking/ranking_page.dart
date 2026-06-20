import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'package:trainlog_app/features/ranking/widgets/ranking_filter_controls.dart';
import 'package:trainlog_app/features/ranking/widgets/ranking_list_view.dart';
import 'package:trainlog_app/features/ranking/widgets/ranking_selector_bar.dart';
import 'package:trainlog_app/features/ranking/widgets/ranking_user_position_block.dart';
import 'package:trainlog_app/l10n/app_localizations.dart';
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
                  IconButton(
                    onPressed: _toggleSearch,
                    icon: Icon(_searchOpen ? Icons.close : Icons.search),
                    tooltip: loc.rankingSearchHint,
                  ),
                ],
              ),
            ),

            if (_searchOpen)
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
            ),
            const SizedBox(height: 12),

            // ── User position block ───────────────────────────────────────
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: RankingUserPositionBlock(provider: provider),
            ),
            const SizedBox(height: 12),

            // ── Filter controls ───────────────────────────────────────────
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: RankingFilterControls(provider: provider),
            ),
            const SizedBox(height: 8),

            // ── Ranking list ──────────────────────────────────────────────
            Expanded(
              child: RankingListView(
                provider: provider,
                searchQuery: _searchQuery,
              ),
            ),
            SizedBox(height: navClearance),
          ],
        );
      },
    );
  }
}
