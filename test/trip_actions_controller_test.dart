import 'package:flutter_test/flutter_test.dart';
import 'package:trainlog_app/core/data/models/trips.dart';
import 'package:trainlog_app/core/providers/polyline_provider.dart';
import 'package:trainlog_app/core/providers/trainlog_provider.dart';
import 'package:trainlog_app/core/providers/trips_provider.dart';
import 'package:trainlog_app/features/trips/detail_sheet/trip_actions_controller.dart';

class _Trip implements Trips {
  _Trip(this.uid);

  @override
  final String uid;

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _Trainlog implements TrainlogProvider {
  _Trainlog({required this.succeeds});

  final bool succeeds;
  final deleted = <int>[];

  @override
  String get instanceUrl => 'https://trainlog.example';

  @override
  Future<bool> deleteTrip(int tripId) async {
    deleted.add(tripId);
    return succeeds;
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _Trips implements TripsProvider {
  final deleted = <int>[];

  @override
  Future<void> deleteTrip(int tripId) async => deleted.add(tripId);

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _Polylines implements PolylineProvider {
  final removed = <int>[];

  @override
  void removePolylineByTripId(int tripId) => removed.add(tripId);

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

void main() {
  TripActionsController controller(
    String uid,
    _Trainlog trainlog,
    _Trips trips,
    _Polylines polylines,
  ) => TripActionsController(
    trip: _Trip(uid),
    trainlog: trainlog,
    trips: trips,
    polylines: polylines,
  );

  test('share url is the public trip page', () {
    final c = controller(
      '42',
      _Trainlog(succeeds: true),
      _Trips(),
      _Polylines(),
    );
    expect(c.shareUrl.toString(), 'https://trainlog.example/public/trip/42');
  });

  test('a deleted trip leaves the local trips and the map', () async {
    final trainlog = _Trainlog(succeeds: true);
    final trips = _Trips();
    final polylines = _Polylines();
    final outcome = await controller('42', trainlog, trips, polylines).delete();
    expect(outcome, TripDeleteOutcome.deleted);
    expect(trainlog.deleted, [42]);
    expect(trips.deleted, [42]);
    expect(polylines.removed, [42]);
  });

  test('a server failure changes nothing locally', () async {
    final trips = _Trips();
    final outcome = await controller(
      '42',
      _Trainlog(succeeds: false),
      trips,
      _Polylines(),
    ).delete();
    expect(outcome, TripDeleteOutcome.failed);
    expect(trips.deleted, isEmpty);
  });

  test('a uid that is not a number is refused before any call', () async {
    final trainlog = _Trainlog(succeeds: true);
    final outcome = await controller(
      'abc',
      trainlog,
      _Trips(),
      _Polylines(),
    ).delete();
    expect(outcome, TripDeleteOutcome.invalidId);
    expect(trainlog.deleted, isEmpty);
  });
}
