import 'dart:ui' show FontFeature;
import 'package:flutter/material.dart';
import 'package:trainlog_app/app/theme/app_theme.dart';

/// Displays stats as a table: Label | Past | Future | Total
/// `stats`: key -> (past, future)
/// Optionally supports time (duration) humanization.
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

    String _formatValue(String key, num scaledValue, {required bool isFuture}) {
      if (isDuration && rawValues != null && rawValueFormatter != null) {
        final raw = rawValues![key];
        if (raw != null) {
          return rawValueFormatter!(context, isFuture ? raw.future : raw.past);
        }
      }
      return valueFormatter(scaledValue);
    }

    String _formatTotal(String key, num scaledTotal) {
      if (isDuration && rawValues != null && rawValueFormatter != null) {
        final raw = rawValues![key];
        if (raw != null) {
          return rawValueFormatter!(context, raw.past + raw.future);
        }
      }
      return valueFormatter(scaledTotal);
    }

    Widget numCell(String text) => Align(
          alignment: Alignment.centerRight,
          child: Text(text, softWrap: false, style: monoStyle),
        );

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
                  for (final r in rowsData)
                    DataRow(
                      cells: [
                        DataCell(labelCell(r.label)),
                        if (!onlyTotal)
                          DataCell(numCell(_formatValue(r.key, r.past, isFuture: false))),
                        if (!onlyTotal)
                          DataCell(numCell(_formatValue(r.key, r.future, isFuture: true))),
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
