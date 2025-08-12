import 'dart:math' as math;
import 'dart:ui' show FontFeature;
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';

/// Input is a LinkedHashMap of label -> (past, future).
/// Slice size uses (past + future).
class StatsPieChart extends StatelessWidget {
  const StatsPieChart({
    super.key,
    required this.stats,
    this.interactive = false,
    this.valueFormatter,
    this.showLegend = true,
    this.sectionsSpace = 2,
    this.centerSpaceRadius = 36,
    this.minChartSize = 220,
    this.colorByLabel,
    this.seedColor,
    this.centerWidget,
    this.sortDescending = true,
  });

  final Map<String, ({double past, double future})> stats;
  final bool interactive;
  final String Function(num value)? valueFormatter;
  final bool showLegend;
  final double sectionsSpace;
  final double centerSpaceRadius;
  final double minChartSize;
  final Map<String, Color>? colorByLabel; // optional per-label colors
  final Color? seedColor;                  // optional seed for auto colors
  final Widget? centerWidget;              // widget in the donut hole
  final bool sortDescending;

  @override
  Widget build(BuildContext context) {
    // Build list of (label, total)
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

    // Colors (stable per label)
    Color colorForLabel(String label) {
      if (colorByLabel != null && colorByLabel![label] != null) {
        return colorByLabel![label]!;
      }
      final base = seedColor ?? Theme.of(context).colorScheme.primary;
      final seedHsl = HSLColor.fromColor(base);
      final hue = (label.hashCode % 360).toDouble();
      // Derive vivid but readable colors
      return HSLColor.fromAHSL(
        1.0,
        hue,
        (seedHsl.saturation + 0.35).clamp(0.45, 0.9),
        0.55,
      ).toColor();
    }

    final sections = <PieChartSectionData>[
      for (final e in entries)
        PieChartSectionData(
          value: e.value,
          color: colorForLabel(e.key),
          showTitle: false,
          radius: 80,
        ),
    ];

    String fmt(num v) =>
        valueFormatter?.call(v) ??
        // fallback if you didn't pass a formatter
        v.toStringAsFixed(v.truncateToDouble() == v ? 0 : 2);

    final legendStyle = Theme.of(context).textTheme.bodyMedium?.copyWith(
          fontFeatures: const [FontFeature.tabularFigures()],
        );

    return LayoutBuilder(
      builder: (context, constraints) {
        // Choose a square size that fits the viewport
        double side = minChartSize;
        final w = constraints.maxWidth;
        final h = constraints.maxHeight;
        if (w.isFinite && h.isFinite) {
          side = math.max(minChartSize, math.min(w, h));
        }

        // Build legend (labels + values)
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
                      color: colorForLabel(e.key),
                      shape: BoxShape.circle,
                    ),
                  ),
                  const SizedBox(width: 6),
                  ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 220),
                    child: Text(
                      '${e.key}: ${fmt(e.value)}',
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
            // Chart
            Center(
              child: SizedBox(
                width: side,
                height: side,
                child: PieChart(
                  PieChartData(
                    sections: sections,
                    sectionsSpace: sectionsSpace,
                    centerSpaceRadius: centerSpaceRadius,
                    centerSpaceColor: Colors.transparent,
                    pieTouchData: PieTouchData(enabled: interactive),
                  ),
                ),
              ),
            ),
            if (centerWidget != null)
              Positioned.fill(child: Center(child: centerWidget!)), // if you embed in a Stack
            const SizedBox(height: 12),
            if (showLegend) legend,
          ],
        );
      },
    );
  }
}
