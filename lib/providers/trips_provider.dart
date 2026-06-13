import 'dart:async';

import 'package:country_picker/country_picker.dart';
import 'package:flutter/material.dart';
import 'package:trainlog_app/data/models/trips.dart';
import 'package:trainlog_app/data/trips_repository.dart';
import 'package:trainlog_app/providers/settings_provider.dart';
import 'package:trainlog_app/services/api/trips_api.dart';
import 'package:trainlog_app/utils/date_utils.dart';

class TripsProvider extends ChangeNotifier {
  TripsRepository? _repository;
  TripsApi? _service;
  SettingsProvider? _settings;
  String? _username;
  bool _hasLoadedForUser = false;
  // For localized country names
  Locale? _locale;

  bool _loading = true;
  bool get isLoading => _loading;

  /// True while an incremental background sync with the server is running,
  /// after the local DB has already been presented to the UI.
  bool _isSyncing = false;
  bool get isSyncing => _isSyncing;
  TripsRepository? get repository => _repository;

  List<VehicleType> _vehicleTypes = const [VehicleType.unknown];
  List<VehicleType> get vehicleTypes => _vehicleTypes;
  List<VehicleType> get vehicleTypesWithoutPoi => _vehicleTypes.where((v) => v != VehicleType.poi).toList();

  List<int> _years = const [];
  List<int> get years => _years;
  List<int> get yearsWithUnknown {
    final y = _years;
    y.add(unknownPast.year);
    y.add(unknownFuture.year);
    return y;
  }

  List<String> _operators = const [];
  List<String> get operators => _operators;

  List<String> _countryCodes = const [];
  List<String> get countryCodes => _countryCodes;
  Future<List<String>> getCountryCodesSafe() async {
    final repo = _repository;
    if(_countryCodes.isNotEmpty) return _countryCodes;
    if(repo == null || await repo.count() == 0) return _countryCodes;

    await refreshCountryCodes();
    return _countryCodes;
  }

  Map<String, String> _mapCountryCodes = const {};
  Map<String, String> get mapCountryCodes => _mapCountryCodes;
  Future<Map<String, String>> getMapCountryCodesSafe({Locale? locale}) async {
    final repo = _repository;
    if(_mapCountryCodes.isNotEmpty) return _mapCountryCodes;
    if(repo == null || await repo.count() == 0) return _mapCountryCodes;

    await refreshMapCountryCodes(locale: locale);
    return _mapCountryCodes;
  }

  List<Trips>? _modificatedTrips;
  List<Trips>? get modificatedTrips {
    final data = _modificatedTrips;
    _modificatedTrips = null;
    return data;
  }

  /// Trip IDs removed server-side and detected via the incremental sync's
  /// id list. Consume-once, like [modificatedTrips], so the polyline layer can
  /// drop their polylines.
  List<int>? _deletedTripIds;
  List<int>? get deletedTripIds {
    final data = _deletedTripIds;
    _deletedTripIds = null;
    return data;
  }

  int _revision = 0;
  int get revision => _revision;
  int _polylineRevision = 0;
  int get polylineRevision => _polylineRevision;

