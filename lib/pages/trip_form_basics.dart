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

enum TripPoint { departure, arrival }

class TripFormBasics extends StatelessWidget {
  const TripFormBasics({super.key});

  @override
  Widget build(BuildContext context) {
    final model = context.watch<TripFormModel>();
    final trainlog = Provider.of<TrainlogProvider>(context, listen: false);

    final theme = Theme.of(context);
    final loc = AppLocalizations.of(context)!;
    final vType = model.vehicleType ?? VehicleType.train;
    final vehicleType = vType.name;

    final hasStationsError = (model.departureHasError && model.highlightDepartureErrors 
                              || model.arrivalHasError && model.highlightArrivalErrors);

    final borderErrorColor = theme.colorScheme.error;

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
            initialValue: model.vehicleType,
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
                    style: theme.textTheme.titleSmall),
                const SizedBox(height: 8,),                
                _stationFields(
                  point: TripPoint.departure,
                  model: model,
                  trainlog: trainlog,
                  loc: loc,
                  vehicleType: vType,
                ),

                const SizedBox(height: 8),
                Align(
                  alignment: Alignment.center,
                  child: IconButton(
                    onPressed: () {
                      model.switchDepartureArrival();
                    },
                    icon: Icon(Icons.swap_vert),
                    style: IconButton.styleFrom(
                      backgroundColor: theme.colorScheme.tertiary,
                      foregroundColor: theme.colorScheme.onTertiary,
                      fixedSize: const Size(44, 44),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 8),

                Text(loc.addTripArrival,
                    style: theme.textTheme.titleSmall),
                const SizedBox(height: 8,),
                _stationFields(
                  point: TripPoint.arrival,
                  model: model,
                  trainlog: trainlog,
                  loc: loc,
                  vehicleType: vType,
                ),             
                const SizedBox(height: 12),

                Row(
                  children: [
                    Expanded(
                      child: _miniMap(
                        point: TripPoint.departure,
                        model: model,
                        loc: loc,
                        vehicleType: vType,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _miniMap(
                        point: TripPoint.arrival,
                        model: model,
                        loc: loc,
                        vehicleType: vType,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8,),
                Text(
                  loc.addTripMapUsageHelper,
                  softWrap: true,
                  style: theme.textTheme.bodySmall,
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

  Widget _stationFields({
    required TripPoint point,
    required TripFormModel model,
    required TrainlogProvider trainlog,
    required AppLocalizations loc,
    required VehicleType vehicleType,
  }) {
    final isDeparture = point == TripPoint.departure;

    return StationFieldsSwitcher(
      // key depends on vehicle type → forces rebuild on change
      key: ValueKey('${isDeparture ? 'dep' : 'arr'}-${vehicleType.name}'),
      trainlog: trainlog,
      vehicleType: vehicleType,
      addressDefaultText: loc.typeStationAddress(vehicleType.name),
      manualNameFieldHint: loc.manualNameStation(vehicleType.name),

      initialGeoMode:
          isDeparture ? model.departureGeoMode : model.arrivalGeoMode,
      initialStationName:
          isDeparture ? model.departureStationName : model.arrivalStationName,
      initialLat: isDeparture ? model.departureLat : model.arrivalLat,
      initialLng: isDeparture ? model.departureLong : model.arrivalLong,
      initialAddress:
          isDeparture ? model.departureAddress : model.arrivalAddress,

      onChanged: (values) {
        final lat = double.tryParse(values['lat'] ?? '');
        final lng = double.tryParse(values['long'] ?? '');

        if (isDeparture) {
          model.setDeparture(
            name: values['name'],
            lat: lat,
            long: lng,
            geoMode: values['mode'] == 'geo',
            address: values['address'],
          );
          model.clearDepartureError();
        } else {
          model.setArrival(
            name: values['name'],
            lat: lat,
            long: lng,
            geoMode: values['mode'] == 'geo',
            address: values['address'],
          );
          model.clearArrivalError();
        }
      },
    );
  }

  Widget _miniMap({
    required TripPoint point,
    required TripFormModel model,
    required AppLocalizations loc,
    required VehicleType vehicleType,
  }) {
    final isDeparture = point == TripPoint.departure;

    return MiniMapBox(
      lat: isDeparture ? model.departureLat : model.arrivalLat,
      long: isDeparture ? model.departureLong : model.arrivalLong,
      emptyMessage: loc.enterStation(
        isDeparture ? 'departure' : 'arrival',
        vehicleType.name,
      ),
      markerColor: isDeparture ? Colors.green : Colors.red,
      marker: isDeparture ? Icons.location_pin : Icons.where_to_vote,
      isCoordinateMovable:
          isDeparture ? model.departureGeoMode : model.arrivalGeoMode,
      onCoordinateChanged: (lat, long) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (isDeparture) {
            model.updateDepartureCoords(lat, long);
          } else {
            model.updateArrivalCoords(lat, long);
          }
        });
      },
    );
  }

}

