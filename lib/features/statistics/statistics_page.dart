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
        final hasData = statsProv.currentStats.isNotEmpty && !statsProv.isLoading;
        final disabledYears = statsProv.graph == GraphType.years;

        return Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ── Header row ────────────────────────────────────────────
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
                  _YearChip(
                    years: [0, ...tripsProv.years],
                    selected: statsProv.year ?? 0,
                    enabled: !disabledYears,
                    allYearsLabel: loc.tripsFilterAllYears,
                    onChanged: (y) => statsProv.year = y,
                  ),
                ],
              ),
              const SizedBox(height: 14),

              // ── Combined filter + view-selector card ──────────────────
              _StatsFilterCard(
                view: _view,
                onViewChanged: (v) => setState(() => _view = v),
                statsProv: statsProv,
                tripsProv: tripsProv,
                sortedAlpha: _sortedAlpha,
                onSortToggle: () => setState(() => _sortedAlpha = !_sortedAlpha),
              ),
              const SizedBox(height: 14),

              // ── Chart area ────────────────────────────────────────────
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

  // ── Chart area ─────────────────────────────────────────────────────────────

  Widget _buildChart(
    BuildContext context,
    StatisticsProvider p,
    AppLocalizations loc,
    Color barColor,
  ) {
    final otherLabel = loc.statisticsOtherLabel;
    final statsShort = p.currentStatsShort(10, otherLabel: otherLabel);
    final keys = statsShort.keys.toList();
    final images = p.graphImagesForKeys(context, keys, otherLabel: otherLabel, barColor: barColor);
    final unitMap = p.unitsByFactor(context);
    final baseUnit = p.baseUnitLabel(context);
    final labelBuilder = p.labelBuilder(context);
    final isDurationOrTrips = p.unit == GraphUnit.duration || p.unit == GraphUnit.trip;

    switch (_view) {
      case StatisticsView.bar:
        return StatsBarChart(
          stats: _orderedStats(statsShort, alpha: _sortedAlpha, otherLabel: otherLabel),
          images: images,
          baseUnit: baseUnit,
          unitsByFactor: unitMap,
          color: barColor,
          labelBuilder: labelBuilder,
          otherLabel: otherLabel,
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
            ? _orderedStats(_localizedStatsForTable(context, fullStats), alpha: _sortedAlpha, otherLabel: otherLabel)
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
    required String otherLabel,
  }) {
    final entries = stats.entries.toList();
    // Always pin "Other" at the end
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

// ── Filter card ────────────────────────────────────────────────────────────

class _StatsFilterCard extends StatelessWidget {
  final StatisticsView view;
  final ValueChanged<StatisticsView> onViewChanged;
  final StatisticsProvider statsProv;
  final TripsProvider tripsProv;
  final bool sortedAlpha;
  final VoidCallback onSortToggle;

  const _StatsFilterCard({
    required this.view,
    required this.onViewChanged,
    required this.statsProv,
    required this.tripsProv,
    required this.sortedAlpha,
    required this.onSortToggle,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final cardColor = isDark ? cs.surface : cs.surface;

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: cs.shadow.withValues(alpha: isDark ? 0.3 : 0.08),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          // Row 1: Dimension dropdown + graph-type icon buttons
          Row(
            children: [
              // Dimension dropdown (expands to fill remaining space)
              Expanded(
                child: _DimensionDropdown(
                  graph: statsProv.graph,
                  vehicle: statsProv.vehicle,
                  onChanged: (g) => statsProv.graph = g,
                ),
              ),
              const SizedBox(width: 8),
              // Graph-type icon buttons (Bar / Pie / Table)
              _GraphTypeButtons(
                selected: view,
                onChanged: onViewChanged,
              ),
            ],
          ),
          const SizedBox(height: 10),
          // Row 2: Vehicle | Unit | Sort
          Row(
            children: [
              Expanded(
                child: _CompactPillDropdown<VehicleType>(
                  items: tripsProv.vehicleTypesWithoutPoi,
                  selected: statsProv.vehicle,
                  iconOf: (v) => VehicleType.iconOf(v),
                  labelOf: (v) => VehicleType.labelOf(v, context),
                  onChanged: (v) => statsProv.vehicle = v ?? statsProv.vehicle,
                ),
              ),
              const SizedBox(width: 6),
              Expanded(
                child: _CompactPillDropdown<GraphUnit>(
                  items: GraphUnit.values,
                  selected: statsProv.unit,
                  iconOf: (u) => u.icon(),
                  labelOf: (u) => u.label(context),
                  onChanged: (u) => statsProv.unit = u ?? statsProv.unit,
                ),
              ),
              if (view != StatisticsView.pie) ...[
                const SizedBox(width: 6),
                _SortButton(alpha: sortedAlpha, onTap: onSortToggle),
              ],
            ],
          ),
        ],
      ),
    );
  }
}

// ── Dimension dropdown (styled pill, full label visible) ───────────────────

class _DimensionDropdown extends StatelessWidget {
  final GraphType graph;
  final VehicleType vehicle;
  final ValueChanged<GraphType> onChanged;

