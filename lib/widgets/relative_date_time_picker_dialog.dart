import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:trainlog_app/providers/settings_provider.dart';
import 'package:trainlog_app/utils/date_utils.dart';
import 'package:trainlog_app/l10n/app_localizations.dart';

Future<DateTime?> showRelativeDateTimePickerDialog({
  required BuildContext context,
  required String title,
  required DateTime origin,
  required String originDateLabel,
  DateTime? initialDateTime,
  String? resetLabel,
  String? confirmLabel,
  bool barrierDismissible = true,
}) {
  return showDialog<DateTime>(
    context: context,
    barrierDismissible: barrierDismissible,
    builder: (_) => RelativeDateTimePickerDialog(
      title: title,
      origin: origin,
      originDateLabel: originDateLabel,
      initialDateTime: initialDateTime,
      resetLabel: resetLabel,
      confirmLabel: confirmLabel,
    ),
  );
}

class RelativeDateTimePickerDialog extends StatefulWidget {
  const RelativeDateTimePickerDialog({
    super.key,
    required this.title,
    required this.origin,
    required this.originDateLabel,
    this.initialDateTime,
    this.resetLabel,
    this.confirmLabel,
  });

  final String title;
  final DateTime origin;
  final String originDateLabel;
  final DateTime? initialDateTime;
  final String? resetLabel;
  final String? confirmLabel;

  @override
  State<RelativeDateTimePickerDialog> createState() =>
      _RelativeDateTimePickerDialogState();
}

class _RelativeDateTimePickerDialogState extends State<RelativeDateTimePickerDialog> {
  late DateTime _origin;
  late DateTime _selectedDateTime;

  DateTime _normalise(DateTime value) {
    return DateTime(
      value.year,
      value.month,
      value.day,
      value.hour,
      value.minute,
    );
  }

  bool _isSameDay(DateTime a, DateTime b) {
    return a.year == b.year && a.month == b.month && a.day == b.day;
  }

  @override
  void initState() {
    super.initState();
    _origin = _normalise(widget.origin);
    _selectedDateTime = _normalise(widget.initialDateTime ?? widget.origin);
  }

  void _changeMinutes(int delta) {
    setState(() {
      _selectedDateTime = _selectedDateTime.add(Duration(minutes: delta));
    });
  }

  void _changeHours(int delta) {
    setState(() {
      _selectedDateTime = _selectedDateTime.add(Duration(hours: delta));
    });
  }

  void _changePeriod(int deltaPeriods) {
    if (deltaPeriods == 0) return;
    setState(() {
      _selectedDateTime =
          _selectedDateTime.add(Duration(hours: deltaPeriods * 12));
    });
  }

  void _changeDay(int delta) {
    setState(() {
      _selectedDateTime = _selectedDateTime.add(Duration(days: delta));
    });
  }

  void _resetToOrigin() {
    setState(() {
      _selectedDateTime = _origin;
    });
  }

  int _mod(int value, int modulo) {
    final result = value % modulo;
    return result < 0 ? result + modulo : result;
  }

  String _hour24Label(int offset) {
    final value = _mod(_selectedDateTime.hour + offset, 24);
    return value.toString().padLeft(2, '0');
  }

  int _hour12ValueFor(DateTime value) {
    final hour = value.hour % 12;
    return hour == 0 ? 12 : hour;
  }

  String _hour12Label(int offset) {
    final shifted = _selectedDateTime.add(Duration(hours: offset));
    return _hour12ValueFor(shifted).toString().padLeft(2, '0');
  }

  String _minuteLabel(int offset) {
    final value = _mod(_selectedDateTime.minute + offset, 60);
    return value.toString().padLeft(2, '0');
  }

  String _periodLabel(int offset) {
    final shifted = _selectedDateTime.add(Duration(hours: offset * 12));
    return shifted.hour >= 12 ? 'PM' : 'AM';
  }

