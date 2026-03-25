import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:material_symbols_icons/symbols.dart';
import 'package:trainlog_app/l10n/app_localizations.dart';
import 'package:trainlog_app/utils/date_utils.dart';
import 'package:trainlog_app/utils/signed_int_formatter.dart';

class DelayFieldsSwitcher extends StatefulWidget {
  const DelayFieldsSwitcher({
    super.key,
    required this.originalTime,
    this.initialMinuteMode = false,
    this.initialDateTimeDelay,
    this.initialMinuteDelay,
    this.onChanged,
    this.minuteIcon,
    this.timeIcon,
  });

  final DateTime? originalTime;

  final bool initialMinuteMode;
  final DateTime? initialDateTimeDelay;
  final int? initialMinuteDelay;

  final ValueChanged<Map<String, String?>>? onChanged;

  final IconData? minuteIcon;
  final IconData? timeIcon;

  static const double extraFieldHeight = 48;

  @override
  State<DelayFieldsSwitcher> createState() => _DelayFieldsSwitcherState();
}

class _DelayFieldsSwitcherState extends State<DelayFieldsSwitcher> {
  late final TextEditingController _timeDelayCtl = TextEditingController();
  late final TextEditingController _minuteDelayCtl = TextEditingController();

  late DateTime? _originalTime;
  late bool _minuteMode;

  late DateTime _selectedDate;
  TimeOfDay? _selectedTime;
  int? _savedDelayMinutes;
  int? _computedDelayMinutes;

  String _delayHint = '';
  int _direction = -1;
  bool _updatingFromSelf = false;

