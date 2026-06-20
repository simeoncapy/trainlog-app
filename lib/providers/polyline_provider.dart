import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';

import 'package:trainlog_app/data/models/polyline_entry.dart';
import 'package:trainlog_app/data/models/polyline_filter_state.dart';
import 'package:trainlog_app/data/models/trips.dart';
import 'package:trainlog_app/data/polyline_cache.dart';
import 'package:trainlog_app/data/polyline_loader.dart';
import 'package:trainlog_app/providers/settings_provider.dart';
import 'package:trainlog_app/providers/trips_provider.dart';
import 'package:trainlog_app/utils/date_utils.dart';
import 'package:trainlog_app/utils/map_color_palette.dart';
import 'package:trainlog_app/utils/polyline_styling.dart';

class PolylineProvider extends ChangeNotifier {
  // ============================================================================
  // Dependencies
  // ============================================================================

  TripsProvider? _trips;
  SettingsProvider? _settings;

  // ============================================================================
  // Raw polyline state
  // ============================================================================
  //
  // _polylines:
  //   Base source list owned by this provider.
  //   These entries are already decoded and restyled, but NOT filtered/sorted
  //   for final display.
  //
  // _renderedPolylines:
  //   Final UI-ready list after filtering, sorting, and applying overlay lines
  //   for future trips.
  // ============================================================================

  List<PolylineEntry> _polylines = [];
  List<Polyline<int>> _renderedPolylines = const [];

  bool _isLoading = true;
  Object? _error;

  /// Number of trips matching the current filter selection (before the future
  /// dash-overlay duplication that happens when building render polylines).
  /// Drives the "Show {count} trips" action button in the filter sheet.
  int _visibleTripCount = 0;

  int _renderRevision = 0;
  int _lastTripsPolylineRevision = -1;
  int _loadToken = 0;

  Timer? _futureFlipTimer;

  // ============================================================================
  // Persisted filter state
  // ============================================================================
  //
  // These values are the "logical" filter state used by the provider.
  // They are persisted via SettingsProvider so the user's choices survive restarts.
  // ============================================================================

  Set<int> _selectedYears = {};
  PolylineYearFilter _selectedYearFilter = PolylineYearFilter.all;
  int _selectedYearFilterOption = 0;

  // Whether the loaded trips include any "unknown past" / "unknown future"
  // entries (sentinel years 0 / 9999). Drives the dedicated toggle buttons in
  // the year filter grid, which are only shown when such trips exist.
  bool _hasUnknownPast = false;
  bool _hasUnknownFuture = false;

  Set<VehicleType> _selectedTypes = {};
  Set<VehicleType> _userDeselectedTypes = {};
  Set<VehicleType> _lastAvailableTypes = {};

  bool _filtersLoadedFromSettings = false;

  // ============================================================================
  // Public getters
  // ============================================================================

  List<PolylineEntry> get polylines => _polylines;
  List<Polyline<int>> get renderedPolylines => _renderedPolylines;

  bool get isLoading => _isLoading;
  Object? get error => _error;

  /// Revision of the underlying trip/polyline source.
  int get revision => _lastTripsPolylineRevision;

  /// Revision of the final rendered polyline list.
  int get renderRevision => _renderRevision;

  /// Number of trips currently visible on the map given the active filters.
  int get visibleTripCount => _visibleTripCount;

  Set<int> get selectedYears => Set.unmodifiable(_selectedYears);
  PolylineYearFilter get selectedYearFilter => _selectedYearFilter;
  int get selectedYearFilterOption => _selectedYearFilterOption;

  /// Whether any loaded trip has an unknown (undated) past start.
  bool get hasUnknownPast => _hasUnknownPast;

  /// Whether any loaded trip has an unknown (undated) future start.
  bool get hasUnknownFuture => _hasUnknownFuture;

  Set<VehicleType> get selectedTypes => Set.unmodifiable(_selectedTypes);
  Set<VehicleType> get userDeselectedTypes => Set.unmodifiable(_userDeselectedTypes);

  List<int> get availableYears => _trips?.years ?? const [];
  List<VehicleType> get availableTypes => _trips?.vehicleTypes ?? const [];
  List<VehicleType> get availableTypesWithoutPoi => _trips?.vehicleTypesWithoutPoi ?? const [];

  DateTime get _nowUtc => DateTime.now().toUtc();

  // ============================================================================
  // Dependency wiring / lifecycle entry points
  // ============================================================================

