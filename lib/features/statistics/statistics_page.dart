import 'dart:collection';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'package:trainlog_app/data/models/trips.dart';
import 'package:trainlog_app/l10n/app_localizations.dart';

import 'package:trainlog_app/providers/trainlog_provider.dart';
import 'package:trainlog_app/providers/trips_provider.dart';
import 'package:trainlog_app/providers/settings_provider.dart';
import 'package:trainlog_app/providers/statistics_provider.dart';

import 'package:trainlog_app/utils/map_color_palette.dart';
import 'package:trainlog_app/utils/number_formatter.dart';
import 'package:trainlog_app/utils/text_utils.dart';
import 'package:trainlog_app/widgets/app_steps_tab_bar.dart';

import 'package:trainlog_app/features/statistics/widgets/logo_bar_chart.dart';
import 'package:trainlog_app/features/statistics/widgets/stats_bar_chart.dart';
import 'package:trainlog_app/features/statistics/widgets/stats_pie_chart.dart';
import 'package:trainlog_app/features/statistics/widgets/stats_table_chart.dart';
import 'package:trainlog_app/platform/adaptive_widget.dart';
import 'package:trainlog_app/widgets/divider_with_widget.dart';

enum StatisticsView { bar, pie, table }

class StatisticsPage extends StatefulWidget {
  const StatisticsPage({super.key});

  @override
  State<StatisticsPage> createState() => _StatisticsPageState();
}

class _StatisticsPageState extends State<StatisticsPage> {
  StatisticsView _view = StatisticsView.bar;
  bool _sortedAlpha = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      final tripsProvider = Provider.of<TripsProvider>(context, listen: false);
      if (tripsProvider.repository == null) {
        await tripsProvider.loadNecessaryTripsData(hardRefresh: true);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context)!;

