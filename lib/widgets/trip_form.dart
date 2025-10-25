import 'package:flutter/material.dart';
import 'package:currency_picker/currency_picker.dart';
import 'package:trainlog_app/data/models/trips.dart';
import 'package:trainlog_app/l10n/app_localizations.dart';

class TripForm extends StatefulWidget {
  const TripForm({super.key});

  @override
  State<TripForm> createState() => _TripFormState();
}

class _TripFormState extends State<TripForm> {
  VehicleType? _selectedVehicleType;
  bool _detailsExpanded = false;
  String? _currencyCode = 'EUR';
  final TextEditingController _priceController = TextEditingController();
  String _scheduleMode = 'precis';
  DateTime? _departureDate = DateTime.now();
  TimeOfDay? _departureTime;
  DateTime? _arrivalDate;
  TimeOfDay? _arrivalTime;
  bool _isPast = true;
  int? _durationHours;
  int? _durationMinutes;


  @override
  void dispose() {
    _priceController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context)!;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          /// Transportation Mode Dropdown
          DropdownButtonFormField<VehicleType>(
            decoration: const InputDecoration(
              labelText: 'Transportation mode',
              border: OutlineInputBorder(),
            ),
            value: _selectedVehicleType,
            items: VehicleType.values
                .where((v) => v != VehicleType.unknown && v != VehicleType.poi)
                .map((type) => DropdownMenuItem<VehicleType>(
                      value: type,
                      child: Row(
                        children: [
                          type.icon(),
                          const SizedBox(width: 8),
                          Text(type.label(context)),
                        ],
                      ),
                    ))
                .toList(),
            onChanged: (value) => setState(() => _selectedVehicleType = value),
          ),
          const SizedBox(height: 16),