  void updateDeps({
    required TripsApi service,
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

    final lastFetch = _settings!.lastFetchingTrips;
    final isFirstLoad = lastFetch == null || lastFetch == forceRefreshDate.toUtc();

    if (isFirstLoad) {
      // No prior data: fetch everything from the server (full hard refresh).
      debugPrint("🚀 TripsProvider: first load for $_username → hard refresh");
      await loadNecessaryTripsData(locale: _locale, hardRefresh: true);
    } else {
      // Returning user: show local DB data immediately, then sync in background.
      debugPrint("🚀 TripsProvider: returning user $_username → local DB + background sync");
      await _loadFromLocalDb();
      unawaited(_backgroundSync());
    }
  }

  /// Loads the repository directly from the local SQLite DB and refreshes all
  /// derived lists.  Fast — no network access.
  Future<void> _loadFromLocalDb() async {
    _loading = true;
    notifyListeners();
    try {
      _repository = await TripsRepository.loadFromDatabase();
      await _refreshDerivedLists();
      _revision++;
      _polylineRevision++;
      final count = await _repository!.count();
      debugPrint("✅ Loaded $count trips from local DB");
    } catch (e, stack) {
      debugPrint("🛑 _loadFromLocalDb failed: $e");
      debugPrintStack(stackTrace: stack);
      _vehicleTypes = const [VehicleType.unknown];
      _years = const [];
      _operators = const [];
      _countryCodes = const [];
      _mapCountryCodes = const {};
    } finally {
      _loading = false;
      notifyListeners();
    }
  }

  /// Runs an incremental network sync without touching the loading state
  /// (the UI is already showing local data).  Sets [isSyncing] = true for
  /// the duration so the progress bar overlay can react.
  Future<void> _backgroundSync() async {
    _isSyncing = true;
    notifyListeners();
    try {
      await loadNecessaryTripsData(locale: _locale, hardRefresh: false, silentSync: true);
    } finally {
      _isSyncing = false;
      notifyListeners();
    }
  }

  // ------------------------
  // Public API
  // ------------------------

  /// Loads (or refreshes) trips data.
  ///
  /// [hardRefresh] — if true, re-downloads everything from the server;
  ///   otherwise only fetches trips modified since [SettingsProvider.lastFetchingTrips].
  ///
  /// [silentSync] — if true, the [isLoading] flag is NOT toggled.  Use this
  ///   when calling from a background context where the UI is already showing
  ///   data from the local DB (e.g. [_backgroundSync]).
  Future<void> loadNecessaryTripsData({Locale? locale, bool hardRefresh = false, bool silentSync = false}) async {
    if (!silentSync) {
      _loading = true;
      notifyListeners();
    }
    if (locale != null) _locale = locale;

    DateTime? lastRefresh = hardRefresh ? null : _settings!.lastFetchingTrips;
    if(lastRefresh == forceRefreshDate.toUtc()) lastRefresh = null; // treat forceRefreshDate as hard refresh

    // If doing incremental refresh, check if new DB columns were added - force hard refresh to fill them
    DateTime? originalLastRefresh = lastRefresh;
    if (lastRefresh != null && await TripsRepository.needsSchemaUpdate()) {
      debugPrint("🔄 Schema update detected, forcing hard refresh to fill new columns");
      lastRefresh = null;
    }

    try {
      // Cursor persisted after the sync. The incremental path overrides this
      // with the server's own `lastLocal` timestamp when one is provided.
      DateTime cursorToPersist = DateTime.now().toUtc();

      if (lastRefresh == null) {
        debugPrint("🔄 Hard refreshing all trips data");
        final content = await _service!.fetchAllTripsData(_username ?? "");
        _settings!.setShouldLoadTripsFromApi(false);
        _repository = await TripsRepository.loadFromCsv(
          content,
          replace: true,
          path: false,
        );
      } else {
        debugPrint("🔄 Refreshing only necessary $_username's trips from ${lastRefresh.toIso8601String()}");
        final result = await _service!.fetchLastUpdatedTripsData(_username??"", lastRefresh);

        _repository ??= await TripsRepository.loadFromDatabase();

        // Merge the getTripsPaths payload onto existing rows, writing only the
        // fields it actually carried so omitted fields keep their values.
        if (result.updates.isNotEmpty) {
          await _repository!.mergeTripUpdates(result.updates);
          _modificatedTrips = [...?_modificatedTrips, ...result.trips];
        }

        // Deletion detection: drop local trips the server no longer lists.
        // Guarded on a non-empty id list so an absent/empty list — e.g. while
        // the backend endpoint is incomplete — can never wipe the local DB.
        List<int> deleted = const [];
        if (result.serverTripIds.isNotEmpty) {
          deleted = await _repository!.deleteTripsNotIn(result.serverTripIds.toSet());
          if (deleted.isNotEmpty) {
            _deletedTripIds = [...?_deletedTripIds, ...deleted];
            debugPrint("🗑️ Removed ${deleted.length} trip(s) deleted server-side");
          }
        }

        // Advance the cursor to the server's own timestamp when provided.
        if (result.lastLocal != null) cursorToPersist = result.lastLocal!;

        if (result.updates.isEmpty && deleted.isEmpty) {
          debugPrint("✅ Nothing to update.");
          _settings!.setLastFetchingTrips(cursorToPersist);
          return; // finally block handles notifyListeners
        }

        debugPrint("✅ Finished updating ${result.updates.length} trip(s), removed ${deleted.length}");
      }

      await _refreshDerivedLists();

      // Skip polyline refresh for schema-triggered hard refreshes, unless trips were
      // also modified since the last update (which may include path changes)
      final hadModifications = originalLastRefresh == null
          || await _repository!.hasTripsModifiedSince(originalLastRefresh);
      if (hadModifications) _polylineRevision++;
      _revision++;
      final count = await _repository!.count();
      debugPrint("✅ Finished loading trips. Total $count rows");
      _settings!.setLastFetchingTrips(cursorToPersist);
    } catch (e, stack) {
      debugPrint("🛑 loadTrips failed: $e");
      debugPrintStack(stackTrace: stack);
      // keep safe fallbacks
      _vehicleTypes = const [VehicleType.unknown];
      _years = const [];
      _operators = const [];
      _countryCodes = const [];
      _mapCountryCodes = const {};
    } finally {
      if (!silentSync) _loading = false;
      notifyListeners();
    }
  }

  Future<void> insertTrip(Trips trip, {bool setLoading = false}) async {
    if(_repository == null) return;
    await _repository!.insertTrip(trip);
    await _refreshDerivedLists();

    _modificatedTrips = [...?_modificatedTrips, trip];
    
    _polylineRevision++;
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
      // await loadTrips(locale: locale);
      await loadNecessaryTripsData(locale: locale, hardRefresh: true);
      return;
    }
    await _refreshDerivedLists();
    notifyListeners();
  }

