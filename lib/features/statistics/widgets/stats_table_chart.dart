import 'dart:ui' show FontFeature;
import 'package:flutter/material.dart';
import 'package:trainlog_app/app/theme/app_theme.dart';

/// Displays stats as a table: Label | Past | Future | Total
/// `stats`: key -> (past, future)
/// Optionally supports time (duration) humanization.
/// With [subRows], each entry is followed by indented detail lines (e.g. the
/// value per vehicle type) and entries are grouped by alternating shading.
class StatsTableChart extends StatelessWidget {
  const StatsTableChart({
    super.key,
    required this.stats,
    required this.valueFormatter,
    this.labelBuilder,
    this.labelHeader = 'Label',
    this.pastHeader = 'Past',
    this.futureHeader = 'Future',
    this.totalHeader = 'Total',
    this.labelMaxWidth = 220,
    this.labelMaxLines,
    this.compact = true,
    this.onlyTotal = false,
    this.rawValues,
    this.rawValueFormatter,
    this.isDuration = false,
    this.subRows,
  });

  final Map<String, ({double past, double future})> stats;
  final String Function(num value) valueFormatter;
  final String Function(String key)? labelBuilder;

  final String labelHeader, pastHeader, futureHeader, totalHeader;
  final double labelMaxWidth;
  final int? labelMaxLines;
  final bool compact;
  final bool onlyTotal;

  final Map<String, ({double past, double future})>? rawValues;
  final String Function(BuildContext context, double rawSeconds)? rawValueFormatter;
  final bool isDuration;

  /// Detail lines per entry, keyed like [stats].
  final Map<String, List<StatsTableSubRow>>? subRows;

  @override
  Widget build(BuildContext context) {
    final rowsData = stats.entries
        .map((e) => (
              key: e.key,
              label: labelBuilder?.call(e.key) ?? e.key,
              past: e.value.past,
              future: e.value.future,
            ))
        .toList();

    final monoStyle = AppTheme.monoFont.copyWith(
      fontSize: 13,
      fontFeatures: const [FontFeature.tabularFigures()],
    );

    Widget labelCell(String text, {bool header = false}) {
      final child = Text(
        text,
        softWrap: true,
        overflow: TextOverflow.visible,
        maxLines: labelMaxLines,
      );
      return ConstrainedBox(
        constraints: BoxConstraints(maxWidth: labelMaxWidth),
        child: header
            ? DefaultTextStyle.merge(
                style: Theme.of(context).textTheme.titleSmall ?? const TextStyle(),
                child: child,
              )
            : child,
      );
    }

    // Prefer the raw (seconds) value for durations when available.
    String format(num scaled, num? raw) {
      if (isDuration && raw != null && rawValueFormatter != null) {
        return rawValueFormatter!(context, raw.toDouble());
      }
      return valueFormatter(scaled);
    }

    num? rawTotal(({double past, double future})? raw) =>
        raw == null ? null : raw.past + raw.future;

    final subStyle = monoStyle.copyWith(
      fontSize: 11,
      color: Theme.of(context).colorScheme.onSurfaceVariant,
    );

    Widget numCell(String text, {TextStyle? style}) => Align(
          alignment: Alignment.centerRight,
          child: Text(text, softWrap: false, style: style ?? monoStyle),
        );

    Widget subLabelCell(StatsTableSubRow sub) => Padding(
          padding: const EdgeInsets.only(left: 16),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              IconTheme(
                data: IconThemeData(size: 14, color: sub.color),
                child: sub.icon,
              ),
              const SizedBox(width: 6),
              Text(sub.label, style: subStyle),
            ],
          ),
        );

    final groupShade = Theme.of(context)
        .colorScheme
        .surfaceContainerHighest
        .withValues(alpha: 0.5);
    final grouped = subRows != null;

    return LayoutBuilder(
      builder: (context, constraints) {
        return SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: ConstrainedBox(
            constraints: BoxConstraints(minWidth: constraints.maxWidth),
            child: DataTableTheme(
              data: DataTableTheme.of(context).copyWith(
                headingRowColor: WidgetStateProperty.resolveWith<Color?>(
                  (_) => Theme.of(context).colorScheme.primaryContainer,
                ),
                headingTextStyle: Theme.of(context).textTheme.labelLarge?.copyWith(
                      color: Theme.of(context).colorScheme.onPrimaryContainer,
                      fontWeight: FontWeight.bold,
                    ),
              ),
              // Grouped rows are told apart by shading instead of dividers.
              child: Theme(
                data: grouped
                    ? Theme.of(context).copyWith(
                        dividerTheme: const DividerThemeData(color: Colors.transparent),
                      )
                    : Theme.of(context),
                child: DataTable(
                  showCheckboxColumn: false,
                  dataRowMinHeight: compact ? 0 : null,
                  dataRowMaxHeight: null,
                  headingRowHeight: compact ? 36 : null,
                  horizontalMargin: compact ? 12 : null,
                  columnSpacing: compact ? 16 : null,
                  columns: [
                    DataColumn(label: labelCell(labelHeader, header: true)),
                    if (!onlyTotal)
                      DataColumn(
                        label: Text(pastHeader, style: monoStyle.copyWith(fontWeight: FontWeight.bold)),
                        numeric: true,
                      ),
                    if (!onlyTotal)
                      DataColumn(
                        label: Text(futureHeader, style: monoStyle.copyWith(fontWeight: FontWeight.bold)),
                        numeric: true,
                      ),
                    DataColumn(
                      label: Text(totalHeader, style: monoStyle.copyWith(fontWeight: FontWeight.bold)),
                      numeric: true,
                    ),
                  ],
                  rows: [
                    for (final (i, r) in rowsData.indexed) ...[
                      DataRow(
                        color: grouped && i.isOdd
                            ? WidgetStatePropertyAll(groupShade)
                            : null,
                        cells: [
                          DataCell(labelCell(r.label)),
                          if (!onlyTotal)
                            DataCell(numCell(format(r.past, rawValues?[r.key]?.past))),
                          if (!onlyTotal)
                            DataCell(numCell(format(r.future, rawValues?[r.key]?.future))),
                          DataCell(numCell(format(r.past + r.future, rawTotal(rawValues?[r.key])))),
                        ],
                      ),
                      for (final sub in subRows?[r.key] ?? const <StatsTableSubRow>[])
                        DataRow(
                          color: i.isOdd ? WidgetStatePropertyAll(groupShade) : null,
                          cells: [
                            DataCell(subLabelCell(sub)),
                            if (!onlyTotal)
                              DataCell(numCell(format(sub.past, sub.raw?.past), style: subStyle)),
                            if (!onlyTotal)
                              DataCell(numCell(format(sub.future, sub.raw?.future), style: subStyle)),
                            DataCell(numCell(format(sub.past + sub.future, rawTotal(sub.raw)), style: subStyle)),
                          ],
                        ),
                    ],
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}

/// Detail line of a [StatsTableChart] entry. [raw] holds raw seconds for
/// durations (formatted with `rawValueFormatter`).
typedef StatsTableSubRow = ({
  Widget icon,
  Color color,
  String label,
  double past,
  double future,
  ({double past, double future})? raw,
});
