import 'package:flutter/material.dart';
import 'package:currency_picker/currency_picker.dart';
import 'package:intl/intl.dart';
import 'package:trainlog_app/l10n/app_localizations.dart';
import 'package:trainlog_app/widgets/titled_container.dart';

class TripFormDetails extends StatefulWidget {
  const TripFormDetails({super.key});

  @override
  State<TripFormDetails> createState() => _TripFormDetailsState();
}

class _TripFormDetailsState extends State<TripFormDetails> {
  String? _currencyCode = 'EUR'; // TODO get user default currency
  final TextEditingController _priceController = TextEditingController();
  DateTime? _selectedPurchaseDate;

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
          Text(loc.addTripFacultative),
          const SizedBox(height: 12),
          /// Expandable Details
          TextFormField(
            decoration: InputDecoration(
              labelText: loc.addTripLine,
              border: OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 12), 
          TextFormField(
            decoration: InputDecoration(
              labelText: loc.addTripMaterial,
              border: OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 12),
          TextFormField(
            decoration: InputDecoration(
              labelText: loc.addTripRegistration,
              border: OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 12),
          TextFormField(
            decoration: InputDecoration(
              labelText: loc.addTripSeat,
              border: OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 12),
          TextFormField(
            decoration: InputDecoration(
              labelText: loc.addTripNotes,
              border: OutlineInputBorder(),
            ),
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
                        controller: _priceController,
                        keyboardType: TextInputType.number,
                        decoration: InputDecoration(
                          labelText: loc.addTripTicketPrice,
                          border: const OutlineInputBorder(),
                        ),
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
                        ? MaterialLocalizations.of(context)
                            .formatMediumDate(_selectedPurchaseDate!)
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
                    }
                  },
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
