import 'package:flutter/material.dart';
import 'package:trainlog_app/features/trips/search_filter_sheet/group_picker_view.dart';
import 'package:trainlog_app/features/trips/search_filter_sheet/sheet_common.dart';
import 'package:trainlog_app/l10n/app_localizations.dart';
import 'package:trainlog_app/ui/adaptive/adaptive_search_field.dart';

/// Country / operator picker, Material: header with back / Done, a search
/// field, the current selection as removable chips, then the full list under
/// the "ALL … FROM YOUR TRIPS" sub-headline with All / None shortcuts.
class MaterialGroupPicker extends StatelessWidget {
  const MaterialGroupPicker({super.key, required this.view});

  final GroupPickerViewData view;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    final p = view.picker;
    final filtered = view.filtered;
    final selectedEntries = view.selectedEntries;

    return Column(
      children: [
        // ── Header: back + title + Done ────────────────────────────────────
        Padding(
          padding: const EdgeInsets.fromLTRB(4, 0, 8, 4),
          child: Row(
            children: [
              GestureDetector(
                onTap: p.onDone,
                behavior: HitTestBehavior.opaque,
                child: Padding(
                  padding: const EdgeInsets.all(8),
                  child: Icon(Icons.arrow_back, size: 22, color: cs.onSurface),
                ),
              ),
              const SizedBox(width: 4),
              Expanded(
                child: Text(
                  p.title,
                  style: theme.textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              SheetMiniButton(
                label: l10n.tripsSearchFilterDone,
                emphasized: true,
                onTap: p.onDone,
              ),
            ],
          ),
        ),

        // ── Search ─────────────────────────────────────────────────────────
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 4, 16, 10),
          child: AdaptiveSearchField(
            controller: view.searchController,
            placeholder: p.searchPlaceholder,
          ),
        ),

        // ── Current selection — one horizontally scrollable line, so a large
        // selection can never push the list off screen ──────────────────────
        if (selectedEntries.isNotEmpty)
          Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Row(
                children: [
                  for (final entry in selectedEntries) ...[
                    SelectedValueChip(
                      label: entry.label,
                      leading: entry.leading,
                      onRemove: () => p.onToggle(entry.value, false),
                    ),
                    if (entry != selectedEntries.last) const SizedBox(width: 8),
                  ],
                ],
              ),
            ),
          ),

        // ── Sub-headline + All/None ────────────────────────────────────────
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 4, 16, 0),
          child: Row(
            children: [
              Expanded(
                child: Text(
                  p.subHeadline.toUpperCase(),
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 1.1,
                    color: cs.onSurfaceVariant,
                  ),
                ),
              ),
              SheetMiniButton(
                label: l10n.mapFilterVehicleTypeAllBtn,
                emphasized: true,
                onTap: p.onSelectAll,
              ),
              const SizedBox(width: 4),
              SheetMiniButton(
                label: l10n.mapFilterVehicleTypeNoneBtn,
                onTap: p.onSelectNone,
              ),
            ],
          ),
        ),

        // ── List ───────────────────────────────────────────────────────────
        Expanded(
          child: ListView.separated(
            controller: view.scrollController,
            padding: const EdgeInsets.fromLTRB(16, 6, 16, 16),
            itemCount: filtered.length,
            separatorBuilder: (_, __) =>
                Divider(height: 1, color: cs.outline.withValues(alpha: 0.2)),
            itemBuilder: (context, index) {
              final entry = filtered[index];
              final selected = p.selectedValues.contains(entry.value);
              return GestureDetector(
                onTap: () => p.onToggle(entry.value, !selected),
                behavior: HitTestBehavior.opaque,
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  child: Row(
                    children: [
                      if (entry.leading != null) ...[
                        SizedBox(
                          width: 40,
                          child: Center(child: entry.leading!),
                        ),
                        const SizedBox(width: 10),
                      ],
                      Expanded(
                        child: Text(
                          entry.label,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        '${entry.tripCount}',
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: cs.onSurfaceVariant,
                        ),
                      ),
                      const SizedBox(width: 12),
                      SheetCheckIndicator(checked: selected),
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
