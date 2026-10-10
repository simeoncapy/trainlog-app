import 'dart:math' as math;
import 'dart:ui' show FontFeature;
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:trainlog_app/app/theme/app_theme.dart';
import 'package:trainlog_app/app/theme/chart_palette.dart';
import 'package:trainlog_app/features/statistics/widgets/stats_unit_scale.dart';
import 'package:trainlog_app/l10n/app_localizations.dart';
import 'package:trainlog_app/utils/number_formatter.dart';
import 'package:trainlog_app/widgets/error_banner.dart';

/// Donut chart of key -> (past, future); slice size uses (past + future).
///
/// Slices follow the order of [stats] clockwise from 12 o'clock, with
/// [otherLabel] always last. Colours come from [ChartPalette] by rank ("Other"
/// is grey); slices big enough show their rank, matching the legend below.
/// Tapping a slice or a legend row highlights it and shows its details in
/// the centre; tapping it again (or the background) clears the selection.
/// Values are scaled like [StatsBarChart] (k/M/G via [unitsByFactor]).
class StatsPieChart extends StatefulWidget {
  const StatsPieChart({
    super.key,
    required this.stats,
    required this.baseUnit,
    this.unitsByFactor,
    this.labelBuilder,
    this.otherLabel,
    this.interactive = true,
    this.showLegend = true,
    this.sectionsSpace = 2,
    this.centerSpaceRadius = 56,
    this.minChartSize = 220,
  });

  final Map<String, ({double past, double future})> stats;
  final String baseUnit;
  final Map<UnitFactor, String>? unitsByFactor;
  final String Function(String key)? labelBuilder;
  final String? otherLabel;

  final bool interactive;
  final bool showLegend;
  final double sectionsSpace;
  final double centerSpaceRadius;
  final double minChartSize;

  @override
  State<StatsPieChart> createState() => _StatsPieChartState();
}

/// Smallest share of the total whose slice shows its rank number.
const _minTitleFraction = 0.05;
const _sliceRadius = 44.0;
const _selectedSliceRadius = 52.0;

class _StatsPieChartState extends State<StatsPieChart> {
  /// Index of the selected entry, or null.
  int? _selected;

  @override
  void didUpdateWidget(covariant StatsPieChart old) {
    super.didUpdateWidget(old);
    // Different data (unit, graph, year…): the index no longer means the same.
    if (!mapEquals(old.stats, widget.stats)) _selected = null;
  }

  void _toggle(int? index) {
    if (!widget.interactive) return;
    setState(() => _selected = (index == null || index == _selected) ? null : index);
  }

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final brightness = theme.brightness;

    // Keep the given order, "Other" last; drop empty entries.
    final all = widget.stats.entries
        .where((e) => e.value.past + e.value.future > 0)
        .toList();
    final entries = [
      ...all.where((e) => e.key != widget.otherLabel),
      ...all.where((e) => e.key == widget.otherLabel),
    ];

    if (entries.isEmpty) return Center(child: Text(loc.noData));

    final selected =
        (_selected != null && _selected! < entries.length) ? _selected : null;

    bool isOther(int i) => entries[i].key == widget.otherLabel;
    Color colorOf(int i) =>
        isOther(i) ? ChartPalette.other(brightness) : ChartPalette.colorAt(i, brightness);
    String labelOf(int i) => widget.labelBuilder?.call(entries[i].key) ?? entries[i].key;
    double totalOf(int i) => entries[i].value.past + entries[i].value.future;

    final total = Iterable.generate(entries.length, totalOf).fold(0.0, (a, b) => a + b);
    final scale = StatsUnitScale(
      Iterable.generate(entries.length, totalOf),
      baseUnit: widget.baseUnit,
      unitsByFactor: widget.unitsByFactor,
    );

    String fmt(double raw) {
      final v = scale.apply(raw);
      return '${formatNumber(context, v, noDecimal: v == v.truncateToDouble())} ${scale.unitLabel}';
    }

    String pct(int i) => formatPercent(context, totalOf(i) / total * 100, maxDecimals: 1);

    final sections = <PieChartSectionData>[
      for (var i = 0; i < entries.length; i++)
        PieChartSectionData(
          value: totalOf(i),
          color: (selected == null || selected == i)
              ? colorOf(i)
              : colorOf(i).withValues(alpha: 0.35),
          radius: selected == i ? _selectedSliceRadius : _sliceRadius,
          showTitle: !isOther(i) && totalOf(i) / total >= _minTitleFraction,
          title: '${i + 1}',
          titleStyle: AppTheme.monoFont.copyWith(
            fontSize: 12,
            fontWeight: FontWeight.w700,
            // Readable on both light (yellow) and dark (violet) slices.
            color: ThemeData.estimateBrightnessForColor(colorOf(i)) == Brightness.dark
                ? Colors.white
                : Colors.black,
          ),
        ),
    ];

