import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart' show Icons, Theme;
import 'package:provider/provider.dart';

import 'package:trainlog_app/core/data/models/ranking_model.dart';
import 'package:trainlog_app/core/providers/railway_coverage_provider.dart';
import 'package:trainlog_app/core/providers/trainlog_provider.dart';
import 'package:trainlog_app/core/services/flag_cache.dart';
import 'package:trainlog_app/features/ranking/cupertino/ranking_header_cupertino.dart';
import 'package:trainlog_app/features/ranking/cupertino/ranking_list_cupertino.dart';
import 'package:trainlog_app/features/ranking/rail_area_ranking_page.dart';
import 'package:trainlog_app/features/ranking/widgets/coverage_flags_loader.dart';
import 'package:trainlog_app/features/ranking/widgets/coverage_progress_ring.dart';
import 'package:trainlog_app/features/ranking/widgets/flag_image.dart';
import 'package:trainlog_app/l10n/app_localizations.dart';
import 'package:trainlog_app/ui/adaptive/adaptive_page_route.dart';
import 'package:trainlog_app/ui/adaptive/adaptive_segmented_button.dart';
import 'package:trainlog_app/ui/adaptive/bottom_sheet_picker.dart';
import 'package:trainlog_app/ui/cupertino/glass_filter_parts.dart';
import 'package:trainlog_app/ui/cupertino/glass_menu_parts.dart';
import 'package:trainlog_app/ui/tokens/app_colors.dart';
import 'package:trainlog_app/utils/text_utils.dart';

/// Railway coverage on iOS, in the ranking page: the same title, sort menu
/// and category capsules as the other leaderboards, then Countries | Regions
/// as a segmented control, the country of the regions as a form row opening
/// the picker, and the areas in an inset grouped list (flag, name, leaders,
/// coverage ring). A row opens the area's own leaderboard.
class RailwayCoverageCupertino extends StatelessWidget {
  const RailwayCoverageCupertino({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (ctx) => RailwayCoverageProvider(
        ctx.read<TrainlogProvider>(),
        flagCache: ctx.read<FlagCache>(),
      )..load(),
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
    final bottomInset = MediaQuery.of(context).padding.bottom;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        RankingTitleBar(
          title: loc.menuRankingTitle,
          // Nothing to sort on Regions until a country is picked.
          actions: provider.sortingEnabled
              ? GlassMenuIconButton(
                  icon: CupertinoIcons.arrow_up_arrow_down,
                  semanticLabel: loc.rankingSortMenu,
                  sections: rankingSortSections(
                    loc,
                    alphabetical: provider.alphabetical,
                    descending: provider.descending,
                    toggleAlphabetical: provider.toggleAlphabetical,
                    toggleDirection: provider.toggleDirection,
                  ),
                )
              : null,
        ),
        const RankingCategoryCapsules(),
        const SizedBox(height: 14),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: AdaptiveSegmentedButton.build<RailCoverageTab>(
            context: context,
            segments: [
              AdaptiveSegmentedButtonSegment(
                value: RailCoverageTab.countries,
                label: Text(loc.railCoverageCountriesTab),
              ),
              AdaptiveSegmentedButtonSegment(
                value: RailCoverageTab.regions,
                label: Text(loc.railCoverageRegionsTab),
              ),
            ],
            selectedValue: provider.tab,
            onChanged: provider.setTab,
          ),
        ),
        if (isRegions)
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
            child: _RegionCountryRow(provider: provider),
          ),
        const SizedBox(height: 12),
        Expanded(child: _list(context, provider, loc, bottomInset)),
      ],
    );
  }

  Widget _list(
    BuildContext context,
    RailwayCoverageProvider provider,
    AppLocalizations loc,
    double bottomInset,
  ) {
    final secondary = CupertinoColors.secondaryLabel.resolveFrom(context);
    Widget message(Widget child) => Padding(
      padding: EdgeInsets.only(bottom: bottomInset),
      child: Center(child: child),
    );

    if (provider.isLoading) {
      return message(const CupertinoActivityIndicator());
    }
    if (provider.error != null) {
      return message(
        Text('Error: ${provider.error}', style: TextStyle(color: secondary)),
      );
    }
    if (provider.tab == RailCoverageTab.regions) {
      if (provider.selectedCountry == null) {
        return message(
          Text(
            loc.railCoverageSelectRegion,
            style: TextStyle(color: secondary),
          ),
        );
      }
      return _CoverageListCupertino(
        entries: provider.regions(),
        nameOf: (e) => e.subdivision.name,
        flagOf: (e) => e.code,
        bottomInset: bottomInset,
      );
    }
    return _CoverageListCupertino(
      entries: provider.countries(context),
      nameOf: (e) => e.country(context).name,
      flagOf: (e) => e.countryCode,
      bottomInset: bottomInset,
    );
  }
}

