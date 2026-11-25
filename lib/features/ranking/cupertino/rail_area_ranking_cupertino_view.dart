import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart' show MaterialLocalizations, Theme;
import 'package:provider/provider.dart';

import 'package:trainlog_app/core/data/models/ranking_model.dart';
import 'package:trainlog_app/features/ranking/cupertino/ranking_header_cupertino.dart';
import 'package:trainlog_app/features/ranking/cupertino/ranking_list_cupertino.dart';
import 'package:trainlog_app/features/ranking/cupertino/ranking_position_card_cupertino.dart';
import 'package:trainlog_app/features/ranking/rail_area_ranking_controller.dart';
import 'package:trainlog_app/features/ranking/ranking_type.dart';
import 'package:trainlog_app/features/ranking/widgets/coverage_progress_bar.dart';
import 'package:trainlog_app/features/ranking/widgets/flag_image.dart';
import 'package:trainlog_app/features/ranking/widgets/ranking_medal.dart';
import 'package:trainlog_app/l10n/app_localizations.dart';
import 'package:trainlog_app/ui/cupertino/glass_menu_parts.dart';
import 'package:trainlog_app/ui/cupertino/glass_search_bar.dart';
import 'package:trainlog_app/ui/cupertino/liquid_glass.dart';
import 'package:trainlog_app/ui/tokens/app_colors.dart';
import 'package:trainlog_app/ui/tokens/app_theme.dart';
import 'package:trainlog_app/utils/number_formatter.dart';
import 'package:trainlog_app/widgets/monogram.dart';

/// One area's rail-coverage leaderboard on iOS, laid out like the ranking
/// page: a glass back button, the search and sort (↕ menu) in a glass
/// capsule, the area's flag and name as the large title, the "Your position"
/// card, then the contenders in an inset grouped list (rank or medal,
/// monogram, name over a coverage bar, percentage). The search bar sits
/// above the keyboard and hides the card while it is open.
class RailAreaRankingCupertinoView extends StatefulWidget {
  const RailAreaRankingCupertinoView({
    super.key,
    required this.displayName,
    required this.flagCode,
  });

  final String displayName;
  final String flagCode;

  @override
  State<RailAreaRankingCupertinoView> createState() =>
      _RailAreaRankingCupertinoViewState();
}

class _RailAreaRankingCupertinoViewState
    extends State<RailAreaRankingCupertinoView> {
  final _search = TextEditingController();
  final _searchFocus = FocusNode();

  @override
  void dispose() {
    _search.dispose();
    _searchFocus.dispose();
    super.dispose();
  }

  void _openSearch(RailAreaRankingController page) {
    page.openSearch();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _searchFocus.requestFocus();
    });
  }

  void _closeSearch(RailAreaRankingController page) {
    _searchFocus.unfocus();
    _search.clear();
    page.closeSearch();
  }

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context)!;
    final page = context.watch<RailAreaRankingController>();
    final searching = page.searchOpen;
    final myRow = page.myRow;
    final media = MediaQuery.of(context);

    // Above the keyboard, or above the home indicator once it is down.
    final keyboard = media.viewInsets.bottom;
    final searchBottom = keyboard > 0 ? keyboard + 8 : media.padding.bottom + 8;

    final content = Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        SizedBox(height: media.padding.top),
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 4, 16, 0),
          child: Row(
            children: [
              GlassIconButton(
                icon: CupertinoIcons.chevron_back,
                shadow: false,
                tooltip: MaterialLocalizations.of(context).backButtonTooltip,
                onPressed: () => Navigator.of(context).maybePop(),
              ),
              const Spacer(),
              if (!searching)
                GlassButtonGroup(
                  children: [
                    GlassGroupItem(
                      icon: CupertinoIcons.search,
                      onPressed: () => _openSearch(page),
                      semanticLabel: loc.rankingSearchHint,
                    ),
                    GlassMenuGroupItem(
                      icon: CupertinoIcons.arrow_up_arrow_down,
                      semanticLabel: loc.rankingSortMenu,
                      sections: rankingSortSections(
                        loc,
                        alphabetical: page.alphabetical,
                        descending: page.descending,
                        toggleAlphabetical: page.toggleAlphabetical,
                        toggleDirection: page.toggleDirection,
                      ),
                    ),
                  ],
                ),
            ],
          ),
        ),
        RankingTitleBar(
          title: widget.displayName,
          leading: FlagImage(code: widget.flagCode, size: 32),
        ),
        if (!searching) ...[
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: PositionCardCupertino(
              accentColor: RankingType.railwayCoverage.accentColor(),
              icon: RankingType.railwayCoverage.icon,
              username: page.currentUsername,
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
        ],
        Expanded(
          child: _AreaListCupertino(
            bottomInset: searching
                ? searchBottom + AppGlassSearchBar.height + 8
                : media.padding.bottom,
          ),
        ),
      ],
    );

    return ColoredBox(
      color: CupertinoDynamicColor.resolve(
        CupertinoTheme.of(context).scaffoldBackgroundColor,
        context,
      ),
      child: Stack(
        children: [
          Positioned.fill(child: content),
          if (searching)
            AnimatedPositioned(
              duration: const Duration(milliseconds: 220),
              curve: Curves.easeOutCubic,
              left: 12,
              right: 12,
              bottom: searchBottom,
              child: AppGlassSearchBar(
                controller: _search,
                focusNode: _searchFocus,
                placeholder: loc.rankingSearchHint,
                onChanged: (v) => page.query = v,
                onCancel: () => _closeSearch(page),
              ),
            ),
        ],
      ),
    );
  }
}