          /// Departure & Arrival (grouped box)
          Container(
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.surfaceContainerHighest,
              borderRadius: BorderRadius.circular(12),
            ),
            padding: const EdgeInsets.all(12),
            child: Column(
              children: [
                CheckboxListTile(
                  title: const Text('Manual departure'),
                  value: false,
                  onChanged: (_) {},
                  controlAffinity: ListTileControlAffinity.leading,
                ),
                TextFormField(
                  decoration: const InputDecoration(
                    labelText: 'Departure station',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 12),
                CheckboxListTile(
                  title: const Text('Manual arrival'),
                  value: false,
                  onChanged: (_) {},
                  controlAffinity: ListTileControlAffinity.leading,
                ),
                TextFormField(
                  decoration: const InputDecoration(
                    labelText: 'Arrival station',
                    border: OutlineInputBorder(),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),

          /// Carrier and Line
          TextFormField(
            decoration: const InputDecoration(
              labelText: 'Operator',
              prefixIcon: Icon(Icons.business),
              border: OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 16),
          TextFormField(
            decoration: const InputDecoration(
              labelText: 'Line',
              border: OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 16),

          Container(
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.surfaceContainerHighest,
              borderRadius: BorderRadius.circular(12),
              // border: Border.all(
              //   color: Theme.of(context).dividerColor.withOpacity(0.3),
              // ),
            ),
            padding: const EdgeInsets.all(12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Horaires', style: Theme.of(context).textTheme.titleMedium),
                const SizedBox(height: 8),

                // --- Mode Selector ---
                SegmentedButton<String>(
                  segments: const [
                    ButtonSegment(value: 'precis', label: Text('Précis')),
                    ButtonSegment(value: 'inconnus', label: Text('Inconnus')),
                    ButtonSegment(value: 'date', label: Text('Date')),
                  ],
                  selected: {_scheduleMode},
                  onSelectionChanged: (value) {
                    setState(() => _scheduleMode = value.first);
                  },
                ),
                const Divider(height: 24),

                // --- PRÉCIS MODE ---
                if (_scheduleMode == 'precis') ...[
                  Text('Début du trajet'),
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
                  Text('Fin du trajet'),
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
                ],

                // --- INCONNUS MODE ---
                if (_scheduleMode == 'inconnus') ...[
                  Row(
                    children: [
                      Expanded(
                        child: RadioListTile<bool>(
                          value: true,
                          groupValue: _isPast,
                          title: const Text('Passé'),
                          onChanged: (v) => setState(() => _isPast = v!),
                        ),
                      ),
                      Expanded(
                        child: RadioListTile<bool>(
                          value: false,
                          groupValue: _isPast,
                          title: const Text('Futur'),
                          onChanged: (v) => setState(() => _isPast = v!),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text('Durée'),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      Expanded(
                        child: TextFormField(
                          keyboardType: TextInputType.number,
                          decoration: const InputDecoration(
                            labelText: 'Heures',
                            border: OutlineInputBorder(),
                          ),
                          onChanged: (v) => _durationHours = int.tryParse(v),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: TextFormField(
                          keyboardType: TextInputType.number,
                          decoration: const InputDecoration(
                            labelText: 'Minutes',
                            border: OutlineInputBorder(),
                          ),
                          onChanged: (v) => _durationMinutes = int.tryParse(v),
                        ),
                      ),
                    ],
                  ),
                ],

                // --- DATE MODE ---
                if (_scheduleMode == 'date') ...[
                  Text('Début du trajet'),
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
                  Text('Durée'),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      Expanded(
                        child: TextFormField(
                          keyboardType: TextInputType.number,
                          decoration: const InputDecoration(
                            labelText: 'Heures',
                            border: OutlineInputBorder(),
                          ),
                          onChanged: (v) => _durationHours = int.tryParse(v),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: TextFormField(
                          keyboardType: TextInputType.number,
                          decoration: const InputDecoration(
                            labelText: 'Minutes',
                            border: OutlineInputBorder(),
                          ),
                          onChanged: (v) => _durationMinutes = int.tryParse(v),
                        ),
                      ),
                    ],
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(height: 16),

          /// Expandable Details
          ExpansionTile(
            title: const Text('Details'),
            initiallyExpanded: _detailsExpanded,
            onExpansionChanged: (expanded) {
              setState(() => _detailsExpanded = expanded);
            },
            children: [
              TextFormField(
                decoration: const InputDecoration(
                  labelText: 'Material',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 12),
              TextFormField(
                decoration: const InputDecoration(
                  labelText: 'Registration',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 12),
              TextFormField(
                decoration: const InputDecoration(
                  labelText: 'Seat',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 12),
              TextFormField(
                decoration: const InputDecoration(
                  labelText: 'Notes',
                  border: OutlineInputBorder(),
                ),
                maxLines: 2,
              ),
              const SizedBox(height: 16),

              /// Price, currency, and purchase date
              Row(
                children: [
                  Expanded(
                    child: TextFormField(
                      controller: _priceController,
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(
                        labelText: 'Ticket price',
                        border: OutlineInputBorder(),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () {
                        showCurrencyPicker(
                          context: context,
                          showFlag: true,
                          showCurrencyName: true,
                          onSelect: (currency) {
                            setState(() => _currencyCode = currency.code);
                          },
                        );
                      },
                      child: Text(_currencyCode ?? 'EUR'),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: TextFormField(
                      decoration: const InputDecoration(
                        labelText: 'Purchase date',
                        border: OutlineInputBorder(),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
            ],
          ),

          // /// Validate button
          // const SizedBox(height: 24),
          // Center(
          //   child: ElevatedButton(
          //     onPressed: () {},
          //     style: ElevatedButton.styleFrom(
          //       padding:
          //           const EdgeInsets.symmetric(horizontal: 50, vertical: 14),
          //       shape: RoundedRectangleBorder(
          //           borderRadius: BorderRadius.circular(24)),
          //     ),
          //     child: const Text('Validate'),
          //   ),
          // ),
        ],
      ),
    );
  }
}