    return ChangeNotifierProvider(
      create: (ctx) => StatisticsProvider(ctx.read<TrainlogProvider>())..load(),
      builder: (context, _) {
        context.watch<TrainlogProvider>();
        final statsProv = context.watch<StatisticsProvider>();
        final settings = context.watch<SettingsProvider>();
        final tripsProv = context.watch<TripsProvider>();
        final palette = MapColorPaletteHelper.getPalette(settings.mapColorPalette);
        final barColor = palette[statsProv.vehicle] ?? Colors.blue;
        final disabledYears = statsProv.graph == GraphType.years;

        return SingleChildScrollView(
          padding: EdgeInsets.only(
            left: 16,
            right: 16,
            top: 12,
            bottom: MediaQuery.of(context).padding.bottom + 16,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ── Header ────────────────────────────────────────────────
              Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Text(
                    loc.statisticsTitle,
                    style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                          fontWeight: FontWeight.w700,
                        ),
                  ),
                  const Spacer(),
                  Flexible(
                    child: _YearChip(
                      years: [0, ...tripsProv.years],
                      selected: statsProv.year ?? 0,
                      enabled: !disabledYears,
                      allYearsLabel: loc.tripsFilterAllYears,
                      onChanged: (y) => statsProv.year = y,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 14),

              // ── Main card (selectors + chart) ─────────────────────────
              _StatsCard(
                view: _view,
                onViewChanged: (v) => setState(() => _view = v),
                statsProv: statsProv,
                tripsProv: tripsProv,
                barColor: barColor,
                sortedAlpha: _sortedAlpha,
                onSortToggle: () => setState(() => _sortedAlpha = !_sortedAlpha),
                chartBuilder: (ctx) => _buildChart(ctx, statsProv, loc, barColor),
              ),
            ],
          ),
        );
      },
    );
  }

  // ── Chart builder ──────────────────────────────────────────────────────────

  Widget _buildChart(
    BuildContext context,
    StatisticsProvider p,
    AppLocalizations loc,
    Color barColor,
  ) {
    final otherLabel = loc.statisticsOtherLabel;
    final statsShort = p.currentStatsShort(10, otherLabel: otherLabel);
    final unitMap = p.unitsByFactor(context);
    final baseUnit = p.baseUnitLabel(context);
    final labelBuilder = p.labelBuilder(context);
    final isDurationOrTrips =
        p.unit == GraphUnit.duration || p.unit == GraphUnit.trip;

    if (p.isLoading) {
      return const Padding(
      padding: EdgeInsets.symmetric(vertical: 40),
      child: Center(child: CircularProgressIndicator()),
    );
    }
    if (p.error != null) return Center(child: Text('Error: ${p.error}'));
    if (statsShort.isEmpty) return Center(child: Text(loc.statisticsNoDataLabel));

    switch (_view) {
      case StatisticsView.bar:
        // Order first, then build images from the SAME ordered keys so the
        // icons follow the bars when sorting mode changes.
        final orderedBar =
            _orderedStats(statsShort, alpha: _sortedAlpha, otherLabel: otherLabel);
        final images = p.graphImagesForKeys(
          context,
          orderedBar.keys.toList(),
          otherLabel: otherLabel,
          barColor: barColor,
        );
        return StatsBarChart(
          stats: orderedBar,
          images: images,
          baseUnit: baseUnit,
          unitsByFactor: unitMap,
          color: barColor,
          labelBuilder: labelBuilder,
          otherLabel: otherLabel,
          unitHelpTooltip: null,//isDurationOrTrips ? null : _tooltipRich(context, unitMap!),
        );

      case StatisticsView.pie:
        return StatsPieChart(
          stats: statsShort,
          interactive: false,
          seedColor: barColor,
          valueFormatter: (v) => formatNumber(context, v, noDecimal: false),
          showLegend: true,
          sectionsSpace: 2,
          centerSpaceRadius: 36,
          labelBuilder: labelBuilder,
        );

      case StatisticsView.table:
        final fullStats = p.currentStats;
        final tableStats = (p.graph == GraphType.country)
            ? _orderedStats(
                _localizedStatsForTable(context, fullStats),
                alpha: _sortedAlpha,
                otherLabel: otherLabel,
              )
            : _orderedStats(fullStats, alpha: _sortedAlpha, otherLabel: otherLabel);
        final isDuration = p.unit == GraphUnit.duration;

        Map<String, ({double past, double future})>? rawForTable;
        if (isDuration) {
          final rawSeconds = p.currentDurationRawSeconds();
          rawForTable = (p.graph == GraphType.country)
              ? _localizedRawSecondsForTable(context, rawSeconds)
              : LinkedHashMap.of(rawSeconds);
        }

        return Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Unit label above the table header
            if (!isDuration)
              Padding(
                padding: const EdgeInsets.only(bottom: 4),
                child: Text(
                  '${loc.statisticsUnitLabel} $baseUnit',
                  style: Theme.of(context).textTheme.labelSmall?.copyWith(
                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                        letterSpacing: 0.5,
                      ),
                ),
              ),
            StatsTableChart(
              stats: tableStats,
              isDuration: isDuration,
              rawValues: rawForTable,
              rawValueFormatter: p.humanizeSeconds,
              valueFormatter: (v) => formatNumber(context, v),
              labelHeader: p.graph.label(context, p.vehicle),
              pastHeader: loc.yearPastList,
              futureHeader: loc.yearFutureList,
              totalHeader: loc.statisticsTotalLabel,
              labelMaxWidth: 200,
              compact: true,
              onlyTotal: switch (p.year) {
                null => false,
                final y when y == 0 => false,
                final y when y == DateTime.now().year => false,
                _ => true,
              },
            ),
          ],
        );
    }
  }

  // ── Helpers ────────────────────────────────────────────────────────────────

  LinkedHashMap<String, ({double past, double future})> _orderedStats(
    Map<String, ({double past, double future})> stats, {
    required bool alpha,
    required String otherLabel,
  }) {
    final entries = stats.entries.toList();
    final other = entries.where((e) => e.key == otherLabel).toList();
    final rest = entries.where((e) => e.key != otherLabel).toList();

    if (alpha) {
      rest.sort((a, b) => a.key.toLowerCase().compareTo(b.key.toLowerCase()));
    } else {
      rest.sort((a, b) {
        final ta = a.value.past + a.value.future;
        final tb = b.value.past + b.value.future;
        final cmp = tb.compareTo(ta);
        return cmp != 0 ? cmp : a.key.toLowerCase().compareTo(b.key.toLowerCase());
      });
    }
    return LinkedHashMap.fromEntries([...rest, ...other]);
  }

  LinkedHashMap<String, ({double past, double future})> _localizedStatsForTable(
    BuildContext context,
    Map<String, ({double past, double future})> stats,
  ) {
    final out = LinkedHashMap<String, ({double past, double future})>();
    for (final e in stats.entries) {
      final name = countryCodeToName(e.key, context);
      final cur = out[name];
      out[name] = (
        past: (cur?.past ?? 0) + e.value.past,
        future: (cur?.future ?? 0) + e.value.future,
      );
    }
    return out;
  }

  LinkedHashMap<String, ({double past, double future})> _localizedRawSecondsForTable(
    BuildContext context,
    Map<String, ({double past, double future})> rawSecondsByCode,
  ) {
    final out = LinkedHashMap<String, ({double past, double future})>();
    for (final e in rawSecondsByCode.entries) {
      final name = countryCodeToName(e.key, context);
      final cur = out[name];
      out[name] = (
        past: (cur?.past ?? 0) + e.value.past,
        future: (cur?.future ?? 0) + e.value.future,
      );
    }
    return out;
  }
}

