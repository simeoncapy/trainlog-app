import 'package:flutter/material.dart';
import 'package:material_symbols_icons/symbols.dart';
import 'package:provider/provider.dart';
import 'package:trainlog_app/data/models/trips.dart';
import 'package:trainlog_app/l10n/app_localizations.dart';
import 'package:trainlog_app/providers/trainlog_provider.dart';
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
            title: loc.graphTypeStations(
              _selectedVehicleType?.name ?? VehicleType.train.name,
            ),
            content: Column(
              children: [
                _leftAlignedSubtitle(context, loc.addTripDeparture),
                const SizedBox(height: 8),
                StationFieldsSwitcher(
                  globePinIcon: Symbols.globe_location_pin,
                  onChanged: (values) {
                    debugPrint('Station name: ${values['name']}');
                    debugPrint('Latitude: ${values['lat']}');
                    debugPrint('Longitude: ${values['long']}');
                  },
                ),
                const SizedBox(height: 12),
                _leftAlignedSubtitle(context, loc.addTripArrival),
                const SizedBox(height: 8),
                StationFieldsSwitcher(
                  // Optional:
                  // initialGeoMode: false,
                  // onModeChanged: (isGeo) => debugPrint('Geo mode: $isGeo'),
                  // searchIcon: Symbols.search,           // if using Material Symbols
                  globePinIcon: Symbols.globe_location_pin, // if using Material Symbols
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          
          TitledContainer(
            title: loc.addTripOperator,
            content: Column(
              children: [
                TextFormField(
                  decoration: InputDecoration(
                    labelText: loc.nameField,
                    prefixIcon: const Icon(Icons.business),
                    border: const OutlineInputBorder(),
                    helperText: loc.addTripOperatorHelper,
                  ),
                  onChanged: (value) {
                    setState(() {
                      _selectedOperatorName = value.trim();
                    });
                  },
                ),
                const SizedBox(height: 12),
                Container(
                  height: 72,
                  width: double.infinity,
                  decoration: BoxDecoration(
                    color: _selectedOperatorName == null || _selectedOperatorName!.isEmpty
                        ? Theme.of(context).colorScheme.surfaceContainerHighest
                        : null,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Theme.of(context).dividerColor),
                  ),
                  alignment: Alignment.center,
                  child: _selectedOperatorName == null || _selectedOperatorName!.isEmpty
                      ? Text(
                          loc.addTripOperatorPlaceholderLogo,
                          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                color: Theme.of(context).hintColor,
                              ),
                        )
                      : Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 8),
                          child: SingleChildScrollView(
                            scrollDirection: Axis.horizontal,
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.start,
                              children: trainlog
                                  .getOperatorImages(
                                    _selectedOperatorName!,
                                    maxWidth: 80,
                                    maxHeight: 48,
                                    separator: ",",
                                  )
                                  .map((img) => Padding(
                                        padding:
                                            const EdgeInsets.symmetric(horizontal: 4.0),
                                        child: ClipRRect(
                                          borderRadius: BorderRadius.circular(8),
                                          child: img,
                                        ),
                                      ))
                                  .toList(),
                            ),
                          ),
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
