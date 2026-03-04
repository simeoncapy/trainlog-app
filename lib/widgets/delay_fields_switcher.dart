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

    // Initial values (for restore)
    this.initialMinuteMode = false,
    this.initialTimeDelay,
    this.initialMinuteDelay,

    this.onChanged,
    this.minuteIcon,
    this.timeIcon,
  });

  final DateTime? originalTime;

  final bool initialMinuteMode;
  final TimeOfDay? initialTimeDelay;
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
  
  late final TextEditingController _timeDelayCtl = TextEditingController();
  late final TextEditingController _minuteDelayCtl = TextEditingController();

  late DateTime? _originalTime = widget.originalTime;
  late bool _minuteMode = widget.initialMinuteMode;
  TimeOfDay? _savedTimeDelay;
  int? _savedDelayMinutes;

  int _direction = -1;

  String _delayHint = "";

  bool _updatingFromSelf = false;

  // ------------------------------
  // INIT: restore values properly
  // ------------------------------
  @override
  void initState() {
    super.initState();

    _minuteMode = widget.initialMinuteMode;
    _savedTimeDelay = widget.initialTimeDelay;
    _savedDelayMinutes = widget.initialMinuteDelay;    

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_minuteMode) {
        _minuteDelayCtl.text = _savedDelayMinutes?.toString() ?? 0.toString();
      } else {
        _timeDelayCtl.text = _savedTimeDelay != null ? _savedTimeDelay!.format(context) : "";
      }

      _helperGenerator(context);
    });
  }

  @override
  void didUpdateWidget(covariant DelayFieldsSwitcher oldWidget) {
    super.didUpdateWidget(oldWidget);

    // Do NOT resync if this widget triggered the update
    if (_updatingFromSelf) return;

    // Detect a meaningful external change (switch or reset)
    final shouldUpdate =
        widget.initialMinuteMode != oldWidget.initialMinuteMode ||
        widget.initialTimeDelay != oldWidget.initialTimeDelay ||
        widget.initialMinuteDelay != oldWidget.initialMinuteDelay ||
        widget.originalTime != oldWidget.originalTime;

    if (!shouldUpdate) return;
    _originalTime = widget.originalTime;

    // --- sync geo mode ---
    _minuteMode = widget.initialMinuteMode;

    if(_minuteMode) {
      _minuteDelayCtl.text = widget.initialMinuteDelay?.toString() ?? "0";
      _timeDelayCtl.text = "";
    }
    else {
      _timeDelayCtl.text = widget.initialTimeDelay != null ? widget.initialTimeDelay!.format(context) : "";
      _minuteDelayCtl.text = "";
    }
    _helperGenerator(context);
    setState(() {});
  }


  // ------------------------------
  // Emit updated values to parent
  // ------------------------------
  void _emitValues() {
    _updatingFromSelf = true;

    widget.onChanged?.call({
      'mode': _minuteMode ? "minute" : "time",
      'minute': _minuteMode ? _minuteDelayCtl.text : null,
      'time': _minuteMode ? null : _timeDelayCtl.text,
    });

    // Let the parent rebuild first
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _updatingFromSelf = false;
    });
  }

  // ------------------------------
  // Toggle mode
  // ------------------------------
  void _toggleMode(BuildContext context) {
    setState(() {
      _minuteMode = !_minuteMode;
      _direction = _minuteMode ? -1 : 1;
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
      debugPrint("Generating helper for minute mode with _savedDelayMinutes=$_savedDelayMinutes and originalTime=$_originalTime");
      if (_savedDelayMinutes == null) {
        _delayHint = "";
        return;
      }
      DateTime timeDelay = _originalTime!.add(Duration(minutes: _savedDelayMinutes!));
      debugPrint("Calculated timeDelay=$timeDelay");
      _delayHint = loc.addTripDelayTime(formatDateTime(context, timeDelay, timeOnly: true));
      debugPrint("Generated hint: $_delayHint");
    } else {
      if (_savedTimeDelay == null) {
        _delayHint = "";
        return;
      }
      int minuteDelay = (_originalTime!.hour - _savedTimeDelay!.hour) * 60 + (_originalTime!.minute - _savedTimeDelay!.minute);
      Duration delayDuration = Duration(minutes: minuteDelay.abs());
      _delayHint = minuteDelay < 0
        ? loc.addTripDelayMinuteDelay(formatDurationFixed(delayDuration))
        : loc.addTripDelayMinuteAdvance(formatDurationFixed(delayDuration));
    }
  }

  // ------------------------------
  // Build UI
  // ------------------------------
  @override
  Widget build(BuildContext context) {
    final minuteIcon = widget.minuteIcon ?? Icons.hourglass_bottom;
    final timeIcon = widget.timeIcon ?? Symbols.watch_later;
    final initialTime = widget.initialTimeDelay == null 
                      ? null 
                      : "${widget.initialTimeDelay!.hour}:${widget.initialTimeDelay!.minute}";

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


    // ---------------- TIME MODE ------------------
    final timeMode = Column(
      key: const ValueKey('time-mode'),
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: TextFormField(
                //initialValue: initialTime,
                readOnly: true,
                controller: _timeDelayCtl,     
                decoration: InputDecoration(
                  labelText: "Real time",
                  border: const OutlineInputBorder(),
                  helperText: _delayHint,
                  prefixIcon: IconButton(
                    onPressed: () {
                      setState(() {
                        _savedTimeDelay = null;
                        _timeDelayCtl.text = "";
                        _helperGenerator(context);
                        _emitValues();
                      });
                    }, 
                    icon: const Icon(Icons.close)
                  ),
                  suffixIcon: IconButton(
                    icon: const Icon(Icons.access_time),
                    onPressed: () async {
                      final picked = await showTimePicker(
                        context: context,
                        initialTime: _savedTimeDelay ?? TimeOfDay.now(),
                      );
                      if (picked != null) {
                        setState(() => _savedTimeDelay = picked);
                        _timeDelayCtl.text = picked.format(context);
                        _helperGenerator(context);
                        _emitValues();
                      }
                    },
                  ),
                ),
              ),
            ),
            const SizedBox(width: 8),
            SizedBox( // center the button on the textfield, and not textfield + helper
              height: DelayFieldsSwitcher.extraFieldHeight,
              child: Center(
                child: actionButton(minuteIcon, () => _toggleMode(context)),
              ),
            )
          ],
        ),
      ],
    );

    // ---------------- MINUTE MODE ------------------
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
                //initialValue: widget.initialMinuteDelay?.toString(),
                textAlign: TextAlign.right,
                controller: _minuteDelayCtl,
                keyboardType:
                    const TextInputType.numberWithOptions(decimal: false, signed: true),
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
                        _emitValues();
                      });
                    }, 
                    icon: const Icon(Icons.close)
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
