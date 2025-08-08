import 'package:flutter/material.dart';
import 'package:trainlog_app/data/models/trips.dart';
import 'package:trainlog_app/data/trips_repository.dart';

class TripsProvider extends ChangeNotifier {
  TripsRepository? _repository;
  bool _loading = true;

  bool get isLoading => _loading;
  TripsRepository? get repository => _repository;

  List<VehicleType> _vehicleTypes = const [VehicleType.unknown];
  List<VehicleType> get vehicleTypes => _vehicleTypes;

  List<int> _years = const [];
  List<int> get years => _years;

  List<String> _operators = const [];
  List<String> get operators => _operators;

  List<String> _countryCodes = const [];
  List<String> get countryCodes => _countryCodes;

  Map<String, String> _mapCountryCodes = const {};
  Map<String, String> get mapCountryCodes => _mapCountryCodes;

  // ------------------------
  // Public API
  // ------------------------

  Future<void> loadTrips({String csvPath = "", BuildContext? context}) async {
    _loading = true;
    notifyListeners();

    try {
      _repository = (csvPath.isEmpty)
          ? await TripsRepository.loadFromDatabase()
          : await TripsRepository.loadFromCsv(csvPath);

      await _refreshDerivedLists(context: context);

      final count = await _repository!.count();
      debugPrint("✅ Finished loading trips. $count rows");
    } catch (e, stack) {
      debugPrint("loadTrips failed: $e");
      debugPrintStack(stackTrace: stack);
      // keep safe fallbacks
      _vehicleTypes = const [VehicleType.unknown];
      _years = const [];
      _operators = const [];
      _countryCodes = const [];
      _mapCountryCodes = const {};
    } finally {
      _loading = false;
      notifyListeners(); // single notify after all data ready
    }
  }

  /// Refresh everything (safe to call anytime).
  Future<void> refreshAll({BuildContext? context}) async {
    if (_repository == null) {
      await loadTrips(context: context);
      return;
    }
    await _refreshDerivedLists(context: context);
    notifyListeners();
  }

  // Optional: keep granular refreshers but ensure repo is loaded
  Future<void> refreshVehicleTypes() async {
    if (_repository == null) { await loadTrips(); return; }
    _vehicleTypes = await _repository!.fetchListOfTypes() ?? const [VehicleType.unknown];
    notifyListeners();
  }

  Future<void> refreshYears() async {
    if (_repository == null) { await loadTrips(); return; }
    final yrs = await _repository!.fetchListOfYears() ?? <int>[];
    yrs.sort((a, b) => b.compareTo(a)); // descending
    _years = yrs;
    notifyListeners();
  }

  Future<void> refreshOperators() async {
    if (_repository == null) { await loadTrips(); return; }
    _operators = await _repository!.fetchListOfOperators() ?? const <String>[];
    notifyListeners();
  }

  Future<void> refreshCountryCodes() async {
    if (_repository == null) { await loadTrips(); return; }
    _countryCodes = await _repository!.fetchListOfCountryCode() ?? const <String>[];
    notifyListeners();
  }

  Future<void> refreshMapCountryCodes(BuildContext context) async {
    if (_repository == null) { await loadTrips(context: context); return; }
    _mapCountryCodes = await _repository!.fetchMapOfCountries(context) ?? const <String, String>{};
    notifyListeners();
  }

  // ------------------------
  // Internals
  // ------------------------

  Future<void> _refreshDerivedLists({BuildContext? context}) async {
    final repo = _repository;
    if (repo == null) return;

    // Fetch in parallel
    final futures = await Future.wait([
      repo.fetchListOfTypes(),               // 0
      repo.fetchListOfYears(),               // 1
      repo.fetchListOfOperators(),           // 2
      repo.fetchListOfCountryCode(),         // 3
      if (context != null) repo.fetchMapOfCountries(context), // 4 (optional, needs context)
    ]);

    _vehicleTypes = (futures[0] as List<VehicleType>?) ?? const [VehicleType.unknown];

    final yrs = (futures[1] as List<int>?) ?? <int>[];
    yrs.sort((a, b) => b.compareTo(a)); // descending
    _years = yrs;

    _operators   = (futures[2] as List<String>?) ?? const <String>[];
    _countryCodes= (futures[3] as List<String>?) ?? const <String>[];

    if (context != null) {
      _mapCountryCodes = (futures.last as Map<String, String>?) ?? const <String, String>{};
    }
  }
}