  String _dateLabel(BuildContext context) {
    if (_isSameDay(_selectedDateTime, _origin)) {
      return widget.originDateLabel;
    }

    return formatDateTime(context, _selectedDateTime, hasTime: false);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final materialLoc = MaterialLocalizations.of(context);
    final settings = context.read<SettingsProvider>();
    final timeFormat12h = settings.hourFormat12;

    return Dialog(
      insetPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(28)),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 420),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 20, 20, 16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                widget.title,
                style: theme.textTheme.titleLarge,
              ),
              const SizedBox(height: 16),
              _CompactTimePicker(
                timeFormat12h: timeFormat12h,
                hourPreviousLabel:
                    timeFormat12h ? _hour12Label(-1) : _hour24Label(-1),
                hourCurrentLabel:
                    timeFormat12h ? _hour12Label(0) : _hour24Label(0),
                hourNextLabel:
                    timeFormat12h ? _hour12Label(1) : _hour24Label(1),
                minutePreviousLabel: _minuteLabel(-1),
                minuteCurrentLabel: _minuteLabel(0),
                minuteNextLabel: _minuteLabel(1),
                periodPreviousLabel: _periodLabel(-1),
                periodCurrentLabel: _periodLabel(0),
                periodNextLabel: _periodLabel(1),
                onHourStep: _changeHours,
                onMinuteStep: _changeMinutes,
                onPeriodStep: _changePeriod,
              ),
              _DateRow(
                label: _dateLabel(context),
                onPreviousDay: () => _changeDay(-1),
                onNextDay: () => _changeDay(1),
              ),
              const SizedBox(height: 8),
              TextButton(
                onPressed: _resetToOrigin,
                child: Text(widget.resetLabel ?? 'Reset to origin'),
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => Navigator.of(context).pop(),
                      child: Text(materialLoc.cancelButtonLabel),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: FilledButton(
                      onPressed: () => Navigator.of(context).pop(_selectedDateTime),
                      child: Text(widget.confirmLabel ?? AppLocalizations.of(context)!.setBtnLabel),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _CompactTimePicker extends StatelessWidget {
  const _CompactTimePicker({
    required this.timeFormat12h,
    required this.hourPreviousLabel,
    required this.hourCurrentLabel,
    required this.hourNextLabel,
    required this.minutePreviousLabel,
    required this.minuteCurrentLabel,
    required this.minuteNextLabel,
    required this.periodPreviousLabel,
    required this.periodCurrentLabel,
    required this.periodNextLabel,
    required this.onHourStep,
    required this.onMinuteStep,
    required this.onPeriodStep,
  });

  final bool timeFormat12h;

  final String hourPreviousLabel;
  final String hourCurrentLabel;
  final String hourNextLabel;

  final String minutePreviousLabel;
  final String minuteCurrentLabel;
  final String minuteNextLabel;

  final String periodPreviousLabel;
  final String periodCurrentLabel;
  final String periodNextLabel;

  final ValueChanged<int> onHourStep;
  final ValueChanged<int> onMinuteStep;
  final ValueChanged<int> onPeriodStep;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final lineColor = theme.colorScheme.outlineVariant;

    return Container(
      decoration: BoxDecoration(
        border: Border(
          top: BorderSide(color: lineColor),
          bottom: BorderSide(color: lineColor),
        ),
      ),
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          _RollSelector(
            width: 88,
            previousLabel: hourPreviousLabel,
            currentLabel: hourCurrentLabel,
            nextLabel: hourNextLabel,
            onStep: onHourStep,
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 6),
            child: Text(
              ':',
              style: theme.textTheme.headlineMedium,
            ),
          ),
          _RollSelector(
            width: 88,
            previousLabel: minutePreviousLabel,
            currentLabel: minuteCurrentLabel,
            nextLabel: minuteNextLabel,
            onStep: onMinuteStep,
          ),
          if (timeFormat12h) ...[
            const SizedBox(width: 12),
            _RollSelector(
              width: 74,
              previousLabel: periodPreviousLabel,
              currentLabel: periodCurrentLabel,
              nextLabel: periodNextLabel,
              onStep: onPeriodStep,
              isTextMode: true,
            ),
          ],
        ],
      ),
    );
  }
}

