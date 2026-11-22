import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:trainlog_app/core/data/models/trips_filter.dart';
import 'package:trainlog_app/features/trips/search_filter_sheet/sheet_common.dart';
import 'package:trainlog_app/l10n/app_localizations.dart';
import 'package:trainlog_app/ui/cupertino/glass_filter_parts.dart';
import 'package:intl/intl.dart';
import 'package:liquid_glass_widgets/liquid_glass_widgets.dart' as lg;
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
    this.onCustomSelected,
  });

  final TripsQuickDateFilter? quickFilter;
  final DateTime? fromDate;
  final DateTime? toDate;
  final ValueChanged<TripsQuickDateFilter> onQuickFilterSelected;
  final ValueChanged<DateTime?> onFromDateChanged;
  final ValueChanged<DateTime?> onToDateChanged;

  /// Apple: "Custom…" picked in the period menu. The parent clears the quick
  /// filter so the From / To rows show.
  final VoidCallback? onCustomSelected;

  bool get _isExactDate => fromDate != null && toDate == null;

  @override
  Widget build(BuildContext context) {
    if (AppPlatform.isApple) return _buildApple(context);
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
        SheetSectionTitle(text: l10n.tripsSearchFilterWhen),
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

  /// Apple: a "Period" row opening a Liquid Glass menu (quick ranges, then
  /// "Custom…"); with Custom, From / To rows with compact date buttons as in
  /// Calendar. A null quick filter means Custom.
  Widget _buildApple(BuildContext context) {
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
        GlassFormGroup(children: [
          GlassFormMenuRow<TripsQuickDateFilter?>(
            title: l10n.mapFilterTimeRange,
            selected: quickFilter,
            onChanged: (v) =>
                v == null ? onCustomSelected?.call() : onQuickFilterSelected(v),
            choices: [
              GlassMenuChoice(
                  value: TripsQuickDateFilter.allTime,
                  label: l10n.tripsSearchFilterAllTime),
              GlassMenuChoice(
                  value: TripsQuickDateFilter.future,
                  label: l10n.yearFutureList),
              GlassMenuChoice(
                  value: TripsQuickDateFilter.thisYear,
                  label: l10n.tripsSearchFilterThisYear),
              GlassMenuChoice(
                  value: TripsQuickDateFilter.past30Days,
                  label: l10n.tripsSearchFilterPast30Days),
              GlassMenuChoice(
                  value: TripsQuickDateFilter.previousYear,
                  label: '$previousYear'),
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
              title: _isExactDate
                  ? l10n.tripsSearchFilterOn
                  : l10n.tripsSearchFilterFrom,
              trailing: GlassDateButton(
                text: dateText(fromDate),
                isSet: fromDate != null,
                onTap: () => _pickDate(context, isFrom: true),
                onClear: fromDate == null ? null : () => onFromDateChanged(null),
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
        ]),
        if (isCustom && _isExactDate)
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
    final now = DateTime.now();
    final initial =
        isFrom ? (fromDate ?? now) : (toDate ?? fromDate ?? now);
    final minimum = isFrom ? DateTime(1900) : (fromDate ?? DateTime(1900));

    final DateTime? picked;
    if (AppPlatform.isApple) {
      picked = await _pickDateGlassCalendar(context,
          initial: initial, minimum: minimum);
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

  /// iOS: the graphical calendar of the compact date picker, in a popover
  /// card. Tapping a day picks it and closes; tapping outside cancels.
  Future<DateTime?> _pickDateGlassCalendar(
    BuildContext context, {
    required DateTime initial,
    required DateTime minimum,
  }) async {
    final locale = Localizations.localeOf(context).toString();
    final effectiveInitial = initial.isBefore(minimum) ? minimum : initial;
    // Flutter: 0 = Sunday; the picker: 7 = Sunday, 1 = Monday.
    final first = MaterialLocalizations.of(context).firstDayOfWeekIndex;
    final firstDayOfWeek = first == 0 ? 7 : first;
    final monthNames = [
      for (int m = 1; m <= 12; m++)
        _capitalize(DateFormat.MMMM(locale).format(DateTime(2024, m, 1))),
    ];
    // 2024-01-07 is a Sunday; shift to the first day of the week.
    final weekdayNames = [
      for (int i = 0; i < 7; i++)
        DateFormat.E(locale)
            .format(DateTime(2024, 1, 7 + (first + i) % 7))
            .toUpperCase(),
    ];

    DateTime? picked;
    await showGeneralDialog<void>(
      context: context,
      useRootNavigator: true,
      barrierDismissible: true,
      barrierLabel: MaterialLocalizations.of(context).modalBarrierDismissLabel,
      barrierColor: const Color(0x14000000),
      transitionDuration: const Duration(milliseconds: 220),
      transitionBuilder: (ctx, anim, _, child) => FadeTransition(
        opacity: anim,
        child: ScaleTransition(
          scale: Tween(begin: 0.92, end: 1.0).animate(
              CurvedAnimation(parent: anim, curve: Curves.easeOutCubic)),
          child: child,
        ),
      ),
      pageBuilder: (ctx, _, __) => Center(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 380),
            child: lg.GlassDatePicker(
              initialDateTime: effectiveInitial,
              minimumDate: minimum,
              maximumDate: DateTime(2200),
              tintColor: CupertinoTheme.of(context).primaryColor,
              firstDayOfWeek: firstDayOfWeek,
              monthNames: monthNames,
              weekdayNames: weekdayNames,
              surfaceStyle: lg.GlassSurfaceStyle.solid,
              // Fires only when a day is tapped: pick it and close, as the
              // iOS compact date picker does.
              onDateTimeChanged: (d) {
                picked = d;
                Navigator.of(ctx, rootNavigator: true).maybePop();
              },
            ),
          ),
        ),
      ),
    );
    return picked;
  }

  static String _capitalize(String s) =>
      s.isEmpty ? s : s[0].toUpperCase() + s.substring(1);
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
