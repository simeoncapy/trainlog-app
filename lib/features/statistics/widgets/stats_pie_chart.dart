import 'dart:math' as math;
import 'dart:ui' show FontFeature;
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';

/// Input is a LinkedHashMap of key -> (past, future).
/// Slice size uses (past + future).
class StatsPieChart extends StatelessWidget {
  const StatsPieChart({
    super.key,
    required this.stats,
    this.labelBuilder,                // 👈 map key -> display label
    this.interactive = false,
    this.valueFormatter,
    this.showLegend = true,
    this.sectionsSpace = 2,
    this.centerSpaceRadius = 36,
    this.minChartSize = 220,
    this.colorByLabel,                // original-key -> color
    this.seedColor,
    this.centerWidget,                // widget in the donut hole
    this.sortDescending = true,
  });

  final Map<String, ({double past, double future})> stats;
  final String Function(String key)? labelBuilder;

  final bool interactive;
  final String Function(num value)? valueFormatter;
  final bool showLegend;
  final double sectionsSpace;
  final double centerSpaceRadius;
  final double minChartSize;
  final Map<String, Color>? colorByLabel; // keyed by ORIGINAL key
  final Color? seedColor;
  final Widget? centerWidget;
  final bool sortDescending;

  @override
  Widget build(BuildContext context) {
    // Build list of (key, total)
    final entries = stats.entries
        .map((e) => MapEntry(e.key, (e.value.past + e.value.future)))
        .where((e) => e.value > 0)
        .toList();

    if (entries.isEmpty) {
      return const Center(child: Text('No data'));
    }

    if (sortDescending) {
      entries.sort((a, b) => b.value.compareTo(a.value));
    }

    // Colors (stable per ORIGINAL key)
    Color colorForKey(String key) {
      if (colorByLabel != null && colorByLabel![key] != null) {
        return colorByLabel![key]!;
      }
      final base = seedColor ?? Theme.of(context).colorScheme.primary;
      final seedHsl = HSLColor.fromColor(base);
      final hue = (key.hashCode % 360).toDouble();
      return HSLColor.fromAHSL(
        1.0,
        hue,
        (seedHsl.saturation + 0.35).clamp(0.45, 0.9),
        0.55,
      ).toColor();
    }

    // Display label for legend
    String labelOf(String key) => labelBuilder?.call(key) ?? key;

    final sections = <PieChartSectionData>[
      for (final e in entries)
        PieChartSectionData(
          value: e.value,
          color: colorForKey(e.key),
          showTitle: false,
          radius: 80,
        ),
    ];

    String fmt(num v) =>
        valueFormatter?.call(v) ??
        v.toStringAsFixed(v.truncateToDouble() == v ? 0 : 2);

    final legendStyle = Theme.of(context).textTheme.bodyMedium?.copyWith(
          fontFeatures: const [FontFeature.tabularFigures()],
        );

    return LayoutBuilder(
      builder: (context, constraints) {
        double side = minChartSize;
        final w = constraints.maxWidth;
        final h = constraints.maxHeight;
        if (w.isFinite && h.isFinite) {
          side = math.max(minChartSize, math.min(w, h));
        }

        final legend = Wrap(
          spacing: 12,
          runSpacing: 8,
          children: [
            for (final e in entries)
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 10,
                    height: 10,
                    decoration: BoxDecoration(
                      color: colorForKey(e.key),
                      shape: BoxShape.circle,
                    ),
                  ),
                  const SizedBox(width: 6),
                  ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 220),
                    child: Text(
                      '${labelOf(e.key)}: ${fmt(e.value)}', // 👈 use display label
                      overflow: TextOverflow.ellipsis,
                      style: legendStyle,
                    ),
                  ),
                ],
              ),
          ],
        );

        return Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Chart + center widget in a Stack so the center shows correctly
            Center(
              child: SizedBox(
                width: side,
                height: side,
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    PieChart(
                      PieChartData(
                        sections: sections,
                        sectionsSpace: sectionsSpace,
                        centerSpaceRadius: centerSpaceRadius,
                        centerSpaceColor: Colors.transparent,
                        pieTouchData: PieTouchData(enabled: interactive),
                      ),
                    ),
                    if (centerWidget != null) centerWidget!,
                  ],
                ),
              ),
            ),
            const SizedBox(height: 12),
            if (showLegend) legend,
          ],
        );
      },
    );
  }
}
