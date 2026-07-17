import 'package:duration/locale.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:timezone/timezone.dart' as tz;
import 'package:lat_lng_to_timezone/lat_lng_to_timezone.dart' as tzmap;
import 'package:trainlog_app/app/theme/app_colors.dart';
import 'package:trainlog_app/app/theme/app_theme.dart';
import 'package:trainlog_app/data/models/trip_form_model.dart';
import 'package:trainlog_app/data/models/trips.dart';
import 'package:trainlog_app/l10n/app_localizations.dart';
import 'package:trainlog_app/providers/settings_provider.dart';
import 'package:trainlog_app/utils/date_utils.dart';
import 'package:trainlog_app/utils/map_color_palette.dart';
import 'package:trainlog_app/utils/signed_int_formatter.dart';
import 'package:trainlog_app/features/trips_add/widgets/relative_date_time_picker_dialog.dart';
import 'package:trainlog_app/widgets/app_steps_tab_bar.dart';
import 'package:trainlog_app/widgets/error_banner.dart';

/// Step 4 of the "Add Trip" wizard: temporal data of the trip.
///
/// A bold headline followed by an [AppStepsTabBar] switching between the
/// three temporal tracking modes:
///  * Precise — departure/arrival blocks with scheduled date & time pickers,
///    an On time / Delayed selector per endpoint and, when delayed, a signed
///    minute input synchronized both ways with an actual-time picker;
///  * Date — a single calendar date plus an optional duration;
///  * Unknown — a Past/Future selector plus an optional duration.
class AddTripWhenStep extends StatefulWidget {
  const AddTripWhenStep({super.key});

  @override
  State<AddTripWhenStep> createState() => _AddTripWhenStepState();
}

class _AddTripWhenStepState extends State<AddTripWhenStep> {
  /// Tab order of the mode selector.
  static const _modes = [DateType.precise, DateType.date, DateType.unknown];

  DateType _scheduleMode = DateType.precise;
  DateTime? _departureDate;
  DateTime? _departureDateOnly;
  TimeOfDay? _departureTime;
  DateTime? _arrivalDate;
  TimeOfDay? _arrivalTime;
  bool _isPast = true;
  bool _isDepartureFilledFromNow = false;

  // Delay state, one pair per endpoint. The signed minute value is the
  // single source of truth: the actual time shown next to it is always
  // scheduled time + minutes, so both inputs stay synchronized.
  bool _departureDelayed = false;
  int? _departureDelayMinutes;
  final TextEditingController _departureDelayCtl = TextEditingController();

  bool _arrivalDelayed = false;
  int? _arrivalDelayMinutes;
  final TextEditingController _arrivalDelayCtl = TextEditingController();

  @override
  void initState() {
    super.initState();

    final model = context.read<TripFormModel>();
    _scheduleMode = model.dateType;
    _isPast = model.isPast;
    _departureDateOnly = model.departureDayDateOnly;
    _initPreciseFromModel(model);
    _initDelaysFromModel(model);
  }

  @override
  void dispose() {
    _departureDelayCtl.dispose();
    _arrivalDelayCtl.dispose();
    super.dispose();
  }

  void _initPreciseFromModel(TripFormModel model) {
    // Departure
    if (model.departureLat != null && model.departureLong != null) {
      final departureTimezone = tzmap.latLngToTimezoneString(
        model.departureLat!,
        model.departureLong!,
      );

      if (model.departureDate == null) {
        final now = DateTime.now();

        _departureDate = DateTime(now.year, now.month, now.day);
        _departureTime = TimeOfDay(hour: now.hour, minute: now.minute);
        _isDepartureFilledFromNow = true;
        model.initDepartureDateTime(
            _departureDate!, _departureTime!, departureTimezone);
      } else {
        final local = _convertUtcToTimezone(
          model.departureDate!,
          departureTimezone,
        );

        _departureDate = DateTime(local.year, local.month, local.day);
        _departureTime = TimeOfDay(hour: local.hour, minute: local.minute);
      }
    }

    // Arrival
    if (model.arrivalDate != null &&
        model.arrivalLat != null &&
        model.arrivalLong != null) {
      final arrivalTimezone = tzmap.latLngToTimezoneString(
        model.arrivalLat!,
        model.arrivalLong!,
      );

      final local = _convertUtcToTimezone(
        model.arrivalDate!,
        arrivalTimezone,
      );

      _arrivalDate = DateTime(local.year, local.month, local.day);
      _arrivalTime = TimeOfDay(hour: local.hour, minute: local.minute);
    }
  }

