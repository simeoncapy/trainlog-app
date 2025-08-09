import 'package:flutter/material.dart';
import 'package:trainlog_app/l10n/app_localizations.dart';

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
    return SegmentedButton<StatisticsType>(
      segments: [
          ButtonSegment(value: StatisticsType.bar, icon: Icon(Icons.bar_chart)),
          ButtonSegment(value: StatisticsType.pie, icon: Icon(Icons.pie_chart)),
          ButtonSegment(value: StatisticsType.table, icon: Icon(Icons.table_chart)),
        ],
      selected: <StatisticsType>{statisticsType},
      onSelectionChanged: (Set<StatisticsType> newSelection) {
        final newValue = newSelection.first;
        setState(() {
          statisticsType = newValue;
        });
        widget.onChanged?.call(newValue);
      },
    );
  }
}

