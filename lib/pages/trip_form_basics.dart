import 'package:flutter/material.dart';
import 'package:material_symbols_icons/symbols.dart';
import 'package:provider/provider.dart';

import 'package:trainlog_app/data/models/trip_form_model.dart';
import 'package:trainlog_app/data/models/trips.dart';
import 'package:trainlog_app/l10n/app_localizations.dart';
import 'package:trainlog_app/providers/trainlog_provider.dart';

import 'package:trainlog_app/widgets/station_fields_switcher.dart';
import 'package:trainlog_app/widgets/operator_selector.dart';
import 'package:trainlog_app/widgets/mini_map_box.dart';
import 'package:trainlog_app/widgets/titled_container.dart';

class TripFormBasics extends StatelessWidget {
  const TripFormBasics({super.key});

  @override
  Widget build(BuildContext context) {
    final model = context.watch<TripFormModel>();
    final trainlog = Provider.of<TrainlogProvider>(context, listen: false);

    final loc = AppLocalizations.of(context)!;
    final vType = model.vehicleType ?? VehicleType.train;
    final vehicleType = vType.name;

    final hasStationsError = (model.departureHasError && model.highlightDepartureErrors 
                              || model.arrivalHasError && model.highlightArrivalErrors);

    final borderErrorColor = Theme.of(context).colorScheme.error;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          // ---------------- Vehicle Type ----------------
          DropdownButtonFormField<VehicleType>(
            decoration: InputDecoration(
              labelText: loc.addTripTransportationMode,
              border: const OutlineInputBorder(),
            ),
            value: model.vehicleType,
            items: VehicleType.values
                .where((v) => v != VehicleType.unknown && v != VehicleType.poi)
                .map(
                  (type) => DropdownMenuItem(
                    value: type,
                    child: Row(
                      children: [
                        type.icon(),
                        const SizedBox(width: 8),
                        Text(type.label(context)),
                      ],
                    ),
                  ),
                )
                .toList(),
            onChanged: (v) {
              if (v == null || v == model.vehicleType) return;

              // 1) update type in model
              model.setVehicleType(v);

              // 2) reset stations in the model
              model.setDeparture(
                name: null,
                lat: null,
                long: null,
                address: null,
                geoMode: false,
              );
              model.setArrival(
                name: null,
                lat: null,
                long: null,
                address: null,
                geoMode: false,
              );
            },
          ),

          const SizedBox(height: 16),

          TitledContainer(
            title: loc.typeStations(vehicleType),
            borderColor: hasStationsError ? borderErrorColor : null,
            content: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (model.vehicleType == VehicleType.plane)
                  ...[
                    ElevatedButton.icon(
                      onPressed: null, 
                      label: Text(loc.addTripImportFr24),
                      icon: Icon(Icons.cloud_download),
                    ),
                    SizedBox(height: 12,),
                  ],
                Text(loc.addTripDeparture,
                    style: Theme.of(context).textTheme.titleSmall),
                const SizedBox(height: 8,),
                // key depends on vehicle type → forces rebuild on change
                StationFieldsSwitcher(
                  key: ValueKey('dep-${vType.name}'),
                  trainlog: trainlog,
                  vehicleType: model.vehicleType ?? VehicleType.train,
                  addressDefaultText: loc.typeStationAddress(vehicleType),
                  manualNameFieldHint: loc.manualNameStation(vehicleType),

                  initialGeoMode: model.departureGeoMode,
                  initialStationName: model.departureStationName,
                  initialLat: model.departureLat,
                  initialLng: model.departureLong,
                  initialAddress: model.departureAddress,

                  onChanged: (values) {
                    model.setDeparture(
                      name: values['name'],
                      lat: double.tryParse(values['lat'] ?? ''),
                      long: double.tryParse(values['long'] ?? ''),
                      geoMode: values['mode'] == 'geo',
                      address: values['address'],
                    );
                    model.clearDepartureError();
                  },
                ),

                const SizedBox(height: 12),
                Text(loc.addTripArrival,
                    style: Theme.of(context).textTheme.titleSmall),
                const SizedBox(height: 8,),
                StationFieldsSwitcher(
                  key: ValueKey('arr-${vType.name}'),
                  trainlog: trainlog,
                  vehicleType: model.vehicleType ?? VehicleType.train,
                  addressDefaultText: loc.typeStationAddress(vehicleType),
                  manualNameFieldHint: loc.manualNameStation(vehicleType),

                  initialGeoMode: model.arrivalGeoMode,
                  initialStationName: model.arrivalStationName,
                  initialLat: model.arrivalLat,
                  initialLng: model.arrivalLong,
                  initialAddress: model.arrivalAddress,

                  onChanged: (values) {
                    model.setArrival(
                      name: values['name'],
                      lat: double.tryParse(values['lat'] ?? ''),
                      long: double.tryParse(values['long'] ?? ''),
                      geoMode: values['mode'] == 'geo',
                      address: values['address'],
                    );
                    model.clearArrivalError();
                  },
                ),              
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: MiniMapBox(
                        lat: model.departureLat,
                        long: model.departureLong,
                        emptyMessage:
                            loc.enterStation("departure", vehicleType),
                        markerColor: Colors.green,
                        isCoordinateMovable: model.departureGeoMode,
                        onCoordinateChanged: (lat, long) {
                          WidgetsBinding.instance.addPostFrameCallback((_) {
                            model.updateDepartureCoords(lat, long);
                          });
                        },
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: MiniMapBox(
                        lat: model.arrivalLat,
                        long: model.arrivalLong,
                        emptyMessage:
                            loc.enterStation("arrival", vehicleType),
                        markerColor: Colors.red,
                        isCoordinateMovable: model.arrivalGeoMode,
                        onCoordinateChanged: (lat, long) {
                          WidgetsBinding.instance.addPostFrameCallback((_) {
                            model.updateArrivalCoords(lat, long);
                          });
                        },
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8,),
                Text(
                  loc.addTripMapUsageHelper,
                  softWrap: true,
                  style: Theme.of(context).textTheme.bodySmall,
                ),
              ],
            ),
          ),

          const SizedBox(height: 16),

          TitledContainer(
            title: loc.addTripOperator,
            borderColor: (model.operatorHasError && model.highlightOperatorsErrors) ? borderErrorColor : null,
            content: OperatorSelector(
              initialOperators: model.selectedOperators,
              onChanged: (ops) {
                model.setOperators(ops);
                model.clearOperatorError();
              },
            ),
          ),
        ],
      ),
    );
  }
}

