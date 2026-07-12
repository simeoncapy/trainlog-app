import 'package:flutter/material.dart';
import 'package:trainlog_app/features/trips/search_filter_sheet/sheet_common.dart';

/// One selectable value of a group (a country or an operator).
class GroupEntry {
  final String value;
  final String label;
  final Widget? leading;
  final int tripCount;

  const GroupEntry({
    required this.value,
    required this.label,
    this.leading,
    this.tripCount = 0,
  });
}

/// Main-sheet section for a multi-select group (Countries / Operators):
/// title with a selected-count badge, the selected values as removable chips
/// and an "+ Add" chip opening the dedicated picker view.
class FilterGroupSection extends StatelessWidget {
  const FilterGroupSection({
    super.key,
    required this.title,
    required this.addLabel,
    required this.selectedEntries,
    required this.onAdd,
    required this.onRemove,
  });

  final String title;
  final String addLabel;
  final List<GroupEntry> selectedEntries;
  final VoidCallback onAdd;
  final ValueChanged<String> onRemove;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SheetSectionTitle(
          text: title,
          trailing: selectedEntries.isEmpty
              ? null
              : SheetCountBadge(count: selectedEntries.length),
        ),
        const SizedBox(height: 10),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            for (final entry in selectedEntries)
              SelectedValueChip(
                label: entry.label,
                leading: entry.leading,
                onRemove: () => onRemove(entry.value),
              ),
            AddValueChip(label: addLabel, onTap: onAdd),
          ],
        ),
      ],
    );
  }
}
