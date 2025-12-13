import 'package:flutter/material.dart';
import 'package:currency_picker/currency_picker.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:trainlog_app/data/models/trip_form_model.dart';
import 'package:trainlog_app/l10n/app_localizations.dart';
import 'package:trainlog_app/utils/date_utils.dart';
import 'package:trainlog_app/utils/number_formatter.dart';
import 'package:trainlog_app/widgets/titled_container.dart';
import 'package:trainlog_app/widgets/trip_visibility_selector.dart';
import 'package:trainlog_app/widgets/vehicle_energy_selector.dart';

class TripFormDetails extends StatefulWidget {
  const TripFormDetails({super.key});

  @override
  State<TripFormDetails> createState() => _TripFormDetailsState();
}

class _TripFormDetailsState extends State<TripFormDetails> {
  late String? _currencyCode;
  DateTime? _selectedPurchaseDate;

  @override
  void initState() {
    super.initState();

    final model = context.read<TripFormModel>();
    _currencyCode = model.currencyCode ?? "EUR"; // TODO get user default currency
    _selectedPurchaseDate = model.purchaseDate ?? DateTime.now();
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
          Text(loc.addTripFacultative),
          const SizedBox(height: 12),
          /// Expandable Details
          TextFormField(
            decoration: InputDecoration(
              labelText: loc.addTripLine,
              border: OutlineInputBorder(),
            ),
            initialValue: model.line,
            onChanged: (value) {
              model.line = value;
            },
          ),
          const SizedBox(height: 12), 
          TextFormField(
            decoration: InputDecoration(
              labelText: loc.addTripMaterial,
              border: OutlineInputBorder(),
            ),
            initialValue: model.material,
            onChanged: (value) {
              model.material = value;
            },
          ),
          const SizedBox(height: 12),
          TextFormField(
            decoration: InputDecoration(
              labelText: loc.addTripRegistration,
              border: OutlineInputBorder(),
            ),
            initialValue: model.registration,
            onChanged: (value) {
              model.registration = value;
            },
          ),
          const SizedBox(height: 12),
          TextFormField(
            decoration: InputDecoration(
              labelText: loc.addTripSeat,
              border: OutlineInputBorder(),
            ),
            initialValue: model.seat,
            onChanged: (value) {
              model.seat = value;
            },
          ),
          const SizedBox(height: 12),
          TextFormField(
            decoration: InputDecoration(
              labelText: loc.addTripNotes,
              border: OutlineInputBorder(),
            ),
            initialValue: model.notes,
            onChanged: (value) {
              model.notes = value;
            },
            maxLines: 2,
          ),
          const SizedBox(height: 16),
          TitledContainer(
            title: loc.addTripTicketTitle,
            content: Column(
              children: [
                Row(
                  children: [
                    Expanded(
                      child: TextFormField(
                        keyboardType: TextInputType.number,
                        inputFormatters: [
                          DecimalTextInputFormatter(),
                        ],
                        decoration: InputDecoration(
                          labelText: loc.addTripTicketPrice,
                          border: const OutlineInputBorder(),
                        ),
                        initialValue: model.price?.toString(),
                        onChanged: (value) {
                          model.price = double.tryParse(
                            value.replaceAll(',', '.'),
                          );
                        },
                      ),
                    ),
                    const SizedBox(width: 8),
                    OutlinedButton(
                      onPressed: () {
                        showCurrencyPicker(
                          context: context,
                          showFlag: true,
                          showCurrencyName: true,
                          onSelect: (currency) {
                            setState(() => _currencyCode = currency.code);
                            model.currencyCode = _currencyCode;
                          },
                        );
                      },
                      child: Text(_currencyCode ?? 'EUR'),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                TextFormField(
                  readOnly: true,
                  decoration: InputDecoration(
                    labelText: loc.addTripPurchaseDate,
                    border: const OutlineInputBorder(),
                    suffixIcon: const Icon(Icons.calendar_today),
                  ),
                  controller: TextEditingController(
                    text: _selectedPurchaseDate != null
                        ? formatDateTime(context, _selectedPurchaseDate!, hasTime: false)
                        : '',
                  ),
                  onTap: () async {
                    final DateTime? picked = await showDatePicker(
                      context: context,
                      initialDate: _selectedPurchaseDate ?? DateTime.now(),
                      firstDate: DateTime(1900),
                      lastDate: DateTime(2500),
                    );
                    if (picked != null && picked != _selectedPurchaseDate) {
                      setState(() {
                        _selectedPurchaseDate = picked;                        
                      });
                      model.purchaseDate = _selectedPurchaseDate;
                    }
                  },
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          TitledContainer(
            title: loc.energy, 
            content: VehicleEnergySelector(
              value: model.energyType,
              onChanged: model.setenergyType,
            ),
          ),
          const SizedBox(height: 16),
          TitledContainer(
            title: loc.visibility, 
            content: TripVisibilitySelector(
              value: model.tripVisibility,
              onChanged: model.setVisibility,
            ),
          ),
        ],
      ),
    );
  }
}
