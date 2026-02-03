import 'package:country_picker/country_picker.dart';
import 'package:flutter/material.dart';
import 'package:trainlog_app/data/models/trips.dart';
import 'package:trainlog_app/data/trips_repository.dart';
import 'package:trainlog_app/providers/settings_provider.dart';
import 'package:trainlog_app/services/trainlog_service.dart';

class TripsProvider extends ChangeNotifier {
  TripsRepository? _repository;
  TrainlogService? _service;
  SettingsProvider? _settings;
  String? _username;
  bool _hasLoadedForUser = false;
  // For localized country names
  Locale? _locale;

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

  int _revision = 0;
  int get revision => _revision;
  int _polylineRevision = 0;
  int get polylineRevision => _polylineRevision;

  void updateDeps({
    required TrainlogService service,
    required SettingsProvider settings,
    required String? username,
  }) {
    _service = service;
    _settings = settings;

    final userChanged = username != null && username != _username;
    debugPrint("Old username: $_username, New username: $username");
    _username = username;

    if (userChanged) {
      debugPrint("TripsProvider: user changed → auto loading trips");
      _hasLoadedForUser = false;
      _autoLoadForUser();
    }
  }

  /// Update locale from UI when needed (safe).
  void updateLocale(Locale locale) {
    _locale = locale;
  }

  Future<void> _autoLoadForUser() async {
    if (_service == null || _username == null || _settings == null) return;
    if (_hasLoadedForUser) return;

    _hasLoadedForUser = true;

    debugPrint("🚀 TripsProvider auto-loading trips for $_username");

    await loadTrips(
      locale: _locale,
      loadFromApi: true,
    );
  }

  // ------------------------
  // Public API
  // ------------------------

  Future<void> loadTrips({String csvPath = "", Locale? locale, bool loadFromApi = false}) async {
    _loading = true;
    notifyListeners();
    if (locale != null) _locale = locale;

    try {
      if (csvPath.isNotEmpty) {
        _repository = await TripsRepository.loadFromCsv(csvPath);
      } else if (loadFromApi) {
        debugPrint("Loading from API");
        final content = await _service!.fetchAllTripsData(_username ?? "");
        _settings!.setShouldLoadTripsFromApi(false);
        _repository = await TripsRepository.loadFromCsv(
          content,
          replace: true,
          path: false,
        );
      } else {
        _repository = await TripsRepository.loadFromDatabase();
      }

      await _refreshDerivedLists();

      _revision++;
      _polylineRevision++;
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

  Future<void> insertTrip(Trips trip, {bool setLoading = false}) async {
    if(_repository == null) return;
    await _repository!.insertTrip(trip);
    await _refreshDerivedLists();
    
    _revision++;
    _loading = setLoading;
    notifyListeners();
  }

  Future<void> clearAll({bool setLoading = false}) async {
    if(_repository == null) return;
    await _repository!.clearAllTrips();

    _vehicleTypes = const [VehicleType.unknown];
    _years = const [];
    _operators = const [];
    _countryCodes = const [];
    _mapCountryCodes = const {};
    _revision++;
    _polylineRevision++;
    _loading = setLoading;
    notifyListeners();
  }

  Future<void> deleteTrip(int tripId) async {
    if(_repository == null) return;
    await _repository!.deleteTripById(tripId.toString());
    await _refreshDerivedLists();

    _revision++;
    _loading = false;
    notifyListeners();
  }

  /// Refresh everything (safe to call anytime).
  Future<void> refreshAll(Locale? locale) async {
    if (locale != null) _locale = locale;
    if (_repository == null) {
      await loadTrips(locale: locale);
      return;
    }
    await _refreshDerivedLists();
    notifyListeners();
  }

  // Optional: keep granular refreshers but ensure repo is loaded
  Future<void> refreshVehicleTypes() async {
    if (_repository == null) { await loadTrips(); return; }
    _vehicleTypes = await _repository!.fetchListOfTypes();
    notifyListeners();
  }

  Future<void> refreshYears() async {
    if (_repository == null) { await loadTrips(); return; }
    final yrs = await _repository!.fetchListOfYears();
    yrs.sort((a, b) => b.compareTo(a)); // descending
    _years = yrs;
    notifyListeners();
  }

  Future<void> refreshOperators() async {
    if (_repository == null) { await loadTrips(); return; }
    _operators = await _repository!.fetchListOfOperators();
    notifyListeners();
  }

  Future<void> refreshCountryCodes() async {
    if (_repository == null) { await loadTrips(); return; }
    _countryCodes = await _repository!.fetchListOfCountryCode();
    notifyListeners();
  }

  Future<void> refreshMapCountryCodes({Locale? locale}) async {
    if (locale != null) _locale = locale;
    if (_repository == null) { await loadTrips(locale: locale); return; }
    //_mapCountryCodes = await _repository!.fetchMapOfCountries(context);
    await _refreshCountryNames();
    notifyListeners();
  }

  // ------------------------
  // Internals
  // ------------------------

  Future<void> _refreshDerivedLists() async {
    final repo = _repository;
    if (repo == null) return;

    //final countryLoc = await CountryLocalizations.delegate.load(locale);

    // Fetch in parallel
    final futures = await Future.wait([
      repo.fetchListOfTypes(),               // 0
      repo.fetchListOfYears(),               // 1
      repo.fetchListOfOperators(),           // 2
      repo.fetchListOfCountryCode(),         // 3
    ]);

    _vehicleTypes = (futures[0] as List<VehicleType>?) ?? const [VehicleType.unknown];

    final yrs = (futures[1] as List<int>?) ?? <int>[];
    yrs.sort((a, b) => b.compareTo(a)); // descending
    _years = yrs;

    _operators   = (futures[2] as List<String>?) ?? const <String>[];
    _countryCodes= (futures[3] as List<String>?) ?? const <String>[];

    await _refreshCountryNames();
  }

  Future<void> _refreshCountryNames() async {
    final repo = _repository;
    final locale = _locale;
    if (repo == null || locale == null) {
      _mapCountryCodes = const {};
      return;
    }

    final details = await CountryLocalizations.delegate.load(locale);
    _mapCountryCodes = await repo.fetchMapOfCountries(details);
  }
}
