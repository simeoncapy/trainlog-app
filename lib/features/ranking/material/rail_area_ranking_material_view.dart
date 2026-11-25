import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'package:trainlog_app/ui/tokens/app_theme.dart';
import 'package:trainlog_app/core/data/models/ranking_model.dart';
import 'package:trainlog_app/features/ranking/rail_area_ranking_controller.dart';
import 'package:trainlog_app/features/ranking/ranking_type.dart';
import 'package:trainlog_app/features/ranking/widgets/coverage_list_card.dart';
import 'package:trainlog_app/features/ranking/widgets/coverage_progress_bar.dart';
import 'package:trainlog_app/features/ranking/widgets/ranking_filter_controls.dart';
import 'package:trainlog_app/features/ranking/widgets/flag_image.dart';
import 'package:trainlog_app/features/ranking/widgets/ranking_user_position_block.dart';
import 'package:trainlog_app/features/ranking/widgets/ranking_medal.dart';
import 'package:trainlog_app/l10n/app_localizations.dart';
import 'package:trainlog_app/ui/adaptive/adaptive_app_bar.dart';
import 'package:trainlog_app/ui/adaptive/adaptive_widget.dart';
import 'package:trainlog_app/utils/number_formatter.dart';
import 'package:trainlog_app/widgets/monogram.dart';

/// One area's rail-coverage leaderboard, Material: app bar with the flag and
/// a search toggle, the user's position block, the sort buttons, an inline
/// search field and the contenders with a linear coverage bar each.
class RailAreaRankingMaterialView extends StatefulWidget {
  const RailAreaRankingMaterialView({
    super.key,
    required this.displayName,
    required this.flagCode,
  });

  final String displayName;
  final String flagCode;

  @override
  State<RailAreaRankingMaterialView> createState() =>
      _RailAreaRankingMaterialViewState();
}

class _RailAreaRankingMaterialViewState
    extends State<RailAreaRankingMaterialView> {
  final _searchController = TextEditingController();

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _toggleSearch(RailAreaRankingController page) {
    if (page.searchOpen) _searchController.clear();
    page.toggleSearch();
  }

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context)!;
    final page = context.watch<RailAreaRankingController>();
    final rows = page.displayRows;
    final myRow = page.myRow;

    return Scaffold(
      appBar: AdaptiveAppBar(
        title: widget.displayName,
        titleWidget: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            FlagImage(code: widget.flagCode, size: 26),
            const SizedBox(width: 10),
            Flexible(
              child: Text(
                widget.displayName,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(fontWeight: FontWeight.w700),
              ),
            ),
          ],
        ),
        onBack: () => Navigator.of(context).pop(),
        materialActions: [
          Center(child: _searchButton(loc, page)),
          const SizedBox(width: 8),
        ],
        cupertinoTrailing: _searchButton(loc, page),
      ),
      body: SafeArea(
        top: false,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
              child: RankingUserPositionBlock(
                icon: RankingPositionIcon(
                  icon: RankingType.railwayCoverage.icon,
                  color: RankingType.railwayCoverage.accentColor(),
                ),
                username: page.currentUsername ?? '',
                subtitle: loc.railCoverageAreaSubtitle(widget.displayName),
                rank: myRow?.rank,
                participantCount: page.ranked.length,
                valueText: myRow == null
                    ? null
                    : NumberFormatter.percent(
                        myRow.percent,
                        locale: Localizations.localeOf(context),
                      ),
              ),
            ),
            const SizedBox(height: 12),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Row(
                children: [
                  const Spacer(),
                  RankingSortButtons(
                    alphabetical: page.alphabetical,
                    descending: page.descending,
                    onToggleAlphabetical: page.toggleAlphabetical,
                    onToggleDirection: page.toggleDirection,
                  ),
                ],
              ),
            ),
            if (page.searchOpen)
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
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
            const SizedBox(height: 8),
            Expanded(
              child: rows.isEmpty
                  ? Center(child: Text(loc.noData))
                  : CoverageListCard(
                      child: ListView.separated(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 8),
                        itemCount: rows.length,
                        separatorBuilder: (_, __) => const SizedBox(height: 4),
                        itemBuilder: (context, i) {
                          final r = rows[i];
                          return _AreaUserRow(
                            row: r,
                            isCurrentUser: page.isCurrentUser(r),
                            showRank: page.showsRank(rows, i),
                          );
                        },
                      ),
                    ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _searchButton(
    AppLocalizations loc,
    RailAreaRankingController page,
  ) => AdaptiveAppBarSquareButton(
        onPressed: () => _toggleSearch(page),
        icon: page.searchOpen ? Icons.search_off : Icons.search,
        tooltip: loc.rankingSearchHint,
      );
}

/// A single contender row: rank, monogram, username + coverage bar, percentage.
class _AreaUserRow extends StatelessWidget {
  final RailUserRow row;
  final bool isCurrentUser;
  final bool showRank;

  const _AreaUserRow({
    required this.row,
    required this.isCurrentUser,
    required this.showRank,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
      decoration: BoxDecoration(
        color:
            isCurrentUser ? cs.primary.withValues(alpha: 0.12) : Colors.transparent,
        borderRadius: BorderRadius.circular(14),
        border: isCurrentUser
            ? Border.all(color: cs.primary.withValues(alpha: 0.6), width: 1.4)
            : null,
      ),
      child: Row(
        children: [
          RankIndicator(rank: row.rank, showRank: showRank),
          const SizedBox(width: 10),
          Monogram(username: row.username, highlight: isCurrentUser),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  row.username,
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w700,
                        color: isCurrentUser ? cs.primary : cs.onSurface,
                      ),
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 6),
                CoverageProgressBar(percent: row.percent),
              ],
            ),
          ),
          const SizedBox(width: 12),
          Text(
            NumberFormatter.percent(
              row.percent,
              locale: Localizations.localeOf(context),
            ),
            style: AppTheme.monoFont.copyWith(
              fontSize: 16,
              fontWeight: FontWeight.w800,
              color: cs.onSurface,
            ),
          ),
        ],
      ),
    );
  }
}

