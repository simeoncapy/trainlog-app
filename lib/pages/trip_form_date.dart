import 'package:duration/locale.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:timezone/timezone.dart' as tz;
import 'package:trainlog_app/data/models/trip_form_model.dart';
import 'package:trainlog_app/l10n/app_localizations.dart';
import 'package:lat_lng_to_timezone/lat_lng_to_timezone.dart' as tzmap;
import 'package:trainlog_app/utils/date_utils.dart';
import 'package:trainlog_app/widgets/error_banner.dart';

class TripFormDate extends StatefulWidget {
  const TripFormDate({super.key});

  @override
  State<TripFormDate> createState() => _TripFormDateState();
}

class _TripFormDateState extends State<TripFormDate> {
  DateType _scheduleMode = DateType.precise;
  DateTime? _departureDate;// = DateTime.now();
  DateTime? _departureDateOnly;
  TimeOfDay? _departureTime;
  DateTime? _arrivalDate;
  TimeOfDay? _arrivalTime;
  bool _isPast = true;
  bool _isDepartureFilledFromNow = false;

  @override
  void initState() {
    super.initState();

    final model = context.read<TripFormModel>();
    _scheduleMode = model.dateType;
    _isPast = model.isPast;
    _departureDateOnly = model.departureDayDateOnly;
    _initPreciseFromModel(model);
  }

