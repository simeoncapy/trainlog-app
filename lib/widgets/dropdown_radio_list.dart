import 'package:flutter/material.dart';

class MultiLevelItem {
  final Widget title;
  final Widget? trailing;
  final Widget? selectedTitle;
  final List<String> subItems;

  MultiLevelItem({
    required this.title,
    this.trailing,
    this.selectedTitle,
    required this.subItems,
  });
}

class DropdownRadioList extends StatefulWidget {
  final List<MultiLevelItem> items;
  final int? selectedTopIndex;
  final Map<int, List<bool>>? selectedSubStates;
  final Function(int topIndex, List<bool> subSelections) onChanged;

  const DropdownRadioList({
    super.key,
    required this.items,
    required this.selectedTopIndex,
    this.selectedSubStates,
    required this.onChanged,
  });

  @override
  State<DropdownRadioList> createState() => _DropdownRadioListState();
}

class _DropdownRadioListState extends State<DropdownRadioList> {
  int? selectedTopLevelIndex;
  late List<List<bool>> subSelections;
  bool isExpanded = false;

  @override
  void initState() {
    super.initState();
    _syncFromWidget();
  }

  @override
  void didUpdateWidget(covariant DropdownRadioList oldWidget) {
    super.didUpdateWidget(oldWidget);

    if (oldWidget.selectedTopIndex != widget.selectedTopIndex ||
        oldWidget.selectedSubStates != widget.selectedSubStates ||
        oldWidget.items.length != widget.items.length) {
      _syncFromWidget();
    }
  }

  void _syncFromWidget() {
    selectedTopLevelIndex = widget.selectedTopIndex;
    subSelections = widget.items.asMap().entries.map((entry) {
      final i = entry.key;
      final item = entry.value;

      if (widget.selectedSubStates != null &&
          widget.selectedSubStates!.containsKey(i)) {
        return List<bool>.from(widget.selectedSubStates![i]!);
      }

      return List<bool>.filled(item.subItems.length, false);
    }).toList();
  }

  void _selectTopLevel(int index) {
    setState(() {
      selectedTopLevelIndex = index;
      if (index != 3) {
        isExpanded = false;
      }
    });

    widget.onChanged(index, List<bool>.from(subSelections[index]));
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      child: Column(
        children: [
          GestureDetector(
            onTap: () {
              setState(() {
                isExpanded = !isExpanded;
              });
            },
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                border: Border.all(color: Colors.grey),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: selectedTopLevelIndex == null
                        ? const Text('Select an item')
                        : (widget.items[selectedTopLevelIndex!].selectedTitle ??
                            widget.items[selectedTopLevelIndex!].title),
                  ),
                  Icon(isExpanded ? Icons.arrow_drop_up : Icons.arrow_drop_down),
                ],
              ),
            ),
          ),
          if (isExpanded)
            ...List.generate(widget.items.length, (index) {
              final isSelected = selectedTopLevelIndex == index;

              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    child: Row(
                      children: [
                        Radio<int>(
                          value: index,
                          groupValue: selectedTopLevelIndex,
                          onChanged: (value) {
                            if (value == null) return;
                            _selectTopLevel(value);
                          },
                        ),
                        Expanded(
                          child: InkWell(
                            onTap: () => _selectTopLevel(index),
                            child: Padding(
                              padding: const EdgeInsets.symmetric(vertical: 12),
                              child: widget.items[index].title,
                            ),
                          ),
                        ),
                        if (widget.items[index].trailing != null) ...[
                          const SizedBox(width: 8),
                          widget.items[index].trailing!,
                        ],
                      ],
                    ),
                  ),
                  if (isSelected && widget.items[index].subItems.isNotEmpty)
                    Padding(
                      padding: const EdgeInsets.only(left: 40),
                      child: Wrap(
                        spacing: 8,
                        runSpacing: 4,
                        children: List.generate(
                          widget.items[index].subItems.length,
                          (subIndex) {
                            final selected = subSelections[index][subIndex];

                            return FilterChip(
                              label: Text(widget.items[index].subItems[subIndex]),
                              selected: selected,
                              showCheckmark: false,
                              onSelected: (value) {
                                setState(() {
                                  subSelections[index][subIndex] = value;
                                });

                                widget.onChanged(
                                  index,
                                  List<bool>.from(subSelections[index]),
                                );
                              },
                            );
                          },
                        ),
                      ),
                    ),
                ],
              );
            }),
        ],
      ),
    );
  }
}