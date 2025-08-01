import 'package:flutter/material.dart';
import 'package:trainlog_app/l10n/app_localizations.dart';

enum TimeMoment { past, future }

class PastFutureSelector extends StatefulWidget {
  final TimeMoment initialValue;
  final ValueChanged<TimeMoment>? onChanged;

  const PastFutureSelector({super.key, this.initialValue = TimeMoment.past, this.onChanged});

  @override
  State<PastFutureSelector> createState() => _PastFutureSelectorState();
}

class _PastFutureSelectorState extends State<PastFutureSelector> {
  late TimeMoment timeMomentView;

  @override
  void initState() {
    super.initState();
    timeMomentView = widget.initialValue;
  }

  @override
  Widget build(BuildContext context) {
    return SegmentedButton<TimeMoment>(
      segments: [
          ButtonSegment(value: TimeMoment.past, label: Text(AppLocalizations.of(context)!.yearPastList), icon: Icon(Icons.restore)),
          ButtonSegment(value: TimeMoment.future, label: Text(AppLocalizations.of(context)!.yearFutureList), icon: Icon(Icons.next_plan)),
        ],
      selected: <TimeMoment>{timeMomentView},
      onSelectionChanged: (Set<TimeMoment> newSelection) {
        final newValue = newSelection.first;
        setState(() {
          timeMomentView = newValue;
        });
        widget.onChanged?.call(newValue);
      },
    );
  }
}