  void _initPreciseFromModel(TripFormModel model) {
    // Departure
    if (model.departureLat != null &&
        model.departureLong != null) {

      final departureTimezone = tzmap.latLngToTimezoneString(
        model.departureLat!,
        model.departureLong!,
      );           

      if (model.departureDate == null) {
        final now = DateTime.now();

        _departureDate = DateTime(now.year, now.month, now.day);
        _departureTime = TimeOfDay(hour: now.hour, minute: now.minute);
        _isDepartureFilledFromNow = true;
      }
      else {
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

  DateTime _convertUtcToTimezone(DateTime utc, String timezone) {
    final location = tz.getLocation(timezone);
    return tz.TZDateTime.from(utc, location);
  }
  
  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context)!;
    final model = context.watch<TripFormModel>();

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [         
              // --- Mode Selector ---
              SizedBox(
                width: double.infinity,
                child: SegmentedButton<DateType>(
                  segments: [
                    ButtonSegment(value: DateType.precise, label: FittedBox(child: Text(loc.addTripDateTypePrecise, softWrap: false))),
                    ButtonSegment(value: DateType.unknown, label: FittedBox(child: Text(loc.addTripDateTypeUnknown, softWrap: false))),
                    ButtonSegment(value: DateType.date,    label: FittedBox(child: Text(loc.addTripDateTypeDate, softWrap: false))),
                  ],
                  selected: {_scheduleMode},
                  onSelectionChanged: (value) {
                    setState(() => _scheduleMode = value.first
                    );
                    model.dateType = value.first;
                  },
                ),
              ),
              //const Divider(height: 24),
              const SizedBox(height: 16),
              if (_scheduleMode == DateType.precise) ..._buildPreciseMode(loc, model),
              if (_scheduleMode == DateType.unknown) ..._buildUnknownMode(loc, model),
              if (_scheduleMode == DateType.date) ..._buildDateMode(loc, model),
            ],
          ),
          const SizedBox(height: 16),
        ],
      ),
    );
  }
  
  /* --------------------------------------------------------------
     ******************** PRECISE *********************************
     --------------------------------------------------------------
  */
  _buildPreciseMode(AppLocalizations loc, TripFormModel model) {
    String departureTimezone = tzmap.latLngToTimezoneString(model.departureLat!, model.departureLong!);
    String arrivalTimezone = tzmap.latLngToTimezoneString(model.arrivalLat!, model.arrivalLong!);

    return [
      Text(loc.addTripStartDate),
      const SizedBox(height: 4),
      Row(
        children: [
          Expanded(
            child: TextFormField(
              readOnly: true,
              controller: TextEditingController(
                text: _departureDate != null
                    ? formatDateTime(context, _departureDate!, hasTime: false)
                    //? MaterialLocalizations.of(context).formatCompactDate(_departureDate!)
                        //.formatMediumDate(_departureDate!)
                    : '',
              ),
              decoration: InputDecoration(
                border: const OutlineInputBorder(),
                helperText: "",
                suffixIcon: IconButton(
                  icon: const Icon(Icons.calendar_today),
                  onPressed: () async {
                    final picked = await showDatePicker(
                      context: context,
                      initialDate: _departureDate ?? DateTime.now(),
                      firstDate: DateTime(1900),
                      lastDate: DateTime(DateTime.now().year+200),
                    );
                    if (picked != null) {
                      setState(() => _departureDate = picked);
                      model.setDepartureDateTime(_departureDate, _departureTime, departureTimezone);
                    }
                  },
                ),
              ),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: TextFormField(
              readOnly: true,
              controller: TextEditingController(
                text: _departureTime != null
                    ? _departureTime!.format(context)
                    : '',
              ),     
              decoration: InputDecoration(
                border: const OutlineInputBorder(),
                helperText: departureTimezone,
                suffixIcon: IconButton(
                  icon: const Icon(Icons.access_time),
                  onPressed: () async {
                    final picked = await showTimePicker(
                      context: context,
                      initialTime: _departureTime ?? TimeOfDay.now(),
                    );
                    if (picked != null) {
                      setState(() => _departureTime = picked);
                      model.setDepartureDateTime(_departureDate, _departureTime, departureTimezone);
                    }
                  },
                ),
              ),
            ),
          ),
        ],
      ),
      const SizedBox(height: 16),
      Text(loc.addTripEndDate),
      const SizedBox(height: 4),
      Row(
        children: [
          Expanded(
            child: TextFormField(
              readOnly: true,
              controller: TextEditingController(
                text: _arrivalDate != null
                    ? formatDateTime(context, _arrivalDate!, hasTime: false)
                        //.formatMediumDate(_arrivalDate!)
                    : '',
              ),
              decoration: InputDecoration(
                border: const OutlineInputBorder(),
                helperText: "",
                suffixIcon: IconButton(
                  icon: const Icon(Icons.calendar_today),
                  onPressed: () async {
                    final picked = await showDatePicker(
                      context: context,
                      initialDate: _arrivalDate ?? DateTime.now(),
                      firstDate: DateTime(1900),
                      lastDate: DateTime(DateTime.now().year+200),
                    );
                    if (picked != null) {
                      setState(() => _arrivalDate = picked);
                      model.setArrivalDateTime(_arrivalDate, _arrivalTime, arrivalTimezone);
                      if(_isDepartureFilledFromNow) {
                        model.setDepartureDateTime(_departureDate, _departureTime, departureTimezone);
                        _isDepartureFilledFromNow = false;
                      }
                    }
                  },
                ),
              ),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: TextFormField(
              readOnly: true,
              controller: TextEditingController(
                text: _arrivalTime != null
                    ? _arrivalTime!.format(context)
                    : '',
              ),
              decoration: InputDecoration(
                border: const OutlineInputBorder(),
                helperText: arrivalTimezone,
                suffixIcon: IconButton(
                  icon: const Icon(Icons.access_time),
                  onPressed: () async {
                    final picked = await showTimePicker(
                      context: context,
                      initialTime: _arrivalTime ?? TimeOfDay.now(),
                    );
                    if (picked != null) {
                      setState(() => _arrivalTime = picked);
                      model.setArrivalDateTime(_arrivalDate, _arrivalTime, arrivalTimezone);
                      if(_isDepartureFilledFromNow) {
                        model.setDepartureDateTime(_departureDate, _departureTime, departureTimezone);
                        _isDepartureFilledFromNow = false;
                      }
                    }
                  },
                ),
              ),
            ),
          ),
        ],
      ),
      const SizedBox(height: 8,),
      Text(
        loc.timezoneInformation,
        style: Theme.of(context).textTheme.bodySmall,
      ),
      if(model.hasDepartureAndArrivalDates() && !model.arrivalIsAfterDeparture())
        ...[
          SizedBox(height: 12,),
          ErrorBanner(
            message: loc.addTripDepartureAfterArrival,
          )
        ],
    ];
  }
  
  /* --------------------------------------------------------------
     ******************** UNKNOWN *********************************
     --------------------------------------------------------------
  */
  _buildUnknownMode(AppLocalizations loc, TripFormModel model) {
    final localeCode = Localizations.localeOf(context).languageCode;
    final durLoc = DurationLocale.fromLanguageCode(localeCode) ?? const EnglishDurationLocale();
    return [
      Row(
        children: [
          Expanded(
            child: RadioListTile<bool>(
              value: true,
              groupValue: _isPast,
              title: Text(loc.addTripPast),
              onChanged: (v) {
                setState(() => _isPast = v!);
                model.isPast = _isPast;
              },
            ),
          ),
          Expanded(
            child: RadioListTile<bool>(
              value: false,
              groupValue: _isPast,
              title: Text(loc.addTripFuture),
              onChanged: (v) {
                setState(() => _isPast = v!);
                model.isPast = _isPast;
              },
            ),
          ),
        ],
      ),
      const SizedBox(height: 8),
      Text("${loc.addTripDuration} (${loc.facultative})"),
      const SizedBox(height: 4),
      Row(
        children: [
          Expanded(
            child: TextFormField(
              key: const ValueKey('duration_hour_unknown'),
              keyboardType: TextInputType.number,
              inputFormatters: [
                FilteringTextInputFormatter.digitsOnly,
              ],
              decoration: InputDecoration(
                labelText: durLoc.hour(0, false),
                border: OutlineInputBorder(),
              ),
              onChanged: (v) {
                model.setDurationHour(DateType.unknown, int.tryParse(v));
              },
              initialValue: model.durationHourByType(DateType.unknown)?.toString(),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: TextFormField(
              key: const ValueKey('duration_minute_unknown'),
              keyboardType: TextInputType.number,
              inputFormatters: [
                FilteringTextInputFormatter.digitsOnly,
              ],
              decoration: InputDecoration(
                labelText: durLoc.minute(0, false),
                border: OutlineInputBorder(),
              ),
              onChanged: (v) {
                model.setDurationMinute(DateType.unknown, int.tryParse(v));
              },
              initialValue: model.durationMinuteByType(DateType.unknown)?.toString(),
            ),
          ),
        ],
      ),
    ];
  }
  
  /* --------------------------------------------------------------
     ******************** DATE ************************************
     --------------------------------------------------------------
  */
  _buildDateMode(AppLocalizations loc, TripFormModel model) {
    final localeCode = Localizations.localeOf(context).languageCode;
    final durLoc = DurationLocale.fromLanguageCode(localeCode) ?? const EnglishDurationLocale();
    return [
      Text(loc.addTripStartDate),
      const SizedBox(height: 4),
      TextFormField(
        readOnly: true,
        controller: TextEditingController(
          text: formatDateTime(context, _departureDateOnly ?? DateTime.now(), hasTime: false),
          // MaterialLocalizations.of(context)
          //     .formatMediumDate(_departureDateOnly ?? DateTime.now()),
        ),
        decoration: InputDecoration(
          border: const OutlineInputBorder(),
          suffixIcon: IconButton(
            icon: const Icon(Icons.calendar_today),
            onPressed: () async {
              final picked = await showDatePicker(
                context: context,
                initialDate: _departureDateOnly ?? DateTime.now(),
                firstDate: DateTime(1900),
                lastDate: DateTime(DateTime.now().year+200),
              );
              if (picked != null) {
                setState(() => _departureDateOnly = picked);
                model.departureDayDateOnly = picked;
              }
            },
          ),
        ),
      ),
      const SizedBox(height: 12),
      Text("${loc.addTripDuration} (${loc.facultative})"),
      const SizedBox(height: 4),
      Row(
        children: [
          Expanded(
            child: TextFormField(
              key: const ValueKey('duration_hour_date'),
              keyboardType: TextInputType.number,
              inputFormatters: [
                FilteringTextInputFormatter.digitsOnly,
              ],
              decoration: InputDecoration(
                labelText: durLoc.hour(0, false),
                border: OutlineInputBorder(),
              ),
              onChanged: (v) {
                model.setDurationHour(DateType.date, int.tryParse(v));
              },
              initialValue: model.durationHourByType(DateType.date)?.toString(),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: TextFormField(
              key: const ValueKey('duration_minute_date'),
              keyboardType: TextInputType.number,
              inputFormatters: [
                FilteringTextInputFormatter.digitsOnly,
              ],
              decoration: InputDecoration(
                labelText: durLoc.minute(0, false),
                border: OutlineInputBorder(),
              ),
              onChanged: (v) {
                model.setDurationMinute(DateType.date, int.tryParse(v));
              },
              initialValue: model.durationMinuteByType(DateType.date)?.toString(),
            ),
          ),
        ],
      ),
    ];
  }
}
