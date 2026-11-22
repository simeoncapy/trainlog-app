import 'dart:math' as math;

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:trainlog_app/core/data/models/polyline_filter_state.dart';
import 'package:trainlog_app/core/providers/polyline_provider.dart';
import 'package:trainlog_app/features/map/filter/map_filter_time_range.dart';
import 'package:trainlog_app/l10n/app_localizations.dart';
import 'package:trainlog_app/ui/adaptive/adaptive_vehicle_type_filter_chips.dart';
import 'package:trainlog_app/ui/cupertino/glass_filter_parts.dart';
import 'package:trainlog_app/utils/date_utils.dart';

/// Map filter, iOS 26 view: glass ✕ / title / ↺ bar, glass segmented
/// control, an aligned 4 × 3 grid of year capsules swiped by page (dots
/// below), vehicle capsules, and the solid amber "Show N trips" button with
/// its icon. The Liquid Glass sheet brings its own background and handle.
///
/// The filter state lives in [PolylineProvider]; this view only keeps the
/// current page of the year grid.
class MapFilterCupertinoView extends StatefulWidget {
  const MapFilterCupertinoView({super.key, required this.onClose});

  final VoidCallback onClose;

  @override
  State<MapFilterCupertinoView> createState() => _MapFilterCupertinoViewState();
}

class _MapFilterCupertinoViewState extends State<MapFilterCupertinoView> {
  /// 4 columns × 3 rows.
  static const int _yearsPerPage = 12;

  /// Current page of the paginated year grid.
  int _yearPage = 0;

  /// The year pages are swiped (PageView) instead of using arrows.
  final PageController _yearPager = PageController();

