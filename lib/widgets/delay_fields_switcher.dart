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

    // Initial values
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

class _DelayFieldsSwitcherState extends State<DelayFieldsSwitcher>
    with TickerProviderStateMixin {
  late final TextEditingController _dateDelayCtl = TextEditingController();
  late final TextEditingController _timeDelayCtl = TextEditingController();
  late final TextEditingController _minuteDelayCtl = TextEditingController();

  late DateTime? _originalTime = widget.originalTime;
  late bool _minuteMode = widget.initialMinuteMode;

  DateTime? _savedDateTimeDelay;
  TimeOfDay? _savedTimeOnly;
  int? _savedDelayMinutes;

  int _direction = -1;
  String _delayHint = "";
  bool _updatingFromSelf = false;

  @override
  void initState() {
    super.initState();

    _minuteMode = widget.initialMinuteMode;
    _savedDateTimeDelay = widget.initialDateTimeDelay ?? widget.originalTime;
    _savedTimeOnly = widget.initialDateTimeDelay != null
        ? TimeOfDay.fromDateTime(widget.initialDateTimeDelay!)
        : (widget.originalTime != null ? TimeOfDay.fromDateTime(widget.originalTime!) : null);
    _savedDelayMinutes = widget.initialMinuteDelay;

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _syncControllersFromState(context);
      _helperGenerator(context);
    });
  }

  @override
  void didUpdateWidget(covariant DelayFieldsSwitcher oldWidget) {
    super.didUpdateWidget(oldWidget);

    if (_updatingFromSelf) return;

    final shouldUpdate =
        widget.initialMinuteMode != oldWidget.initialMinuteMode ||
        widget.initialDateTimeDelay != oldWidget.initialDateTimeDelay ||
        widget.initialMinuteDelay != oldWidget.initialMinuteDelay ||
        widget.originalTime != oldWidget.originalTime;

    if (!shouldUpdate) return;

    _originalTime = widget.originalTime;
    _minuteMode = widget.initialMinuteMode;
    _savedDateTimeDelay = widget.initialDateTimeDelay ?? widget.originalTime;
    _savedTimeOnly = widget.initialDateTimeDelay != null
        ? TimeOfDay.fromDateTime(widget.initialDateTimeDelay!)
        : (widget.originalTime != null ? TimeOfDay.fromDateTime(widget.originalTime!) : null);
    _savedDelayMinutes = widget.initialMinuteDelay;

    _syncControllersFromState(context);
    _helperGenerator(context);
    setState(() {});
  }

  @override
  void dispose() {
    _dateDelayCtl.dispose();
    _timeDelayCtl.dispose();
    _minuteDelayCtl.dispose();
    super.dispose();
  }

  DateTime _dateOnly(DateTime value) {
    return DateTime(value.year, value.month, value.day);
  }

  int _dayOffsetFromOriginal() {
    if (_originalTime == null || _savedDateTimeDelay == null) return 0;

    final originalDate = _dateOnly(_originalTime!);
    final savedDate = _dateOnly(_savedDateTimeDelay!);
    return savedDate.difference(originalDate).inDays;
  }

  void _syncControllersFromState(BuildContext context) {
    if (_minuteMode) {
      _minuteDelayCtl.text = _savedDelayMinutes?.toString() ?? "";
      _dateDelayCtl.text = "";
      _timeDelayCtl.text = "";
    } else {
      _minuteDelayCtl.text = "";

      final offset = _dayOffsetFromOriginal();
      _dateDelayCtl.text = offset >= 0 ? "+$offset" : "$offset";

      _timeDelayCtl.text = _savedTimeOnly == null
          ? ""
          : _savedTimeOnly!.format(context);
    }
  }

  DateTime? _effectiveDateTime() {
    if (_savedDateTimeDelay == null || _savedTimeOnly == null) return null;
    return _combineDateAndTime(datePart: _savedDateTimeDelay!, timePart: _savedTimeOnly!);
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

  void _emitValues() {
    _updatingFromSelf = true;

    widget.onChanged?.call({
      'mode': _minuteMode ? "minute" : "time",
      'minute': _minuteMode ? _minuteDelayCtl.text : null,
      'dateTime': _minuteMode ? null : _effectiveDateTime()?.toIso8601String(),
    });

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _updatingFromSelf = false;
    });
  }

  void _toggleMode(BuildContext context) {
    setState(() {
      _minuteMode = !_minuteMode;
      _direction = _minuteMode ? -1 : 1;

      if (!_minuteMode && _savedDateTimeDelay == null) {
        _savedDateTimeDelay = _originalTime ?? DateTime.now();
      }

      _syncControllersFromState(context);
      _helperGenerator(context);
    });
    _emitValues();
  }

  void _helperGenerator(BuildContext context) {
    final loc = AppLocalizations.of(context)!;

    if (_originalTime == null) {
      _delayHint = "";
      return;
    }

    if (_minuteMode) {
      if (_savedDelayMinutes == null) {
        _delayHint = "";
        return;
      }

      final delayedTime =
          _originalTime!.add(Duration(minutes: _savedDelayMinutes!));

      _delayHint =
          loc.addTripDelayTime(formatDateTime(context, delayedTime, timeOnly: true));
    } else {
      final effective = _effectiveDateTime();
      if (effective == null) {
        _delayHint = "";
        return;
      }

      final minuteDifference =
          _withoutTimezone(effective).difference(_withoutTimezone(_originalTime!)).inMinutes;
      final delayDuration = Duration(minutes: minuteDifference.abs());

      final deltaText = minuteDifference >= 0
          ? loc.addTripDelayMinuteDelay(formatDurationFixed(delayDuration))
          : loc.addTripDelayMinuteAdvance(formatDurationFixed(delayDuration));

      _delayHint = deltaText;
    }
  }

  Future<void> _pickTime(BuildContext context) async {
    final initialTime = _savedTimeOnly ??
        (_originalTime != null ? TimeOfDay.fromDateTime(_originalTime!) : TimeOfDay.now());

    final picked = await showTimePicker(
      context: context,
      initialTime: initialTime,
    );

    if (picked == null) return;

    setState(() {
      _savedTimeOnly = picked;
      _savedDateTimeDelay ??= _originalTime ?? DateTime.now();
      _syncControllersFromState(context);
      _helperGenerator(context);
    });

    _emitValues();
  }

  void _changeDay(BuildContext context, int dayOffset) {
    final base = _savedDateTimeDelay ?? _originalTime ?? DateTime.now();

    setState(() {
      _savedDateTimeDelay = DateTime(
        base.year,
        base.month,
        base.day + dayOffset,
        base.hour,
        base.minute,
      );
      _syncControllersFromState(context);
      _helperGenerator(context);
    });

    _emitValues();
  }

  @override
  Widget build(BuildContext context) {
    final minuteIcon = widget.minuteIcon ?? Icons.hourglass_bottom;
    final timeIcon = widget.timeIcon ?? Symbols.watch_later;

    Widget actionButton(IconData icon, VoidCallback onTap) {
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

    final timeMode = Column(
      key: const ValueKey('time-mode'),
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: TextFormField(
                readOnly: true,
                controller: _dateDelayCtl,
                decoration: InputDecoration(
                  labelText: "Day offset",
                  border: const OutlineInputBorder(),
                  helperText: _savedDateTimeDelay == null
                      ? ""
                      : formatDateTime(context, _savedDateTimeDelay!, hasTime: false),
                  prefixIcon: IconButton(
                    onPressed: () => _changeDay(context, -1),
                    icon: const Icon(Icons.exposure_minus_1),
                  ),
                  suffixIcon: IconButton(
                    onPressed: () => _changeDay(context, 1),
                    icon: const Icon(Icons.plus_one),
                  ),
                ),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: TextFormField(
                readOnly: true,
                controller: _timeDelayCtl,
                decoration: InputDecoration(
                  labelText: "Real time",
                  border: const OutlineInputBorder(),
                  helperText: _delayHint,
                  prefixIcon: IconButton(
                    onPressed: () {
                      setState(() {
                        _savedTimeOnly = null;
                        _timeDelayCtl.text = "";
                        _helperGenerator(context);
                      });
                      _emitValues();
                    },
                    icon: const Icon(Icons.close),
                  ),
                  suffixIcon: IconButton(
                    icon: const Icon(Icons.access_time),
                    onPressed: () => _pickTime(context),
                  ),
                ),
              ),
            ),
            const SizedBox(width: 8),
            SizedBox(
              height: DelayFieldsSwitcher.extraFieldHeight,
              child: Center(
                child: actionButton(minuteIcon, () => _toggleMode(context)),
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
                child: actionButton(timeIcon, () => _toggleMode(context)),
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
                  labelText: "Delay/advance in minute",
                  helperText: _delayHint,
                  border: const OutlineInputBorder(),
                  suffix: const Text(" min"),
                  prefixIcon: IconButton(
                    onPressed: () {
                      setState(() {
                        _savedDelayMinutes = null;
                        _minuteDelayCtl.text = "";
                        _helperGenerator(context);
                      });
                      _emitValues();
                    },
                    icon: const Icon(Icons.close),
                  ),
                ),
                inputFormatters: [
                  FilteringTextInputFormatter.allow(RegExp(r'^[+-]?\d*$')),
                  SignedIntFormatter(),
                ],
                onChanged: (v) {
                  _savedDelayMinutes = int.tryParse(v);
                  setState(() {
                    _helperGenerator(context);
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
          position: Tween(
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