/// The contenders as one inset grouped card.
class _AreaListCupertino extends StatelessWidget {
  const _AreaListCupertino({required this.bottomInset});

  final double bottomInset;

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context)!;
    final page = context.watch<RailAreaRankingController>();
    final rows = page.displayRows;

    if (rows.isEmpty) {
      return Padding(
        padding: EdgeInsets.only(bottom: bottomInset),
        child: Center(
          child: Text(
            loc.noData,
            style: TextStyle(
              color: CupertinoColors.secondaryLabel.resolveFrom(context),
            ),
          ),
        ),
      );
    }

    return ListView.builder(
      physics: const AlwaysScrollableScrollPhysics(
        parent: BouncingScrollPhysics(),
      ),
      keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
      padding: EdgeInsets.fromLTRB(16, 0, 16, bottomInset + 12),
      itemCount: rows.length,
      itemBuilder: (context, i) => RankingGroupedRow(
        isFirst: i == 0,
        isLast: i == rows.length - 1,
        highlighted: page.isCurrentUser(rows[i]),
        // Under the text, as in iOS lists.
        dividerIndent: 102,
        child: _AreaRowCupertino(
          row: rows[i],
          isCurrentUser: page.isCurrentUser(rows[i]),
          showRank: page.showsRank(rows, i),
        ),
      ),
    );
  }
}

/// Rank or medal, monogram, the name over a coverage bar, the percentage.
class _AreaRowCupertino extends StatelessWidget {
  const _AreaRowCupertino({
    required this.row,
    required this.isCurrentUser,
    required this.showRank,
  });

  final RailUserRow row;
  final bool isCurrentUser;
  final bool showRank;

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    final label = CupertinoColors.label.resolveFrom(context);
    final isDark = CupertinoTheme.brightnessOf(context) == Brightness.dark;

    return Padding(
      padding: const EdgeInsets.fromLTRB(10, 10, 14, 10),
      child: Row(
        children: [
          RankIndicator(rank: row.rank, showRank: showRank),
          const SizedBox(width: 10),
          Monogram(username: row.username, highlight: isCurrentUser),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  row.username,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: text.titleMedium?.copyWith(
                    fontWeight: FontWeight.w700,
                    letterSpacing: 0,
                    color: isCurrentUser
                        ? (isDark ? AppColors.amber : AppColors.amberDk)
                        : label,
                  ),
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
              fontSize: text.titleMedium?.fontSize,
              fontWeight: FontWeight.w700,
              color: label,
            ),
          ),
        ],
      ),
    );
  }
}
