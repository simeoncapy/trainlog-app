import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:trainlog_app/data/models/edited_route.dart';
import 'package:trainlog_app/data/models/trip_form_model.dart';
import 'package:trainlog_app/data/models/trips.dart';

/// A trip as the edit endpoint describes it: `wplist` as its path.
Trips _trip({String? waypoints}) => Trips.fromJson(
      {
        'uid': '42',
        'origin_station': 'Paris',
        'destination_station': 'Lyon',
        'start_datetime': '2026-03-30T10:00:00',
        'end_datetime': '2026-03-30T12:00:00',
        'type': 'train',
        'operator': 'SNCF',
        'path': [
          [48.84, 2.37],
          [46.0, 4.0],
          [45.76, 4.86],
        ],
        'waypoints': waypoints,
      },
      pathAsGooglePolyline: false,
    );

/// A `getRouteForApp()` result from the routing page.
Map<String, dynamic> _routerResult() => {
      'ok': true,
      'path': [
        {'lat': 48.85, 'lng': 2.36},
        {'lat': 47.0, 'lng': 3.5},
        {'lat': 45.75, 'lng': 4.85},
      ],
      'waypoints': [
        {'lat': 47.0, 'lng': 3.5, 'name': 'Nevers', 'hard': true},
      ],
      'route_source': 'router',
      'details': {'powerType': 'auto'},
      'trip_length': 470000.5,
      'estimated_trip_duration': 7200,
    };

void main() {
  group('EditedRoute', () {
    test('a routed path is sent with its measurements and waypoints', () {
      final columns = EditedRoute.fromJson(_routerResult()).toTripColumns();

      expect(columns['path'], [
        {'lat': 48.85, 'lng': 2.36},
        {'lat': 47.0, 'lng': 3.5},
        {'lat': 45.75, 'lng': 4.85},
      ]);
      expect(columns['waypoints'], [
        {'lat': 47.0, 'lng': 3.5, 'name': 'Nevers', 'hard': true},
      ]);
      expect(columns['route_source'], 'router');
      expect(columns['details'], {'powerType': 'auto'});
      expect(columns['trip_length'], 470000.5);
      expect(columns['estimated_trip_duration'], 7200.0);
      expect(columns.containsKey('altitude'), isFalse);
      expect(columns.containsKey('timestamps'), isFalse);
    });

    test('a flight keeps the stored waypoints and sends its 3D track', () {
      final columns = EditedRoute.fromJson({
        'ok': true,
        'path': [
          {'lat': 49.0, 'lng': 2.5},
          {'lat': 35.5, 'lng': 139.8},
        ],
        'altitude': [100, 200],
        'timestamps': [1, 2],
        'route_source': 'fr24',
        'trip_length': 9700000,
        'estimated_trip_duration': 45000,
      }).toTripColumns();

      expect(columns.containsKey('waypoints'), isFalse);
      expect(columns.containsKey('details'), isFalse);
      expect(columns['altitude'], [100, 200]);
      expect(columns['timestamps'], [1, 2]);
      expect(columns['route_source'], 'fr24');
    });
  });

  group('TripFormModel path', () {
    test('the stored waypoints are routed through, with their hard flag', () {
      final form = TripFormModel.fromTrip(_trip(
        waypoints: jsonEncode([
          {'lat': 47.0, 'lng': 3.5, 'name': 'Nevers', 'hard': true},
          {'lat': 46.5, 'lng': 4.0, 'hard': false},
          {'lat': 46.2, 'lng': 4.2},
        ]),
      ));

      final payload = jsonDecode(form.toJson()) as Map<String, dynamic>;
      expect(payload['viaStations'], [
        [
          [47.0, 3.5],
          'Nevers',
          null,
          true,
        ],
        [
          [46.5, 4.0],
          '',
          null,
          false,
        ],
        [
          [46.2, 4.2],
          '',
          null,
          null,
        ],
      ]);
      expect(form.hasBeenChanged, isFalse);
    });

    test('a trip without waypoints sends no via stations', () {
      final form = TripFormModel.fromTrip(_trip());
      final payload = jsonDecode(form.toJson()) as Map<String, dynamic>;
      expect(payload.containsKey('viaStations'), isFalse);
    });

    test('the route is only patched once it was redrawn', () {
      final form = TripFormModel.fromTrip(_trip());
      expect(form.toTripColumns().containsKey('path'), isFalse);

      form.setEditedRoute(EditedRoute.fromJson(_routerResult()));

      expect(form.hasBeenChanged, isTrue);
      final columns = form.toTripColumns();
      expect(columns['path'], hasLength(3));
      expect(columns['route_source'], 'router');
      expect(columns['trip_length'], 470000.5);
    });

    test('a redrawn route moves the endpoints and the via points', () {
      final form = TripFormModel.fromTrip(_trip());
      form.setEditedRoute(EditedRoute.fromJson(_routerResult()));

      expect(form.departureLat, 48.85);
      expect(form.departureLong, 2.36);
      expect(form.arrivalLat, 45.75);
      expect(form.arrivalLong, 4.85);

      final payload = jsonDecode(form.toJson()) as Map<String, dynamic>;
      expect(payload['originStation'][0], [48.85, 2.36]);
      expect(payload['viaStations'], [
        [
          [47.0, 3.5],
          'Nevers',
          null,
          true,
        ],
      ]);
    });
  });
}