  // Optional: keep granular refreshers but ensure repo is loaded
  Future<void> refreshVehicleTypes() async {
    // if (_repository == null) { await loadTrips(); return; }
    if (_repository == null) { await loadNecessaryTripsData(hardRefresh: true); return; }
    _vehicleTypes = await _repository!.fetchListOfTypes();
    notifyListeners();
  }

  Future<void> refreshYears() async {
    // if (_repository == null) { await loadTrips(); return; }
    if (_repository == null) { await loadNecessaryTripsData(hardRefresh: true); return; }
    final yrs = await _repository!.fetchListOfYears();
    yrs.sort((a, b) => b.compareTo(a)); // descending
    _years = yrs;
    notifyListeners();
  }

  Future<void> refreshOperators() async {
    // if (_repository == null) { await loadTrips(); return; }
    if (_repository == null) { await loadNecessaryTripsData(hardRefresh: true); return; }
    _operators = await _repository!.fetchListOfOperators();
    notifyListeners();
  }

  Future<void> refreshCountryCodes() async {
    // if (_repository == null) { await loadTrips(); return; }
    if (_repository == null) { await loadNecessaryTripsData(hardRefresh: true); return; }
    _countryCodes = await _repository!.fetchListOfCountryCode();
    notifyListeners();
  }

  Future<void> refreshMapCountryCodes({Locale? locale}) async {
    if (locale != null) _locale = locale;
    // if (_repository == null) { await loadTrips(locale: locale); return; }
    if (_repository == null) { await loadNecessaryTripsData(locale: locale, hardRefresh: true); return; }
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

    try {
      _vehicleTypes = await repo.fetchListOfTypes();
      debugPrint("✅ fetchListOfTypes OK");
    } catch (e) { debugPrint("🛑 fetchListOfTypes: $e"); }

    try {
      final yrs = await repo.fetchListOfYears();
      yrs.sort((a, b) => b.compareTo(a));
      _years = yrs;
      debugPrint("✅ fetchListOfYears OK");
    } catch (e) { debugPrint("🛑 fetchListOfYears: $e"); }

    try {
      _operators = await repo.fetchListOfOperators();
      debugPrint("✅ fetchListOfOperators OK");
    } catch (e) { debugPrint("🛑 fetchListOfOperators: $e"); }

    try {
      _countryCodes = await repo.fetchListOfCountryCode();
      debugPrint("✅ fetchListOfCountryCode OK");
    } catch (e) { debugPrint("🛑 fetchListOfCountryCode: $e"); }

    try {
      await _refreshCountryNames();
      debugPrint("✅ _refreshCountryNames OK");
    } catch (e) { debugPrint("🛑 _refreshCountryNames: $e"); }
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
