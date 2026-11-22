import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:trainlog_app/core/data/models/trips_filter.dart';
import 'package:trainlog_app/features/trips/search_filter_sheet/when_section.dart';
import 'package:trainlog_app/l10n/app_localizations.dart';
import 'package:trainlog_app/ui/cupertino/glass_date_popover.dart';
import 'package:trainlog_app/ui/cupertino/glass_filter_parts.dart';
import 'package:trainlog_app/utils/date_utils.dart';

/// "When" section, iOS: a "Period" row opening a Liquid Glass menu (quick
/// ranges, then "Custom…"); with Custom, From / To rows with compact date
/// buttons as in Calendar. A null quick filter means Custom. See
/// [WhenSectionInputs].
class CupertinoWhenSection extends StatelessWidget with WhenSectionInputs {
  const CupertinoWhenSection({
    super.key,
    required this.quickFilter,
    required this.fromDate,
    required this.toDate,
    required this.onQuickFilterSelected,
    required this.onFromDateChanged,
    required this.onToDateChanged,
    this.onCustomSelected,
  });

  @override
  final TripsQuickDateFilter? quickFilter;
  @override
  final DateTime? fromDate;
  @override
  final DateTime? toDate;
  @override
  final ValueChanged<TripsQuickDateFilter> onQuickFilterSelected;
  @override
  final ValueChanged<DateTime?> onFromDateChanged;
  @override
  final ValueChanged<DateTime?> onToDateChanged;

  /// "Custom…" picked in the period menu. The parent clears the quick
  /// filter so the From / To rows show.
  final VoidCallback? onCustomSelected;

  /// Apple: a "Period" row opening a Liquid Glass menu (quick ranges, then
  /// "Custom…"); with Custom, From / To rows with compact date buttons as in
  /// Calendar. A null quick filter means Custom.
  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final previousYear = DateTime.now().year - 1;
    final isCustom = quickFilter == null;

    String dateText(DateTime? d) => d == null
        ? l10n.tripsSearchFilterNoDate
        : formatDateTime(context, d, hasTime: false);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: [
        GlassFormGroup(
          children: [
            GlassFormMenuRow<TripsQuickDateFilter?>(
              title: l10n.mapFilterTimeRange,
              selected: quickFilter,
              onChanged: (v) => v == null
                  ? onCustomSelected?.call()
                  : onQuickFilterSelected(v),
              choices: [
                GlassMenuChoice(
                  value: TripsQuickDateFilter.allTime,
                  label: l10n.tripsSearchFilterAllTime,
                ),
                GlassMenuChoice(
                  value: TripsQuickDateFilter.future,
                  label: l10n.yearFutureList,
                ),
                GlassMenuChoice(
                  value: TripsQuickDateFilter.thisYear,
                  label: l10n.tripsSearchFilterThisYear,
                ),
                GlassMenuChoice(
                  value: TripsQuickDateFilter.past30Days,
                  label: l10n.tripsSearchFilterPast30Days,
                ),
                GlassMenuChoice(
                  value: TripsQuickDateFilter.previousYear,
                  label: '$previousYear',
                ),
                GlassMenuChoice<TripsQuickDateFilter?>(
                  value: null,
                  label: l10n.tripsSearchFilterCustom,
                  menuLabel: l10n.tripsSearchFilterCustomMenu,
                  menuIcon: CupertinoIcons.calendar,
                  dividerBefore: true,
                ),
              ],
            ),
            if (isCustom) ...[
              GlassFormRow(
                title: isExactDate
                    ? l10n.tripsSearchFilterOn
                    : l10n.tripsSearchFilterFrom,
                trailing: GlassDateButton(
                  text: dateText(fromDate),
                  isSet: fromDate != null,
                  onTap: () => _pickDate(context, isFrom: true),
                  onClear: fromDate == null
                      ? null
                      : () => onFromDateChanged(null),
                ),
              ),
              GlassFormRow(
                title: l10n.tripsSearchFilterTo,
                trailing: GlassDateButton(
                  text: dateText(toDate),
                  isSet: toDate != null,
                  onTap: () => _pickDate(context, isFrom: false),
                  onClear: toDate == null ? null : () => onToDateChanged(null),
                ),
              ),
            ],
          ],
        ),
        if (isCustom && isExactDate)
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
            child: Text(
              l10n.tripsSearchFilterOnHelper,
              style: TextStyle(
                fontSize: 13,
                color: CupertinoColors.secondaryLabel.resolveFrom(context),
              ),
            ),
          ),
      ],
    );
  }

  Future<void> _pickDate(BuildContext context, {required bool isFrom}) async {
    final bounds = pickBounds(isFrom: isFrom);
    final picked = await showGlassDatePopover(
      context,
      initial: bounds.initial,
      minimum: bounds.minimum,
    );
    applyPicked(picked, isFrom: isFrom);
  }
}
