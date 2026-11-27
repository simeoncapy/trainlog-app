import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart' show Theme;
import 'package:provider/provider.dart';

import 'package:trainlog_app/core/providers/statistics_provider.dart';
import 'package:trainlog_app/features/statistics/statistics_chart.dart';
import 'package:trainlog_app/features/statistics/widgets/stats_figure_text.dart';
import 'package:trainlog_app/features/statistics/widgets/stats_table_chart.dart';
import 'package:trainlog_app/l10n/app_localizations.dart';
import 'package:trainlog_app/ui/cupertino/app_grouped_list.dart';
import 'package:trainlog_app/ui/tokens/app_theme.dart';

/// The table view on iOS: an inset grouped list, one row per entry with its
/// total trailing and past / future under the name. With all modes, a row
/// opens to show the detail per mode.
class StatisticsTableCupertino extends StatelessWidget {
  const StatisticsTableCupertino({super.key, required this.data});

  final StatisticsTableData data;

  @override
  Widget build(BuildContext context) {
    final labelOf = context.read<StatisticsProvider>().labelBuilder(context);
    return AppGroupedSection(
      children: [
        for (final e in data.stats.entries)
          _EntryRow(
            label: labelOf?.call(e.key) ?? e.key,
            value: e.value,
            raw: data.raw?[e.key],
            subRows: data.subRows?[e.key] ?? const [],
            data: data,
          ),
      ],
    );
  }
}

class _EntryRow extends StatefulWidget {
  const _EntryRow({
    required this.label,
    required this.value,
    required this.raw,
    required this.subRows,
    required this.data,
  });

  final String label;
  final ({double past, double future}) value;
  final ({double past, double future})? raw;
  final List<StatsTableSubRow> subRows;
  final StatisticsTableData data;

  @override
  State<_EntryRow> createState() => _EntryRowState();
}

class _EntryRowState extends State<_EntryRow> {
  bool _open = false;

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context)!;
    final text = Theme.of(context).textTheme;
    final label = CupertinoColors.label.resolveFrom(context);
    final secondary = CupertinoColors.secondaryLabel.resolveFrom(context);
    final format = widget.data.format;
    final v = widget.value;
    final raw = widget.raw;
    final canOpen = widget.subRows.isNotEmpty;

    final mono = AppTheme.monoFont.copyWith(fontSize: 15, color: label);
    final smallMono = AppTheme.monoFont.copyWith(
      fontSize: 12,
      color: secondary,
    );

    String pastFuture(
      ({double past, double future}) v,
      ({double past, double future})? raw,
    ) =>
        '${loc.yearPastList} ${format(v.past, raw?.past)} · '
        '${loc.yearFutureList} ${format(v.future, raw?.future)}';

    final subtitle = widget.data.onlyTotal
        ? null
        : Text.rich(
            statsFigureSpans(pastFuture(v, raw), mono: smallMono),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          );

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        AppListTile(
          title: Text(
            widget.label,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
          subtitle: subtitle,
          boldTitle: false,
          onTap: canOpen ? () => setState(() => _open = !_open) : null,
          trailing: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text.rich(
                statsFigureSpans(
                  format(
                    v.past + v.future,
                    raw == null ? null : raw.past + raw.future,
                  ),
                  mono: mono,
                ),
              ),
              if (canOpen) ...[
                const SizedBox(width: 8),
                AnimatedRotation(
                  turns: _open ? 0.25 : 0,
                  duration: const Duration(milliseconds: 200),
                  child: Icon(
                    CupertinoIcons.chevron_forward,
                    size: 15,
                    color: CupertinoColors.tertiaryLabel.resolveFrom(context),
                  ),
                ),
              ],
            ],
          ),
        ),
        AnimatedSize(
          duration: const Duration(milliseconds: 200),
          curve: Curves.easeOut,
          alignment: Alignment.topCenter,
          child: !_open
              ? const SizedBox(width: double.infinity)
              : Padding(
                  padding: const EdgeInsets.fromLTRB(16, 0, 16, 10),
                  child: Column(
                    children: [
                      for (final sub in widget.subRows)
                        Padding(
                          padding: const EdgeInsets.symmetric(vertical: 5),
                          child: Row(
                            children: [
                              IconTheme(
                                data: IconThemeData(size: 16, color: sub.color),
                                child: sub.icon,
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  sub.label,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: text.bodyMedium?.copyWith(
                                    color: secondary,
                                    letterSpacing: 0,
                                  ),
                                ),
                              ),
                              Text.rich(
                                statsFigureSpans(
                                  format(
                                    sub.past + sub.future,
                                    sub.raw == null
                                        ? null
                                        : sub.raw!.past + sub.raw!.future,
                                  ),
                                  mono: smallMono.copyWith(fontSize: 13),
                                ),
                              ),
                              // Lines up with the entry's total, left of the chevron.
                              const SizedBox(width: 23),
                            ],
                          ),
                        ),
                    ],
                  ),
                ),
        ),
      ],
    );
  }
}