// ═══════════════════════════════════════════════════════════════════════════
// Main card — selectors + chart all inside one bordered container
// ═══════════════════════════════════════════════════════════════════════════

class _StatsCard extends StatelessWidget {
  final StatisticsView view;
  final ValueChanged<StatisticsView> onViewChanged;
  final StatisticsProvider statsProv;
  final TripsProvider tripsProv;
  final Color barColor;
  final bool sortedAlpha;
  final VoidCallback onSortToggle;
  final Widget Function(BuildContext) chartBuilder;

  const _StatsCard({
    required this.view,
    required this.onViewChanged,
    required this.statsProv,
    required this.tripsProv,
    required this.barColor,
    required this.sortedAlpha,
    required this.onSortToggle,
    required this.chartBuilder,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final loc = AppLocalizations.of(context)!;
    final isDurationOrTrips =
        statsProv.unit == GraphUnit.duration || statsProv.unit == GraphUnit.trip;

    return Container(
      decoration: BoxDecoration(
        color: isDark ? cs.surface : Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: isDark
              ? cs.outline.withValues(alpha: 0.25)
              : cs.outline.withValues(alpha: 0.18),
          width: 1.2,
        ),
        boxShadow: [
          BoxShadow(
            color: cs.shadow.withValues(alpha: isDark ? 0.25 : 0.06),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Row 1: dimension title + graph-type tab bar
          Padding(
            padding: const EdgeInsets.fromLTRB(14, 14, 10, 0),
            child: Row(
              children: [
                _DimensionButton(
                  graph: statsProv.graph,
                  vehicle: statsProv.vehicle,
                  onChanged: (g) => statsProv.graph = g,
                ),
                const Spacer(),
                // AppStepsTabBar — icon-only tabs, not full width
                Builder(builder: (context) {                  
                  return AppStepsTabBar(
                    fullWidth: false,
                    selectedIndex: view.index,
                    onTabChanged: (i) => onViewChanged(StatisticsView.values[i]),
                    tabs: [
                      AppStepsTab(
                        label: loc.statisticsViewBar,
                        iconOnly: true,
                        leadingIcon: const Icon(Icons.bar_chart),
                      ),
                      AppStepsTab(
                        label: loc.statisticsViewPie,
                        iconOnly: true,
                        leadingIcon: const Icon(Icons.pie_chart),
                      ),
                      AppStepsTab(
                        label: loc.statisticsViewTable,
                        iconOnly: true,
                        leadingIcon: const Icon(Icons.table_chart),
                      ),
                    ],
                  );
                }),
              ],
            ),
          ),
          // Row 2: compact outlined dropdowns + sort button
          Padding(
            padding: const EdgeInsets.fromLTRB(10, 10, 10, 0),
            child: Row(
              children: [
                // Vehicle type
                Expanded(
                  child: _OutlinedDropdown<VehicleType>(
                    items: tripsProv.vehicleTypesWithoutPoi,
                    selected: statsProv.vehicle,
                    iconOf: (v) => VehicleType.iconOf(v),
                    labelOf: (v) => VehicleType.labelOf(v, context),
                    onChanged: (v) => statsProv.vehicle = v ?? statsProv.vehicle,
                  ),
                ),
                const SizedBox(width: 6),
                // Unit
                Expanded(
                  child: _OutlinedDropdown<GraphUnit>(
                    items: GraphUnit.values,
                    selected: statsProv.unit,
                    iconOf: (u) => u.icon(),
                    labelOf: (u) => u.label(context),
                    onChanged: (u) => statsProv.unit = u ?? statsProv.unit,
                  ),
                ),
                // Sort toggle — hidden for Pie view
                if (view != StatisticsView.pie) ...[
                  const SizedBox(width: 10),
                  _SortButton(alpha: sortedAlpha, onTap: onSortToggle),
                ],
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(10, 20, 10, 10), // "${loc.statisticsTotalLabel} ${statsProv.totalFormatted(context)}"
            child: DividerWithWidget(
              child: Row(
                children: [
                  Text('${loc.statisticsTotalLabel} ${statsProv.totalFormatted(context)}',
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            color: Theme.of(context).colorScheme.onSurfaceVariant,
                          ),
                    ),
                  if (!isDurationOrTrips) ...[
                    const SizedBox(width: 6),
                    _tooltipWidget(context, statsProv.unitsByFactor(context)!),
                  ],
                ],
              ),
            ),
          ),
          // Chart content
          Padding(
            padding: const EdgeInsets.all(12),
            child: chartBuilder(context),
          ),
        ],
      ),
    );
  }

  InlineSpan _tooltipRich(BuildContext context, Map<UnitFactor, String> units) {
    final base = Theme.of(context).textTheme.bodyMedium!;
    final baseUnit = units[UnitFactor.base]!;
    return WidgetSpan(
      child: DefaultTextStyle(
        style: base.copyWith(
          color: Theme.of(context).colorScheme.onPrimaryContainer,
        ),
        child: IntrinsicWidth(
          child: Table(
            defaultColumnWidth: const IntrinsicColumnWidth(),
            children: [
              for (final f in UnitFactor.values.where((f) => f != UnitFactor.base))
                TableRow(children: [
                  Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: Text(units[f]!),
                  ),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 8),
                    child: Align(
                      alignment: Alignment.centerRight,
                      child: Text(formatNumber(context, f.multiplier, noDecimal: true)),
                    ),
                  ),
                  Text(baseUnit),
                ]),
            ],
          ),
        ),
      ),
    );
  }

  Tooltip _tooltipWidget(BuildContext context, Map<UnitFactor, String> units) {
    final cs = Theme.of(context).colorScheme;
    return Tooltip(
      triggerMode: TooltipTriggerMode.tap,
      richMessage: TextSpan(children: [_tooltipRich(context, units)]),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.primaryContainer,
      ),
      waitDuration: Duration.zero,
      showDuration: const Duration(seconds: 4),
      child: Icon(Icons.help, size: 18, color: cs.primary,),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════
// Dimension title button (large, acts as dropdown opener)
// ═══════════════════════════════════════════════════════════════════════════

class _DimensionButton extends StatelessWidget {
  final GraphType graph;
  final VehicleType vehicle;
  final ValueChanged<GraphType> onChanged;

  const _DimensionButton({
    required this.graph,
    required this.vehicle,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return AdaptivePopup<GraphType>(
      onSelected: onChanged,
      initialValue: graph,
      items: GraphType.values
          .map((g) => AdaptivePopupItem(
                value: g,
                label: g.label(context, vehicle),
                leading: g.icon(),
              ))
          .toList(),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          graph.icon(),
          const SizedBox(width: 8),
          Text(
            graph.label(context, vehicle),
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w700,
                ),
          ),
          const SizedBox(width: 4),
          Icon(
            Icons.keyboard_arrow_down,
            size: 18,
            color: Theme.of(context).colorScheme.onSurfaceVariant,
          ),
        ],
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════
// Outlined compact dropdown pill
// ═══════════════════════════════════════════════════════════════════════════

class _OutlinedDropdown<T> extends StatelessWidget {
  final List<T> items;
  final T selected;
  final Icon? Function(T) iconOf;
  final String Function(T) labelOf;
  final ValueChanged<T?> onChanged;

  const _OutlinedDropdown({
    required this.items,
    required this.selected,
    required this.iconOf,
    required this.labelOf,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final icon = iconOf(selected);

    return AdaptivePopup<T>(
      onSelected: onChanged,
      initialValue: selected,
      items: items
          .map((item) => AdaptivePopupItem(
                value: item,
                label: labelOf(item),
                leading: iconOf(item) != null
                    ? IconTheme(
                        data: IconThemeData(size: 18, color: cs.primary),
                        child: iconOf(item)!,
                      )
                    : null,
              ))
          .toList(),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
        decoration: BoxDecoration(
          color: Colors.transparent,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: cs.outline.withValues(alpha: 0.4),
            width: 1.2,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (icon != null) ...[
              IconTheme(
                data: IconThemeData(size: 18, color: cs.primary),
                child: icon,
              ),
              const SizedBox(width: 5),
            ],
            Flexible(
              child: Text(
                labelOf(selected),
                style: Theme.of(context).textTheme.labelLarge?.copyWith(
                      color: cs.onSurface,
                      fontWeight: FontWeight.w500,
                    ),
                overflow: TextOverflow.ellipsis,
                maxLines: 1,
              ),
            ),
            const SizedBox(width: 3),
            Icon(Icons.keyboard_arrow_down, size: 18, color: cs.onSurfaceVariant),
          ],
        ),
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════
// Sort toggle button — icon changes with state
// ═══════════════════════════════════════════════════════════════════════════

class _SortButton extends StatelessWidget {
  final bool alpha;
  final VoidCallback onTap;

  const _SortButton({required this.alpha, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Tooltip(
      message: alpha ? 'Sort by total' : 'Sort alphabetically',
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: Colors.transparent,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(
              color: cs.outline.withValues(alpha: 0.4),
              width: 1.2,
            ),
          ),
          child: Icon(
            alpha ? Icons.filter_list : Icons.sort_by_alpha,
            size: 18,
            color: cs.primary,
          ),
        ),
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════
// Year chip (header)
// ═══════════════════════════════════════════════════════════════════════════

class _YearChip extends StatelessWidget {
  final List<int> years;
  final int selected;
  final bool enabled;
  final String allYearsLabel;
  final ValueChanged<int> onChanged;

  const _YearChip({
    required this.years,
    required this.selected,
    required this.enabled,
    required this.allYearsLabel,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final label = selected == 0 ? allYearsLabel : selected.toString();

    return AdaptivePopup<int>(
      enabled: enabled,
      initialValue: selected,
      onSelected: onChanged,
      items: years
          .map((y) => AdaptivePopupItem(
                value: y,
                label: y == 0 ? allYearsLabel : y.toString(),
              ))
          .toList(),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: cs.surfaceContainerHighest,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: cs.outline.withValues(alpha: 0.3)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.calendar_today_outlined, size: 14, color: cs.onSurfaceVariant),
            const SizedBox(width: 6),
            Flexible(
              child: Text(
                label,
                overflow: TextOverflow.ellipsis,
                style: Theme.of(context)
                    .textTheme
                    .labelLarge
                    ?.copyWith(fontWeight: FontWeight.w600),
              ),
            ),
            const SizedBox(width: 4),
            Icon(Icons.keyboard_arrow_down, size: 16, color: cs.onSurfaceVariant),
          ],
        ),
      ),
    );
  }
}
