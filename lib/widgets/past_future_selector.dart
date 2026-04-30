import 'package:flutter/material.dart';
import 'package:trainlog_app/l10n/app_localizations.dart';
import 'package:trainlog_app/platform/adaptive_segmented_button.dart';

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
    final loc = AppLocalizations.of(context)!;
    return AdaptiveSegmentedButton.build<TimeMoment>(
      context: context,
      segments: [
        AdaptiveSegmentedButtonSegment(
          value: TimeMoment.past,
          label: Text(loc.yearPastList),
          icon: const Icon(Icons.restore),
        ),
        AdaptiveSegmentedButtonSegment(
          value: TimeMoment.future,
          label: Text(loc.yearFutureList),
          icon: const Icon(Icons.next_plan),
        ),
      ],
      selectedValue: timeMomentView,
      onChanged: (newValue) {
        setState(() => timeMomentView = newValue);
        widget.onChanged?.call(newValue);
      },
    );
  }
}

