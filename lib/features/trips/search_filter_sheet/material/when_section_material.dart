import 'package:flutter/material.dart';
import 'package:trainlog_app/core/data/models/trips_filter.dart';
import 'package:trainlog_app/features/trips/search_filter_sheet/sheet_common.dart';
import 'package:trainlog_app/features/trips/search_filter_sheet/when_section.dart';
import 'package:trainlog_app/l10n/app_localizations.dart';
import 'package:trainlog_app/utils/date_utils.dart';

/// "When" section, Material: quick-range pills and FROM / TO date tiles
/// opening the Material date picker. See [WhenSectionInputs].
class MaterialWhenSection extends StatelessWidget with WhenSectionInputs {
  const MaterialWhenSection({
    super.key,
    required this.quickFilter,
    required this.fromDate,
    required this.toDate,
    required this.onQuickFilterSelected,
    required this.onFromDateChanged,
    required this.onToDateChanged,
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
                label: isExactDate
                    ? l10n.tripsSearchFilterOn
                    : l10n.tripsSearchFilterFrom,
                date: fromDate,
                highlighted: isExactDate,
                onTap: () => _pickDate(context, isFrom: true),
                onClear: fromDate == null
                    ? null
                    : () => onFromDateChanged(null),
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
        if (isExactDate) ...[
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
    final bounds = pickBounds(isFrom: isFrom);
    final picked = await showDatePicker(
      context: context,
      initialDate: bounds.initial,
      firstDate: bounds.minimum,
      lastDate: DateTime(2200),
    );
    applyPicked(picked, isFrom: isFrom);
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
    final display = date != null
        ? formatDateTime(context, date!, hasTime: false)
        : '—';

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
            Icon(Icons.calendar_today_outlined, size: 17, color: cs.primary),
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
                    Icons.cancel,
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
