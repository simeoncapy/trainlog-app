import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:trainlog_app/app/theme/app_theme.dart';
import 'package:trainlog_app/data/models/trip_form_model.dart';
import 'package:trainlog_app/data/models/trips.dart';
import 'package:trainlog_app/l10n/app_localizations.dart';
import 'package:trainlog_app/providers/settings_provider.dart';
import 'package:trainlog_app/providers/trainlog_provider.dart';
import 'package:trainlog_app/utils/map_color_palette.dart';
import 'package:trainlog_app/features/trips_add/widgets/mini_map_box.dart';
import 'package:trainlog_app/features/trips_add/widgets/station_endpoint_fields.dart';
import 'package:trainlog_app/widgets/app_steps_tab_bar.dart';

/// Step 2 of the "Add Trip" wizard: departure and arrival selection.
///
/// One block per trip endpoint, each with a timeline marker and an
/// [AppStepsTabBar] mode selector (by name / manual) in the header, the
/// station fields (by-name search with the full-screen suggestion overlay,
/// or manual coordinates) and a mini map below the fields. A swap button
/// sits between the two blocks.
class AddTripRouteStep extends StatelessWidget {
  const AddTripRouteStep({super.key});

  @override
  Widget build(BuildContext context) {
    final model = context.watch<TripFormModel>();
    final settings = context.watch<SettingsProvider>();
    final trainlog = Provider.of<TrainlogProvider>(context, listen: false);
    final colours = MapColorPaletteHelper.getPalette(settings.mapColorPalette);

    final theme = Theme.of(context);
    final loc = AppLocalizations.of(context)!;
    final vType = model.vehicleType ?? VehicleType.train;
    final routeColour = colours[vType] ?? theme.colorScheme.primary;

    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(24, 8, 24, 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            loc.addTripRouteTitle,
            style: AppTheme.displayFont.copyWith(
              fontSize: 26,
              fontWeight: FontWeight.w700,
              color: theme.colorScheme.onSurface,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            loc.addTripRouteSubtitle,
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 20),

          _EndpointBlock(
            isDeparture: true,
            model: model,
            trainlog: trainlog,
            vehicleType: vType,
            markerColour: routeColour,
            hasError:
                model.departureHasError && model.highlightDepartureErrors,
          ),

          // Swap button between the departure and arrival blocks.
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 8),
            child: Align(
              alignment: Alignment.center,
              child: IconButton(
                onPressed: model.switchDepartureArrival,
                icon: const Icon(Icons.swap_vert),
                tooltip: loc.addTripSwapTooltip,
                style: IconButton.styleFrom(
                  backgroundColor: theme.colorScheme.inverseSurface,
                  foregroundColor: theme.colorScheme.onInverseSurface,
                  fixedSize: const Size(44, 44),
                  shape: const CircleBorder(),
                ),
              ),
            ),
          ),

          _EndpointBlock(
            isDeparture: false,
            model: model,
            trainlog: trainlog,
            vehicleType: vType,
            markerColour: routeColour,
            hasError: model.arrivalHasError && model.highlightArrivalErrors,
          ),
        ],
      ),
    );
  }
}

/// One departure/arrival block: header with timeline marker, label and mode
/// tab bar; station fields; and the mini map underneath.
class _EndpointBlock extends StatefulWidget {
  const _EndpointBlock({
    required this.isDeparture,
    required this.model,
    required this.trainlog,
    required this.vehicleType,
    required this.markerColour,
    required this.hasError,
  });

  final bool isDeparture;
  final TripFormModel model;
  final TrainlogProvider trainlog;
  final VehicleType vehicleType;
  final Color markerColour;
  final bool hasError;

  @override
  State<_EndpointBlock> createState() => _EndpointBlockState();
}

class _EndpointBlockState extends State<_EndpointBlock> {
  bool get isDeparture => widget.isDeparture;
  TripFormModel get model => widget.model;
  VehicleType get vehicleType => widget.vehicleType;

