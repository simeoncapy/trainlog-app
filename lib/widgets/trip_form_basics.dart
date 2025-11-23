import 'package:flutter/material.dart';
import 'package:material_symbols_icons/symbols.dart';
import 'package:provider/provider.dart';
import 'package:trainlog_app/data/models/trips.dart';
import 'package:trainlog_app/l10n/app_localizations.dart';
import 'package:trainlog_app/providers/trainlog_provider.dart';
import 'package:trainlog_app/widgets/mini_map_box.dart';
import 'package:trainlog_app/widgets/operator_selector.dart';
import 'package:trainlog_app/widgets/station_fields_switcher.dart';
import 'package:trainlog_app/widgets/titled_container.dart';

class TripFormBasics extends StatefulWidget {
  const TripFormBasics({super.key});

  @override
  State<TripFormBasics> createState() => _TripFormBasicsState();
}

class _TripFormBasicsState extends State<TripFormBasics> {
  late TrainlogProvider trainlog;
  VehicleType? _selectedVehicleType;
  String? _selectedOperatorName;
  final _operatorSelectorKey = GlobalKey<OperatorSelectorState>();
  double? _departureLat;
  double? _departureLong;

  double? _arrivalLat;
  double? _arrivalLong;


  @override
  void initState() {
    super.initState();
    trainlog = Provider.of<TrainlogProvider>(context, listen: false);
  }

  Widget _leftAlignedSubtitle(BuildContext context, String text, {TextStyle? style}) {
    return Align(
      alignment: Alignment.centerLeft,
      child: Text(
        text,
        style: style ?? Theme.of(context).textTheme.titleSmall,
        textAlign: TextAlign.left,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context)!;
    final vehicleType = _selectedVehicleType?.name ?? VehicleType.train.name;

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
          TitledContainer(
            title: loc.typeStations(vehicleType),
            content: Column(
              children: [
                _leftAlignedSubtitle(context, loc.addTripDeparture),
                const SizedBox(height: 4),
                StationFieldsSwitcher(
                  globePinIcon: Symbols.globe_location_pin,
                  addressDefaultText: loc.typeStationAddress(vehicleType),
                  manualNameFieldHint: loc.manualNameStation(vehicleType),
                  onChanged: (values) {
                    setState(() {
                      _departureLat = double.tryParse(values['lat'] ?? '');
                      _departureLong = double.tryParse(values['long'] ?? '');
                    });

                    debugPrint('Station name: ${values['name']}');
                    debugPrint('Latitude: ${values['lat']}');
                    debugPrint('Longitude: ${values['long']}');
                    debugPrint('Mode: ${values['mode']}');
                  },
                ),
                const SizedBox(height: 12),
                _leftAlignedSubtitle(context, loc.addTripArrival),
                const SizedBox(height: 4),
                StationFieldsSwitcher(
                  globePinIcon: Symbols.globe_location_pin,
                  addressDefaultText: loc.typeStationAddress(vehicleType),
                  manualNameFieldHint: loc.manualNameStation(vehicleType),
                  onChanged: (values) {
                    setState(() {
                      _arrivalLat = double.tryParse(values['lat'] ?? '');
                      _arrivalLong = double.tryParse(values['long'] ?? '');
                    });

                    debugPrint('Arrival Station: ${values['name']}');
                    debugPrint('Latitude: $_arrivalLat');
                    debugPrint('Longitude: $_arrivalLong');
                  },
                ),
                const SizedBox(height: 12),
                Row(
                  children: [ // 35.6808907,139.7671718
                    Expanded(
                      child: MiniMapBox(
                        lat: _departureLat,
                        long: _departureLong,
                        emptyMessage: loc.enterStation("departure",
                          _selectedVehicleType?.name ?? VehicleType.train.name,
                        ),
                        markerColor: Colors.green,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: MiniMapBox(
                        lat: _arrivalLat,
                        long: _arrivalLong,
                        emptyMessage: loc.enterStation("arrival",
                          _selectedVehicleType?.name ?? VehicleType.train.name,
                        ),
                        markerColor: Colors.red,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          
          TitledContainer(
            title: loc.addTripOperator,
            content: OperatorSelector(key: _operatorSelectorKey),
          ),
        ],
      ),
    );
  }
}
