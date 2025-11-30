import 'package:duration/locale.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:trainlog_app/data/models/trip_form_model.dart';
import 'package:trainlog_app/l10n/app_localizations.dart';
import 'package:lat_lng_to_timezone/lat_lng_to_timezone.dart' as tzmap;
import 'package:trainlog_app/utils/date_utils.dart';

class TripFormDate extends StatefulWidget {
  const TripFormDate({super.key});

  @override
  State<TripFormDate> createState() => _TripFormDateState();
}

class _TripFormDateState extends State<TripFormDate> {
  DateType _scheduleMode = DateType.precise;
  DateTime? _departureDate = DateTime.now();
  TimeOfDay? _departureTime;
  DateTime? _arrivalDate;
  TimeOfDay? _arrivalTime;
  bool _isPast = true;
  int? _durationHours;
  int? _durationMinutes;
  
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
                    setState(() => _scheduleMode = value.first);
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
                    ? MaterialLocalizations.of(context)
                        .formatMediumDate(_departureDate!)
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
                      lastDate: DateTime(2500),
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
                    ? MaterialLocalizations.of(context)
                        .formatMediumDate(_arrivalDate!)
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
                      lastDate: DateTime(2500),
                    );
                    if (picked != null) {
                      setState(() => _arrivalDate = picked);
                      model.setArrivalDateTime(_arrivalDate, _arrivalTime, arrivalTimezone);
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
    ];
  }
  
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
              onChanged: (v) => setState(() => _isPast = v!),
            ),
          ),
          Expanded(
            child: RadioListTile<bool>(
              value: false,
              groupValue: _isPast,
              title: Text(loc.addTripFuture),
              onChanged: (v) => setState(() => _isPast = v!),
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
              keyboardType: TextInputType.number,
              decoration: InputDecoration(
                labelText: durLoc.hour(0, false),
                border: OutlineInputBorder(),
              ),
              onChanged: (v) => _durationHours = int.tryParse(v),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: TextFormField(
              keyboardType: TextInputType.number,
              decoration: InputDecoration(
                labelText: durLoc.minute(0, false),
                border: OutlineInputBorder(),
              ),
              onChanged: (v) => _durationMinutes = int.tryParse(v),
            ),
          ),
        ],
      ),
    ];
  }
  
  _buildDateMode(AppLocalizations loc, TripFormModel model) {
    final localeCode = Localizations.localeOf(context).languageCode;
    final durLoc = DurationLocale.fromLanguageCode(localeCode) ?? const EnglishDurationLocale();
    return [
      Text(loc.addTripStartDate),
      const SizedBox(height: 4),
      TextFormField(
        readOnly: true,
        controller: TextEditingController(
          text: MaterialLocalizations.of(context)
              .formatMediumDate(_departureDate ?? DateTime.now()),
        ),
        decoration: InputDecoration(
          border: const OutlineInputBorder(),
          suffixIcon: IconButton(
            icon: const Icon(Icons.calendar_today),
            onPressed: () async {
              final picked = await showDatePicker(
                context: context,
                initialDate: _departureDate ?? DateTime.now(),
                firstDate: DateTime(1900),
                lastDate: DateTime(2500),
              );
              if (picked != null) {
                setState(() => _departureDate = picked);
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
              keyboardType: TextInputType.number,
              decoration: InputDecoration(
                labelText: durLoc.hour(0, false),
                border: OutlineInputBorder(),
              ),
              onChanged: (v) => _durationHours = int.tryParse(v),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: TextFormField(
              keyboardType: TextInputType.number,
              decoration: InputDecoration(
                labelText: durLoc.minute(0, false),
                border: OutlineInputBorder(),
              ),
              onChanged: (v) => _durationMinutes = int.tryParse(v),
            ),
          ),
        ],
      ),
    ];
  }
}