  bool get _geoMode =>
      isDeparture ? model.departureGeoMode : model.arrivalGeoMode;

  /// Key giving the header tab bar access to the fields' state so the mode
  /// toggle behaves exactly like the deprecated inline toggle button.
  GlobalKey<StationEndpointFieldsState> _fieldsKey = GlobalKey();

  @override
  void didUpdateWidget(covariant _EndpointBlock oldWidget) {
    super.didUpdateWidget(oldWidget);
    // A new key remounts the fields on vehicle type change, matching the
    // vehicle-type-dependent ValueKey behaviour of the previous design.
    if (oldWidget.vehicleType != widget.vehicleType) {
      _fieldsKey = GlobalKey();
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final loc = AppLocalizations.of(context)!;
    final label = isDeparture ? loc.addTripDeparture : loc.addTripArrival;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: theme.cardColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: widget.hasError
              ? theme.colorScheme.error
              : theme.colorScheme.outline,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              _TimelineMarker(
                  colour: widget.markerColour, filled: !isDeparture),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  label.toUpperCase(),
                  style: theme.textTheme.labelSmall?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                    fontWeight: FontWeight.w600,
                    letterSpacing: 1.2,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              AppStepsTabBar(
                tabs: [
                  AppStepsTab(label: loc.addTripModeByName),
                  AppStepsTab(label: loc.addTripModeManual),
                ],
                selectedIndex: _geoMode ? 1 : 0,
                onTabChanged: (index) =>
                    _fieldsKey.currentState?.setMode(index == 1),
              ),
            ],
          ),
          const SizedBox(height: 12),
          _stationFields(context, loc),
          const SizedBox(height: 12),
          _miniMap(loc),
          ..._miniMapHelper(loc, theme),
        ],
      ),
    );
  }

  Widget _stationFields(BuildContext context, AppLocalizations loc) {
    return StationEndpointFields(
      key: _fieldsKey,
      trainlog: widget.trainlog,
      vehicleType: vehicleType,
      addressDefaultText: loc.typeStationAddress(vehicleType.name),
      manualNameFieldHint: loc.manualNameStation(vehicleType.name),

      initialGeoMode: _geoMode,
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
            baseName: values['baseName'],
            lat: lat,
            long: lng,
            geoMode: values['mode'] == 'geo',
            address: values['address'],
          );
          model.clearDepartureError();
        } else {
          model.setArrival(
            name: values['name'],
            baseName: values['baseName'],
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

  Widget _miniMap(AppLocalizations loc) {
    return MiniMapBox(
      height: 120,
      lat: isDeparture ? model.departureLat : model.arrivalLat,
      long: isDeparture ? model.departureLong : model.arrivalLong,
      emptyMessage: loc.enterStation(
        isDeparture ? 'departure' : 'arrival',
        vehicleType.name,
      ),
      markerColor: isDeparture ? Colors.green : Colors.red,
      marker: isDeparture ? Icons.location_pin : Icons.where_to_vote,
      isCoordinateMovable: _geoMode,
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

  List<Widget> _miniMapHelper(AppLocalizations loc, ThemeData theme) {
    return _geoMode ? [
      const SizedBox(height: 8,),
      Text(
        loc.addTripMapUsageHelper,
        softWrap: true,
        style: theme.textTheme.bodySmall,
      ),
    ] : [];
  }
}

/// Trip summary timeline marker: hollow rounded square for the departure,
/// filled with the vehicle colour for the arrival.
class _TimelineMarker extends StatelessWidget {
  const _TimelineMarker({required this.colour, required this.filled});

  final Color colour;
  final bool filled;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 14,
      height: 14,
      decoration: BoxDecoration(
        color: filled ? colour : Colors.transparent,
        borderRadius: BorderRadius.circular(4),
        border: Border.all(color: colour, width: 2.5),
      ),
    );
  }
}