  void _initDelaysFromModel(TripFormModel model) {
    _departureDelayMinutes = model.delayDepartureMinute ??
        _minutesBetween(model.departureDateLocal, model.delayDepartureTime);
    _departureDelayed =
        _departureDelayMinutes != null || model.delayDepartureTime != null;
    _departureDelayCtl.text = _signedText(_departureDelayMinutes);

    _arrivalDelayMinutes = model.delayArrivalMinute ??
        _minutesBetween(model.arrivalDateLocal, model.delayArrivalTime);
    _arrivalDelayed =
        _arrivalDelayMinutes != null || model.delayArrivalTime != null;
    _arrivalDelayCtl.text = _signedText(_arrivalDelayMinutes);
  }

  DateTime _convertUtcToTimezone(DateTime utc, String timezone) {
    final location = tz.getLocation(timezone);
    return tz.TZDateTime.from(utc, location);
  }

  int? _minutesBetween(DateTime? origin, DateTime? actual) {
    if (origin == null || actual == null) return null;
    return actual.difference(_withoutSeconds(origin)).inMinutes;
  }

  DateTime _withoutSeconds(DateTime dt) {
    return DateTime(dt.year, dt.month, dt.day, dt.hour, dt.minute);
  }

  DateTime _dateOnly(DateTime dt) => DateTime(dt.year, dt.month, dt.day);

  /// Signed text for the minute delay field — a positive value always shows
  /// its "+" prefix.
  String _signedText(int? minutes) {
    if (minutes == null) return '';
    return minutes >= 0 ? '+$minutes' : '$minutes';
  }

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final model = context.watch<TripFormModel>();
    final settings = context.watch<SettingsProvider>();
    final colours = MapColorPaletteHelper.getPalette(settings.mapColorPalette);
    final vType = model.vehicleType ?? VehicleType.train;
    final markerColour = colours[vType] ?? theme.colorScheme.primary;

    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(24, 8, 24, 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            loc.addTripWhenTitle,
            style: AppTheme.displayFont.copyWith(
              fontSize: 26,
              fontWeight: FontWeight.w700,
              color: theme.colorScheme.onSurface,
            ),
          ),
          const SizedBox(height: 16),

          // --- Mode selector ---
          AppStepsTabBar(
            fullWidth: true,
            tabs: [
              AppStepsTab(label: loc.addTripDateTypePrecise),
              AppStepsTab(label: loc.addTripDateTypeDate),
              AppStepsTab(label: loc.addTripDateTypeUnknown),
            ],
            selectedIndex: _modes.indexOf(_scheduleMode),
            onTabChanged: (index) {
              setState(() => _scheduleMode = _modes[index]);
              model.dateType = _modes[index];
            },
          ),
          const SizedBox(height: 16),

