import 'package:flutter/material.dart';
import 'package:currency_picker/currency_picker.dart';
import 'package:trainlog_app/l10n/app_localizations.dart';

class TripFormDetails extends StatefulWidget {
  const TripFormDetails({super.key});

  @override
  State<TripFormDetails> createState() => _TripFormDetailsState();
}

class _TripFormDetailsState extends State<TripFormDetails> {
  String? _currencyCode = 'EUR'; // TODO get user default currency
  final TextEditingController _priceController = TextEditingController();

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

          Container(
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.surfaceContainerLow,
              borderRadius: BorderRadius.circular(12),
              // border: Border.all(
              //   color: Theme.of(context).dividerColor,
              // ),
            ),
            padding: const EdgeInsets.all(12),
            child: Column(
              children: [
                Text(loc.addTripTicketTitle,
                  style: Theme.of(context).textTheme.titleSmall,),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Expanded(
                      child: TextFormField(
                        controller: _priceController,
                        keyboardType: TextInputType.number,
                        decoration: InputDecoration(
                          labelText: loc.addTripTicketPrice,
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
                  ],
                ),
                const SizedBox(height: 12),
                TextFormField(
                  decoration: InputDecoration(
                    labelText: loc.addTripPurchaseDate,
                    border: OutlineInputBorder(),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
