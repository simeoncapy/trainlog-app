import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'package:trainlog_app/core/data/models/trips.dart';
import 'package:trainlog_app/core/providers/statistics_provider.dart';
import 'package:trainlog_app/core/providers/trips_provider.dart';
import 'package:trainlog_app/features/statistics/statistics_chart.dart';
import 'package:trainlog_app/features/statistics/statistics_controller.dart';
import 'package:trainlog_app/features/statistics/statistics_graph_images.dart';
import 'package:trainlog_app/l10n/app_localizations.dart';
import 'package:trainlog_app/ui/adaptive/adaptive_widget.dart';
import 'package:trainlog_app/ui/adaptive/app_steps_tab_bar.dart';
import 'package:trainlog_app/utils/number_formatter.dart';
import 'package:trainlog_app/widgets/divider_with_widget.dart';
import 'package:trainlog_app/widgets/icon_toggle_button.dart';

/// The Statistics page in Material 3: a header with the year chip, then one
/// bordered card holding the selectors and the chart.
class StatisticsMaterialView extends StatelessWidget {
  const StatisticsMaterialView({super.key});

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context)!;
    final statsProv = context.watch<StatisticsProvider>();
    final tripsProv = context.watch<TripsProvider>();
    final controller = context.watch<StatisticsController>();
    final barColor = statisticsBarColor(context);
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
              const SizedBox(width: 8),
              Expanded(
                child: Align(
                  alignment: Alignment.centerRight,
                  child: _YearChip(
                    years: [0, ...tripsProv.years],
                    selected: statsProv.year ?? 0,
                    enabled: !disabledYears,
                    allYearsLabel: loc.tripsFilterAllYears,
                    onChanged: (y) => statsProv.year = y,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),

          // ── Main card (selectors + chart) ─────────────────────────
          _StatsCard(
            view: controller.view,
            onViewChanged: (v) => controller.view = v,
            statsProv: statsProv,
            tripsProv: tripsProv,
            barColor: barColor,
            sortedAlpha: controller.sortedAlpha,
            onSortToggle: controller.toggleSort,
            chartBuilder: (_) => const StatisticsChart(),
          ),
        ],
      ),
    );
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
                const SizedBox(width: 8),
                Expanded(
                  child: Align(
                    alignment: Alignment.centerRight,
                    // AppStepsTabBar — icon-only tabs, not full width
                    child: Builder(builder: (context) {
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
                  ),
                ),
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
                  // Wrapped in a record: a null popup value reads as "cancelled".
                  child: _OutlinedDropdown<({VehicleType? type})>(
                    items: [
                      (type: null),
                      for (final v in tripsProv.vehicleTypesWithoutPoi) (type: v),
                    ],
                    selected: (type: statsProv.vehicle),
                    iconOf: (v) => statisticsVehicleIcon(v.type),
                    labelOf: (v) => v.type == null
                        ? loc.statisticsAllVehicles
                        : VehicleType.labelOf(v.type!, context),
                    onChanged: (v) => statsProv.vehicle = v == null ? statsProv.vehicle : v.type,
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
                  IconToggleButton(
                    onScaffold: false,
                    icon: sortedAlpha ? Icons.filter_list : Icons.sort_by_alpha,
                    tooltip:
                        sortedAlpha ? 'Sort by total' : 'Sort alphabetically',
                    onTap: onSortToggle,
                  ),
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
  final VehicleType? vehicle;
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
