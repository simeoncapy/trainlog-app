import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';

import 'package:trainlog_app/data/models/polyline_entry.dart';
import 'package:trainlog_app/data/models/polyline_filter_state.dart';
import 'package:trainlog_app/data/models/trips.dart';
import 'package:trainlog_app/providers/settings_provider.dart';
import 'package:trainlog_app/providers/trips_provider.dart';
import 'package:trainlog_app/utils/cached_data_utils.dart';
import 'package:trainlog_app/utils/date_utils.dart';
import 'package:trainlog_app/utils/map_color_palette.dart';

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

  bool _isLoading = false;
  Object? _error;

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

  Set<VehicleType> _selectedTypes = {};
  Set<VehicleType> _userDeselectedTypes = {};
  Set<VehicleType> _lastAvailableTypes = {};

  bool _filtersLoadedFromSettings = false;

  // ============================================================================
  // Rendering constants
  // ============================================================================

  static const Color _ongoingColor = Colors.red;
  static const Color _futureDashColor = Colors.white;
  static const double _dashLen = 20.0;
  static const double _gapLen = 20.0;

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

  Set<int> get selectedYears => Set.unmodifiable(_selectedYears);
  PolylineYearFilter get selectedYearFilter => _selectedYearFilter;
  int get selectedYearFilterOption => _selectedYearFilterOption;

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
      // Only remove years that no longer exist.
      _selectedYears = _selectedYears.intersection(availableYears);
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
    _selectedYears = years.toSet();

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
    if (trips.isLoading || trips.repository == null) return;

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
      final cacheFile = File(AppCacheFilePath.polylines);
      if (!ignoreCache && await cacheFile.exists()) {
        try {
          final cachedJson = await cacheFile.readAsString();
          final decoded = (json.decode(cachedJson) as List<dynamic>)
              .map((e) => PolylineEntry.fromJson(e as Map<String, dynamic>))
              .toList();

          if (myToken != _loadToken) return;

          _polylines = _restyleAll(decoded, palette);
          _reconcileFiltersWithTrips();
          _rebuildRenderedPolylines(notify: false);

          debugPrint('✅ Loaded ${_polylines.length} polylines from cache');

          _isLoading = false;
          _scheduleNextFlip();
          notifyListeners();
          return;
        } catch (e) {
          debugPrint('Polyline cache read failed: $e');
        }
      }

      // -----------------------------------------------------------------------
      // 2) Fall back to DB
      // -----------------------------------------------------------------------
      final pathData = await repo.getPathExtendedData(PathDisplayOrder.creationDate);

      // Build isolate-friendly colour map.
      final colors = <String, int>{};
      for (final type in VehicleType.values) {
        colors[type.name] = (palette[type] ?? Colors.black).toARGB32();
      }

      // Convert entries to isolate-friendly format.
      final entries = pathData.map<Map<String, dynamic>>((raw) {
        final m = Map<String, dynamic>.from(raw);
        final typeVal = m['type'];

        if (typeVal is VehicleType) {
          m['type'] = typeVal.name;
        } else {
          m['type'] = typeVal?.toString() ?? '';
        }

        return m;
      }).toList();

      final decoded = await compute(
        PolylineTools.decodePolylinesBatchIsolateFriendly,
        {'entries': entries, 'colors': colors},
      );

      if (myToken != _loadToken) return;

      final styled = _restyleAll(decoded, palette);
      _polylines = styled;
      _reconcileFiltersWithTrips();
      _rebuildRenderedPolylines(notify: false);

      debugPrint('✅ Loaded ${_polylines.length} polylines from DB');

      _isLoading = false;
      _scheduleNextFlip();
      notifyListeners();

      if (styled.isNotEmpty) {
        unawaited(_writeCache(styled));
      }
    } catch (e) {
      if (myToken != _loadToken) return;

      _isLoading = false;
      _error = e;
      notifyListeners();
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
    final polyline = _createPolyline(path, trip, palette);
    final entry = _createPolylineEntry(polyline, trip);

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

      final polyline = _createPolyline(path, trip, palette);
      final entry = _createPolylineEntry(polyline, trip);

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
  // Polyline creation helpers
  // ============================================================================

  Polyline<Object> _createPolyline(
    List<LatLng>? path,
    Trips trip,
    Map<VehicleType, Color> palette,
  ) {
    return PolylineTools.createPolyline(
      path ?? trip.pathPoints ?? PolylineTools.decodePath(trip.path),
      palette[trip.vehicleType] ?? Colors.black,
    );
  }

  PolylineEntry _createPolylineEntry(Polyline<Object> polyline, Trips trip) {
    return PolylineEntry(
      polyline: polyline,
      type: trip.vehicleType,
      startDate: trip.startDate,
      creationDate: trip.creationDate,
      utcStartDate: trip.utcStartDate,
      utcEndDate: trip.utcEndDate,
      hasTimeRange: PolylineTools.hasClockPart(trip.startDate.toIso8601String()) &&
          PolylineTools.hasClockPart(trip.endDate.toIso8601String()),
      isFuture: trip.utcStartDate != null && trip.utcStartDate!.isAfter(DateTime.now().toUtc()),
      tripId: int.parse(trip.uid),
    );
  }

  // ============================================================================
  // Render pipeline
  // ============================================================================
  //
  // Source entries -> filtered entries -> sorted entries -> UI polylines
  // ============================================================================

  List<PolylineEntry> _filterBySelection(List<PolylineEntry> polylines) {
    switch (_selectedYearFilter) {
      case PolylineYearFilter.past:
        final now = _nowUtc;
        return polylines.where((e) {
          return (e.utcStartDate?.isBefore(now) ?? false) &&
              _selectedTypes.contains(e.type);
        }).toList();

      case PolylineYearFilter.future:
        final now = _nowUtc;
        return polylines.where((e) {
          return (e.utcStartDate?.isAfter(now) ?? false) &&
              _selectedTypes.contains(e.type);
        }).toList();

      case PolylineYearFilter.all:
        final allowedYears = {...availableYears, unknownPast.year, unknownFuture.year};
        return polylines.where((e) {
          return allowedYears.contains(e.startDate?.year) &&
              _selectedTypes.contains(e.type);
        }).toList();

      case PolylineYearFilter.years:
        final allowedYears = {..._selectedYears, unknownPast.year, unknownFuture.year};
        return polylines.where((e) {
          return allowedYears.contains(e.startDate?.year) &&
              _selectedTypes.contains(e.type);
        }).toList();
    }
  }

  void _sortInPlace(List<PolylineEntry> list, PathDisplayOrder order) {
    switch (order) {
      case PathDisplayOrder.creationDate:
        list.sort((a, b) {
          return (a.creationDate ?? DateTime(0))
              .compareTo(b.creationDate ?? DateTime(0));
        });
        break;

      case PathDisplayOrder.tripDate:
        list.sort((a, b) {
          return (a.startDate ?? DateTime(0))
              .compareTo(b.startDate ?? DateTime(0));
        });
        break;

      case PathDisplayOrder.tripDatePlaneOver:
        final nonAir = list
            .where((e) => e.type != VehicleType.plane && e.type != VehicleType.helicopter)
            .toList()
          ..sort((a, b) {
            return (a.startDate ?? DateTime(0))
                .compareTo(b.startDate ?? DateTime(0));
          });

        final air = list
            .where((e) => e.type == VehicleType.plane || e.type == VehicleType.helicopter)
            .toList()
          ..sort((a, b) {
            return (a.creationDate ?? DateTime(0))
                .compareTo(b.creationDate ?? DateTime(0));
          });

        list
          ..clear()
          ..addAll(nonAir)
          ..addAll(air);
        break;
    }
  }

  List<Polyline<int>> _toRenderPolylines(List<PolylineEntry> entries) {
    return entries.expand((e) {
      final base = Polyline<int>(
        points: e.polyline.points,
        color: e.polyline.color,
        strokeWidth: e.polyline.strokeWidth,
        borderColor: e.polyline.borderColor,
        borderStrokeWidth: e.polyline.borderStrokeWidth,
        pattern: e.polyline.pattern,
        hitValue: e.tripId,
      );

      if (_isOngoing(e)) return [base];

      final isFuture = !_isOngoing(e) && _isFutureUtc(e.utcStartDate);
      if (isFuture) {
        final overlay = Polyline<int>(
          points: e.polyline.points,
          color: _futureDashColor,
          strokeWidth: e.polyline.strokeWidth,
          pattern: StrokePattern.dashed(segments: const [_dashLen, _gapLen]),
          hitValue: e.tripId,
        );
        return [base, overlay];
      }

      return [base];
    }).toList();
  }

  void _rebuildRenderedPolylines({required bool notify}) {
    final settings = _settings;
    if (settings == null) return;

    final filtered = _filterBySelection(_polylines);
    _sortInPlace(filtered, settings.pathDisplayOrder);
    _renderedPolylines = _toRenderPolylines(filtered);
    _renderRevision++;

    if (notify) {
      notifyListeners();
    }
  }

  // ============================================================================
  // Temporal styling
  // ============================================================================
  //
  // This section handles:
  // - ongoing trip colouring
  // - future trip detection
  // - timer scheduling for style changes when time boundaries are crossed
  // ============================================================================

  bool _isFutureUtc(DateTime? utcStart) {
    return utcStart != null && utcStart.isAfter(_nowUtc);
  }

  bool _isOngoing(PolylineEntry e) {
    if (!e.hasTimeRange) return false;

    final start = e.utcStartDate;
    final end = e.utcEndDate;
    if (start == null || end == null) return false;

    final inclusiveEnd = end.add(const Duration(minutes: 1));
    final now = _nowUtc;

    return !now.isBefore(start) && !now.isAfter(inclusiveEnd);
  }

  PolylineEntry _restyleEntry(PolylineEntry e, Map<VehicleType, Color> palette) {
    final ongoing = _isOngoing(e);
    final isFuture = !ongoing && _isFutureUtc(e.utcStartDate);

    final baseColor = ongoing ? _ongoingColor : (palette[e.type] ?? e.polyline.color);

    final base = Polyline(
      points: e.polyline.points,
      color: baseColor,
      strokeWidth: e.polyline.strokeWidth,
      borderColor: Colors.black,
      borderStrokeWidth: 1.0,
      pattern: const StrokePattern.solid(),
    );

    return PolylineEntry(
      polyline: base,
      type: e.type,
      startDate: e.startDate,
      creationDate: e.creationDate,
      utcStartDate: e.utcStartDate,
      utcEndDate: e.utcEndDate,
      hasTimeRange: e.hasTimeRange,
      isFuture: isFuture,
      tripId: e.tripId,
    );
  }

  List<PolylineEntry> _restyleAll(
    List<PolylineEntry> list,
    Map<VehicleType, Color> palette,
  ) {
    return list.map((e) => _restyleEntry(e, palette)).toList();
  }

  void _refreshTemporalStyles() {
    final settings = _settings;
    if (settings == null) return;

    final palette = MapColorPaletteHelper.getPalette(settings.mapColorPalette);
    bool changed = false;

    final updated = _polylines.map((e) {
      final ongoingNow = _isOngoing(e);
      final isFutureNow = !ongoingNow && _isFutureUtc(e.utcStartDate);
      final wasRed = e.polyline.color == _ongoingColor;

      final shouldRestyle =
          (isFutureNow != e.isFuture) ||
          (ongoingNow && !wasRed) ||
          (!ongoingNow && wasRed);

      if (shouldRestyle) {
        changed = true;
        return _restyleEntry(e, palette);
      }

      return e;
    }).toList();

    if (!changed) return;

    _polylines = updated;
    _rebuildRenderedPolylines(notify: false);
    notifyListeners();
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
        if (end != null && end.isAfter(now)) {
          if (nextEdge == null || end.isBefore(nextEdge)) {
            nextEdge = end;
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

    await _writeCache(_polylines);
    debugPrint('💾 Saved ${_polylines.length} polylines to cache');
  }

  Future<void> _writeCache(List<PolylineEntry> list) async {
    try {
      final encoded = json.encode(list.map((e) => e.toJson()).toList());
      final cacheFile = File(AppCacheFilePath.polylines);
      await cacheFile.writeAsString(encoded);
    } catch (e) {
      debugPrint('Failed to write polyline cache: $e');
    }
  }

  // ============================================================================
  // Listeners
  // ============================================================================

  void _onTripsChanged() {
    final trips = _trips;
    if (trips == null) return;

    final partialUpdate = trips.modificatedTrips;
    debugPrint('Trips changed (${partialUpdate?.length ?? -1})');

    if (partialUpdate == null) {
      _syncWithTrips();
      return;
    }

    upsertPolylinesFromTrips(partialUpdate);
    _lastTripsPolylineRevision = trips.polylineRevision;
  }

  void _onSettingsChanged() {
    final settings = _settings;
    if (settings == null) return;

    final palette = MapColorPaletteHelper.getPalette(settings.mapColorPalette);

    // Reapply palette / temporal base styling.
    _polylines = _restyleAll(_polylines, palette);

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