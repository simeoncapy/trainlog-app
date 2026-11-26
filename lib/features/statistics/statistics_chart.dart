import 'dart:collection';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'package:trainlog_app/core/data/models/trips.dart';
import 'package:trainlog_app/core/providers/settings_provider.dart';
import 'package:trainlog_app/core/providers/statistics_provider.dart';
import 'package:trainlog_app/features/statistics/statistics_controller.dart';
import 'package:trainlog_app/features/statistics/statistics_graph_images.dart';
import 'package:trainlog_app/features/statistics/widgets/stats_bar_chart.dart';
import 'package:trainlog_app/features/statistics/widgets/stats_pie_chart.dart';
import 'package:trainlog_app/features/statistics/widgets/stats_table_chart.dart';
import 'package:trainlog_app/l10n/app_localizations.dart';
import 'package:trainlog_app/utils/map_color_palette.dart';
import 'package:trainlog_app/utils/number_formatter.dart';
import 'package:trainlog_app/utils/text_utils.dart';

/// The colour of the bars: the chosen vehicle's, or the primary colour for
/// all modes.
Color statisticsBarColor(BuildContext context) {
  final statsProv = context.watch<StatisticsProvider>();
  final palette = MapColorPaletteHelper.getPalette(
    context.watch<SettingsProvider>().mapColorPalette,
  );
  return statsProv.vehicle == null
      ? Theme.of(context).colorScheme.primary
      : palette[statsProv.vehicle] ?? Colors.blue;
}

