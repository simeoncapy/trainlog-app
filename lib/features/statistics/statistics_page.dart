import 'dart:collection';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'package:trainlog_app/data/models/trips.dart';
import 'package:trainlog_app/l10n/app_localizations.dart';
import 'package:trainlog_app/platform/adaptive_dropdown.dart';

import 'package:trainlog_app/providers/trainlog_provider.dart';
import 'package:trainlog_app/providers/trips_provider.dart';
import 'package:trainlog_app/providers/settings_provider.dart';
import 'package:trainlog_app/providers/statistics_provider.dart';

import 'package:trainlog_app/utils/map_color_palette.dart';
import 'package:trainlog_app/utils/number_formatter.dart';
import 'package:trainlog_app/utils/text_utils.dart';
import 'package:trainlog_app/widgets/app_steps_tab_bar.dart';
import 'package:trainlog_app/widgets/min_height_scrollable.dart';

import 'package:trainlog_app/features/statistics/widgets/logo_bar_chart.dart';
import 'package:trainlog_app/features/statistics/widgets/stats_bar_chart.dart';
import 'package:trainlog_app/features/statistics/widgets/stats_pie_chart.dart';
import 'package:trainlog_app/features/statistics/widgets/stats_table_chart.dart';

enum StatisticsView { bar, pie, table }

class StatisticsPage extends StatefulWidget {
  const StatisticsPage({super.key});

  @override
  State<StatisticsPage> createState() => _StatisticsPageState();
}

class _StatisticsPageState extends State<StatisticsPage> {
  StatisticsView _view = StatisticsView.bar;
  bool _sortedAlpha = false;
  late List<int> _listYears;