  void updateDependencies({
    required TripsProvider trips,
    required SettingsProvider settings,
  }) {
    final prevTrips = _trips;
    final prevSettings = _settings;

    _trips = trips;
    _settings = settings;

    if (prevTrips != trips) {
      prevTrips?.removeListener(_onTripsChanged);
      trips.addListener(_onTripsChanged);
    }

    if (prevSettings != settings) {
      prevSettings?.removeListener(_onSettingsChanged);
      settings.addListener(_onSettingsChanged);
    }

    _loadFiltersFromSettingsIfNeeded();
    _syncWithTrips();
  }

  /// Ensures that polylines are available.
  /// Safe to call repeatedly.
  Future<void> ensureLoaded() async {
    final trips = _trips;
    final settings = _settings;

    if (trips == null || settings == null) return;
    if (trips.repository == null || trips.isLoading) return;
    if (_isLoading) return;

    if (_polylines.isNotEmpty) {
      _scheduleNextFlip();
      return;
    }

    await reload(ignoreCache: false);
  }

  /// Force a full refresh from the database.
  Future<void> refreshFromDb() => reload(ignoreCache: true);

  // ============================================================================
  // Filter state loading / persistence
  // ============================================================================

  void _loadFiltersFromSettingsIfNeeded() {
    final settings = _settings;
    if (settings == null || _filtersLoadedFromSettings) return;

    _selectedYearFilter = settings.mapPolylineYearFilter;
    _selectedYears = {...settings.mapPolylineSelectedYears};
    _userDeselectedTypes = {...settings.mapPolylineDeselectedTypes};
    _selectedYearFilterOption = settings.mapPolylineYearFilterOption;

    _filtersLoadedFromSettings = true;
  }

  Future<void> _persistFilters() async {
    final settings = _settings;
    if (settings == null) return;

    await settings.setMapPolylineFilterState(
      yearFilter: _selectedYearFilter,
      selectedYears: _selectedYears,
      deselectedTypes: _userDeselectedTypes,
      yearFilterOption: _selectedYearFilterOption,
    );
  }

  /// Reconciles current filter state with currently available trip years/types.
  ///
  /// This is important after trip reloads:
  /// - if new types appear, they should be auto-selected unless explicitly deselected
  /// - if selected years disappear, the filter should fall back safely
  void _reconcileFiltersWithTrips() {
    final trips = _trips;
    if (trips == null) return;

    final availableYears = trips.years.toSet();
    final availableTypes = trips.vehicleTypes.toSet();

    // ---- Years
    if (_selectedYearFilter == PolylineYearFilter.all) {
      _selectedYears = availableYears;
      _selectedYearFilterOption = 0;
    } else if (_selectedYearFilter == PolylineYearFilter.years) {
      // Stay in explicit "years" mode, even if nothing is selected.
      // Only remove years that no longer exist. The unknown-past/future
      // sentinel years are valid selections too, so keep them around.
      final allowedYears = {
        ...availableYears,
        unknownPast.year,
        unknownFuture.year,
      };
      _selectedYears = _selectedYears.intersection(allowedYears);
    }

    // ---- Types
    if (_selectedTypes.isEmpty) {
      // Keep explicit "none selected" if user deselected everything.
      _selectedTypes = availableTypes.difference(_userDeselectedTypes);
    } else {
      _selectedTypes = _selectedTypes.intersection(availableTypes);
      _selectedTypes.removeAll(_userDeselectedTypes);

      final newlyAdded = availableTypes.difference(_lastAvailableTypes);
      _selectedTypes.addAll(newlyAdded.difference(_userDeselectedTypes));
    }

    _lastAvailableTypes = availableTypes;
  }

  // ============================================================================
  // Public filter actions
  // ============================================================================

  Future<void> toggleType(VehicleType type, bool selected) async {
    if (selected) {
      _selectedTypes.add(type);
      _userDeselectedTypes.remove(type);
    } else {
      _selectedTypes.remove(type);
      _userDeselectedTypes.add(type);
    }

    await _persistFilters();
    _rebuildRenderedPolylines(notify: true);
  }