          if (_scheduleMode == DateType.precise)
            ..._buildPreciseMode(loc, theme, model, markerColour),
          if (_scheduleMode == DateType.date)
            ..._buildDateMode(loc, theme, model),
          if (_scheduleMode == DateType.unknown)
            ..._buildUnknownMode(loc, theme, model),
        ],
      ),
    );
  }

  /* --------------------------------------------------------------
     ******************** PRECISE *********************************
     --------------------------------------------------------------
  */
  List<Widget> _buildPreciseMode(
    AppLocalizations loc,
    ThemeData theme,
    TripFormModel model,
    Color markerColour,
  ) {
    final durationSummary = _durationSummary(loc, theme, model);

    return [
      // Global timezone helper, between the mode selector and the blocks.
      Text(
        loc.timezoneInformation,
        style: theme.textTheme.bodySmall?.copyWith(
          color: theme.colorScheme.onSurfaceVariant,
        ),
      ),
      const SizedBox(height: 16),
      _endpointCard(
        isDeparture: true,
        model: model,
        markerColour: markerColour,
      ),
      const SizedBox(height: 16),
      _endpointCard(
        isDeparture: false,
        model: model,
        markerColour: markerColour,
      ),
      if (model.hasDepartureAndArrivalDates() &&
          !model.arrivalIsAfterDeparture()) ...[
        const SizedBox(height: 12),
        ErrorBanner(message: loc.addTripDepartureAfterArrival),
      ],
      if (durationSummary != null) ...[
        const SizedBox(height: 16),
        durationSummary,
      ],
    ];
  }

  /// One departure/arrival block: header with route marker and label,
  /// scheduled date & time pickers with the endpoint timezone underneath,
  /// then the On time / Delayed selector and its optional sub-panel.
  Widget _endpointCard({
    required bool isDeparture,
    required TripFormModel model,
    required Color markerColour,
  }) {
    final theme = Theme.of(context);
    final loc = AppLocalizations.of(context)!;

    final label = isDeparture ? loc.addTripDeparture : loc.addTripArrival;
    final timezone = isDeparture
        ? tzmap.latLngToTimezoneString(
            model.departureLat!, model.departureLong!)
        : tzmap.latLngToTimezoneString(model.arrivalLat!, model.arrivalLong!);
    final date = isDeparture ? _departureDate : _arrivalDate;
    final time = isDeparture ? _departureTime : _arrivalTime;
    final delayed = isDeparture ? _departureDelayed : _arrivalDelayed;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: theme.cardColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: theme.colorScheme.outline),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              _RouteMarker(colour: markerColour, filled: !isDeparture),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  label.toUpperCase(),
                  style: theme.textTheme.labelSmall?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                    fontWeight: FontWeight.w600,
                    letterSpacing: 1.2,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                flex: 3,
                child: _PickerField(
                  icon: Icons.calendar_today,
                  text: date != null
                      ? formatDateTime(context, date, hasTime: false)
                      : '',
                  onTap: () => _pickScheduledDate(isDeparture, model),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                flex: 2,
                child: _PickerField(
                  text: time != null ? time.format(context) : '',
                  mono: true,
                  onTap: () => _pickScheduledTime(isDeparture, model),
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            timezone,
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 12),
          AppStepsTabBar(
            tabs: [
              AppStepsTab(label: loc.addTripOnTime),
              AppStepsTab(label: loc.addTripDelayed),
            ],
            selectedIndex: delayed ? 1 : 0,
            onTabChanged: (index) =>
                _setDelayed(isDeparture, index == 1, model),
          ),
          if (delayed) ...[
            const SizedBox(height: 12),
            _delayPanel(isDeparture, model),
          ],
        ],
      ),
    );
  }

  /// Sub-panel of a delayed endpoint: the signed minute input and the actual
  /// time picker side by side, kept synchronized in both directions.
  Widget _delayPanel(bool isDeparture, TripFormModel model) {
    final theme = Theme.of(context);
    final loc = AppLocalizations.of(context)!;
    final isDark = theme.brightness == Brightness.dark;

    final controller = isDeparture ? _departureDelayCtl : _arrivalDelayCtl;
    final minutes = isDeparture ? _departureDelayMinutes : _arrivalDelayMinutes;
    final scheduled =
        isDeparture ? model.departureDateLocal : model.arrivalDateLocal;

    // Green for early / in advance, red for late; neutral otherwise.
    final Color delayColour;
    if (minutes == null || minutes == 0) {
      delayColour = theme.colorScheme.onSurface;
    } else if (minutes > 0) {
      delayColour = theme.colorScheme.error;
    } else {
      delayColour = isDark ? AppColors.successDark : AppColors.successLight;
    }

    // The actual time always mirrors scheduled time + delay minutes. Before
    // any delay is entered it previews the scheduled time itself.
    final DateTime? actual = scheduled == null
        ? null
        : _withoutSeconds(scheduled).add(Duration(minutes: minutes ?? 0));
    final int dayShift = (actual == null || scheduled == null)
        ? 0
        : _dateOnly(actual).difference(_dateOnly(scheduled)).inDays;

    return Row(
      children: [
        Expanded(
          child: TextFormField(
            controller: controller,
            keyboardType: const TextInputType.numberWithOptions(
              decimal: false,
              signed: true,
            ),
            style: theme.textTheme.bodyLarge?.copyWith(
              color: delayColour,
              fontWeight: FontWeight.w700,
            ),
            decoration: InputDecoration(
              suffixText: 'min',
              suffixStyle: theme.textTheme.bodyMedium?.copyWith(
                color: delayColour,
                fontWeight: FontWeight.w600,
              ),
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 12,
                vertical: 14,
              ),
            ),
            inputFormatters: [
              FilteringTextInputFormatter.allow(RegExp(r'^[+-]?\d*$')),
              SignedIntFormatter(),
            ],
            onChanged: (value) =>
                _onDelayMinutesChanged(isDeparture, value, model),
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: _PickerField(
            icon: Icons.access_time,
            text: actual != null
                ? formatDateTime(context, actual, timeOnly: true)
                : '',
            trailing: dayShift != 0
                ? '${loc.daySingleCharacter}${dayShift > 0 ? '+' : '-'}${dayShift.abs()}'
                : null,
            mono: true,
            muted: minutes == null,
            onTap: () => _pickActualTime(isDeparture, model),
          ),
        ),
      ],
    );
  }

  /// Inline summary of the computed trip duration, shown at the bottom of
  /// the precise mode column once both endpoints have a full date & time.
  Widget? _durationSummary(
    AppLocalizations loc,
    ThemeData theme,
    TripFormModel model,
  ) {
    if (!model.hasDepartureAndArrivalDates() ||
        model.departureDate == null ||
        model.arrivalDate == null ||
        !model.arrivalIsAfterDeparture()) {
      return null;
    }

    final scheduled = model.arrivalDate!.difference(model.departureDate!);
    var actual = scheduled +
        Duration(
          minutes: (_arrivalDelayMinutes ?? 0) - (_departureDelayMinutes ?? 0),
        );
    if (actual.isNegative) actual = Duration.zero;

    final text = actual == scheduled
        ? loc.addTripDurationSummary(formatDurationFixed(actual))
        : loc.addTripDurationSummaryScheduled(
            formatDurationFixed(actual),
            formatDurationFixed(scheduled),
          );

    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Icon(
          Icons.schedule,
          size: 16,
          color: theme.colorScheme.onSurfaceVariant,
        ),
        const SizedBox(width: 6),
        Flexible(
          child: Text(
            text,
            style: AppTheme.monoFont.copyWith(
              fontSize: 12,
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
        ),
      ],
    );
  }

  Future<void> _pickScheduledDate(
      bool isDeparture, TripFormModel model) async {
    final departureTimezone = tzmap.latLngToTimezoneString(
        model.departureLat!, model.departureLong!);
    final arrivalTimezone =
        tzmap.latLngToTimezoneString(model.arrivalLat!, model.arrivalLong!);

    final picked = await showDatePicker(
      context: context,
      initialDate:
          (isDeparture ? _departureDate : _arrivalDate) ?? DateTime.now(),
      firstDate: DateTime(1900),
      lastDate: DateTime(DateTime.now().year + 200),
    );
    if (picked == null) return;

    if (isDeparture) {
      setState(() => _departureDate = picked);
      model.setDepartureDateTime(
          _departureDate, _departureTime, departureTimezone);
      if (_arrivalDate == null) {
        setState(() => _arrivalDate = _departureDate);
        model.setArrivalDateTime(_arrivalDate, _arrivalTime, arrivalTimezone);
      }
    } else {
      setState(() => _arrivalDate = picked);
      model.setArrivalDateTime(_arrivalDate, _arrivalTime, arrivalTimezone);
      if (_isDepartureFilledFromNow) {
        model.setDepartureDateTime(
            _departureDate, _departureTime, departureTimezone);
        _isDepartureFilledFromNow = false;
      }
    }
  }

  Future<void> _pickScheduledTime(
      bool isDeparture, TripFormModel model) async {
    final departureTimezone = tzmap.latLngToTimezoneString(
        model.departureLat!, model.departureLong!);
    final arrivalTimezone =
        tzmap.latLngToTimezoneString(model.arrivalLat!, model.arrivalLong!);

    final picked = await showTimePicker(
      context: context,
      initialTime:
          (isDeparture ? _departureTime : _arrivalTime) ?? TimeOfDay.now(),
    );
    if (picked == null) return;

    if (isDeparture) {
      setState(() => _departureTime = picked);
      model.setDepartureDateTime(
          _departureDate, _departureTime, departureTimezone);
    } else {
      setState(() => _arrivalTime = picked);
      model.setArrivalDateTime(_arrivalDate, _arrivalTime, arrivalTimezone);
      if (_isDepartureFilledFromNow) {
        model.setDepartureDateTime(
            _departureDate, _departureTime, departureTimezone);
        _isDepartureFilledFromNow = false;
      }
    }
  }

  void _setDelayed(bool isDeparture, bool delayed, TripFormModel model) {
    setState(() {
      if (isDeparture) {
        _departureDelayed = delayed;
        if (!delayed) {
          _departureDelayMinutes = null;
          _departureDelayCtl.clear();
        }
      } else {
        _arrivalDelayed = delayed;
        if (!delayed) {
          _arrivalDelayMinutes = null;
          _arrivalDelayCtl.clear();
        }
      }
    });

    if (!delayed) {
      if (isDeparture) {
        model.setDepartureDelay(false, null, null);
      } else {
        model.setArrivalDelay(false, null, null);
      }
    }
  }

  void _onDelayMinutesChanged(
      bool isDeparture, String value, TripFormModel model) {
    final minutes = int.tryParse(value);

    setState(() {
      if (isDeparture) {
        _departureDelayMinutes = minutes;
      } else {
        _arrivalDelayMinutes = minutes;
      }
    });

    if (isDeparture) {
      model.setDepartureDelay(true, null, minutes);
    } else {
      model.setArrivalDelay(true, null, minutes);
    }
  }

  Future<void> _pickActualTime(bool isDeparture, TripFormModel model) async {
    final loc = AppLocalizations.of(context)!;
    final scheduled =
        isDeparture ? model.departureDateLocal : model.arrivalDateLocal;

    if (scheduled == null) {
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

    final origin = _withoutSeconds(scheduled);
    final minutes = isDeparture ? _departureDelayMinutes : _arrivalDelayMinutes;

    final picked = await showRelativeDateTimePickerDialog(
      context: context,
      title: loc.addTripRealTime,
      origin: origin,
      initialDateTime:
          minutes == null ? null : origin.add(Duration(minutes: minutes)),
      originDateLabel: loc.addTripOriginDayLabel,
      resetLabel: loc.addTripResetToScheduled,
    );
    if (picked == null) return;

    final newMinutes = picked.difference(origin).inMinutes;

    setState(() {
      if (isDeparture) {
        _departureDelayMinutes = newMinutes;
        _departureDelayCtl.text = _signedText(newMinutes);
      } else {
        _arrivalDelayMinutes = newMinutes;
        _arrivalDelayCtl.text = _signedText(newMinutes);
      }
    });

    if (isDeparture) {
      model.setDepartureDelay(false, picked, newMinutes);
    } else {
      model.setArrivalDelay(false, picked, newMinutes);
    }
  }

  /* --------------------------------------------------------------
     ******************** DATE ************************************
     --------------------------------------------------------------
  */
  List<Widget> _buildDateMode(
    AppLocalizations loc,
    ThemeData theme,
    TripFormModel model,
  ) {
    return [
      Container(
        decoration: BoxDecoration(
          color: theme.cardColor,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: theme.colorScheme.outline),
        ),
        child: Column(
          children: [
            _CardLineItem(
              icon: Icons.calendar_today,
              label: loc.addTripDateTypeDate,
              value: Text(
                formatDateTime(
                  context,
                  _departureDateOnly ?? DateTime.now(),
                  hasTime: false,
                ),
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
              onTap: () => _pickDateOnly(model),
            ),
            Divider(height: 1, color: theme.dividerColor),
            _durationLineItem(loc, theme, model, DateType.date),
          ],
        ),
      ),
      const SizedBox(height: 12),
      Center(
        child: Text(
          loc.addTripDateOnlyHelper,
          textAlign: TextAlign.center,
          style: theme.textTheme.bodySmall?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
          ),
        ),
      ),
    ];
  }

  Future<void> _pickDateOnly(TripFormModel model) async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _departureDateOnly ?? DateTime.now(),
      firstDate: DateTime(1900),
      lastDate: DateTime(DateTime.now().year + 200),
    );
    if (picked == null) return;

    setState(() => _departureDateOnly = picked);
    model.departureDayDateOnly = picked;
  }

  /* --------------------------------------------------------------
     ******************** UNKNOWN *********************************
     --------------------------------------------------------------
  */
  List<Widget> _buildUnknownMode(
    AppLocalizations loc,
    ThemeData theme,
    TripFormModel model,
  ) {
    return [
      Text(
        loc.addTripRoughlyWhen.toUpperCase(),
        style: theme.textTheme.labelSmall?.copyWith(
          color: theme.colorScheme.onSurfaceVariant,
          fontWeight: FontWeight.w600,
          letterSpacing: 1.2,
        ),
      ),
      const SizedBox(height: 8),
      AppStepsTabBar(
        fullWidth: true,
        tabs: [
          AppStepsTab(label: loc.addTripPast),
          AppStepsTab(label: loc.addTripFuture),
        ],
        selectedIndex: _isPast ? 0 : 1,
        onTabChanged: (index) {
          setState(() => _isPast = index == 0);
          model.isPast = _isPast;
        },
      ),
      const SizedBox(height: 16),
      Container(
        decoration: BoxDecoration(
          color: theme.cardColor,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: theme.colorScheme.outline),
        ),
        child: _durationLineItem(loc, theme, model, DateType.unknown),
      ),
    ];
  }

  /* --------------------------------------------------------------
     ******************** SHARED DURATION *************************
     --------------------------------------------------------------
  */
  Widget _durationLineItem(
    AppLocalizations loc,
    ThemeData theme,
    TripFormModel model,
    DateType type,
  ) {
    final text = _durationText(model, type);

    return _CardLineItem(
      icon: Icons.schedule,
      label: '${loc.addTripDuration} (${loc.addTripOptional})',
      value: Text(
        text ?? loc.addTripDurationNotSet,
        style: theme.textTheme.titleMedium?.copyWith(
          fontWeight: FontWeight.w600,
          color: text == null
              ? theme.colorScheme.onSurfaceVariant
              : theme.colorScheme.onSurface,
        ),
      ),
      onTap: () => _pickDuration(model, type),
    );
  }

  String? _durationText(TripFormModel model, DateType type) {
    final hour = model.durationHourByType(type);
    final minute = model.durationMinuteByType(type);
    if (hour == null && minute == null) return null;
    return formatDurationFixed(
      Duration(hours: hour ?? 0, minutes: minute ?? 0),
    );
  }

  Future<void> _pickDuration(TripFormModel model, DateType type) async {
    final result = await showDialog<(int?, int?)>(
      context: context,
      builder: (_) => _DurationPickerDialog(
        initialHour: model.durationHourByType(type),
        initialMinute: model.durationMinuteByType(type),
      ),
    );
    if (result == null) return;

    setState(() {});
    model.setDuration(type, result.$1, result.$2);
  }
}

