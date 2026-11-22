import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:trainlog_app/features/trips/search_filter_sheet/group_picker_view.dart';
import 'package:trainlog_app/l10n/app_localizations.dart';
import 'package:trainlog_app/ui/adaptive/adaptive_search_field.dart';
import 'package:trainlog_app/ui/cupertino/glass_filter_parts.dart';
import 'package:trainlog_app/ui/cupertino/liquid_glass.dart';

/// Country / operator picker, iOS 26: glass back / title / glass ✓ bar,
/// search field, sentence-case header with Select All / Deselect All, and
/// an inset grouped list with a check mark on the selected rows (as in iOS
/// Settings pickers).
class CupertinoGroupPicker extends StatelessWidget {
  const CupertinoGroupPicker({super.key, required this.view});

  final GroupPickerViewData view;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final p = view.picker;
    final filtered = view.filtered;
    final allSelected =
        p.entries.isNotEmpty &&
        p.entries.every((e) => p.selectedValues.contains(e.value));
    final cell = Theme.of(context).colorScheme.surface;
    final separator = CupertinoColors.separator.resolveFrom(context);
    final tint = CupertinoTheme.of(context).primaryColor;
    const radius = Radius.circular(GlassFormGroup.radius);

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(14, 2, 14, 8),
          child: Row(
            children: [
              GlassIconButton(
                icon: CupertinoIcons.chevron_back,
                shadow: false,
                tooltip: MaterialLocalizations.of(context).backButtonTooltip,
                onPressed: p.onDone,
              ),
              Expanded(
                child: Text(
                  p.title,
                  textAlign: TextAlign.center,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 17,
                    fontWeight: FontWeight.w600,
                    color: CupertinoColors.label.resolveFrom(context),
                  ),
                ),
              ),
              // Plain glass "Done", matching the back button (a tinted glass
              // turns pale yellow in light mode and dark red in dark mode).
              GlassIconButton(
                icon: CupertinoIcons.checkmark,
                shadow: false,
                tooltip: l10n.tripsSearchFilterDone,
                onPressed: p.onDone,
              ),
            ],
          ),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 4, 16, 12),
          child: AdaptiveSearchField(
            controller: view.searchController,
            placeholder: p.searchPlaceholder,
          ),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 6),
          child: GlassFilterSectionHeader(
            title: p.subHeadline,
            actionLabel: allSelected
                ? l10n.filterDeselectAll
                : l10n.filterSelectAll,
            onAction: allSelected ? p.onSelectNone : p.onSelectAll,
          ),
        ),
        Expanded(
          child: ListView.builder(
            controller: view.scrollController,
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
            itemCount: filtered.length,
            itemBuilder: (context, index) {
              final entry = filtered[index];
              final selected = p.selectedValues.contains(entry.value);
              final first = index == 0;
              final last = index == filtered.length - 1;
              return ClipRRect(
                borderRadius: BorderRadius.vertical(
                  top: first ? radius : Radius.zero,
                  bottom: last ? radius : Radius.zero,
                ),
                child: ColoredBox(
                  color: cell,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      if (!first)
                        Padding(
                          padding: EdgeInsetsDirectional.only(
                            start: entry.leading != null ? 62 : 16,
                          ),
                          child: Container(height: 0.5, color: separator),
                        ),
                      GlassFormRow(
                        title: entry.label,
                        leading: entry.leading == null
                            ? null
                            : SizedBox(
                                width: 34,
                                child: Center(child: entry.leading!),
                              ),
                        onTap: () => p.onToggle(entry.value, !selected),
                        trailing: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              '${entry.tripCount}',
                              style: TextStyle(
                                fontSize: 15,
                                color: CupertinoColors.secondaryLabel
                                    .resolveFrom(context),
                              ),
                            ),
                            SizedBox(
                              width: 30,
                              child: selected
                                  ? Icon(
                                      CupertinoIcons.checkmark,
                                      size: 18,
                                      color: tint,
                                    )
                                  : null,
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }
}
