import 'package:flutter/material.dart';

import 'package:trainlog_app/app/theme/app_colors.dart';
import 'package:trainlog_app/app/theme/app_theme.dart';
import 'package:trainlog_app/data/models/ranking_model.dart';
import 'package:trainlog_app/features/ranking/widgets/coverage_list_card.dart';
import 'package:trainlog_app/features/ranking/widgets/coverage_progress_bar.dart';
import 'package:trainlog_app/features/ranking/widgets/coverage_sort_controls.dart';
import 'package:trainlog_app/features/ranking/widgets/flag_image.dart';
import 'package:trainlog_app/features/ranking/widgets/rail_user_position_block.dart';
import 'package:trainlog_app/features/ranking/widgets/ranking_medal.dart';
import 'package:trainlog_app/l10n/app_localizations.dart';
import 'package:trainlog_app/platform/adaptive_app_bar.dart';
import 'package:trainlog_app/platform/adaptive_widget.dart';
import 'package:trainlog_app/utils/number_formatter.dart';

/// Drill-down sub-page for a single country or subdivision's rail-coverage
/// leaderboard. Pushed onto the stack (hiding the bottom navigation), it shows
/// the per-user contender pool as ranked rows with a linear coverage bar each.
///
/// The competitive rank is computed once from the coverage percentage (highest
/// first); the alphabetical / direction toggles and the search field only
/// affect what is displayed.
class RailAreaRankingPage extends StatefulWidget {
  /// The area's coverage data (a country or a subdivision entry).
  final RailPercentageEntry entry;

  /// Localized area name shown in the app-bar title.
  final String displayName;

  /// Flag code (country or ISO 3166-2 subdivision) for the app-bar title flag.
  final String flagCode;

  /// The current user's login name, used to highlight their row.
  final String? currentUsername;

  const RailAreaRankingPage({
    super.key,
    required this.entry,
    required this.displayName,
    required this.flagCode,
    required this.currentUsername,
  });

  @override
  State<RailAreaRankingPage> createState() => _RailAreaRankingPageState();
}

class _RailAreaRankingPageState extends State<RailAreaRankingPage> {
  bool _alphabetical = false;
  bool _descending = true;
  bool _searchOpen = false;
  String _searchQuery = '';
  final _searchController = TextEditingController();

  late final List<RailUserRow> _ranked = buildRailUserRows(widget.entry);

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

  /// Rows in display order (the competitive rank inside each row is untouched).
  List<RailUserRow> get _displayRows {
    final list = List<RailUserRow>.of(_ranked);
    if (_alphabetical) {
      list.sort(
        (a, b) => a.username.toLowerCase().compareTo(b.username.toLowerCase()),
      );
    } else {
      list.sort((a, b) {
        final cmp = b.percent.compareTo(a.percent);
        if (cmp != 0) return cmp;
        return a.username.toLowerCase().compareTo(b.username.toLowerCase());
      });
    }
    final ordered = _descending ? list : list.reversed.toList();
    final query = _searchQuery.trim().toLowerCase();
    if (query.isEmpty) return ordered;
    return ordered
        .where((r) => r.username.toLowerCase().contains(query))
        .toList();
  }

  RailUserRow? get _myRow {
    final me = widget.currentUsername?.toLowerCase();
    if (me == null) return null;
    for (final r in _ranked) {
      if (r.username.toLowerCase() == me) return r;
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context)!;
    final rows = _displayRows;
    final me = widget.currentUsername?.toLowerCase();
    final myRow = _myRow;

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
          Center(child: _searchButton(loc)),
          const SizedBox(width: 8),
        ],
        cupertinoTrailing: _searchButton(loc),
      ),
      body: SafeArea(
        top: false,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
              child: RailUserPositionBlock(
                username: widget.currentUsername ?? '',
                subtitle: loc.railCoverageAreaSubtitle(widget.displayName),
                rank: myRow?.rank,
                contenders: _ranked.length,
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
                  CoverageSortControls(
                    alphabetical: _alphabetical,
                    descending: _descending,
                    onToggleAlphabetical: () =>
                        setState(() => _alphabetical = !_alphabetical),
                    onToggleDirection: () =>
                        setState(() => _descending = !_descending),
                  ),
                ],
              ),
            ),
            if (_searchOpen)
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
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
            const SizedBox(height: 8),
            Expanded(
              child: rows.isEmpty
                  ? Center(child: Text(loc.rankingNoData))
                  : CoverageListCard(
                      child: ListView.separated(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 8),
                        itemCount: rows.length,
                        separatorBuilder: (_, __) => const SizedBox(height: 4),
                        itemBuilder: (context, i) {
                          final r = rows[i];
                          final showRank = i == 0 ||
                              rows[i - 1].percent != r.percent ||
                              _alphabetical;
                          return _AreaUserRow(
                            row: r,
                            isCurrentUser:
                                me != null && r.username.toLowerCase() == me,
                            showRank: showRank,
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

  Widget _searchButton(AppLocalizations loc) => AdaptiveAppBarSquareButton(
        onPressed: _toggleSearch,
        icon: _searchOpen ? Icons.search_off : Icons.search,
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
          _RankIndicator(rank: row.rank, showRank: showRank),
          const SizedBox(width: 10),
          _Monogram(username: row.username, highlight: isCurrentUser),
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

class _RankIndicator extends StatelessWidget {
  final int rank;
  final bool showRank;

  const _RankIndicator({required this.rank, required this.showRank});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    if (!showRank) return const SizedBox(width: 34);

    if (RankingMedal.isMedal(rank)) {
      return Container(
        width: 34,
        height: 34,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: RankingMedal.colorOf(rank).withValues(alpha: 0.18),
          shape: BoxShape.circle,
        ),
        child: RankingMedal(rank: rank, size: 18),
      );
    }

    return SizedBox(
      width: 34,
      child: Text(
        '$rank',
        textAlign: TextAlign.center,
        style: AppTheme.monoFont.copyWith(
          fontSize: 15,
          fontWeight: FontWeight.w700,
          color: cs.onSurfaceVariant,
        ),
      ),
    );
  }
}

class _Monogram extends StatelessWidget {
  final String username;
  final bool highlight;

  const _Monogram({required this.username, required this.highlight});

  static const _palette = <Color>[
    AppColors.blue,
    AppColors.modeBus,
    AppColors.modeTram,
    AppColors.modeAir,
    AppColors.modeFerry,
    AppColors.violet,
    AppColors.amberDk,
  ];

  @override
  Widget build(BuildContext context) {
    final letter =
        username.isEmpty ? '?' : username.substring(0, 1).toUpperCase();
    final color = _palette[username.hashCode.abs() % _palette.length];

    return Container(
      width: 44,
      height: 44,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: color,
        shape: BoxShape.circle,
        border:
            highlight ? Border.all(color: AppColors.amber, width: 2) : null,
      ),
      child: Text(
        letter,
        style: const TextStyle(
          color: Colors.white,
          fontSize: 18,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }
}
