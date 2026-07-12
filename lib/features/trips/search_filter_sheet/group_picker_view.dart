import 'package:diacritic/diacritic.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:trainlog_app/features/trips/search_filter_sheet/filter_group_section.dart';
import 'package:trainlog_app/features/trips/search_filter_sheet/sheet_common.dart';
import 'package:trainlog_app/l10n/app_localizations.dart';
import 'package:trainlog_app/utils/platform_utils.dart';

/// Secondary picker view of the search & filter sheet, used to select the
/// countries or operators of the filter (the "granular metadata categories").
///
/// Layout follows the design mock: header with back / Done, a search field,
/// the current selection as removable chips, then the full list — ordered by
/// trip count — under the "ALL … FROM YOUR TRIPS" sub-headline with All/None
/// shortcuts.
class GroupPickerView extends StatefulWidget {
  const GroupPickerView({
    super.key,
    required this.title,
    required this.searchPlaceholder,
    required this.subHeadline,
    required this.entries,
    required this.selectedValues,
    required this.onToggle,
    required this.onSelectAll,
    required this.onSelectNone,
    required this.onDone,
  });

  final String title;
  final String searchPlaceholder;

  /// Localized "All countries/operators from your trips" copy (rendered
  /// uppercase).
  final String subHeadline;

  /// Every available value, ordered by trip count (descending).
  final List<GroupEntry> entries;
  final Set<String> selectedValues;
  final void Function(String value, bool selected) onToggle;
  final VoidCallback onSelectAll;
  final VoidCallback onSelectNone;
  final VoidCallback onDone;

  @override
  State<GroupPickerView> createState() => _GroupPickerViewState();
}

class _GroupPickerViewState extends State<GroupPickerView> {
  final _searchController = TextEditingController();
  final _scrollController = ScrollController();
  String _query = '';

  @override
  void initState() {
    super.initState();
    _searchController.addListener(() {
      setState(() =>
          _query = removeDiacritics(_searchController.text.trim().toLowerCase()));
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final cs = theme.colorScheme;

    final filtered = _query.isEmpty
        ? widget.entries
        : widget.entries
            .where((e) =>
                removeDiacritics(e.label.toLowerCase()).contains(_query) ||
                e.value.toLowerCase().contains(_query))
            .toList();

    final selectedEntries = widget.entries
        .where((e) => widget.selectedValues.contains(e.value))
        .toList();

    return Column(
      children: [
        // ── Header: back + title + Done ────────────────────────────────────
        Padding(
          padding: const EdgeInsets.fromLTRB(4, 0, 8, 4),
          child: Row(
            children: [
              GestureDetector(
                onTap: widget.onDone,
                behavior: HitTestBehavior.opaque,
                child: Padding(
                  padding: const EdgeInsets.all(8),
                  child: Icon(
                    AppPlatform.isApple
                        ? CupertinoIcons.chevron_left
                        : Icons.arrow_back,
                    size: 22,
                    color: cs.onSurface,
                  ),
                ),
              ),
              const SizedBox(width: 4),
              Expanded(
                child: Text(
                  widget.title,
                  style: theme.textTheme.titleLarge
                      ?.copyWith(fontWeight: FontWeight.w700),
                ),
              ),
              SheetMiniButton(
                label: l10n.tripsSearchFilterDone,
                emphasized: true,
                onTap: widget.onDone,
              ),
            ],
          ),
        ),

        // ── Search ─────────────────────────────────────────────────────────
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 4, 16, 10),
          child: SheetSearchField(
            controller: _searchController,
            placeholder: widget.searchPlaceholder,
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
                      onRemove: () => widget.onToggle(entry.value, false),
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
                  widget.subHeadline.toUpperCase(),
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
                onTap: widget.onSelectAll,
              ),
              const SizedBox(width: 4),
              SheetMiniButton(
                label: l10n.mapFilterVehicleTypeNoneBtn,
                onTap: widget.onSelectNone,
              ),
            ],
          ),
        ),

        // ── List ───────────────────────────────────────────────────────────
        Expanded(
          child: ListView.separated(
            controller: _scrollController,
            padding: const EdgeInsets.fromLTRB(16, 6, 16, 16),
            itemCount: filtered.length,
            separatorBuilder: (_, __) => Divider(
              height: 1,
              color: cs.outline.withValues(alpha: 0.2),
            ),
            itemBuilder: (context, index) {
              final entry = filtered[index];
              final selected = widget.selectedValues.contains(entry.value);
              return GestureDetector(
                onTap: () => widget.onToggle(entry.value, !selected),
                behavior: HitTestBehavior.opaque,
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  child: Row(
                    children: [
                      if (entry.leading != null) ...[
                        SizedBox(width: 40, child: Center(child: entry.leading!)),
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
