import 'package:flutter/cupertino.dart';
import 'package:provider/provider.dart';

import 'package:trainlog_app/core/data/models/trips.dart';
import 'package:trainlog_app/core/providers/ranking_provider.dart';
import 'package:trainlog_app/core/providers/settings_provider.dart';
import 'package:trainlog_app/features/ranking/cupertino/ranking_list_cupertino.dart';
import 'package:trainlog_app/features/ranking/cupertino/ranking_position_card_cupertino.dart';
import 'package:trainlog_app/features/ranking/ranking_page_controller.dart';
import 'package:trainlog_app/features/ranking/ranking_type.dart';
import 'package:trainlog_app/features/ranking/widgets/railway_coverage_view.dart';
import 'package:trainlog_app/l10n/app_localizations.dart';
import 'package:trainlog_app/ui/adaptive/adaptive_segmented_button.dart';
import 'package:trainlog_app/ui/cupertino/glass_filter_parts.dart';
import 'package:trainlog_app/ui/cupertino/glass_menu_parts.dart';
import 'package:trainlog_app/ui/cupertino/glass_search_bar.dart';
import 'package:trainlog_app/ui/cupertino/liquid_glass.dart';
import 'package:trainlog_app/utils/map_color_palette.dart';

/// Ranking page, iOS: the large title with the search and sort buttons
/// grouped in a glass capsule, the categories as capsules (the vehicles in a
/// Liquid Glass menu), then the "Your position" card and the unit as a
/// segmented control, both staying in place while the leaderboard scrolls
/// beneath in an inset grouped list.
///
/// The search bar sits above the keyboard, as on the map, and filters the
/// list as one types. Railway coverage keeps its own layout.
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
    final searching = page.searchOpen && !isRail;

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
        _TitleBar(
          title: loc.menuRankingTitle,
          actions: isRail || searching
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
                      sections: _sortSections(loc, provider),
                    ),
                  ],
                ),
        ),
        if (!searching) ...[
          const _CategoryCapsules(),
          const SizedBox(height: 14),
        ],
        if (isRail)
          const Expanded(child: RailwayCoverageView())
        else ...[
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

  /// The sort menu: by value or alphabetically, then the order.
  List<AppMenuSection> _sortSections(
    AppLocalizations loc,
    RankingProvider provider,
  ) {
    return [
      AppMenuSection(
        entries: [
          AppMenuEntry(
            label: loc.rankingSortByValue,
            checked: !provider.alphabetical,
            onTap: () {
              if (provider.alphabetical) provider.toggleAlphabetical();
            },
          ),
          AppMenuEntry(
            label: loc.rankingSortAlphabetical,
            checked: provider.alphabetical,
            onTap: () {
              if (!provider.alphabetical) provider.toggleAlphabetical();
            },
          ),
        ],
      ),
      AppMenuSection(
        entries: [
          AppMenuEntry(
            label: loc.rankingOrderDescending,
            checked: provider.descending,
            onTap: () {
              if (!provider.descending) provider.toggleDirection();
            },
          ),
          AppMenuEntry(
            label: loc.rankingOrderAscending,
            checked: !provider.descending,
            onTap: () {
              if (provider.descending) provider.toggleDirection();
            },
          ),
        ],
      ),
    ];
  }
}

/// The page title in the iOS large-title style (as the shell draws it for
/// the other tabs), with the page's glass buttons on the trailing side.
class _TitleBar extends StatelessWidget {
  const _TitleBar({required this.title, this.actions});

  final String title;
  final Widget? actions;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 6, 16, 10),
      child: SizedBox(
        height: 48,
        child: Row(
          children: [
            Expanded(
              child: Text(
                title,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: CupertinoTheme.of(
                  context,
                ).textTheme.navLargeTitleTextStyle,
              ),
            ),
            if (actions != null) actions!,
          ],
        ),
      ),
    );
  }
}

/// The leaderboard categories as capsules scrolling sideways, the selected
/// one filled with its colour. The vehicles share one capsule opening a
/// Liquid Glass menu; it shows the chosen vehicle once one is picked.
class _CategoryCapsules extends StatelessWidget {
  const _CategoryCapsules();

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context)!;
    final provider = context.watch<RankingProvider>();
    final selected = provider.selection;
    final palette = MapColorPaletteHelper.getPalette(
      context.watch<SettingsProvider>().mapColorPalette,
    );
    final pills = buildRankingPills();
    final vehicles = pills.where((p) => p.isVehicle).toList();

    final children = <Widget>[];
    var vehiclesAdded = false;
    for (final pill in pills) {
      if (pill.isVehicle) {
        if (vehiclesAdded) continue;
        vehiclesAdded = true;
        children.add(
          GlassMenuCapsule(
            label: selected.isVehicle
                ? selected.label(context)
                : loc.rankingTypeVehicles,
            selected: selected.isVehicle,
            selectedColor: selected.isVehicle
                ? selected.accentColor(palette)
                : null,
            semanticLabel: loc.rankingTypeVehicles,
            sections: [
              AppMenuSection(
                entries: [
                  for (final v in vehicles)
                    AppMenuEntry(
                      label: v.label(context),
                      checked: v == selected,
                      trailing: Icon(
                        VehicleType.iconOf(v.vehicle!).icon,
                        size: 18,
                        color: v.accentColor(palette),
                      ),
                      onTap: () => provider.select(v),
                    ),
                ],
              ),
            ],
          ),
        );
        continue;
      }
      children.add(
        FilterCapsule(
          label: pill.label(context),
          selected: pill == selected,
          selectedColor: pill.accentColor(palette),
          onTap: () => provider.select(pill),
        ),
      );
    }

    return SizedBox(
      height: FilterCapsule.height,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        clipBehavior: Clip.none,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        itemCount: children.length,
        separatorBuilder: (_, _) => const SizedBox(width: 8),
        itemBuilder: (_, i) => Center(child: children[i]),
      ),
    );
  }
}