/// The chart of the Statistics page in the controller's view (bars, pie or
/// table), with its loading, error and empty states. Shared by both designs.
class StatisticsChart extends StatelessWidget {
  const StatisticsChart({super.key});

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context)!;
    final p = context.watch<StatisticsProvider>();
    final controller = context.watch<StatisticsController>();
    final palette = MapColorPaletteHelper.getPalette(
      context.watch<SettingsProvider>().mapColorPalette,
    );
    final barColor = statisticsBarColor(context);
    final otherLabel = loc.statisticsOtherLabel;
    Color colorOf(VehicleType v) => palette[v] ?? Colors.blue;
    final statsShort = p.currentStatsShort(10, otherLabel: otherLabel);

    if (p.isLoading) {
      return const Padding(
        padding: EdgeInsets.symmetric(vertical: 40),
        child: Center(child: CircularProgressIndicator()),
      );
    }
    if (p.error != null) return Center(child: Text('Error: ${p.error}'));
    if (statsShort.isEmpty) return Center(child: Text(loc.noData));

    final chart = _buildChartView(
      context,
      p,
      controller,
      loc,
      barColor,
      colorOf,
      statsShort,
      otherLabel,
    );
    if (p.failedVehicles.isEmpty) return chart;

    // Some modes failed to load: warn, but still show the others.
    final failed = p.failedVehicles.map((v) => v.label(context)).join(', ');
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Padding(
          padding: const EdgeInsets.only(bottom: 12),
          child: Row(
            children: [
              Icon(Icons.warning_amber, size: 18, color: Theme.of(context).colorScheme.error),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  loc.statisticsPartialLoadWarning(failed),
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: Theme.of(context).colorScheme.error,
                      ),
                ),
              ),
            ],
          ),
        ),
        chart,
      ],
    );
  }

  Widget _buildChartView(
    BuildContext context,
    StatisticsProvider p,
    StatisticsController controller,
    AppLocalizations loc,
    Color barColor,
    Color Function(VehicleType) colorOf,
    LinkedHashMap<String, StatisticsEntry> statsShort,
    String otherLabel,
  ) {
    final unitMap = p.unitsByFactor(context);
    final baseUnit = p.baseUnitLabel(context);
    final baseUnitFor = p.baseUnitFor(context);
    final labelBuilder = p.labelBuilder(context);
    final alpha = controller.sortedAlpha;

    switch (controller.view) {
      case StatisticsView.bar:
        // Order first, then build images from the SAME ordered keys so the
        // icons follow the bars when sorting mode changes.
        final orderedBar = StatisticsController.ordered(
          statsShort,
          alpha: alpha,
          otherLabel: otherLabel,
          labelOf: labelBuilder,
        );
        final images = p.graphImagesForKeys(
          context,
          orderedBar.keys.toList(),
          otherLabel: otherLabel,
          barColor: barColor,
        );
        // All modes: one coloured segment per vehicle type.
        List<List<StatsBarSegment>>? segments;
        if (p.isAllVehicles) {
          final byVehicle = p.currentStatsByVehicleShort(10, otherLabel: otherLabel);
          segments = [
            for (final key in orderedBar.keys)
              [
                for (final e in (byVehicle[key] ?? const {}).entries)
                  (color: colorOf(e.key), past: e.value.past, future: e.value.future),
              ],
          ];
        }
        return StatsBarChart(
          stats: orderedBar,
          images: images,
          segments: segments,
          baseUnit: baseUnit,
          unitsByFactor: unitMap,
          baseUnitFor: baseUnitFor,
          color: barColor,
          labelBuilder: labelBuilder,
          otherLabel: otherLabel,
        );

      case StatisticsView.pie:
        return StatsPieChart(
          stats: statsShort,
          baseUnit: baseUnit,
          unitsByFactor: unitMap,
          baseUnitFor: baseUnitFor,
          labelBuilder: labelBuilder,
          otherLabel: otherLabel,
        );

      case StatisticsView.table:
        final fullStats = p.currentStats;
        final tableStats = (p.graph == GraphType.country)
            ? StatisticsController.ordered(
                _localizedStatsForTable(context, fullStats),
                alpha: alpha,
                otherLabel: otherLabel,
              )
            : StatisticsController.ordered(fullStats, alpha: alpha, otherLabel: otherLabel);
        final isDuration = p.unit == GraphUnit.duration;
        final isCountry = p.graph == GraphType.country;

        Map<String, StatisticsEntry>? rawForTable;
        if (isDuration) {
          final rawSeconds = p.currentDurationRawSeconds();
          rawForTable = isCountry
              ? _localizedStatsForTable(context, rawSeconds)
              : LinkedHashMap.of(rawSeconds);
        }

        // All modes: one detail line per vehicle type under each entry.
        Map<String, List<StatsTableSubRow>>? subRows;
        if (p.isAllVehicles) {
          var byVehicle = p.currentStatsByVehicle();
          var rawByVehicle = isDuration ? p.currentDurationRawSecondsByVehicle() : null;
          if (isCountry) {
            byVehicle = _localizedBreakdownForTable(context, byVehicle);
            if (rawByVehicle != null) {
              rawByVehicle = _localizedBreakdownForTable(context, rawByVehicle);
            }
          }
          subRows = {
            for (final e in byVehicle.entries)
              e.key: [
                for (final m in e.value.entries)
                  (
                    icon: VehicleType.iconOf(m.key),
                    color: colorOf(m.key),
                    label: VehicleType.labelOf(m.key, context),
                    past: m.value.past,
                    future: m.value.future,
                    raw: rawByVehicle?[e.key]?[m.key],
                  ),
              ],
          };
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
              subRows: subRows,
              valueFormatter: (v) => formatNumber(context, v),
              labelHeader: p.graph.label(context, p.vehicle),
              pastHeader: loc.yearPastList,
              futureHeader: loc.yearFutureList,
              totalHeader: loc.statisticsTotalLabel,
              labelMaxWidth: 200,
              compact: true,
              onlyTotal: StatisticsController.tableOnlyTotal(
                p.year,
                currentYear: DateTime.now().year,
              ),
            ),
          ],
        );
    }
  }

  /// Merge entries under their localized country name.
  LinkedHashMap<String, StatisticsEntry> _localizedStatsForTable(
    BuildContext context,
    Map<String, StatisticsEntry> stats,
  ) {
    final out = LinkedHashMap<String, StatisticsEntry>();
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

  /// Merge per-mode breakdowns under their localized country name.
  LinkedHashMap<String, Map<VehicleType, StatValue>> _localizedBreakdownForTable(
    BuildContext context,
    Map<String, Map<VehicleType, StatValue>> byCode,
  ) {
    final out = LinkedHashMap<String, Map<VehicleType, StatValue>>();
    for (final e in byCode.entries) {
      final merged = out.putIfAbsent(countryCodeToName(e.key, context), () => {});
      for (final m in e.value.entries) {
        final cur = merged[m.key];
        merged[m.key] = (
          past: (cur?.past ?? 0) + m.value.past,
          future: (cur?.future ?? 0) + m.value.future,
        );
      }
    }
    return out;
  }
}