/// The country whose regions are listed, as an iOS form row opening the
/// country picker.
class _RegionCountryRow extends StatelessWidget {
  const _RegionCountryRow({required this.provider});

  final RailwayCoverageProvider provider;

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context)!;
    final options = provider.regionCountryOptions(context);
    RailCountryOption? selected;
    for (final o in options) {
      if (o.code == provider.selectedCountry) selected = o;
    }

    return GlassFormGroup(
      children: [
        GlassFormRow(
          title: selected == null
              ? loc.railCoverageSelectRegion
              : '${countryCodeToEmoji(selected.code)}  ${selected.name}',
          trailing: GlassDisclosure(
            value: selected == null
                ? null
                : loc.railCoverageRegionCount(selected.count),
          ),
          onTap: options.isEmpty
              ? null
              : () => showBottomSheetPicker<String>(
                  context: context,
                  title: loc.railCoverageSelectRegion,
                  selected: provider.selectedCountry ?? '',
                  onChanged: provider.selectCountry,
                  options: [
                    for (final o in options)
                      BottomSheetPickerOption<String>(
                        value: o.code,
                        label: o.name,
                        subtitle: loc.railCoverageRegionCount(o.count),
                        leading: Text(
                          countryCodeToEmoji(o.code),
                          style: TextStyle(
                            fontSize: Theme.of(
                              context,
                            ).textTheme.headlineSmall?.fontSize,
                          ),
                        ),
                      ),
                  ],
                ),
        ),
      ],
    );
  }
}

/// The countries or regions as an inset grouped list, pull to refresh.
class _CoverageListCupertino extends StatefulWidget {
  const _CoverageListCupertino({
    required this.entries,
    required this.nameOf,
    required this.flagOf,
    required this.bottomInset,
  });

  final List<RailPercentageEntry> entries;
  final String Function(RailPercentageEntry entry) nameOf;
  final String Function(RailPercentageEntry entry) flagOf;
  final double bottomInset;

  @override
  State<_CoverageListCupertino> createState() => _CoverageListCupertinoState();
}

