import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:provider/provider.dart';
import 'package:trainlog_app/core/providers/settings_provider.dart';
import 'package:trainlog_app/core/providers/trips_provider.dart';
import 'package:trainlog_app/features/map/map_marker.dart';
import 'package:trainlog_app/features/map/map_page_controller.dart';
import 'package:trainlog_app/ui/adaptive/adaptive_trip_card.dart';
import 'package:trainlog_app/ui/adaptive/map_theme.dart';
import 'package:trainlog_app/widgets/rendered_polyline_layer.dart';
import 'package:trainlog_app/widgets/trip_direction_chevron_layer.dart';

/// The map of the map page, the same in both designs: OpenStreetMap tiles
/// (inverted in dark map theme), the trips (tap one for its details), their
/// direction, the user's position and the pin of the searched place.
class MapCanvas extends StatelessWidget {
  const MapCanvas({
    super.key,
    required this.mapController,
    required this.rotation,
  });

  final MapController mapController;

  /// Updated with the map rotation, in degrees (for the compass).
  final ValueNotifier<double> rotation;

  @override
  Widget build(BuildContext context) {
    final settings = context.watch<SettingsProvider>();
    final controller = context.watch<MapPageController>();
    final userPosition = controller.userPosition;
    final searchedPlace = controller.searchedPlace;

    return FlutterMap(
      mapController: mapController,
      options: MapOptions(
        initialCenter: controller.center,
        initialZoom: controller.zoom,
        // Both bounds must stay finite. A fast pinch can make flutter_map
        // feed a non-positive scale to log() (its guard checks
        // details.scale, but the value used is details.scale plus an
        // internal gesture-race corrector), producing an infinite or NaN
        // zoom. MapCamera then asserts on it. Finite limits let clampZoom
        // absorb that frame instead: -infinity lands on minZoom, NaN on
        // maxZoom. 0 is a fully zoomed-out world; 22 is past anything
        // usable, so over-zoom above OSM's native zoom 19 still works as
        // before.
        minZoom: 0,
        maxZoom: 22,
        keepAlive: true,
        interactionOptions: const InteractionOptions(
          rotationThreshold: 20.0,
          enableMultiFingerGestureRace: true,
        ),
        onPositionChanged: (pos, hasGesture) {
          controller.onCameraChanged(pos.center, pos.zoom);
        },
        // flutter_map calls onPositionChanged only when the centre or the
        // zoom changes, not for a rotation alone: follow the rotation from
        // every map event instead, so the compass shows as soon as the map
        // turns.
        onMapEvent: (event) => rotation.value = event.camera.rotation,
      ),
      children: [
        TileLayer(
          urlTemplate: "https://tile.openstreetmap.org/{z}/{x}/{y}.png",
          userAgentPackageName: 'me.trainlog.app',
          errorTileCallback: (tile, error, stackTrace) {},
          // OSM only serves light tiles: the "Map theme" setting's dark
          // mode inverts them (flutter_map's built-in dark filter).
          tileBuilder: mapBrightness(context) == Brightness.dark
              ? darkModeTileBuilder
              : null,
        ),
        RenderedPolylineLayer(
          onTripTap: (tripId) async {
            final repo = context.read<TripsProvider>().repository;
            if (repo == null) return;

            final tappedTrip = await repo.getTripById(tripId);
            if (tappedTrip == null || !context.mounted) return;

            await showAdaptiveTripBottomSheet(context, trip: tappedTrip);
          },
        ),
        if (settings.mapDisplayTripDirection) const TripDirectionChevronLayer(),
        if (userPosition != null && settings.mapDisplayUserLocationMarker)
          MarkerLayer(
            markers: [
              Marker(
                width: 30,
                height: 30,
                point: userPosition,
                child: const MapMarker(),
              ),
            ],
          ),
        if (searchedPlace != null)
          MarkerLayer(
            markers: [
              Marker(
                width: 40,
                height: 40,
                point: searchedPlace.point,
                alignment: Alignment.topCenter,
                child: GestureDetector(
                  onTap: controller.clearSearchedPlace,
                  child: Icon(
                    Icons.location_on,
                    size: 40,
                    color: Theme.of(context).colorScheme.error,
                  ),
                ),
              ),
            ],
          ),
      ],
    );
  }
}
