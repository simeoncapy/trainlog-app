import 'dart:collection';
import 'package:flutter/foundation.dart';
import 'package:trainlog_app/data/models/trips.dart';
import 'package:trainlog_app/data/trips_repository.dart';
import 'package:trainlog_app/pages/statistics_page.dart';
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

  late LinkedHashMap<String, ({double past, double future})> _statsDistance 
                          = LinkedHashMap<String, ({double past, double future})>();

  late LinkedHashMap<String, ({double past, double future})> _statsTrip 
                          = LinkedHashMap<String, ({double past, double future})>();

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

  LinkedHashMap<String, ({double past, double future})> get currentStats =>
    isDistance ? _statsDistance : _statsTrip;


  // METHODS

  Future<void> load() async {
    final myReq = ++_req;
    _loading = true; _error = null;
    notifyListeners();

    try {
      // TODO: use _graph/_year in your queries when ready
      final rawDist = await repository.fetchOperatorsByDistancePF(
        filter: TripsFilterResult(keyword: "", types: [_vehicle]),
      );
      final rawTrip = await repository.fetchOperatorsByTripPF(
        filter: TripsFilterResult(keyword: "", types: [_vehicle]),
      );

      final dist = await getTop9WithOtherPF(original: rawDist, factor: 1_000);
      final trip = await getTop9WithOtherPF(original: rawTrip, factor: 1.0);

      if (myReq != _req) return; // a newer load started; drop this result

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

  Future<LinkedHashMap<String, ({double past, double future})>> getTop9WithOtherPF({
    required Map<String, ({num past, num future})> original,
    double factor = 1_000, // divide by this
    String otherLabel = 'Other',
  }) async {
    // Sort by (past + future) descending
    final sortedEntries = original.entries.toList()
      ..sort((a, b) =>
          (b.value.past + b.value.future).compareTo(a.value.past + a.value.future));

    // Take top 9 and the rest
    final top9 = sortedEntries.take(9).toList();
    final rest = sortedEntries.skip(9);

    // Sum the rest into "Other"
    double otherPast = 0;
    double otherFuture = 0;
    for (final e in rest) {
      otherPast  += e.value.past.toDouble();
      otherFuture+= e.value.future.toDouble();
    }

    // Build result (preserve order) and apply scaling
    final result = LinkedHashMap<String, ({double past, double future})>();

    for (final e in top9) {
      result[e.key] = (
        past:   e.value.past.toDouble()   / factor,
        future: e.value.future.toDouble() / factor,
      );
    }

    if (otherPast > 0 || otherFuture > 0) {
      result[otherLabel] = (
        past:   otherPast   / factor,
        future: otherFuture / factor,
      );
    }

    return result;
  }
}