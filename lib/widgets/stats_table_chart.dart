import 'package:flutter/material.dart';

/// Displays stats as a table: Label | Past | Future | Total
/// `stats`: label -> (past, future)
class StatsTableChart extends StatelessWidget {
  const StatsTableChart({
    super.key,
    required this.stats,
    required this.valueFormatter,        // (num) -> String
    this.labelHeader = 'Label',
    this.pastHeader = 'Past',
    this.futureHeader = 'Future',
    this.totalHeader = 'Total',
    this.labelMaxWidth = 220,
    this.labelMaxLines,                  // null = unlimited
    this.compact = true,                 // shrink rows to content
  });

  final Map<String, ({double past, double future})> stats;
  final String Function(num value) valueFormatter;

  final String labelHeader, pastHeader, futureHeader, totalHeader;
  final double labelMaxWidth;
  final int? labelMaxLines;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final rowsData = stats.entries
        .map((e) => (label: e.key, past: e.value.past, future: e.value.future))
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
                style: Theme.of(context).textTheme.titleSmall ?? const TextStyle(),
                child: child,
              )
            : child,
      );
    }

    Widget numCell(num v) =>
        Align(alignment: Alignment.centerRight, child: Text(valueFormatter(v)));

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: DataTableTheme(
        data: DataTableTheme.of(context).copyWith(
            headingRowColor: WidgetStateProperty.resolveWith<Color?>(
              (Set<WidgetState> states) =>
                  Theme.of(context).colorScheme.primaryContainer,
            ),
            headingTextStyle: Theme.of(context).textTheme.labelLarge?.copyWith(
                  color: Theme.of(context).colorScheme.onPrimaryContainer,
                  fontWeight: FontWeight.bold,
                ),
          ),
        child: DataTable(
          // display-only: no selection, no checkbox column
          showCheckboxColumn: false,
          dataRowMinHeight: compact ? 0 : null,
          dataRowMaxHeight: null,   // allow wrapping to grow
          headingRowHeight: compact ? 36 : null,
          horizontalMargin: compact ? 12 : null,
          columnSpacing: compact ? 16 : null,
          columns: [
            DataColumn(label: labelCell(labelHeader, header: true)),
            DataColumn(label: Text(pastHeader)),
            DataColumn(label: Text(futureHeader)),
            DataColumn(label: Text(totalHeader)),
          ],
          rows: [
            for (final r in rowsData)
              DataRow(
                // no onSelectChanged, purely read-only
                cells: [
                  DataCell(labelCell(r.label)),
                  DataCell(numCell(r.past)),
                  DataCell(numCell(r.future)),
                  DataCell(numCell(r.past + r.future)),
                ],
              ),
          ],
        ),
      ),
    );
  }
}
