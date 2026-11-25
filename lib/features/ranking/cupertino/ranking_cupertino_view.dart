import 'package:flutter/cupertino.dart';
import 'package:provider/provider.dart';

import 'package:trainlog_app/core/providers/ranking_provider.dart';
import 'package:trainlog_app/features/ranking/cupertino/ranking_list_cupertino.dart';
import 'package:trainlog_app/features/ranking/cupertino/ranking_position_card_cupertino.dart';
import 'package:trainlog_app/features/ranking/ranking_page_controller.dart';
import 'package:trainlog_app/features/ranking/ranking_type.dart';
import 'package:trainlog_app/features/ranking/cupertino/railway_coverage_cupertino.dart';
import 'package:trainlog_app/features/ranking/cupertino/ranking_header_cupertino.dart';
import 'package:trainlog_app/l10n/app_localizations.dart';
import 'package:trainlog_app/ui/adaptive/adaptive_segmented_button.dart';
import 'package:trainlog_app/ui/cupertino/glass_menu_parts.dart';
import 'package:trainlog_app/ui/cupertino/glass_search_bar.dart';
import 'package:trainlog_app/ui/cupertino/liquid_glass.dart';

/// Ranking page, iOS: the large title with the search and sort buttons
/// grouped in a glass capsule, the categories as capsules (the vehicles in a
/// Liquid Glass menu), then the "Your position" card and the unit as a
/// segmented control, both staying in place while the leaderboard scrolls
/// beneath in an inset grouped list.
///
/// The search bar sits above the keyboard, as on the map, and filters the
/// list as one types. Railway coverage has its own layout
/// ([RailwayCoverageCupertino]).
class RankingCupertinoView extends StatefulWidget {
  const RankingCupertinoView({super.key});

  @override
  State<RankingCupertinoView> createState() => _RankingCupertinoViewState();
}

class _RankingCupertinoViewState extends State<RankingCupertinoView> {
  final _search = TextEditingController();
  final _searchFocus = FocusNode();

  @override
  void dispose() {
    _search.dispose();
    _searchFocus.dispose();
    super.dispose();
  }

  void _openSearch(RankingPageController page) {
    page.openSearch();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _searchFocus.requestFocus();
    });
  }

  void _closeSearch(RankingPageController page) {
    _searchFocus.unfocus();
    _search.clear();
    page.closeSearch();
  }

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context)!;
    final provider = context.watch<RankingProvider>();
    final page = context.watch<RankingPageController>();
    final isRail = provider.selection.type == RankingType.railwayCoverage;
    // Railway coverage has its own layout (tabs, countries or regions).
    if (isRail) return const RailwayCoverageCupertino();
    final searching = page.searchOpen;

    final media = MediaQuery.of(context);
    // Above the keyboard, or above the tab bar once the keyboard is down.
    // The shell's scaffold may already have shrunk the page to end at the
    // keyboard (its inset is then removed here): ask the window.
    final keyboard = media.viewInsets.bottom;
    final keyboardUp = View.of(context).viewInsets.bottom > 0;
    final searchBottom = keyboard > 0
        ? keyboard + 8
        : keyboardUp
        ? 8.0
        : media.padding.bottom + 8;

    final content = Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        RankingTitleBar(
          title: loc.menuRankingTitle,
          actions: searching
              ? null
              : GlassButtonGroup(
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
                        alphabetical: provider.alphabetical,
                        descending: provider.descending,
                        toggleAlphabetical: provider.toggleAlphabetical,
                        toggleDirection: provider.toggleDirection,
                      ),
                    ),
                  ],
                ),
        ),
        if (!searching) ...[
          const RankingCategoryCapsules(),
          const SizedBox(height: 14),
        ],
        if (!searching) ...[
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 16),
            child: RankingPositionCardCupertino(),
          ),
          if (provider.showsUnitDropdown)
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
              child: AdaptiveSegmentedButton.build<RankingSortUnit>(
                context: context,
                segments: [
                  for (final u in provider.availableUnits)
                    AdaptiveSegmentedButtonSegment(
                      value: u,
                      label: Text(u.label(context)),
                    ),
                ],
                selectedValue: provider.sortUnit,
                onChanged: (u) => provider.sortUnit = u,
              ),
            ),
          const SizedBox(height: 12),
        ],
        Expanded(
          child: RankingListCupertino(
            bottomInset: searching
                ? searchBottom + AppGlassSearchBar.height + 8
                : media.padding.bottom,
          ),
        ),
      ],
    );

    return Stack(
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
    );
  }
}
