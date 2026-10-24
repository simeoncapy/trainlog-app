import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:trainlog_app/data/models/trip_form_model.dart';
import 'package:trainlog_app/services/api/trainlog_http_client.dart';
import 'package:trainlog_app/services/api/trips_api.dart';
import 'package:trainlog_app/utils/date_utils.dart';

import 'fake_trainlog_server.dart';

/// The edit endpoint's context for a bus from Shinjuku (13:05 JST, 04:05 UTC)
/// to Kawaguchiko (15:15 JST, 06:15 UTC), as edit_copy_trip renders it: the
/// local times at the top level, the UTC ones in the nested trip row.
Map<String, dynamic> _editContext(String precision) => {
      'tripId': '7',
      'username': 'alice',
      'origin': 'Shinjuku',
      'destination': 'Kawaguchiko',
      'start_datetime': '2026-10-23 13:05:00',
      'end_datetime': '2026-10-23 15:15:00',
      'precision': precision,
      'tripType': 'bus',
      'tripOperator': 'Keio',
      'wplist': [
        [35.69, 139.70],
        [35.50, 138.76],
      ],
      'trip': {
        'start_datetime': '2026-10-23 13:05:00',
        'end_datetime': '2026-10-23 15:15:00',
        'utc_start_datetime': '2026-10-23 04:05:00',
        'utc_end_datetime': '2026-10-23 06:15:00',
        'last_modified': '2026-10-23 10:00:00',
      },
    };

Future<TripFormModel> _openForEdit(String precision) async {
  final client = TrainlogHttpClient()
    ..dio.httpClientAdapter =
        FakeAdapter((_) => jsonBody(jsonEncode(_editContext(precision))));
  final data =
      await TripsApi(client).fetchTripEditCopy('alice', 7, EditCopy.edit);
  return TripFormModel.fromTrip(data.formTrip);
}

void main() {
  // The edit page spells it "precise" (edit_copy_trip); the forms post
  // "preciseDates". Either way the trip's UTC times must be kept: dropping
  // them read the local departure as UTC (13:05 JST became 22:05 JST) and the
  // local arrival in the phone's timezone, so the dates could not be saved.
  for (final precision in ['precise', 'preciseDates']) {
    test('a trip with times keeps its UTC times ($precision)', () async {
      final form = await _openForEdit(precision);

      expect(form.dateType, DateType.precise);
      expect(form.departureDate, DateTime.utc(2026, 10, 23, 4, 5));
      expect(form.arrivalDate, DateTime.utc(2026, 10, 23, 6, 15));
      expect(form.departureDateLocal, DateTime(2026, 10, 23, 13, 5));
      expect(form.arrivalDateLocal, DateTime(2026, 10, 23, 15, 15));
      expect(form.validateDate(), isTrue);
    });
  }
}
