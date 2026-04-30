import 'package:flutter/material.dart';
import 'package:trainlog_app/platform/adaptive_segmented_button.dart';

enum StatisticsType { bar, pie, table }

class StatisticsTypeSelector extends StatefulWidget {
  final StatisticsType initialValue;
  final ValueChanged<StatisticsType>? onChanged;

  const StatisticsTypeSelector({super.key, this.initialValue = StatisticsType.bar, this.onChanged});

  @override
  State<StatisticsTypeSelector> createState() => _StatisticsTypeSelectorState();
}

class _StatisticsTypeSelectorState extends State<StatisticsTypeSelector> {
  late StatisticsType statisticsType;

  @override
  void initState() {
    super.initState();
    statisticsType = widget.initialValue;
  }

  @override
  Widget build(BuildContext context) {
    return AdaptiveSegmentedButton.build<StatisticsType>(
      context: context,
      segments: const [
        AdaptiveSegmentedButtonSegment(value: StatisticsType.bar, icon: Icon(Icons.bar_chart)),
        AdaptiveSegmentedButtonSegment(value: StatisticsType.pie, icon: Icon(Icons.pie_chart)),
        AdaptiveSegmentedButtonSegment(value: StatisticsType.table, icon: Icon(Icons.table_chart)),
      ],
      selectedValue: statisticsType,
      onChanged: (newValue) {
        setState(() => statisticsType = newValue);
        widget.onChanged?.call(newValue);
      },
    );
  }
}

