import 'package:flutter/material.dart';
import 'package:trainlog_app/data/models/trips.dart';
import 'package:trainlog_app/l10n/app_localizations.dart';

class TripFormBasics extends StatefulWidget {
  const TripFormBasics({super.key});

  @override
  State<TripFormBasics> createState() => _TripFormBasicsState();
}

class _TripFormBasicsState extends State<TripFormBasics> {
  VehicleType? _selectedVehicleType;

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
            decoration: InputDecoration(
              labelText: loc.addTripTransportationMode,
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
              color: Theme.of(context).colorScheme.surfaceContainerLow,
              borderRadius: BorderRadius.circular(12),
            ),
            padding: const EdgeInsets.all(12),
            child: Column(
              children: [
                Text(loc.graphTypeStations(_selectedVehicleType?.name ?? VehicleType.train.name),
                  style: Theme.of(context).textTheme.titleSmall,),
                const SizedBox(height: 8),
                CheckboxListTile(
                  title: Text(loc.addTripManualDeparture),
                  value: false,
                  onChanged: (_) {},
                  controlAffinity: ListTileControlAffinity.leading,
                ),
                TextFormField(
                  decoration: InputDecoration(
                    labelText: loc.addTripDeparture,
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 12),
                CheckboxListTile(
                  title: Text(loc.addTripManualArrival),
                  value: false,
                  onChanged: (_) {},
                  controlAffinity: ListTileControlAffinity.leading,
                ),
                TextFormField(
                  decoration: InputDecoration(
                    labelText: loc.addTripArrival,
                    border: OutlineInputBorder(),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),

          /// Carrier and Line
          TextFormField(
            decoration: InputDecoration(
              labelText: loc.addTripOperator,
              prefixIcon: Icon(Icons.business),
              border: OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 16),
          TextFormField(
            decoration: InputDecoration(
              labelText: loc.addTripLine,
              border: OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 16), 
          
        ],
      ),
    );
  }
}
