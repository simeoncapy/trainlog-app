import 'dart:convert';

import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:timezone/data/latest.dart' as tzdata;
import 'package:trainlog_app/data/models/trip_form_model.dart';
import 'package:trainlog_app/data/models/trips.dart';
import 'package:trainlog_app/providers/trips_provider.dart';
import 'package:trainlog_app/services/api/trainlog_http_client.dart';
import 'package:trainlog_app/services/api/trips_api.dart';
import 'package:trainlog_app/services/trip_edit_copy_service.dart';
import 'package:trainlog_app/utils/date_utils.dart';

import 'fake_trainlog_server.dart';

/// A copied stop, as the trip row stores it: timetable and live data.
const _stop = {
  'name': 'Otsuki',
  'arr': '2026-10-23T05:00:00Z',
  'arr_rt': '2026-10-23T05:03:00Z',
  'platform': '2',
  'platform_rt': '3',
  'trip': 'run-1',
};

/// The edit/copy endpoint's context for trip 7, Shinjuku 13:05 → Kawaguchiko
/// 15:15 (JST), as edit_copy_trip renders it. For a copy, the delays are
/// emptied and `stored_waypoints` lists the stops without their live data,
/// while the nested trip row keeps them.
Map<String, dynamic> _context({required bool copy}) => {
      'tripId': '7',
      'username': 'alice',
      'origin': 'Shinjuku',
      'destination': 'Kawaguchiko',
      'start_datetime': '2026-10-23 13:05:00',
      'end_datetime': '2026-10-23 15:15:00',
      'precision': 'precise',
      'tripType': 'bus',
      'tripDepartureDelay': copy ? '' : 5,
      'tripArrivalDelay': copy ? '' : 10,
      'wplist': [
        [35.69, 139.70],
        [35.61, 138.94],
        [35.50, 138.76],
      ],
      'stored_waypoints': [
        {
          'lat': 35.61,
          'lng': 138.94,
          'stop': copy
              ? {'name': 'Otsuki', 'arr': '2026-10-23T05:00:00Z', 'platform': '2'}
              : _stop,
        },
      ],
      'trip': {
        'utc_start_datetime': '2026-10-23 04:05:00',
        'utc_end_datetime': '2026-10-23 06:15:00',
        'waypoints': jsonEncode([
          {'lat': 35.61, 'lng': 138.94, 'stop': _stop},
        ]),
      },
    };

/// A fake Trainlog answering the calls a duplicate makes, recording them.
class _Server {
  final requests = <RequestOptions>[];
  bool typeChangeFails = false;

  Handler get handler => (options) {
        requests.add(options);
        final path = options.path;
        if (path == '/u/alice/patchTrip') {
          return jsonBody(jsonEncode({
            'trip_id': 99,
            'copied_from': 7,
            'patched': (options.data as Map).keys
                .where((k) => k != 'trip_id' && k != 'copy')
                .toList(),
            'ignored': [],
          }));
        }
        if (path.startsWith('/u/alice/toType/')) {
          return jsonBody(jsonEncode(typeChangeFails
              ? {'error': 'not allowed'}
              : {'message': 'Trip types updated successfully'}));
        }
        if (path == '/u/alice/deleteTrip') {
          return ResponseBody.fromString('', 200);
        }
        if (path.startsWith('/u/alice/edit/')) {
          return jsonBody(jsonEncode(_context(copy: false)));
        }
        if (path.startsWith('/u/alice/copy/')) {
          return jsonBody(jsonEncode(_context(copy: true)));
        }
        return ResponseBody.fromString('', 404);
      };

  Iterable<String> get paths => requests.map((r) => r.path);
}

TripsApi _api(_Server server) {
  final client = TrainlogHttpClient()
    ..dio.httpClientAdapter = FakeAdapter(server.handler);
  return TripsApi(client);
}

TripEditCopyService _service(_Server server) =>
    TripEditCopyService(api: _api(server), trips: TripsProvider());

