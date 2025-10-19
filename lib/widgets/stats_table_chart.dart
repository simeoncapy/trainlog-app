import 'package:flutter/material.dart';

/// Displays stats as a table: Label | Past | Future | Total
/// `stats`: key -> (past, future)
/// Optionally supports time (duration) humanization.
class StatsTableChart extends StatelessWidget {
  const StatsTableChart({
    super.key,
    required this.stats,
    required this.valueFormatter,        // (num) -> String
    this.labelBuilder,                   // (key) -> display label
    this.labelHeader = 'Label',
    this.pastHeader = 'Past',
    this.futureHeader = 'Future',
    this.totalHeader = 'Total',
    this.labelMaxWidth = 220,
    this.labelMaxLines,                  // null = unlimited
    this.compact = true,                 // shrink rows to content
    this.onlyTotal = false,
    this.rawValues,                      // same keys as stats, in seconds for duration
    this.rawValueFormatter,              // (context, seconds) -> humanized string
    this.isDuration = false,             // automatically use duration formatting
  });

  final Map<String, ({double past, double future})> stats;
  final String Function(num value) valueFormatter;
  final String Function(String key)? labelBuilder;

  final String labelHeader, pastHeader, futureHeader, totalHeader;
  final double labelMaxWidth;
  final int? labelMaxLines;
  final bool compact;
  final bool onlyTotal;

  /// Optional: raw time values in seconds for human formatting
  final Map<String, ({double past, double future})>? rawValues;
  final String Function(BuildContext context, double rawSeconds)? rawValueFormatter;

  /// If true, display durations as “1 year 2 months …”
  final bool isDuration;

  @override
  Widget build(BuildContext context) {
    // Build rows, mapping key -> display label if provided
    final rowsData = stats.entries
        .map((e) => (
              key: e.key,
              label: labelBuilder?.call(e.key) ?? e.key,
              past: e.value.past,
              future: e.value.future,
            ))
        .toList();

    Widget labelCell(String text, {bool header = false}) {
      final child = Text(
        text,
        softWrap: true,
        overflow: TextOverflow.ellipsis,
        maxLines: labelMaxLines,
      );
      return ConstrainedBox(
        constraints: BoxConstraints(maxWidth: labelMaxWidth),
        child: header
            ? DefaultTextStyle.merge(
                style: Theme.of(context).textTheme.titleSmall ??
                    const TextStyle(),
                child: child,
              )
            : child,
      );
    }

    // Helper for formatting each numeric or duration cell
    String _formatValue(String key, num scaledValue, {required bool isFuture}) {
      if (isDuration && rawValues != null && rawValueFormatter != null) {
        final raw = rawValues![key];
        if (raw != null) {
          final rawVal = isFuture ? raw.future : raw.past;
          return rawValueFormatter!(context, rawVal);
        }
      }
      return valueFormatter(scaledValue);
    }

    String _formatTotal(String key, num scaledTotal) {
      if (isDuration && rawValues != null && rawValueFormatter != null) {
        final raw = rawValues![key];
        if (raw != null) {
          final totalRaw = raw.past + raw.future;
          return rawValueFormatter!(context, totalRaw);
        }
      }
      return valueFormatter(scaledTotal);
    }

    Widget numCell(String text) => Align(
        alignment: Alignment.centerRight,
        child: Text(text, softWrap: false));

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
                headingTextStyle: Theme.of(context)
                    .textTheme
                    .labelLarge
                    ?.copyWith(
                      color:
                          Theme.of(context).colorScheme.onPrimaryContainer,
                      fontWeight: FontWeight.bold,
                    ),
              ),
              child: DataTable(
                showCheckboxColumn: false,
                dataRowMinHeight: compact ? 0 : null,
                dataRowMaxHeight: null,
                headingRowHeight: compact ? 36 : null,
                horizontalMargin: compact ? 12 : null,
                columnSpacing: compact ? 16 : null,
                columns: [
                  DataColumn(label: labelCell(labelHeader, header: true)),
                  if (!onlyTotal) DataColumn(label: Text(pastHeader)),
                  if (!onlyTotal) DataColumn(label: Text(futureHeader)),
                  DataColumn(label: Text(totalHeader)),
                ],
                rows: [
                  for (final r in rowsData)
                    DataRow(
                      cells: [
                        DataCell(labelCell(r.label)),
                        if (!onlyTotal)
                          DataCell(
                            numCell(
                              _formatValue(r.key, r.past, isFuture: false),
                            ),
                          ),
                        if (!onlyTotal)
                          DataCell(
                            numCell(
                              _formatValue(r.key, r.future, isFuture: true),
                            ),
                          ),
                        DataCell(numCell(_formatTotal(r.key, r.past + r.future))),
                      ],
                    ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}
