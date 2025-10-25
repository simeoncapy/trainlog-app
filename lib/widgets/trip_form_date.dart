import 'package:duration/locale.dart';
import 'package:flutter/material.dart';
import 'package:trainlog_app/l10n/app_localizations.dart';

class TripFormDate extends StatefulWidget {
  const TripFormDate({super.key});

  @override
  State<TripFormDate> createState() => _TripFormDateState();
}

class _TripFormDateState extends State<TripFormDate> {
  String _scheduleMode = 'precise';
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
                child: SegmentedButton<String>(
                  segments: [
                    ButtonSegment(value: 'precise', label: FittedBox(child: Text(loc.addTripDateTypePrecise, softWrap: false))),
                    ButtonSegment(value: 'unknown', label: FittedBox(child: Text(loc.addTripDateTypeUnknown, softWrap: false))),
                    ButtonSegment(value: 'date', label: FittedBox(child: Text(loc.addTripDateTypeDate, softWrap: false))),
                  ],
                  selected: {_scheduleMode},
                  onSelectionChanged: (value) {
                    setState(() => _scheduleMode = value.first);
                  },
                ),
              ),
              //const Divider(height: 24),
              const SizedBox(height: 16),
              if (_scheduleMode == 'precise') ..._buildPreciseMode(loc),
              if (_scheduleMode == 'unknown') ..._buildUnknownMode(loc),
              if (_scheduleMode == 'date') ..._buildDateMode(loc),
            ],
          ),
          const SizedBox(height: 16),
        ],
      ),
    );
  }
  
  _buildPreciseMode(AppLocalizations loc) {
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
                suffixIcon: IconButton(
                  icon: const Icon(Icons.calendar_today),
                  onPressed: () async {
                    final picked = await showDatePicker(
                      context: context,
                      initialDate: _departureDate ?? DateTime.now(),
                      firstDate: DateTime(2000),
                      lastDate: DateTime(2100),
                    );
                    if (picked != null) {
                      setState(() => _departureDate = picked);
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
                suffixIcon: IconButton(
                  icon: const Icon(Icons.access_time),
                  onPressed: () async {
                    final picked = await showTimePicker(
                      context: context,
                      initialTime: _departureTime ?? TimeOfDay.now(),
                    );
                    if (picked != null) {
                      setState(() => _departureTime = picked);
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
                suffixIcon: IconButton(
                  icon: const Icon(Icons.calendar_today),
                  onPressed: () async {
                    final picked = await showDatePicker(
                      context: context,
                      initialDate: _arrivalDate ?? DateTime.now(),
                      firstDate: DateTime(2000),
                      lastDate: DateTime(2100),
                    );
                    if (picked != null) {
                      setState(() => _arrivalDate = picked);
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
                suffixIcon: IconButton(
                  icon: const Icon(Icons.access_time),
                  onPressed: () async {
                    final picked = await showTimePicker(
                      context: context,
                      initialTime: _arrivalTime ?? TimeOfDay.now(),
                    );
                    if (picked != null) {
                      setState(() => _arrivalTime = picked);
                    }
                  },
                ),
              ),
            ),
          ),
        ],
      ),
    ];
  }
  
  _buildUnknownMode(AppLocalizations loc) {
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
      Text(loc.addTripDuration),
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
  
  _buildDateMode(AppLocalizations loc) {
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
                firstDate: DateTime(2000),
                lastDate: DateTime(2100),
              );
              if (picked != null) {
                setState(() => _departureDate = picked);
              }
            },
          ),
        ),
      ),
      const SizedBox(height: 12),
      Text(loc.addTripDuration),
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