/// Trip route marker matching the route step: hollow rounded square for the
/// departure, filled with the vehicle colour for the arrival.
class _RouteMarker extends StatelessWidget {
  const _RouteMarker({required this.colour, required this.filled});

  final Color colour;
  final bool filled;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 14,
      height: 14,
      decoration: BoxDecoration(
        color: filled ? colour : Colors.transparent,
        borderRadius: BorderRadius.circular(4),
        border: Border.all(color: colour, width: 2.5),
      ),
    );
  }
}

/// Input-styled tappable field showing a picked date or time value, with an
/// optional leading icon and an optional trailing marker (e.g. "D+1").
class _PickerField extends StatelessWidget {
  const _PickerField({
    this.icon,
    required this.text,
    this.trailing,
    this.mono = false,
    this.muted = false,
    required this.onTap,
  });

  final IconData? icon;
  final String text;
  final String? trailing;
  final bool mono;
  final bool muted;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final textColour = muted
        ? theme.colorScheme.onSurfaceVariant
        : theme.colorScheme.onSurface;
    final style = mono
        ? AppTheme.monoFont.copyWith(
            fontSize: 14,
            fontWeight: FontWeight.w700,
            color: textColour,
          )
        : theme.textTheme.bodyMedium?.copyWith(
            fontWeight: FontWeight.w600,
            color: textColour,
          );

