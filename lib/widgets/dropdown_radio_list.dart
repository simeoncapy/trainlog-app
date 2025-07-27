import 'package:flutter/material.dart';

class MultiLevelItem {
  final String title;
  final List<String> subItems;

  MultiLevelItem({required this.title, required this.subItems});
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
    selectedTopLevelIndex = widget.selectedTopIndex;
    subSelections = widget.items.asMap().entries.map((entry) {
      final i = entry.key;
      final item = entry.value;
      if (widget.selectedSubStates != null && widget.selectedSubStates!.containsKey(i)) {
        return List<bool>.from(widget.selectedSubStates![i]!);
      } else {
        return List<bool>.filled(item.subItems.length, false);
      }
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
    child:
      Column(
      children: [
        // Top-level dropdown
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
                Text(
                  selectedTopLevelIndex == null
                      ? "Select an item"
                      : widget.items[selectedTopLevelIndex!].title,
                ),
                Icon(isExpanded ? Icons.arrow_drop_up : Icons.arrow_drop_down),
              ],
            ),
          ),
        ),

        // Dropdown content
        if (isExpanded)
          ...List.generate(widget.items.length, (index) {
            final isSelected = selectedTopLevelIndex == index;

            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                ListTile(
                  leading: Radio<int>(
                    value: index,
                    groupValue: selectedTopLevelIndex,
                    onChanged: (value) {
                      setState(() {
                        selectedTopLevelIndex = value;
                        if (value != 3) isExpanded = false;
                      });
                      widget.onChanged(index, subSelections[index]);
                    },
                  ),
                  title: Text(widget.items[index].title),
                  onTap: () {
                    setState(() {
                      selectedTopLevelIndex = index;
                      if (index != 3) isExpanded = false; // Collapsing for other than "years..."
                    });
                    widget.onChanged(index, subSelections[index]);
                  },
                ),
                if (isSelected)
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
                              widget.onChanged(index, subSelections[index]);
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
    )
    );
  }
}