  Future<void> updateYearFilter({
    required int topIndex,
    required List<int> years,
    required List<bool> subSelection,
  }) async {
    switch (topIndex) {
      case 0:
        _selectedYears = years.toSet();
        _selectedYearFilter = PolylineYearFilter.all;
        break;
      case 1:
        _selectedYearFilter = PolylineYearFilter.past;
        break;
      case 2:
        _selectedYearFilter = PolylineYearFilter.future;
        break;
      case 3:
        _selectedYearFilter = PolylineYearFilter.years;
        _selectedYears = subSelection
            .asMap()
            .entries
            .where((e) => e.value)
            .map((e) => years[e.key])
            .toSet();
        // Entering explicit "years" mode starts with every available range
        // selected, so include the unknown past/future ranges when present.
        if (_hasUnknownPast) _selectedYears.add(unknownPast.year);
        if (_hasUnknownFuture) _selectedYears.add(unknownFuture.year);
        break;
    }

    _selectedYearFilterOption = topIndex;
    _reconcileFiltersWithTrips();
    await _persistFilters();
    _rebuildRenderedPolylines(notify: true);
  }

  Future<void> selectAllYears(List<int> years) async {
    _selectedYearFilter = PolylineYearFilter.years;
    _selectedYearFilterOption = 3;
    _selectedYears = {
      ...years,
      if (_hasUnknownPast) unknownPast.year,
      if (_hasUnknownFuture) unknownFuture.year,
    };

    await _persistFilters();
    _rebuildRenderedPolylines(notify: true);
  }

  /// Toggles a single year (or unknown-past/future sentinel year) in the
  /// explicit "years" filter, leaving every other selection untouched. Used by
  /// both the year chips and the unknown past/future buttons in the grid.
  Future<void> toggleYear(int year) async {
    _selectedYearFilter = PolylineYearFilter.years;
    _selectedYearFilterOption = 3;
    if (_selectedYears.contains(year)) {
      _selectedYears.remove(year);
    } else {
      _selectedYears.add(year);
    }

    await _persistFilters();
    _rebuildRenderedPolylines(notify: true);
  }

  Future<void> unselectAllYears() async {
    _selectedYearFilter = PolylineYearFilter.years;
    _selectedYearFilterOption = 3;
    _selectedYears = {};

    await _persistFilters();
    _rebuildRenderedPolylines(notify: true);
  }

  /// Restores the default filter state: all time ranges and every available
  /// vehicle type selected. Used by the "Reset" action in the filter sheet.
  Future<void> resetFilters() async {
    final trips = _trips;
    final availableTypes = trips?.vehicleTypes.toSet() ?? <VehicleType>{};

    _selectedYearFilter = PolylineYearFilter.all;
    _selectedYearFilterOption = 0;
    _selectedYears = availableYears.toSet();

    _userDeselectedTypes.clear();
    _selectedTypes = availableTypes;

    _reconcileFiltersWithTrips();
    await _persistFilters();
    _rebuildRenderedPolylines(notify: true);
  }

  Future<void> selectAllVehicleTypes(List<VehicleType> types) async {
    _selectedTypes = types.toSet();
    _userDeselectedTypes.clear();

    await _persistFilters();
    _rebuildRenderedPolylines(notify: true);
  }

  Future<void> unselectAllVehicleTypes(List<VehicleType> types) async {
    _selectedTypes = {};
    _userDeselectedTypes = types.toSet();

    await _persistFilters();
    _rebuildRenderedPolylines(notify: true);
  }

  // ============================================================================
  // Trip sync / loading
  // ============================================================================

  void _syncWithTrips() {
    final trips = _trips;
    if (trips == null) return;

    if (trips.isLoading || trips.repository == null) {
      // Trips finished loading but failed (no repository) – nothing to show.
      if (!trips.isLoading && _isLoading) {
        _isLoading = false;
        notifyListeners();
      }
      return;
    }

    final newRevision = trips.polylineRevision;

    // First load
    if (_polylines.isEmpty) {
      final ignoreCache =
          (_lastTripsPolylineRevision != -1 && newRevision != _lastTripsPolylineRevision);

      unawaited(reload(ignoreCache: ignoreCache));
      _lastTripsPolylineRevision = newRevision;
      return;
    }

    // Later reloads
    if (newRevision != _lastTripsPolylineRevision) {
      _lastTripsPolylineRevision = newRevision;
      unawaited(reload(ignoreCache: true));
    }
  }

