import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:trainlog_app/data/models/trips_filter.dart';
import 'package:trainlog_app/features/trips/search_filter_sheet/sheet_common.dart';
import 'package:trainlog_app/l10n/app_localizations.dart';
import 'package:trainlog_app/utils/date_utils.dart';
import 'package:trainlog_app/utils/platform_utils.dart';

/// "When" section of the trips search & filter sheet.
///
/// Shows a row of mutually exclusive quick-filter chips (All time, Future,
/// This year, Past 30 days, previous year) plus custom FROM / TO date pickers.
/// The two mechanisms are exclusive: the parent callbacks are expected to
/// clear the custom dates when a chip is selected, and to deselect the chip
/// when a custom date is picked (see [TripsSearchFilterSheet]).
///
/// When only FROM is set the filter matches that exact day, and the field's
/// label switches from "From" to "On" to make this visible.
class WhenSection extends StatelessWidget {
  const WhenSection({
    super.key,
    required this.quickFilter,
    required this.fromDate,
    required this.toDate,
    required this.onQuickFilterSelected,
    required this.onFromDateChanged,
    required this.onToDateChanged,
  });

  final TripsQuickDateFilter? quickFilter;
  final DateTime? fromDate;
  final DateTime? toDate;
  final ValueChanged<TripsQuickDateFilter> onQuickFilterSelected;
  final ValueChanged<DateTime?> onFromDateChanged;
  final ValueChanged<DateTime?> onToDateChanged;

  bool get _isExactDate => fromDate != null && toDate == null;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final cs = Theme.of(context).colorScheme;
    final previousYear = DateTime.now().year - 1;

    final quickChips = <(TripsQuickDateFilter, String)>[
      (TripsQuickDateFilter.allTime, l10n.tripsSearchFilterAllTime),
      (TripsQuickDateFilter.future, l10n.yearFutureList),
      (TripsQuickDateFilter.thisYear, l10n.tripsSearchFilterThisYear),
      (TripsQuickDateFilter.past30Days, l10n.tripsSearchFilterPast30Days),
      (TripsQuickDateFilter.previousYear, '$previousYear'),
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SheetSectionTitle(
          text: l10n.tripsSearchFilterWhen,
          trailing: Text(
            l10n.tripsSearchFilterCustom,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: cs.onSurfaceVariant,
            ),
          ),
        ),
        const SizedBox(height: 10),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            for (final (value, label) in quickChips)
              SheetChoicePill(
                label: label,
                selected: quickFilter == value,
                onTap: () => onQuickFilterSelected(value),
              ),
          ],
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: _DateTile(
                label: _isExactDate
                    ? l10n.tripsSearchFilterOn
                    : l10n.tripsSearchFilterFrom,
                date: fromDate,
                highlighted: _isExactDate,
                onTap: () => _pickDate(context, isFrom: true),
                onClear:
                    fromDate == null ? null : () => onFromDateChanged(null),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: _DateTile(
                label: l10n.tripsSearchFilterTo,
                date: toDate,
                onTap: () => _pickDate(context, isFrom: false),
                onClear: toDate == null ? null : () => onToDateChanged(null),
              ),
            ),
          ],
        ),
        if (_isExactDate) ...[
          const SizedBox(height: 6),
          Text(
            l10n.tripsSearchFilterOnHelper,
            style: TextStyle(
              fontSize: 12,
              fontStyle: FontStyle.italic,
              color: cs.onSurfaceVariant,
            ),
          ),
        ],
      ],
    );
  }

  Future<void> _pickDate(BuildContext context, {required bool isFrom}) async {
    final now = DateTime.now();
    final initial =
        isFrom ? (fromDate ?? now) : (toDate ?? fromDate ?? now);
    final minimum = isFrom ? DateTime(1900) : (fromDate ?? DateTime(1900));

    final DateTime? picked;
    if (AppPlatform.isApple) {
      picked = await _pickDateCupertino(context, initial: initial, minimum: minimum);
    } else {
      picked = await showDatePicker(
        context: context,
        initialDate: initial.isBefore(minimum) ? minimum : initial,
        firstDate: minimum,
        lastDate: DateTime(2200),
      );
    }

    if (picked == null) return;
    if (isFrom) {
      onFromDateChanged(picked);
      // Keep the range consistent: drop a TO date earlier than the new FROM.
      if (toDate != null && toDate!.isBefore(picked)) {
        onToDateChanged(null);
      }
    } else {
      onToDateChanged(picked);
    }
  }

  Future<DateTime?> _pickDateCupertino(
    BuildContext context, {
    required DateTime initial,
    required DateTime minimum,
  }) {
    final effectiveInitial = initial.isBefore(minimum) ? minimum : initial;
    DateTime temp = effectiveInitial;

    return showCupertinoModalPopup<DateTime>(
      context: context,
      useRootNavigator: true,
      builder: (sheetCtx) => Container(
        color: CupertinoColors.systemBackground.resolveFrom(sheetCtx),
        child: SafeArea(
          top: false,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  CupertinoButton(
                    child: Text(
                        MaterialLocalizations.of(context).cancelButtonLabel),
                    onPressed: () =>
                        Navigator.of(sheetCtx, rootNavigator: true).pop(),
                  ),
                  CupertinoButton(
                    child:
                        Text(MaterialLocalizations.of(context).okButtonLabel),
                    onPressed: () =>
                        Navigator.of(sheetCtx, rootNavigator: true).pop(temp),
                  ),
                ],
              ),
              SizedBox(
                height: 220,
                child: CupertinoDatePicker(
                  mode: CupertinoDatePickerMode.date,
                  initialDateTime: effectiveInitial,
                  minimumDate: minimum,
                  maximumDate: DateTime(2200),
                  onDateTimeChanged: (dt) => temp = dt,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _DateTile extends StatelessWidget {
  const _DateTile({
    required this.label,
    required this.date,
    required this.onTap,
    this.onClear,
    this.highlighted = false,
  });

  final String label;
  final DateTime? date;
  final VoidCallback onTap;
  final VoidCallback? onClear;
  final bool highlighted;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final display =
        date != null ? formatDateTime(context, date!, hasTime: false) : '—';

    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(
          color: cs.surfaceContainerHighest.withValues(alpha: 0.5),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: highlighted || date != null
                ? cs.primary
                : cs.outline.withValues(alpha: 0.4),
            width: highlighted ? 1.6 : 1,
          ),
        ),
        child: Row(
          children: [
            Icon(
              AppPlatform.isApple
                  ? CupertinoIcons.calendar
                  : Icons.calendar_today_outlined,
              size: 17,
              color: cs.primary,
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    label.toUpperCase(),
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 0.8,
                      color: cs.onSurfaceVariant,
                    ),
                  ),
                  Text(
                    display,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: date != null ? cs.onSurface : cs.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ),
            if (onClear != null)
              GestureDetector(
                onTap: onClear,
                behavior: HitTestBehavior.opaque,
                child: Padding(
                  padding: const EdgeInsets.only(left: 4),
                  child: Icon(
                    AppPlatform.isApple
                        ? CupertinoIcons.xmark_circle_fill
                        : Icons.cancel,
                    size: 16,
                    color: cs.onSurfaceVariant.withValues(alpha: 0.7),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