void main() {
  setUpAll(tzdata.initializeTimeZones);

  group('duplicating a trip', () {
    test('the copy is made from the trip with the form as a patch', () async {
      final server = _Server();
      final result = await _service(server).duplicate(
        username: 'alice',
        tripId: 7,
        fields: {'notes': 'Second time'},
      );

      final patch = server.requests.first;
      expect(patch.path, '/u/alice/patchTrip');
      expect(patch.data, {'notes': 'Second time', 'trip_id': 7, 'copy': true});
      expect(result.patch.tripId, 99);
      expect(result.patch.copiedFrom, 7);
      // The new trip is then read back, to be cached.
      expect(server.paths.skip(1), ['/u/alice/edit/99?fromApp=true']);
    });

    test('a copy is made even when nothing was changed', () async {
      final server = _Server();
      await _api(server).patchTrip('alice', 7, const {}, copy: true);

      expect(server.requests.single.data, {'trip_id': 7, 'copy': true});
    });

    test('a new vehicle type is given to the copy', () async {
      final server = _Server();
      await _service(server).duplicate(
        username: 'alice',
        tripId: 7,
        fields: const {},
        oldType: VehicleType.bus,
        newType: VehicleType.car,
      );

      expect(server.paths, contains('/u/alice/toType/car/99'));
      expect(server.paths, isNot(contains('/u/alice/deleteTrip')));
    });

    test('a copy whose type could not be changed is deleted again', () async {
      final server = _Server()..typeChangeFails = true;

      await expectLater(
        _service(server).duplicate(
          username: 'alice',
          tripId: 7,
          fields: const {},
          oldType: VehicleType.bus,
          newType: VehicleType.car,
        ),
        throwsA(isA<TripPatchException>()),
      );

      final delete =
          server.requests.singleWhere((r) => r.path == '/u/alice/deleteTrip');
      expect((delete.data as Map)['tripId'], '99');
    });
  });

  group('the duplicate form', () {
    test('its stops come without the copied run\'s live data', () async {
      final data = await _api(_Server())
          .fetchTripEditCopy('alice', 7, EditCopy.copy);
      final form = TripFormModel.fromTrip(data.formTrip);

      expect(form.routeWaypoints.single['stop'], {
        'name': 'Otsuki',
        'arr': '2026-10-23T05:00:00Z',
        'platform': '2',
      });
      expect(form.delayDepartureMinute, isNull);
      expect(form.delayArrivalMinute, isNull);
    });

    test('an edit keeps its stops as stored', () async {
      final data = await _api(_Server())
          .fetchTripEditCopy('alice', 7, EditCopy.edit);
      final form = TripFormModel.fromTrip(data.formTrip);

      expect(form.routeWaypoints.single['stop'], _stop);
    });

    test('it starts on today, at the trip\'s times', () async {
      final data = await _api(_Server())
          .fetchTripEditCopy('alice', 7, EditCopy.copy);
      final form = TripFormModel.fromTrip(data.formTrip)
        ..moveScheduleToToday(today: DateTime(2026, 11, 2, 18, 30));

      expect(form.departureDateLocal, DateTime(2026, 11, 2, 13, 5));
      expect(form.arrivalDateLocal, DateTime(2026, 11, 2, 15, 15));
      // Tokyo is UTC+9.
      expect(form.departureDate, DateTime.utc(2026, 11, 2, 4, 5));
      expect(form.arrivalDate, DateTime.utc(2026, 11, 2, 6, 15));
      expect(form.validateDate(), isTrue);
      expect(form.hasBeenChanged, isFalse);
    });

    test('an overnight trip still arrives the next day', () {
      final form = TripFormModel.fromTrip(Trips.fromJson(
        {
          'uid': '8',
          'type': 'train',
          'start_datetime': '2026-10-23 23:00:00',
          'end_datetime': '2026-10-24 01:00:00',
          'utc_start_datetime': '2026-10-23 21:00:00',
          'utc_end_datetime': '2026-10-23 23:00:00',
          'path': [
            [48.84, 2.37],
            [45.76, 4.86],
          ],
        },
        pathAsGooglePolyline: false,
      ))
        ..moveScheduleToToday(today: DateTime(2026, 11, 2));

      expect(form.departureDateLocal, DateTime(2026, 11, 2, 23));
      expect(form.arrivalDateLocal, DateTime(2026, 11, 3, 1));
      expect(form.validateDate(), isTrue);
    });

    test('a trip without times keeps its date', () {
      final form = TripFormModel.fromTrip(Trips.fromJson(
        {
          'uid': '9',
          'type': 'train',
          'start_datetime': '2026-10-23 00:00:01',
          'end_datetime': '2026-10-23 00:00:01',
          'path': [
            [48.84, 2.37],
            [45.76, 4.86],
          ],
        },
        pathAsGooglePolyline: false,
      ));
      final before = form.departureDayDateOnly;
      form.moveScheduleToToday(today: DateTime(2026, 11, 2));

      expect(form.dateType, DateType.date);
      expect(form.departureDayDateOnly, before);
    });
  });
}