  const _DimensionDropdown({
    required this.graph,
    required this.vehicle,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return PopupMenuButton<GraphType>(
      onSelected: onChanged,
      itemBuilder: (_) => GraphType.values.map((g) {
        return PopupMenuItem<GraphType>(
          value: g,
          child: Row(
            children: [
              g.icon(),
              const SizedBox(width: 10),
              Text(g.label(context, vehicle)),
            ],
          ),
        );
      }).toList(),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
        decoration: BoxDecoration(
          color: isDark
              ? cs.surfaceContainerHighest.withValues(alpha: 0.3)
              : cs.surfaceContainerHighest.withValues(alpha: 0.6),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            IconTheme(
              data: IconThemeData(size: 16, color: cs.onSurface),
              child: graph.icon(),
            ),
            const SizedBox(width: 8),
            Flexible(
              child: Text(
                graph.label(context, vehicle),
                style: Theme.of(context).textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                overflow: TextOverflow.ellipsis,
                maxLines: 1,
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

// ── Graph type icon-only toggle (Bar | Pie | Table) ────────────────────────

class _GraphTypeButtons extends StatelessWidget {
  final StatisticsView selected;
  final ValueChanged<StatisticsView> onChanged;

  static const _items = [
    (StatisticsView.bar,   Icons.bar_chart),
    (StatisticsView.pie,   Icons.pie_chart),
    (StatisticsView.table, Icons.table_chart),
  ];

  const _GraphTypeButtons({required this.selected, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      decoration: BoxDecoration(
        color: isDark
            ? cs.surfaceContainerHighest.withValues(alpha: 0.3)
            : cs.surfaceContainerHighest.withValues(alpha: 0.6),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: _items.map((item) {
          final (view, icon) = item;
          final isSelected = selected == view;
          return GestureDetector(
            onTap: () => onChanged(view),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 180),
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 9),
              decoration: BoxDecoration(
                color: isSelected ? cs.primary.withValues(alpha: isDark ? 0.25 : 0.15) : Colors.transparent,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(
                icon,
                size: 18,
                color: isSelected ? cs.primary : cs.onSurfaceVariant.withValues(alpha: 0.6),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }
}

// ── Compact pill dropdown ──────────────────────────────────────────────────

class _CompactPillDropdown<T> extends StatelessWidget {
  final List<T> items;
  final T selected;
  final Icon? Function(T) iconOf;
  final String Function(T) labelOf;
  final ValueChanged<T?> onChanged;

  const _CompactPillDropdown({
    required this.items,
    required this.selected,
    required this.iconOf,
    required this.labelOf,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final icon = iconOf(selected);

    return PopupMenuButton<T>(
      onSelected: (v) => onChanged(v),
      itemBuilder: (_) => items.map((item) {
        return PopupMenuItem<T>(
          value: item,
          child: Row(
            children: [
              if (iconOf(item) != null) ...[
                iconOf(item)!,
                const SizedBox(width: 10),
              ],
              Text(labelOf(item)),
            ],
          ),
        );
      }).toList(),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
        decoration: BoxDecoration(
          color: isDark
              ? cs.surfaceContainerHighest.withValues(alpha: 0.3)
              : cs.surfaceContainerHighest.withValues(alpha: 0.6),
          borderRadius: BorderRadius.circular(20),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (icon != null) ...[
              IconTheme(
                data: IconThemeData(size: 14, color: cs.onSurfaceVariant),
                child: icon,
              ),
              const SizedBox(width: 5),
            ],
            Flexible(
              child: Text(
                labelOf(selected),
                style: Theme.of(context).textTheme.labelMedium?.copyWith(
                      color: cs.onSurface,
                    ),
                overflow: TextOverflow.ellipsis,
                maxLines: 1,
              ),
            ),
            const SizedBox(width: 2),
            Icon(Icons.keyboard_arrow_down, size: 13, color: cs.onSurfaceVariant),
          ],
        ),
      ),
    );
  }
}

// ── Sort icon button ───────────────────────────────────────────────────────

class _SortButton extends StatelessWidget {
  final bool alpha;
  final VoidCallback onTap;

  const _SortButton({required this.alpha, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Tooltip(
      message: alpha ? 'Sort by total' : 'Sort alphabetically',
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.all(9),
          decoration: BoxDecoration(
            color: isDark
                ? cs.surfaceContainerHighest.withValues(alpha: 0.3)
                : cs.surfaceContainerHighest.withValues(alpha: 0.6),
            borderRadius: BorderRadius.circular(20),
          ),
          child: Icon(
            alpha ? Icons.sort_by_alpha : Icons.arrow_downward,
            size: 16,
            color: cs.onSurfaceVariant,
          ),
        ),
      ),
    );
  }
}

// ── Year chip ──────────────────────────────────────────────────────────────

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

    return PopupMenuButton<int>(
      enabled: enabled,
      initialValue: selected,
      onSelected: onChanged,
      itemBuilder: (_) => years
          .map((y) => PopupMenuItem<int>(
                value: y,
                child: Text(y == 0 ? allYearsLabel : y.toString()),
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
            Text(
              label,
              style: Theme.of(context).textTheme.labelLarge?.copyWith(fontWeight: FontWeight.w600),
            ),
            const SizedBox(width: 4),
            Icon(Icons.keyboard_arrow_down, size: 16, color: cs.onSurfaceVariant),
          ],
        ),
      ),
    );
  }
}
