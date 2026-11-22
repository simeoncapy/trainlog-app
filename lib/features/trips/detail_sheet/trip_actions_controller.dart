import 'package:flutter/foundation.dart';
import 'package:trainlog_app/core/data/models/trips.dart';
import 'package:trainlog_app/core/providers/polyline_provider.dart';
import 'package:trainlog_app/core/providers/trainlog_provider.dart';
import 'package:trainlog_app/core/providers/trips_provider.dart';

/// How deleting a trip ended.
enum TripDeleteOutcome { deleted, invalidId, failed }

/// Actions on one trip from its details sheet (share, delete), shared by the
/// Material and iOS views. Confirming, navigating and messages stay in the
/// views; the server call and the state updates happen here.
class TripActionsController {
  TripActionsController({
    required this.trip,
    required TrainlogProvider trainlog,
    required TripsProvider trips,
    required PolylineProvider polylines,
  }) : _trainlog = trainlog,
       _trips = trips,
       _polylines = polylines;

  final Trips trip;
  final TrainlogProvider _trainlog;
  final TripsProvider _trips;
  final PolylineProvider _polylines;

  /// The trip's numeric id, or null when its uid is not one.
  int? get tripId => int.tryParse(trip.uid);

  /// The trip's public page on the Trainlog instance.
  Uri get shareUrl =>
      Uri.parse('${_trainlog.instanceUrl}/public/trip/${trip.uid}');

  /// Deletes the trip on the server, then from the local trips and the map.
  Future<TripDeleteOutcome> delete() async {
    final id = tripId;
    if (id == null) return TripDeleteOutcome.invalidId;

    final success = await _trainlog.deleteTrip(id);
    if (!success) return TripDeleteOutcome.failed;

    debugPrint('Trip $id deleted successfully');
    _trips.deleteTrip(id);
    _polylines.removePolylineByTripId(id);
    return TripDeleteOutcome.deleted;
  }
}