  /// Rebuild the full source polyline list.
  ///
  /// ignoreCache = true:
  ///   Skip file cache and decode from DB.
  Future<void> reload({required bool ignoreCache}) async {
    final trips = _trips;
    final settings = _settings;
    if (trips == null || settings == null) return;

    final repo = trips.repository;
    if (repo == null) return;

    final myToken = ++_loadToken;

    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final palette = MapColorPaletteHelper.getPalette(settings.mapColorPalette);

      // -----------------------------------------------------------------------
      // 1) Try file cache first
      // -----------------------------------------------------------------------
      if (!ignoreCache) {
        try {
          final decoded = await PolylineCache.read();
          if (decoded != null) {
            if (myToken != _loadToken) return;

            _polylines = PolylineStyling.restyleAll(decoded, palette, _nowUtc);
            _reconcileFiltersWithTrips();
            _rebuildRenderedPolylines(notify: false);

            debugPrint('✅ Loaded ${_polylines.length} polylines from cache');

            _isLoading = false;
            _scheduleNextFlip();
            notifyListeners();

            // Run integrity check asynchronously: the cache may be stale or
            // incomplete if a trip was added/updated without flushing the cache.
            unawaited(_checkAndFixMissingPolylines(myToken));
            return;
          }
        } catch (e) {
          debugPrint('Polyline cache read failed: $e');
        }
      }

      // -----------------------------------------------------------------------
      // 2) Fall back to DB
      // -----------------------------------------------------------------------
      final decoded = await PolylineLoader.loadFromDb(repo, palette);

      if (myToken != _loadToken) return;

      final styled = PolylineStyling.restyleAll(decoded, palette, _nowUtc);
      _polylines = styled;
      _reconcileFiltersWithTrips();
      _rebuildRenderedPolylines(notify: false);

      debugPrint('✅ Loaded ${_polylines.length} polylines from DB');

      _isLoading = false;
      _scheduleNextFlip();
      notifyListeners();

      if (styled.isNotEmpty) {
        unawaited(PolylineCache.write(styled));
      }

      // Even after a DB load, some entries may have been silently dropped due
      // to decode errors.  Verify completeness and patch any gaps.
      unawaited(_checkAndFixMissingPolylines(myToken));
    } catch (e) {
      if (myToken != _loadToken) return;

      _isLoading = false;
      _error = e;
      notifyListeners();
    }
  }

  // ============================================================================
  // Polyline integrity check
  // ============================================================================
  //
  // In rare cases a trip with a path in the DB may not have a corresponding
  // PolylineEntry in [_polylines] — e.g. after loading from a stale file cache,
  // after a silent decode error, or when an incremental trip refresh only
  // updated a subset of trips.
  //
  // This method compares the set of trip IDs that have a path in the DB with
  // the set of IDs currently loaded in [_polylines].  Any mismatch is repaired
  // by fetching and decoding only the missing entries.
  //
  // The [loadToken] argument prevents stale results from being applied if a
  // newer reload starts while this check is still in progress.
  // ============================================================================

  Future<void> _checkAndFixMissingPolylines(int loadToken) async {
    final trips = _trips;
    final settings = _settings;
    if (trips == null || settings == null) return;

    final repo = trips.repository;
    if (repo == null) return;

    try {
      final palette = MapColorPaletteHelper.getPalette(settings.mapColorPalette);
      final loadedIds = _polylines.map((e) => e.tripId).toSet();

      // Fetch + decode only the trips missing from the in-memory list.
      final decoded = await PolylineLoader.loadMissing(repo, loadedIds, palette);

      if (decoded.isEmpty) return;
      if (_loadToken != loadToken) return; // Check after the heavy compute step.

      debugPrint(
        '⚠️ Polyline integrity: ${decoded.length} trip(s) have a path in the DB '
        'but no polyline loaded — recovering...',
      );

      final styled = PolylineStyling.restyleAll(decoded, palette, _nowUtc);

      for (final entry in styled) {
        final index = _polylines.indexWhere((e) => e.tripId == entry.tripId);
        if (index >= 0) {
          _polylines[index] = entry;
        } else {
          _polylines.add(entry);
        }
      }

      debugPrint('✅ Polyline integrity: recovered ${styled.length} missing polyline(s)');

      _reconcileFiltersWithTrips();
      _rebuildRenderedPolylines(notify: true);

      // Flush the now-complete polyline list to the cache.
      if (_polylines.isNotEmpty) {
        unawaited(PolylineCache.write(_polylines));
      }
    } catch (e) {
      debugPrint('⚠️ Polyline integrity check failed: $e');
    }
  }

  // ============================================================================
  // Direct polyline mutations
  // ============================================================================
  //
  // These methods are useful when only a few trips changed and we do not want
  // a full reload from the database.
  // ============================================================================

  void upsertPolyline(PolylineEntry entry) {
    final index = _polylines.indexWhere((e) => e.tripId == entry.tripId);

    if (index >= 0) {
      _polylines[index] = entry;
    } else {
      _polylines.add(entry);
    }

    _reconcileFiltersWithTrips();
    _rebuildRenderedPolylines(notify: true);
  }

  void upsertPolylineFromTrip(Trips trip, {List<LatLng>? path}) {
    final settings = _settings;
    if (settings == null) return;

    final palette = MapColorPaletteHelper.getPalette(settings.mapColorPalette);
    final polyline = PolylineStyling.createPolyline(path, trip, palette);
    final entry = PolylineStyling.createPolylineEntry(polyline, trip);

    final index = _polylines.indexWhere((e) => e.tripId == int.parse(trip.uid));
    if (index >= 0) {
      _polylines[index] = entry;
    } else {
      _polylines.add(entry);
    }

    _reconcileFiltersWithTrips();
    _rebuildRenderedPolylines(notify: true);
    unawaited(saveToCache());
  }

  void upsertPolylinesFromTrips(List<Trips> trips, {List<List<LatLng>>? paths}) {
    final settings = _settings;
    if (settings == null) return;

    if (paths != null && trips.length != paths.length) {
      throw Exception('Trip and path length different');
    }

    final palette = MapColorPaletteHelper.getPalette(settings.mapColorPalette);

    for (int i = 0; i < trips.length; i++) {
      final trip = trips[i];
      final path = paths?[i];

      final polyline = PolylineStyling.createPolyline(path, trip, palette);
      final entry = PolylineStyling.createPolylineEntry(polyline, trip);

      final index = _polylines.indexWhere((e) => e.tripId == int.parse(trip.uid));
      if (index >= 0) {
        _polylines[index] = entry;
      } else {
        _polylines.add(entry);
      }
    }

    _reconcileFiltersWithTrips();
    _rebuildRenderedPolylines(notify: true);
    unawaited(saveToCache());
  }

  void removePolylineByTripId(int tripId) {
    debugPrint('Removing polyline for tripId $tripId');
    _polylines.removeWhere((e) => e.tripId == tripId);

    _reconcileFiltersWithTrips();
    _rebuildRenderedPolylines(notify: true);
  }

  // ============================================================================
  // Render pipeline
  // ============================================================================
  //
  // Source entries -> filtered entries -> sorted entries -> UI polylines.
  // The actual filtering / sorting / styling lives in [PolylineStyling]; this
  // method just feeds it the current provider state.
  // ============================================================================

  void _rebuildRenderedPolylines({required bool notify}) {
    final settings = _settings;
    if (settings == null) return;

    final now = _nowUtc;

    // Refresh whether unknown past/future trips exist so the filter UI can
    // show/hide their dedicated buttons in step with the loaded data.
    _hasUnknownPast =
        _polylines.any((e) => e.startDate?.year == unknownPast.year);
    _hasUnknownFuture =
        _polylines.any((e) => e.startDate?.year == unknownFuture.year);

    final filtered = PolylineStyling.filterBySelection(
      _polylines,
      yearFilter: _selectedYearFilter,
      selectedTypes: _selectedTypes,
      selectedYears: _selectedYears,
      availableYears: availableYears,
      nowUtc: now,
    );
    PolylineStyling.sortInPlace(filtered, settings.pathDisplayOrder);
    _visibleTripCount = filtered.length;
    _renderedPolylines = PolylineStyling.toRenderPolylines(filtered, now);
    _renderRevision++;

    // Reschedule the temporal flip so trips added/removed/restyled since the
    // last schedule still get their ongoing/future transitions on time.
    _scheduleNextFlip();

    if (notify) {
      notifyListeners();
    }
  }

  // ============================================================================
  // Temporal styling
  // ============================================================================
  //
  // Re-applies base styling when a trip crosses an ongoing/future boundary and
  // schedules the next such boundary so the map updates without a reload.
  // ============================================================================

  void _refreshTemporalStyles() {
    final settings = _settings;
    if (settings == null) return;

    final palette = MapColorPaletteHelper.getPalette(settings.mapColorPalette);
    final now = _nowUtc;

    // Recompute every entry's base styling for the current instant. This runs
    // only when the flip timer fires (i.e. at an ongoing/future boundary), so
    // restyling unconditionally is cheap and avoids fragile change-detection
    // that could leave a finished trip stuck red.
    _polylines = PolylineStyling.restyleAll(_polylines, palette, now);
    _rebuildRenderedPolylines(notify: true);
  }

  void _scheduleNextFlip() {
    _futureFlipTimer?.cancel();

    final now = _nowUtc;
    DateTime? nextEdge;

    for (final e in _polylines) {
      final start = e.utcStartDate;
      if (start != null && start.isAfter(now)) {
        if (nextEdge == null || start.isBefore(nextEdge)) {
          nextEdge = start;
        }
      }

      if (e.hasTimeRange) {
        final end = e.utcEndDate;
        // The trip stays ongoing (red) until end + grace, so schedule the
        // un-redden flip at that moment — not at the bare end — otherwise the
        // transition is missed and the polyline stays red.
        final endEdge = end?.add(PolylineStyling.ongoingEndGrace);
        if (endEdge != null && endEdge.isAfter(now)) {
          if (nextEdge == null || endEdge.isBefore(nextEdge)) {
            nextEdge = endEdge;
          }
        }
      }
    }

    if (nextEdge == null) return;

    var delay = nextEdge.difference(now) + const Duration(milliseconds: 50);
    if (delay.isNegative) {
      delay = const Duration(milliseconds: 50);
    }

    _futureFlipTimer = Timer(delay, () {
      _refreshTemporalStyles();
      _scheduleNextFlip();
    });
  }

  // ============================================================================
  // Cache persistence
  // ============================================================================

  Future<void> saveToCache() async {
    if (_polylines.isEmpty) {
      debugPrint('⚠️ No polylines to cache');
      return;
    }

    await PolylineCache.write(_polylines);
    debugPrint('💾 Saved ${_polylines.length} polylines to cache');
  }

  // ============================================================================
  // Listeners
  // ============================================================================

  void _onTripsChanged() {
    final trips = _trips;
    if (trips == null) return;

    // Consume both signals up front (the getters clear themselves on read).
    final deleted = trips.deletedTripIds;
    final partialUpdate = trips.modificatedTrips;
    debugPrint('Trips changed (upserts=${partialUpdate?.length ?? -1}, deletes=${deleted?.length ?? 0})');

    // Drop polylines for trips removed server-side. Done first so any rebuild
    // below already reflects the removals.
    if (deleted != null && deleted.isNotEmpty) {
      final removeSet = deleted.toSet();
      _polylines.removeWhere((e) => removeSet.contains(e.tripId));
    }

    if (partialUpdate != null) {
      // upsertPolylinesFromTrips reconciles filters, rebuilds and persists.
      upsertPolylinesFromTrips(partialUpdate);
      _lastTripsPolylineRevision = trips.polylineRevision;

      // An incremental refresh only updates modified trips, so a polyline that
      // was missing before the refresh will still be absent.  Run the integrity
      // check to catch and recover any such gaps.
      unawaited(_checkAndFixMissingPolylines(_loadToken));
      return;
    }

    if (deleted != null && deleted.isNotEmpty) {
      // Deletions only: reconcile, rebuild and flush the (possibly smaller)
      // list to the cache — write directly so an emptied list is persisted too.
      _reconcileFiltersWithTrips();
      _rebuildRenderedPolylines(notify: true);
      _lastTripsPolylineRevision = trips.polylineRevision;
      unawaited(PolylineCache.write(_polylines));
      return;
    }

    _syncWithTrips();
  }

  void _onSettingsChanged() {
    final settings = _settings;
    if (settings == null) return;

    final palette = MapColorPaletteHelper.getPalette(settings.mapColorPalette);

    // Reapply palette / temporal base styling.
    _polylines = PolylineStyling.restyleAll(_polylines, palette, _nowUtc);

    // Re-import persisted filter state in case it was changed elsewhere.
    _selectedYearFilter = settings.mapPolylineYearFilter;
    _selectedYears = {...settings.mapPolylineSelectedYears};
    _userDeselectedTypes = {...settings.mapPolylineDeselectedTypes};
    _selectedYearFilterOption = settings.mapPolylineYearFilterOption;

    _reconcileFiltersWithTrips();
    _rebuildRenderedPolylines(notify: false);
    notifyListeners();
  }

  // ============================================================================
  // Disposal
  // ============================================================================

  @override
  void dispose() {
    _futureFlipTimer?.cancel();
    _settings?.removeListener(_onSettingsChanged);
    _trips?.removeListener(_onTripsChanged);
    super.dispose();
  }
}