class _DateRow extends StatelessWidget {
  const _DateRow({
    required this.label,
    required this.onPreviousDay,
    required this.onNextDay,
  });

  final String label;
  final VoidCallback onPreviousDay;
  final VoidCallback onNextDay;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final lineColor = theme.colorScheme.outlineVariant;

    return Container(
      height: 64,
      decoration: BoxDecoration(
        border: Border(
          bottom: BorderSide(color: lineColor),
        ),
      ),
      child: Row(
        children: [
          SizedBox(
            width: 56,
            child: IconButton(
              onPressed: onPreviousDay,
              icon: const Icon(Icons.chevron_left),
              tooltip: 'Previous day',
            ),
          ),
          Expanded(
            child: Center(
              child: Text(
                label,
                textAlign: TextAlign.center,
                style: theme.textTheme.titleMedium,
              ),
            ),
          ),
          SizedBox(
            width: 56,
            child: IconButton(
              onPressed: onNextDay,
              icon: const Icon(Icons.chevron_right),
              tooltip: 'Next day',
            ),
          ),
        ],
      ),
    );
  }
}

class _RollSelector extends StatefulWidget {
  const _RollSelector({
    required this.previousLabel,
    required this.currentLabel,
    required this.nextLabel,
    required this.onStep,
    required this.width,
    this.isTextMode = false,
  });

  final String previousLabel;
  final String currentLabel;
  final String nextLabel;
  final ValueChanged<int> onStep;
  final double width;
  final bool isTextMode;

  @override
  State<_RollSelector> createState() => _RollSelectorState();
}

class _RollSelectorState extends State<_RollSelector> {
  static const double _stepThreshold = 18;
  double _dragAccumulator = 0;

  void _applyDragStep(double deltaY) {
    _dragAccumulator += deltaY;

    while (_dragAccumulator <= -_stepThreshold) {
      widget.onStep(1);
      _dragAccumulator += _stepThreshold;
    }

    while (_dragAccumulator >= _stepThreshold) {
      widget.onStep(-1);
      _dragAccumulator -= _stepThreshold;
    }
  }

  void _resetDrag() {
    _dragAccumulator = 0;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final currentStyle = (widget.isTextMode
            ? theme.textTheme.titleLarge
            : theme.textTheme.headlineMedium)
        ?.copyWith(fontWeight: FontWeight.w500);
    final sideStyle = (widget.isTextMode
            ? theme.textTheme.titleMedium
            : theme.textTheme.headlineSmall)
        ?.copyWith(
          color: theme.colorScheme.onSurfaceVariant,
          fontWeight: FontWeight.w400,
        );
    final lineColor = theme.colorScheme.outlineVariant;

    return Listener(
      onPointerSignal: (event) {
        if (event is PointerScrollEvent) {
          if (event.scrollDelta.dy > 0) {
            widget.onStep(1);
          } else if (event.scrollDelta.dy < 0) {
            widget.onStep(-1);
          }
        }
      },
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onVerticalDragStart: (_) => _resetDrag(),
        onVerticalDragUpdate: (details) => _applyDragStep(details.delta.dy),
        onVerticalDragEnd: (_) => _resetDrag(),
        onVerticalDragCancel: _resetDrag,
        child: SizedBox(
          width: widget.width,
          height: 136,
          child: Column(
            children: [
              Expanded(
                child: InkWell(
                  onTap: () => widget.onStep(-1),
                  child: Center(
                    child: Text(widget.previousLabel, style: sideStyle),
                  ),
                ),
              ),
              Container(
                height: 48,
                decoration: BoxDecoration(
                  border: Border(
                    top: BorderSide(color: lineColor, width: 2),
                    bottom: BorderSide(color: lineColor, width: 2),
                  ),
                ),
                child: Center(
                  child: Text(widget.currentLabel, style: currentStyle),
                ),
              ),
              Expanded(
                child: InkWell(
                  onTap: () => widget.onStep(1),
                  child: Center(
                    child: Text(widget.nextLabel, style: sideStyle),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