  @override
  void initState() {
    super.initState();
    _listYears = [DateTime.now().year];

    WidgetsBinding.instance.addPostFrameCallback((_) async {
      final tripsProvider = Provider.of<TripsProvider>(context, listen: false);
      if (tripsProvider.repository == null) {
        await tripsProvider.loadNecessaryTripsData(hardRefresh: true);
      }
      final years = await tripsProvider.repository?.fetchListOfYears()
        ?..sort((a, b) => b.compareTo(a));
      if (!mounted) return;
      setState(() => _listYears = years ?? [DateTime.now().year]);
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
        final hasData = statsProv.currentStats.isNotEmpty && !statsProv.isLoading;
        final disabledYears = statsProv.graph == GraphType.years;

        return Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ── Header: title + year picker ────────────────────────────
              _buildHeader(context, statsProv, loc, tripsProv, disabledYears),
              const SizedBox(height: 16),

              // ── Graph-type tab bar (Bar / Pie / Table) ─────────────────
              AppStepsTabBar(
                fullWidth: true,
                selectedIndex: _view.index,
                onTabChanged: (i) => setState(() => _view = StatisticsView.values[i]),
                tabs: [
                  AppStepsTab(label: loc.statisticsViewBar,   leadingIcon: const Icon(Icons.bar_chart)),
                  AppStepsTab(label: loc.statisticsViewPie,   leadingIcon: const Icon(Icons.pie_chart)),
                  AppStepsTab(label: loc.statisticsViewTable, leadingIcon: const Icon(Icons.table_chart)),
                ],
              ),
              const SizedBox(height: 16),

              // ── Dimension dropdown + filter row ────────────────────────
              _buildDimensionRow(context, statsProv, loc),
              const SizedBox(height: 8),
              _buildFilterRow(context, statsProv, loc, tripsProv),
              const SizedBox(height: 16),

              // ── Chart area ─────────────────────────────────────────────
              Expanded(
                child: MinHeightScrollable(
                  minHeight: 350,
                  padding: EdgeInsets.only(bottom: MediaQuery.of(context).padding.bottom),
                  child: Builder(builder: (_) {
                    if (statsProv.isLoading) {
                      return const Center(child: CircularProgressIndicator());
                    }
                    if (statsProv.error != null) {
                      return Center(child: Text('Error: ${statsProv.error}'));
                    }
                    if (!hasData) {
                      return Center(child: Text(loc.statisticsNoDataLabel));
                    }
                    return _buildChart(context, statsProv, loc, barColor);
                  }),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  // ── Header: "Statistics" title  +  year dropdown ──────────────────────────

  Widget _buildHeader(
    BuildContext context,
    StatisticsProvider p,
    AppLocalizations loc,
    TripsProvider tripsProv,
    bool disabledYears,
  ) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Text(
          loc.statisticsTitle,
          style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                fontWeight: FontWeight.w700,
              ),
        ),
        const Spacer(),
        // Year selector chip
        _YearDropdown(
          years: [0, ...tripsProv.years],
          selected: p.year ?? 0,
          enabled: !disabledYears,
          allYearsLabel: loc.tripsFilterAllYears,
          onChanged: (y) => p.year = y,
        ),
      ],
    );
  }

  // ── Dimension dropdown (By operator / country / year …) ───────────────────

  Widget _buildDimensionRow(
    BuildContext context,
    StatisticsProvider p,
    AppLocalizations loc,
  ) {
    return AdaptiveDropdown<GraphType>(
      items: GraphType.values,
      selectedValue: p.graph,
      onChanged: (g) => p.graph = g ?? GraphType.operator,
      labelOf: (t) => t.label(context, p.vehicle),
      iconOf: (t) => t.icon(),
      hintText: loc.statisticsSelectDimension,
    );
  }

  // ── Filter row: vehicle  |  unit  |  sort toggle ──────────────────────────

  Widget _buildFilterRow(
    BuildContext context,
    StatisticsProvider p,
    AppLocalizations loc,
    TripsProvider tripsProv,
  ) {
    return Row(
      children: [
        // Vehicle type
        Expanded(
          child: AdaptiveDropdown<VehicleType>(
            items: tripsProv.vehicleTypesWithoutPoi,
            selectedValue: p.vehicle,
            onChanged: (v) => p.vehicle = v ?? VehicleType.train,
            labelOf: (v) => VehicleType.labelOf(v, context),
            iconOf: (v) => VehicleType.iconOf(v),
            hintText: loc.statisticsSelectVehicle,
          ),
        ),
        const SizedBox(width: 8),
        // Unit
        Expanded(
          child: AdaptiveDropdown<GraphUnit>(
            items: GraphUnit.values,
            selectedValue: p.unit,
            onChanged: (u) => p.unit = u ?? GraphUnit.trip,
            labelOf: (u) => u.label(context),
            iconOf: (u) => u.icon(),
            hintText: loc.statisticsSelectUnit,
          ),
        ),
        // Sort toggle — hidden for Pie view
        if (_view != StatisticsView.pie) ...[
          const SizedBox(width: 8),
          _SortToggleButton(
            alpha: _sortedAlpha,
            onToggle: () => setState(() => _sortedAlpha = !_sortedAlpha),
          ),
        ],
      ],
    );
  }

  // ── Chart switcher ─────────────────────────────────────────────────────────

  Widget _buildChart(
    BuildContext context,
    StatisticsProvider p,
    AppLocalizations loc,
    Color barColor,
  ) {
    final statsShort = p.currentStatsShort(
      10,
      otherLabel: loc.statisticsOtherLabel,
    );
    final images = p.graphImagesForKeys(context, statsShort.keys.toList());
    final unitMap = p.unitsByFactor(context);
    final baseUnit = p.baseUnitLabel(context);
    final labelBuilder = p.labelBuilder(context);

    // Raw seconds for duration tooltips
    List<double>? rawPastSecs;
    List<double>? rawFutureSecs;
    String Function(BuildContext, double)? rawFormatter;

    if (p.unit == GraphUnit.duration) {
      final rawShort = p.currentDurationRawSecondsShort(
        10,
        otherLabel: loc.statisticsOtherLabel,
      );
      rawPastSecs = [for (final k in statsShort.keys) rawShort[k]?.past ?? 0];
      rawFutureSecs = [for (final k in statsShort.keys) rawShort[k]?.future ?? 0];
      rawFormatter = (ctx, v) => p.humanizeSeconds(ctx, v);
    }

    final isDurationOrTrips =
        p.unit == GraphUnit.duration || p.unit == GraphUnit.trip;

    switch (_view) {
      case StatisticsView.bar:
        return StatsBarChart(
          stats: _orderedStats(statsShort, alpha: _sortedAlpha),
          images: images,
          baseUnit: baseUnit,
          unitsByFactor: unitMap,
          color: barColor,
          labelBuilder: labelBuilder,
          unitHelpTooltip: isDurationOrTrips ? null : _tooltipRich(context, unitMap!),
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
            ? _orderedStats(_localizedStatsForTable(context, fullStats), alpha: _sortedAlpha)
            : _orderedStats(fullStats, alpha: _sortedAlpha);
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
            if (!isDuration)
              Padding(
                padding: const EdgeInsets.only(bottom: 4),
                child: Text(
                  baseUnit,
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
  }) {
    final entries = stats.entries.toList();
    if (alpha) {
      entries.sort((a, b) => a.key.toLowerCase().compareTo(b.key.toLowerCase()));
    } else {
      entries.sort((a, b) {
        final ta = a.value.past + a.value.future;
        final tb = b.value.past + b.value.future;
        final cmp = tb.compareTo(ta);
        return cmp != 0 ? cmp : a.key.toLowerCase().compareTo(b.key.toLowerCase());
      });
    }
    return LinkedHashMap.fromEntries(entries);
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
    return _orderedStats(out, alpha: _sortedAlpha);
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

  InlineSpan _tooltipRich(BuildContext context, Map<UnitFactor, String> units) {
    final base = Theme.of(context).textTheme.bodyMedium!;
    final baseUnit = units[UnitFactor.base]!;
    return WidgetSpan(
      child: DefaultTextStyle(
        style: base.copyWith(color: Theme.of(context).colorScheme.onPrimaryContainer),
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
}

// ── Year selector chip ─────────────────────────────────────────────────────

class _YearDropdown extends StatelessWidget {
  final List<int> years;
  final int selected;
  final bool enabled;
  final String allYearsLabel;
  final ValueChanged<int> onChanged;

  const _YearDropdown({
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

    return PopupMenuButton<int>(
      enabled: enabled,
      initialValue: selected,
      onSelected: onChanged,
      itemBuilder: (_) => [
        for (final y in years)
          PopupMenuItem<int>(
            value: y,
            child: Text(y == 0 ? allYearsLabel : y.toString()),
          ),
      ],
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: cs.surfaceContainerHighest,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: cs.outline.withValues(alpha: 0.4)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.calendar_today_outlined, size: 15, color: cs.onSurfaceVariant),
            const SizedBox(width: 6),
            Text(
              label,
              style: Theme.of(context).textTheme.labelLarge?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
            ),
            const SizedBox(width: 4),
            Icon(Icons.expand_more, size: 16, color: cs.onSurfaceVariant),
          ],
        ),
      ),
    );
  }
}

// ── Sort toggle button ─────────────────────────────────────────────────────

class _SortToggleButton extends StatelessWidget {
  final bool alpha;
  final VoidCallback onToggle;

  const _SortToggleButton({required this.alpha, required this.onToggle});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Tooltip(
      message: alpha ? 'Sort by total' : 'Sort alphabetically',
      child: InkWell(
        onTap: onToggle,
        borderRadius: BorderRadius.circular(8),
        child: Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: cs.surfaceContainerHighest,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: cs.outline.withValues(alpha: 0.4)),
          ),
          child: Icon(
            alpha ? Icons.sort_by_alpha : Icons.arrow_downward,
            size: 18,
            color: cs.onSurfaceVariant,
          ),
        ),
      ),
    );
  }
}