  @override
  void initState() {
    super.initState();
    _loadFromWidget(resetDateWhenEmpty: true);

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      _syncControllersFromState();
      _updateHelper();
    });
  }

  @override
  void didUpdateWidget(covariant DelayFieldsSwitcher oldWidget) {
    super.didUpdateWidget(oldWidget);

    if (_updatingFromSelf) return;

    final externalSelectionChanged =
        widget.initialMinuteMode != oldWidget.initialMinuteMode ||
        widget.initialDateTimeDelay != oldWidget.initialDateTimeDelay ||
        widget.initialMinuteDelay != oldWidget.initialMinuteDelay;

    final originalTimeChanged = widget.originalTime != oldWidget.originalTime;

    if (!externalSelectionChanged && !originalTimeChanged) return;

    if (externalSelectionChanged) {
      _loadFromWidget(resetDateWhenEmpty: true);
    } else {
      _originalTime = widget.originalTime;

      // If there is no selected time yet, keep the widget in the "empty delay"
      // state and re-anchor the day shift to 0.
      if (_selectedTime == null && widget.initialDateTimeDelay == null) {
        _selectedDate = _anchorDate();
      }
    }

    _syncControllersFromState();
    _updateHelper();
    setState(() {});
  }

  @override
  void dispose() {
    _timeDelayCtl.dispose();
    _minuteDelayCtl.dispose();
    super.dispose();
  }

  void _loadFromWidget({required bool resetDateWhenEmpty}) {
    _originalTime = widget.originalTime;
    _minuteMode = widget.initialMinuteMode;
    _savedDelayMinutes = widget.initialMinuteDelay;

    if (widget.initialDateTimeDelay != null) {
      final delay = widget.initialDateTimeDelay!;
      _selectedDate = _dateOnly(delay);
      _selectedTime = TimeOfDay.fromDateTime(delay);
    } else {
      if (resetDateWhenEmpty) {
        _selectedDate = _anchorDate();
      }
      _selectedTime = null;
    }
  }

  DateTime _anchorDate() {
    return _dateOnly(_originalTime ?? DateTime.now());
  }

  DateTime _dateOnly(DateTime value) {
    return DateTime(value.year, value.month, value.day);
  }

  DateTime _combineDateAndTime({
    required DateTime datePart,
    required TimeOfDay timePart,
  }) {
    return DateTime(
      datePart.year,
      datePart.month,
      datePart.day,
      timePart.hour,
      timePart.minute,
    );
  }

  DateTime _withoutTimezone(DateTime dt) {
    return DateTime(dt.year, dt.month, dt.day, dt.hour, dt.minute);
  }

  int _dayOffsetFromOriginal() {
    if (_originalTime == null) return 0;
    return _dateOnly(_selectedDate).difference(_dateOnly(_originalTime!)).inDays;
  }

  String _formatDayShift(int value) {
    if (value == 0) return '0';
    return value > 0 ? '+$value' : '$value';
  }

  DateTime? _effectiveDateTime() {
    if (_selectedTime == null) return null;

    return _combineDateAndTime(
      datePart: _selectedDate,
      timePart: _selectedTime!,
    );
  }

  void _syncControllersFromState() {
    if (_minuteMode) {
      _minuteDelayCtl.text = _savedDelayMinutes?.toString() ?? '';
      _timeDelayCtl.text = '';
      return;
    }

    _minuteDelayCtl.text = '';
    _timeDelayCtl.text = _selectedTime?.format(context) ?? '';
  }

  void _emitValues() {
    _updatingFromSelf = true;

    final effectiveDateTime = _effectiveDateTime();
    final hasMinuteDelay = _minuteMode && _savedDelayMinutes != null;
    final hasTimeDelay = !_minuteMode && effectiveDateTime != null; // _computedDelayMinutes

    widget.onChanged?.call({
      'mode': hasMinuteDelay
          ? 'minute'
          : hasTimeDelay
              ? 'time'
              : null,
      'minute': _minuteMode ? _savedDelayMinutes?.toString() : _computedDelayMinutes?.toString(),
      'dateTime': hasTimeDelay ? effectiveDateTime!.toIso8601String() : null,
    });

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _updatingFromSelf = false;
    });
  }

  void _toggleMode() {
    setState(() {
      _minuteMode = !_minuteMode;
      _direction = _minuteMode ? -1 : 1;
      _syncControllersFromState();
      _updateHelper();
    });

    _emitValues();
  }

  void _updateHelper() {
    final loc = AppLocalizations.of(context)!;

    if (_originalTime == null) {
      _delayHint = '';
      return;
    }

    if (_minuteMode) {
      if (_savedDelayMinutes == null) {
        _delayHint = '';
        return;
      }

      final delayedTime = _originalTime!.add(Duration(minutes: _savedDelayMinutes!));
      _delayHint = loc.addTripDelayTime(
        formatDateTime(context, delayedTime, timeOnly: true),
      );
      return;
    }

    final effective = _effectiveDateTime();
    if (effective == null) {
      _delayHint = '';
      return;
    }

    final minuteDifference =
        _withoutTimezone(effective).difference(_withoutTimezone(_originalTime!)).inMinutes;

    final delayDuration = Duration(minutes: minuteDifference.abs());
    _computedDelayMinutes = minuteDifference;

    _delayHint = minuteDifference >= 0
        ? loc.addTripDelayMinuteDelay(formatDurationFixed(delayDuration))
        : loc.addTripDelayMinuteAdvance(formatDurationFixed(delayDuration));
  }

  Future<void> _pickTime() async {
    final initialTime = _selectedTime ??
        (_originalTime != null
            ? TimeOfDay.fromDateTime(_originalTime!)
            : TimeOfDay.now());

    final picked = await showTimePicker(
      context: context,
      initialTime: initialTime,
    );

    if (picked == null) return;

    setState(() {
      _selectedTime = picked;
      _syncControllersFromState();
      _updateHelper();
    });

    _emitValues();
  }

  void _changeDay(int delta) {
    setState(() {
      _selectedDate = _selectedDate.add(Duration(days: delta));
      _updateHelper();
    });

    _emitValues();
  }

  void _resetDay() {
    setState(() {
      _selectedDate = _anchorDate();
      _updateHelper();
    });

    _emitValues();
  }

  void _clearTime() {
    setState(() {
      _selectedTime = null;
      _timeDelayCtl.clear();
      _updateHelper();
    });

    _emitValues();
  }

  void _clearMinuteDelay() {
    setState(() {
      _savedDelayMinutes = null;
      _minuteDelayCtl.clear();
      _updateHelper();
    });

    _emitValues();
  }

  Widget _buildModeButton(IconData icon, VoidCallback onTap) {
    final theme = Theme.of(context);

    return IconButton(
      onPressed: onTap,
      icon: Icon(icon),
      style: IconButton.styleFrom(
        backgroundColor: theme.colorScheme.primary,
        foregroundColor: theme.colorScheme.onPrimary,
        fixedSize: const Size(44, 44),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
      ),
    );
  }

  Widget _buildSegmentDivider(Color color) {
    return SizedBox(
      width: 1,
      child: ColoredBox(color: color),
    );
  }

  Widget _buildSegment({
    required Widget child,
    required VoidCallback onTap,
    int flex = 1,
  }) {
    return Expanded(
      flex: flex,
      child: InkWell(
        onTap: onTap,
        child: Center(child: child),
      ),
    );
  }

  Widget _buildDayShiftControl() {
    final theme = Theme.of(context);
    final borderColor = theme.colorScheme.outline;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          height: DelayFieldsSwitcher.extraFieldHeight,
          child: Material(
            color: theme.colorScheme.surface,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(4),
              side: BorderSide(color: borderColor),
            ),
            clipBehavior: Clip.antiAlias,
            child: Row(
              children: [
                _buildSegment(
                  onTap: () => _changeDay(-1),
                  child: Transform.rotate(
                    angle: math.pi,
                    child: const Icon(Icons.play_arrow_rounded),
                  ),
                ),
                _buildSegmentDivider(borderColor),
                _buildSegment(
                  flex: 2,
                  onTap: _resetDay,
                  child: Text(
                    _formatDayShift(_dayOffsetFromOriginal()),
                    style: theme.textTheme.titleMedium,
                  ),
                ),
                _buildSegmentDivider(borderColor),
                _buildSegment(
                  onTap: () => _changeDay(1),
                  child: const Icon(Icons.play_arrow_rounded),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 4),
        Text(
          _originalTime == null
              ? ''
              : formatDateTime(context, _selectedDate, hasTime: false),
          style: theme.textTheme.bodySmall,
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final minuteIcon = widget.minuteIcon ?? Icons.hourglass_bottom;
    final timeIcon = widget.timeIcon ?? Symbols.watch_later;

    final timeMode = Column(
      key: const ValueKey('time-mode'),
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Flexible(
              flex: 4,
              child: _buildDayShiftControl(),
            ),
            const SizedBox(width: 8),
            Expanded(
              flex: 5,
              child: TextFormField(
                readOnly: true,
                controller: _timeDelayCtl,
                decoration: InputDecoration(
                  labelText: 'Real time',
                  border: const OutlineInputBorder(),
                  helperText: _delayHint,
                  prefixIcon: IconButton(
                    onPressed: _clearTime,
                    icon: const Icon(Icons.close),
                  ),
                  suffixIcon: IconButton(
                    onPressed: _pickTime,
                    icon: const Icon(Icons.access_time),
                  ),
                ),
              ),
            ),
            const SizedBox(width: 8),
            SizedBox(
              height: DelayFieldsSwitcher.extraFieldHeight,
              child: Center(
                child: _buildModeButton(minuteIcon, _toggleMode),
              ),
            ),
          ],
        ),
      ],
    );

    final minuteMode = Column(
      key: const ValueKey('minute-mode'),
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(
              height: DelayFieldsSwitcher.extraFieldHeight,
              child: Center(
                child: _buildModeButton(timeIcon, _toggleMode),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: TextFormField(
                textAlign: TextAlign.right,
                controller: _minuteDelayCtl,
                keyboardType: const TextInputType.numberWithOptions(
                  decimal: false,
                  signed: true,
                ),
                decoration: InputDecoration(
                  labelText: 'Delay/advance in minute',
                  helperText: _delayHint,
                  border: const OutlineInputBorder(),
                  suffix: const Text(' min'),
                  prefixIcon: IconButton(
                    onPressed: _clearMinuteDelay,
                    icon: const Icon(Icons.close),
                  ),
                ),
                inputFormatters: [
                  FilteringTextInputFormatter.allow(RegExp(r'^[+-]?\d*$')),
                  SignedIntFormatter(),
                ],
                onChanged: (value) {
                  _savedDelayMinutes = int.tryParse(value);

                  setState(() {
                    _updateHelper();
                  });

                  _emitValues();
                },
              ),
            ),
          ],
        ),
      ],
    );

    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 250),
      transitionBuilder: (child, animation) {
        return SlideTransition(
          position: Tween<Offset>(
            begin: Offset(_direction * 0.15, 0),
            end: Offset.zero,
          ).animate(animation),
          child: FadeTransition(
            opacity: animation,
            child: child,
          ),
        );
      },
      child: _minuteMode ? minuteMode : timeMode,
    );
  }
}