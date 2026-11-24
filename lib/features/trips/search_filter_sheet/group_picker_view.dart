import 'package:diacritic/diacritic.dart';
import 'package:flutter/material.dart';
import 'package:trainlog_app/features/trips/search_filter_sheet/filter_group_section.dart';
import 'package:trainlog_app/features/trips/search_filter_sheet/cupertino/group_picker_cupertino.dart';
import 'package:trainlog_app/features/trips/search_filter_sheet/material/group_picker_material.dart';
import 'package:trainlog_app/ui/design.dart';

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
      setState(
        () => _query = removeDiacritics(
          _searchController.text.trim().toLowerCase(),
        ),
      );
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
    final filtered = _query.isEmpty
        ? widget.entries
        : widget.entries
              .where(
                (e) =>
                    removeDiacritics(e.label.toLowerCase()).contains(_query) ||
                    e.value.toLowerCase().contains(_query),
              )
              .toList();

    final view = GroupPickerViewData(
      picker: widget,
      searchController: _searchController,
      scrollController: _scrollController,
      filtered: filtered,
      selectedEntries: widget.entries
          .where((e) => widget.selectedValues.contains(e.value))
          .toList(),
    );
    return PlatformView(
      material: (_) => MaterialGroupPicker(view: view),
      cupertino: (_) => CupertinoGroupPicker(view: view),
    );
  }
}

/// What both renderings of the picker draw: the picker's inputs, its search
/// and scroll state, and the entries to list.
class GroupPickerViewData {
  const GroupPickerViewData({
    required this.picker,
    required this.searchController,
    required this.scrollController,
    required this.filtered,
    required this.selectedEntries,
  });

  final GroupPickerView picker;
  final TextEditingController searchController;
  final ScrollController scrollController;

  /// Entries matching the search, by trip count.
  final List<GroupEntry> filtered;

  /// Entries currently selected.
  final List<GroupEntry> selectedEntries;
}
