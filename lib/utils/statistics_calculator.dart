import 'dart:collection';
import 'package:flutter/foundation.dart';
import 'package:trainlog_app/data/models/trips.dart';
import 'package:trainlog_app/data/trips_repository.dart';
import 'package:trainlog_app/pages/statistics_page.dart';
import 'package:trainlog_app/providers/statistics_provider.dart';
import 'package:trainlog_app/widgets/trips_filter_dialog.dart';

class StatisticsCalculator extends ChangeNotifier {
  final TripsRepository repository;

  VehicleType _vehicle;
  GraphType _graph;
  int? _year;
  bool _isDistance = false;

  bool _loading = false;
  String? _error;
  int _req = 0; // request id to ignore stale loads

  LinkedHashMap<String, ({double past, double future})> _statsDistance = LinkedHashMap();
  LinkedHashMap<String, ({double past, double future})> _statsTrip = LinkedHashMap();

  StatisticsCalculator(this.repository, this._vehicle, this._graph, {int? initialYear})
      : _year = initialYear;

  // GETTER & SETTERS

  bool get isLoading => _loading;
  String? get error => _error;
  bool get isDistance => _isDistance;
  set isDistance(bool v) { if (_isDistance != v) { _isDistance = v; notifyListeners(); } }

  VehicleType get vehicle => _vehicle;
  GraphType get graph => _graph;
  int? get year => _year;

  set vehicle(VehicleType v) { if (v != _vehicle) { _vehicle = v; load(); } }
  set graph(GraphType g)     { if (g != _graph)     { _graph = g; load(); } }
  set year(int? y)           { if (y != _year)      { _year = y; load(); } }

  /// Full stats (ALL rows), already scaled.
  LinkedHashMap<String, ({double past, double future})> get currentStats =>
    isDistance ? _statsDistance : _statsTrip;

  /// Top `itemsNumber` rows + "Other" (sum of remaining), using the current mode.
  LinkedHashMap<String, ({double past, double future})> currentStatsShort(
    int itemsNumber, {
    String otherLabel = 'Other',
  }) {
    if (itemsNumber <= 0) return LinkedHashMap();

    // Work from the full set; sort by (past+future) desc.
    final entries = currentStats.entries.toList()
      ..sort((a, b) => (b.value.past + b.value.future)
          .compareTo(a.value.past + a.value.future));

    if (entries.length <= itemsNumber) {
      return LinkedHashMap.fromEntries(entries);
    }

    final top = entries.take(itemsNumber);
    final rest = entries.skip(itemsNumber);

    double otherPast = 0, otherFuture = 0;
    for (final e in rest) {
      otherPast += e.value.past;
      otherFuture += e.value.future;
    }

    final out = LinkedHashMap<String, ({double past, double future})>();
    for (final e in top) {
      out[e.key] = (past: e.value.past, future: e.value.future);
    }
    if (otherPast > 0 || otherFuture > 0) {
      out[otherLabel] = (past: otherPast, future: otherFuture);
    }
    return out;
  }


  // METHODS
  Future<void> load() async {
    final myReq = ++_req;
    _loading = true; _error = null;
    notifyListeners();
    final (DateTime? start, DateTime? endExclusive) = switch (year) {
      null || 0 => (null, null),
      int y => (DateTime(y, 1, 1), DateTime(y + 1, 1, 1)),
    };
    final filter = TripsFilterResult(
      keyword: "",
      types: [_vehicle],
      startDate: start,
      endDate: endExclusive,
    );

    try {
      Map<String, ({num past, num future})> rawDist;
      Map<String, ({num past, num future})> rawTrip;

      switch (_graph) {
        case GraphType.operator:
          rawDist = await repository.fetchOperatorsByDistancePF(filter: filter);
          rawTrip = await repository.fetchOperatorsByTripPF(filter: filter);
          break;

        case GraphType.country:
          rawDist = await repository.fetchCountriesByDistancePF(filter: filter);
          rawTrip = await repository.fetchCountriesByTripPF(filter: filter);
          break;

        // TODO: GraphType.years/material/itinerary/stations
        default:
          rawDist = const {};
          rawTrip = const {};
          break;
      }

      // Store **all** rows, scaled (distance ÷ 1000; trips ×1).
      final dist = _scalePF(rawDist, factor: 1_000);
      final trip = _scalePF(rawTrip, factor: 1.0);

      if (myReq != _req) return;

      _statsDistance = dist;
      _statsTrip = trip;
    } catch (e) {
      if (myReq != _req) return;
      _error = e.toString();
      _statsDistance.clear();
      _statsTrip.clear();
    } finally {
      if (myReq == _req) {
        _loading = false;
        notifyListeners();
      }
    }
  }

  Future<LinkedHashMap<String, double>> getTop9WithOther({
    required Map<String, double> original,
    double factor = 1_000, // divide by this
  }) async {
    // Sort descending by value
    final sortedEntries = original.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    // Keep top 9
    final top9 = sortedEntries.take(9).toList();
    final rest = sortedEntries.skip(9);

    // Sum the rest
    final otherValue = rest.fold<double>(0, (sum, e) => sum + e.value);

    // Create LinkedHashMap to preserve order
    final result = LinkedHashMap<String, double>();

    // Add scaled top 9
    for (final e in top9) {
      result[e.key] = e.value / factor;
    }

    // Add "Other" if there was anything to sum
    if (otherValue > 0) {
      result["Other"] = otherValue / factor;
    }

    return result;
  }

  /// Scale map by `factor` (divide), return as LinkedHashMap.
  LinkedHashMap<String, ({double past, double future})> _scalePF(
    Map<String, ({num past, num future})> original, {
    double factor = 1.0,
  }) {
    // Sort by total desc for predictable order (optional—remove if you prefer original order).
    final sorted = original.entries.toList()
      ..sort((a, b) =>
          (b.value.past + b.value.future).compareTo(a.value.past + a.value.future));

    final out = LinkedHashMap<String, ({double past, double future})>();
    for (final e in sorted) {
      out[e.key] = (
        past:   e.value.past.toDouble()   / factor,
        future: e.value.future.toDouble() / factor,
      );
    }
    return out;
  }
}