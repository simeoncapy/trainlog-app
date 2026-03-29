import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:material_symbols_icons/symbols.dart';
import 'package:trainlog_app/l10n/app_localizations.dart';
import 'package:trainlog_app/utils/date_utils.dart';
import 'package:trainlog_app/utils/signed_int_formatter.dart';
import 'package:trainlog_app/widgets/relative_date_time_picker_dialog.dart';

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

  DateTime? _selectedDateTime;
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
      if (_selectedDateTime == null && widget.initialDateTimeDelay == null) {
        _selectedDateTime = null;
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
    _computedDelayMinutes = null;

    if (widget.initialDateTimeDelay != null) {
      _selectedDateTime = widget.initialDateTimeDelay;
    } else {
      _selectedDateTime = null;
    }
  }

  DateTime _dateOnly(DateTime value) {
    return DateTime(value.year, value.month, value.day);
  }

  DateTime _withoutTimezone(DateTime dt) {
    return DateTime(dt.year, dt.month, dt.day, dt.hour, dt.minute);
  }

  DateTime? _effectiveDateTime() {
    return _selectedDateTime;
  }

  String _formatRealTimeFieldText(DateTime? value) {
    if (value == null) return '';

    final timeText = formatDateTime(context, value, timeOnly: true);

    if (_originalTime == null) {
      return timeText;
    }

    final dayShift = _dateOnly(value).difference(_dateOnly(_originalTime!)).inDays;

    if (dayShift == 0) {
      return timeText;
    }

    final sign = dayShift > 0 ? '+' : '-';
    return '${AppLocalizations.of(context)!.daySingleCharacter}$sign${dayShift.abs()}\t$timeText';
  }

  void _syncControllersFromState() {
    if (_minuteMode) {
      _minuteDelayCtl.text = _savedDelayMinutes?.toString() ?? '';
      _timeDelayCtl.text = '';
      return;
    }

    _minuteDelayCtl.text = '';
    _timeDelayCtl.text = _formatRealTimeFieldText(_selectedDateTime);
  }

  void _emitValues() {
    _updatingFromSelf = true;

    final effectiveDateTime = _effectiveDateTime();
    final hasMinuteDelay = _minuteMode && _savedDelayMinutes != null;
    final hasTimeDelay = !_minuteMode && effectiveDateTime != null;

    widget.onChanged?.call({
      'mode': hasMinuteDelay
          ? 'minute'
          : hasTimeDelay
              ? 'time'
              : null,
      'minute': _minuteMode
          ? _savedDelayMinutes?.toString()
          : _computedDelayMinutes?.toString(),
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
      _computedDelayMinutes = null;
      _delayHint = '';
      return;
    }

    if (_minuteMode) {
      if (_savedDelayMinutes == null) {
        _delayHint = '';
        return;
      }

      final delayedTime = _originalTime!.add(Duration(minutes: _savedDelayMinutes!));
      final dayShift =
        _dateOnly(delayedTime).difference(_dateOnly(_originalTime!)).inDays;

      final delayedDisplay = dayShift == 0
          ? formatDateTime(context, delayedTime, timeOnly: true)
          : '${loc.daySingleCharacter}${dayShift > 0 ? '+' : '-'}${dayShift.abs()} '
              '${formatDateTime(context, delayedTime, timeOnly: true)}';

      _delayHint = loc.addTripDelayTime(delayedDisplay);
      return;
    }

    final effective = _effectiveDateTime();
    if (effective == null) {
      _computedDelayMinutes = null;
      _delayHint = '';
      return;
    }

    final minuteDifference =
        _withoutTimezone(effective).difference(_withoutTimezone(_originalTime!)).inMinutes;

    _computedDelayMinutes = minuteDifference;

    final delayDuration = Duration(minutes: minuteDifference.abs());

    _delayHint = minuteDifference >= 0
        ? loc.addTripDelayMinuteDelay(formatDurationFixed(delayDuration))
        : loc.addTripDelayMinuteAdvance(formatDurationFixed(delayDuration));
  }

  Future<void> _pickTime() async {
    final loc = AppLocalizations.of(context)!;
    if (_originalTime == null) {
      final messenger = ScaffoldMessenger.maybeOf(context);
      messenger
        ?..clearSnackBars()
        ..showSnackBar(
          const SnackBar(
            content: Text('Select the scheduled time before'),
          ),
        );
      return;
    }

    final picked = await showRelativeDateTimePickerDialog(
      context: context,
      title: loc.addTripRealTime,
      origin: _originalTime!,
      initialDateTime: _selectedDateTime,
      originDateLabel: loc.addTripOriginDayLabel,
      resetLabel: loc.addTripResetToScheduled,
    );

    if (picked == null) return;

    setState(() {
      _selectedDateTime = picked;
      _syncControllersFromState();
      _updateHelper();
    });

    _emitValues();
  }

  void _clearTime() {
    setState(() {
      _selectedDateTime = null;
      _computedDelayMinutes = null;
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

  @override
  Widget build(BuildContext context) {
    final minuteIcon = widget.minuteIcon ?? Icons.hourglass_bottom;
    final timeIcon = widget.timeIcon ?? Symbols.watch_later;
    final loc = AppLocalizations.of(context)!;

    final timeMode = Column(
      key: const ValueKey('time-mode'),
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: TextFormField(
                readOnly: true,
                textAlign: TextAlign.right,
                enabled: _originalTime != null,
                controller: _timeDelayCtl,
                decoration: InputDecoration(
                  labelText: loc.addTripRealTime,
                  border: const OutlineInputBorder(),
                  helperText: _delayHint,
                  suffixIcon: IconButton(
                    onPressed: _pickTime,
                    icon: const Icon(Icons.access_time),
                  ),
                  prefixIcon: IconButton(
                    onPressed: _selectedDateTime == null ? null : _clearTime,
                    icon: const Icon(Icons.close),
                  ),
                ),
                onTap: _pickTime,
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