class _CoverageListCupertinoState extends State<_CoverageListCupertino>
    with CoverageFlagsLoader<_CoverageListCupertino> {
  @override
  List<RailPercentageEntry> get coverageEntries => widget.entries;

  @override
  String coverageFlagOf(RailPercentageEntry entry) => widget.flagOf(entry);

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context)!;
    final provider = context.read<RailwayCoverageProvider>();
    final flagWidth = flagColumnWidth(context.read<FlagCache>());
    final entries = widget.entries;

    return CustomScrollView(
      physics: const AlwaysScrollableScrollPhysics(
        parent: BouncingScrollPhysics(),
      ),
      slivers: [
        CupertinoSliverRefreshControl(onRefresh: provider.load),
        if (entries.isEmpty)
          SliverFillRemaining(
            hasScrollBody: false,
            child: Center(
              child: Text(
                loc.noData,
                style: TextStyle(
                  color: CupertinoColors.secondaryLabel.resolveFrom(context),
                ),
              ),
            ),
          )
        else
          SliverPadding(
            padding: EdgeInsets.fromLTRB(16, 0, 16, widget.bottomInset + 12),
            sliver: SliverList.builder(
              itemCount: entries.length,
              itemBuilder: (context, i) {
                final e = entries[i];
                final name = widget.nameOf(e);
                return RankingGroupedRow(
                  isFirst: i == 0,
                  isLast: i == entries.length - 1,
                  dividerIndent: 16 + flagWidth + 14,
                  onTap: () => AdaptivePageRoute.push(
                    context,
                    (_) => RailAreaRankingPage(
                      entry: e,
                      displayName: name,
                      flagCode: widget.flagOf(e),
                      currentUsername: provider.currentUsername,
                    ),
                  ),
                  child: _CoverageRowCupertino(
                    flagCode: widget.flagOf(e),
                    flagWidth: flagWidth,
                    title: name,
                    leaders: e.leaders.map((u) => u.username).toList(),
                    currentUsername: provider.currentUsername,
                    percent: e.highestPercent,
                  ),
                );
              },
            ),
          ),
      ],
    );
  }
}

/// Flag, name, the leaders (the user first, as "You"), the coverage ring and
/// a chevron.
class _CoverageRowCupertino extends StatelessWidget {
  const _CoverageRowCupertino({
    required this.flagCode,
    required this.flagWidth,
    required this.title,
    required this.leaders,
    required this.currentUsername,
    required this.percent,
  });

  final String flagCode;
  final double flagWidth;
  final String title;
  final List<String> leaders;
  final String? currentUsername;
  final double percent;

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context)!;
    final text = Theme.of(context).textTheme;
    final label = CupertinoColors.label.resolveFrom(context);
    final secondary = CupertinoColors.secondaryLabel.resolveFrom(context);
    final isDark = CupertinoTheme.brightnessOf(context) == Brightness.dark;
    final amber = isDark ? AppColors.amber : AppColors.amberDk;

    final me = currentUsername?.toLowerCase();
    final iAmLeader = me != null && leaders.any((l) => l.toLowerCase() == me);
    final others = iAmLeader
        ? leaders.where((l) => l.toLowerCase() != me).toList()
        : leaders;

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 14, 12),
      child: Row(
        children: [
          SizedBox(
            width: flagWidth,
            child: Center(
              child: FlagImage(
                code: flagCode,
                size: CoverageFlagsLoader.flagSize,
              ),
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: text.titleMedium?.copyWith(
                    fontWeight: FontWeight.w700,
                    letterSpacing: 0,
                    color: label,
                  ),
                ),
                if (leaders.isNotEmpty) ...[
                  const SizedBox(height: 3),
                  Row(
                    children: [
                      Icon(Icons.emoji_events, size: 13, color: amber),
                      const SizedBox(width: 4),
                      if (iAmLeader)
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 6,
                            vertical: 1,
                          ),
                          decoration: ShapeDecoration(
                            color: AppColors.amber,
                            shape: RoundedSuperellipseBorder(
                              borderRadius: BorderRadius.circular(6),
                            ),
                          ),
                          child: Text(
                            loc.railCoverageYou,
                            style: text.bodySmall?.copyWith(
                              color: AppColors.navy,
                              fontWeight: FontWeight.w700,
                              letterSpacing: 0,
                            ),
                          ),
                        ),
                      if (others.isNotEmpty)
                        Expanded(
                          child: Text(
                            iAmLeader
                                ? ', ${others.join(', ')}'
                                : others.join(', '),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: text.bodySmall?.copyWith(
                              color: secondary,
                              letterSpacing: 0,
                            ),
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
          Icon(
            CupertinoIcons.chevron_forward,
            size: 16,
            color: CupertinoColors.tertiaryLabel.resolveFrom(context),
          ),
        ],
      ),
    );
  }
}
