import 'package:latlong2/latlong.dart';
import 'package:trainlog_app/data/models/polyline_entry.dart';

/// A trip path drawn on the path editor, as the routing web page hands it back
/// through its `getRouteForApp()` function.
///
/// It is kept in the edit form until the trip is saved, and then sent with the
/// rest of the edit through `TripsApi.patchTrip` (see [toTripColumns]).
class EditedRoute {
  /// The drawn path, departure first.
  final List<LatLng> path;

  /// Intermediate points of the route, as the `trips.waypoints` column stores
  /// them: `{lat, lng}` plus `name`, `stop` and `hard` when set. Null when the
  /// page does not report any (the flight page has no intermediate points), in
  /// which case the stored ones are left as they are.
  final List<Map<String, dynamic>>? waypoints;

  /// How the path was made: `router`, `freehand` or `fr24`.
  final String routeSource;

  /// The router's description of the route (electrification, power type…), or
  /// null when there is none (a freehand path, a flight).
  final Map<String, dynamic>? details;

  /// Length of the path, in metres.
  final double? tripLength;

  /// Duration the router estimates for the path, in seconds.
  final double? estimatedTripDuration;

  /// The FR24 flight track's altitude (metres) and timestamps (epoch seconds),
  /// parallel to [path]. Null for any other path, which clears the stored 3D
  /// track: it no longer matches the geometry.
  final List<dynamic>? altitude;
  final List<dynamic>? timestamps;

  const EditedRoute({
    required this.path,
    required this.waypoints,
    required this.routeSource,
    this.details,
    this.tripLength,
    this.estimatedTripDuration,
    this.altitude,
    this.timestamps,
  });

  /// Parses a successful `getRouteForApp()` result.
  factory EditedRoute.fromJson(Map<String, dynamic> json) {
    final waypoints = json['waypoints'];
    final details = json['details'];

    return EditedRoute(
      path: PolylineTools.toLatLngList(json['path']),
      waypoints: waypoints is List
          ? waypoints
              .whereType<Map>()
              .map((w) => Map<String, dynamic>.from(w))
              .toList()
          : null,
      routeSource: json['route_source']?.toString() ?? 'router',
      details: details is Map ? Map<String, dynamic>.from(details) : null,
      tripLength: (json['trip_length'] as num?)?.toDouble(),
      estimatedTripDuration:
          (json['estimated_trip_duration'] as num?)?.toDouble(),
      altitude: json['altitude'] is List ? json['altitude'] as List : null,
      timestamps: json['timestamps'] is List ? json['timestamps'] as List : null,
    );
  }

  /// The route as `patchTrip` takes it. Sending `path` is what makes the
  /// server replace the stored geometry; `trip_length` and
  /// `estimated_trip_duration` go together, as the server only works the
  /// countries out again from the new path when it gets both.
  Map<String, dynamic> toTripColumns() {
    return <String, dynamic>{
      'path': [
        for (final point in path)
          {'lat': point.latitude, 'lng': point.longitude},
      ],
      if (waypoints != null) 'waypoints': waypoints,
      'route_source': routeSource,
      if (details != null) 'details': details,
      'trip_length': tripLength,
      'estimated_trip_duration': estimatedTripDuration,
      if (altitude != null) 'altitude': altitude,
      if (timestamps != null) 'timestamps': timestamps,
    };
  }
}