    final monoStyle = AppTheme.monoFont.copyWith(
      fontSize: 13,
      fontFeatures: const [FontFeature.tabularFigures()],
      color: theme.colorScheme.onSurface,
    );
    final mutedStyle = monoStyle.copyWith(
      fontSize: 11,
      color: theme.colorScheme.onSurfaceVariant,
    );

    // ── Centre of the donut: selected entry, or the total ──────────────────
    Widget center() {
      final i = selected;
      final label = i == null ? loc.statisticsTotalLabel : labelOf(i);
      final value = i == null ? fmt(total) : fmt(totalOf(i));
      final e = i == null ? null : entries[i].value;
      return SizedBox(
        width: widget.centerSpaceRadius * 2 - 12,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              label,
              textAlign: TextAlign.center,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: theme.textTheme.labelMedium?.copyWith(fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 2),
            FittedBox(fit: BoxFit.scaleDown, child: Text(value, style: monoStyle)),
            if (i != null)
              Text(pct(i), style: mutedStyle),
            if (e != null && e.future > 0)
              FittedBox(
                fit: BoxFit.scaleDown,
                child: Text(
                  '${formatNumber(context, scale.apply(e.past))} + ${formatNumber(context, scale.apply(e.future))}',
                  style: mutedStyle,
                ),
              ),
          ],
        ),
      );
    }

    // ── Legend: same order as the slices ───────────────────────────────────
    Widget legendRow(int i) {
      final isSelected = selected == i;
      final dimmed = selected != null && !isSelected;
      return Opacity(
        opacity: dimmed ? 0.5 : 1,
        child: Material(
          color: isSelected
              ? theme.colorScheme.primary.withValues(alpha: 0.12)
              : Colors.transparent,
          borderRadius: BorderRadius.circular(8),
          child: InkWell(
            borderRadius: BorderRadius.circular(8),
            onTap: widget.interactive ? () => _toggle(i) : null,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
              child: Row(
                children: [
                  Container(
                    width: 12,
                    height: 12,
                    decoration: BoxDecoration(color: colorOf(i), shape: BoxShape.circle),
                  ),
                  const SizedBox(width: 8),
                  SizedBox(
                    width: 22,
                    child: Text(
                      isOther(i) ? '' : '${i + 1}',
                      style: monoStyle.copyWith(fontWeight: FontWeight.w700),
                    ),
                  ),
                  Expanded(
                    child: Text(
                      labelOf(i),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: theme.textTheme.bodyMedium?.copyWith(
                        fontWeight: isSelected ? FontWeight.w700 : FontWeight.w600,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(fmt(totalOf(i)), style: monoStyle),
                  SizedBox(
                    width: 52,
                    child: Text(pct(i), textAlign: TextAlign.right, style: mutedStyle),
                  ),
                ],
              ),
            ),
          ),
        ),
      );
    }

    return LayoutBuilder(
      builder: (context, constraints) {
        double side = widget.minChartSize;
        final w = constraints.maxWidth;
        final h = constraints.maxHeight;
        if (w.isFinite && h.isFinite) {
          side = math.max(widget.minChartSize, math.min(w, h));
        }

        return Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            ErrorBanner(
              severity: ErrorSeverity.info,
              compact: true,
              message: loc.statisticsPieWip,
            ),
            const SizedBox(height: 12),
            Center(
              child: SizedBox(
                width: side,
                height: side,
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    PieChart(
                      duration: const Duration(milliseconds: 250),
                      PieChartData(
                        sections: sections,
                        startDegreeOffset: -90, // first slice at 12 o'clock
                        sectionsSpace: widget.sectionsSpace,
                        centerSpaceRadius: widget.centerSpaceRadius,
                        centerSpaceColor: Colors.transparent,
                        pieTouchData: PieTouchData(
                          enabled: widget.interactive,
                          touchCallback: (event, response) {
                            if (event is! FlTapUpEvent) return;
                            final index = response?.touchedSection?.touchedSectionIndex;
                            _toggle(index == null || index < 0 ? null : index);
                          },
                        ),
                      ),
                    ),
                    IgnorePointer(child: center()),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 12),
            if (widget.showLegend)
              Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [for (var i = 0; i < entries.length; i++) legendRow(i)],
              ),
          ],
        );
      },
    );
  }
}