    return Material(
      color: theme.inputDecorationTheme.fillColor,
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          height: 48,
          padding: const EdgeInsets.symmetric(horizontal: 12),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: theme.colorScheme.outline),
          ),
          child: Row(
            children: [
              if (icon != null) ...[
                Icon(
                  icon,
                  size: 16,
                  color: theme.colorScheme.onSurfaceVariant,
                ),
                const SizedBox(width: 8),
              ],
              Expanded(
                child: Text(
                  text,
                  style: style,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              if (trailing != null) ...[
                const SizedBox(width: 4),
                Text(
                  trailing!,
                  style: theme.textTheme.labelSmall?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

/// One tappable line item of a grouped card: small icon + uppercase label on
/// the first line, current value underneath.
class _CardLineItem extends StatelessWidget {
  const _CardLineItem({
    required this.icon,
    required this.label,
    required this.value,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final Widget value;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icon, size: 14, color: theme.colorScheme.primary),
                const SizedBox(width: 6),
                Text(
                  label.toUpperCase(),
                  style: theme.textTheme.labelSmall?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                    fontWeight: FontWeight.w600,
                    letterSpacing: 1.2,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 6),
            value,
          ],
        ),
      ),
    );
  }
}

/// Dialog editing the optional trip duration as hours + minutes. Pops with a
/// record of the two values on confirmation, or null when cancelled.
class _DurationPickerDialog extends StatefulWidget {
  const _DurationPickerDialog({this.initialHour, this.initialMinute});

  final int? initialHour;
  final int? initialMinute;

  @override
  State<_DurationPickerDialog> createState() => _DurationPickerDialogState();
}

class _DurationPickerDialogState extends State<_DurationPickerDialog> {
  late final TextEditingController _hourCtl =
      TextEditingController(text: widget.initialHour?.toString() ?? '');
  late final TextEditingController _minuteCtl =
      TextEditingController(text: widget.initialMinute?.toString() ?? '');

  @override
  void dispose() {
    _hourCtl.dispose();
    _minuteCtl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context)!;
    final materialLoc = MaterialLocalizations.of(context);
    final localeCode = Localizations.localeOf(context).languageCode;
    final durLoc = DurationLocale.fromLanguageCode(localeCode) ??
        const EnglishDurationLocale();

    return AlertDialog(
      title: Text(loc.addTripDuration),
      content: Row(
        children: [
          Expanded(
            child: TextFormField(
              controller: _hourCtl,
              keyboardType: TextInputType.number,
              inputFormatters: [FilteringTextInputFormatter.digitsOnly],
              decoration: InputDecoration(
                labelText: durLoc.hour(0, false),
                border: const OutlineInputBorder(),
              ),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: TextFormField(
              controller: _minuteCtl,
              keyboardType: TextInputType.number,
              inputFormatters: [FilteringTextInputFormatter.digitsOnly],
              decoration: InputDecoration(
                labelText: durLoc.minute(0, false),
                border: const OutlineInputBorder(),
              ),
            ),
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: Text(materialLoc.cancelButtonLabel),
        ),
        FilledButton(
          onPressed: () => Navigator.of(context).pop(
            (int.tryParse(_hourCtl.text), int.tryParse(_minuteCtl.text)),
          ),
          child: Text(materialLoc.okButtonLabel),
        ),
      ],
    );
  }
}