  @override
  void dispose() {
    _yearPager.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => _buildApple(context);

  Widget _buildApple(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final poly = context.watch<PolylineProvider>();
    final mediaQuery = MediaQuery.of(context);
    final maxHeight = (mediaQuery.size.height - mediaQuery.padding.top) * 0.9;

    final types = poly.availableTypesWithoutPoi;
    final allTypesSelected =
        types.isNotEmpty && types.every(poly.selectedTypes.contains);

    return ConstrainedBox(
      constraints: BoxConstraints(maxHeight: maxHeight),
      child: SafeArea(
        top: false,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // No top spacer: the sheet already leaves room for its grab
            // handle, so the header sits at the same height as on the trips
            // filter sheet.
            GlassSheetHeader(
              title: l10n.mapFilterTitle,
              closeTooltip: MaterialLocalizations.of(
                context,
              ).closeButtonTooltip,
              resetTooltip: l10n.mapFilterReset,
              onClose: widget.onClose,
              onReset: () {
                context.read<PolylineProvider>().resetFilters();
                setState(() => _yearPage = 0);
              },
            ),
            Flexible(
              fit: FlexFit.loose,
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(16, 4, 16, 8),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    MapFilterTimeRange(
                      onYearsChosen: () => setState(() => _yearPage = 0),
                    ),
                    if (poly.yearFilterChoice == PolylineYearFilter.years) ...[
                      const SizedBox(height: 14),
                      _appleYearSection(context, l10n, poly),
                    ],
                    const SizedBox(height: 14),
                    GlassFilterSectionHeader(
                      title: l10n.typeTitle,
                      actionLabel: allTypesSelected
                          ? l10n.filterDeselectAll
                          : l10n.filterSelectAll,
                      onAction: () {
                        final p = context.read<PolylineProvider>();
                        allTypesSelected
                            ? p.unselectAllVehicleTypes(types)
                            : p.selectAllVehicleTypes(types);
                      },
                    ),
                    const SizedBox(height: 6),
                    AdaptiveVehicleTypeFilterChips(
                      availableTypes: types,
                      selectedTypes: poly.selectedTypes,
                      onTypeToggle: (type, selected) {
                        context.read<PolylineProvider>().toggleType(
                          type,
                          selected,
                        );
                      },
                    ),
                  ],
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 10, 16, 14),
              child: GlassPrimaryButton(
                icon: CupertinoIcons.map,
                label: l10n.mapFilterShowTrips(poly.visibleTripCount),
                onPressed: widget.onClose,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _appleYearSection(
    BuildContext context,
    AppLocalizations l10n,
    PolylineProvider poly,
  ) {
    final years = poly.availableYears; // sorted descending
    final items = poly.yearChoices;
    final allSelected =
        items.isNotEmpty && items.every(poly.selectedYears.contains);

    final pageCount = math.max(1, (items.length / _yearsPerPage).ceil());
    final page = _yearPage.clamp(0, pageCount - 1);

    List<int> pageItems(int p) => items.sublist(
      p * _yearsPerPage,
      math.min((p + 1) * _yearsPerPage, items.length),
    );

    const rowGap = 8.0;
    const fullHeight = 3 * FilterCapsule.height + 2 * rowGap;

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        GlassFilterSectionHeader(
          title: l10n.mapFilterSelectYears,
          actionLabel: allSelected
              ? l10n.filterDeselectAll
              : l10n.filterSelectAll,
          onAction: () {
            final p = context.read<PolylineProvider>();
            allSelected ? p.unselectAllYears() : p.selectAllYears(years);
          },
        ),
        const SizedBox(height: 6),
        if (pageCount == 1)
          _appleYearGrid(context, l10n, poly, items, rowGap: rowGap)
        else ...[
          SizedBox(
            height: fullHeight,
            child: PageView.builder(
              controller: _yearPager,
              itemCount: pageCount,
              onPageChanged: (p) => setState(() => _yearPage = p),
              itemBuilder: (context, p) => Align(
                alignment: Alignment.topCenter,
                child: _appleYearGrid(
                  context,
                  l10n,
                  poly,
                  pageItems(p),
                  rowGap: rowGap,
                ),
              ),
            ),
          ),
          FilterPageDots(
            count: pageCount,
            current: page,
            onSelect: (p) => _yearPager.animateToPage(
              p,
              duration: const Duration(milliseconds: 300),
              curve: Curves.easeOutCubic,
            ),
          ),
        ],
      ],
    );
  }

  Widget _appleYearGrid(
    BuildContext context,
    AppLocalizations l10n,
    PolylineProvider poly,
    List<int> items, {
    required double rowGap,
  }) {
    final currentYear = DateTime.now().year;
    final rows = <Widget>[];
    for (int start = 0; start < items.length; start += 4) {
      if (rows.isNotEmpty) rows.add(SizedBox(height: rowGap));
      rows.add(
        Row(
          children: [
            for (int col = 0; col < 4; col++) ...[
              if (col > 0) const SizedBox(width: 8),
              Expanded(
                child: start + col < items.length
                    ? _appleYearCapsule(
                        context,
                        l10n,
                        poly,
                        items[start + col],
                        currentYear,
                      )
                    : const SizedBox(height: FilterCapsule.height),
              ),
            ],
          ],
        ),
      );
    }
    return Column(mainAxisSize: MainAxisSize.min, children: rows);
  }

  Widget _appleYearCapsule(
    BuildContext context,
    AppLocalizations l10n,
    PolylineProvider poly,
    int year,
    int currentYear,
  ) {
    final isUnknownFuture = year == unknownFuture.year;
    final isUnknownPast = year == unknownPast.year;
    final isUnknown = isUnknownFuture || isUnknownPast;
    final isFuture = isUnknownFuture || (!isUnknown && year > currentYear);
    return FilterCapsule(
      expand: true,
      label: isUnknownFuture
          ? l10n.mapFilterUnknownFuture
          : isUnknownPast
          ? l10n.mapFilterUnknownPast
          : year.toString(),
      // Future years: a thin solid outline and a small clock (no dashes).
      outlined: isFuture,
      leading: isFuture ? CupertinoIcons.clock : null,
      selected: poly.selectedYears.contains(year),
      onTap: () => context.read<PolylineProvider>().toggleYear(year),
    );
  }
}
