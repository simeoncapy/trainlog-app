import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';

import 'package:trainlog_app/data/models/polyline_entry.dart';
import 'package:trainlog_app/data/models/trips.dart';
import 'package:trainlog_app/providers/settings_provider.dart';
import 'package:trainlog_app/providers/trips_provider.dart';
import 'package:trainlog_app/utils/cached_data_utils.dart';
import 'package:trainlog_app/utils/map_color_palette.dart';

import 'package:latlong2/latlong.dart';

class PolylineProvider extends ChangeNotifier {
  TripsProvider? _trips;
  SettingsProvider? _settings;

  List<PolylineEntry> _polylines = [];
  bool _isLoading = false;
  Object? _error;

  Timer? _futureFlipTimer;
  int _loadToken = 0;

  int _lastTripsPolylineRevision = -1;

  static const Color _ongoingColor = Colors.red;

  List<PolylineEntry> get polylines => _polylines;
  bool get isLoading => _isLoading;
  Object? get error => _error;

  DateTime get _nowUtc => DateTime.now().toUtc();

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

    // Trigger first load when repo becomes available.
    _syncWithTrips();
  }

  /// Call this anytime you want to ensure polylines exist (no-op if already loaded).
  Future<void> ensureLoaded() async {
    final trips = _trips;
    final settings = _settings;
    if (trips == null || settings == null) return;
    if (trips.repository == null || trips.isLoading) return;

    if (_isLoading) return;

    // If already loaded and no reload requested, keep it.
    if (_polylines.isNotEmpty /*&& !settings.shouldReloadPolylines*/) {
      _scheduleNextFlip();
      return;
    }

    await reload(ignoreCache: false);
  }

  void _syncWithTrips() {
    final trips = _trips;
    if (trips == null) return;

    if (trips.isLoading || trips.repository == null) return;
    final pr = trips.polylineRevision;

    // First load: allow cache
    if (_polylines.isEmpty) {
      final ignoreCache = (_lastTripsPolylineRevision != -1 && pr != _lastTripsPolylineRevision);
      unawaited(reload(ignoreCache: ignoreCache));
      _lastTripsPolylineRevision = pr;
      return;
    }

    // Subsequent: reload only if trips changed
    if (pr != _lastTripsPolylineRevision) {
      _lastTripsPolylineRevision = pr;
      unawaited(reload(ignoreCache: true));
    }
  }

  /// Force rebuild of polyline list.
  /// - ignoreCache=true: skip cache and go straight to DB
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

      // 1) Cache
      final cacheFile = File(AppCacheFilePath.polylines);
      if (!ignoreCache &&
          //!settings.shouldReloadPolylines &&
          await cacheFile.exists()) {
        try {
          final cachedJson = await cacheFile.readAsString();
          final decoded = (json.decode(cachedJson) as List<dynamic>)
              .map((e) => PolylineEntry.fromJson(e as Map<String, dynamic>))
              .toList();

          if (myToken != _loadToken) return;

          _polylines = _restyleAll(decoded, palette);
          debugPrint("✅ Loaded ${_polylines.length} polylines from cache");
          _isLoading = false;
          _scheduleNextFlip();
          notifyListeners();
          return;
        } catch (e) {
          debugPrint('Polyline cache read failed: $e');
        }
      }

      // 2) DB load
      // IMPORTANT: Always load in base order (creationDate) and let UI sort.
      final pathData = await repo.getPathExtendedData(PathDisplayOrder.creationDate);

      // isolate-friendly colors map: typeName -> ARGB int
      final colors = <String, int>{};
      for (final t in VehicleType.values) {
        colors[t.name] = (palette[t] ?? Colors.black).toARGB32();
      }

      // isolate-friendly entries: convert VehicleType -> String name
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
      debugPrint("✅ Loaded ${_polylines.length} polylines from DB");
      _isLoading = false;
      _scheduleNextFlip();
      notifyListeners();

      // Persist cache
      if (styled.isNotEmpty) {
        unawaited(_writeCache(styled, settings));
      }
    } catch (e) {
      if (myToken != _loadToken) return;
      _isLoading = false;
      _error = e;
      notifyListeners();
    }
  }

  /// Convenient API: call this after you add/remove trips in DB.
  Future<void> refreshFromDb() => reload(ignoreCache: true);

  void upsertPolyline(PolylineEntry entry) {
    final i = _polylines.indexWhere((e) => e.tripId == entry.tripId);
    if (i >= 0) {
      _polylines[i] = entry;
    } else {
      _polylines.add(entry);
    }
    notifyListeners();
  }

  void upsertPolylineFromTrip(Trips trip, List<LatLng>? path) {
    final settings = _settings;
    if (settings == null) return;
    final palette = MapColorPaletteHelper.getPalette(settings.mapColorPalette);    

    final polyline = PolylineTools.createPolyline(
      path ?? PolylineTools.decodePath(trip.path),
      palette[trip.vehicleType] ?? Colors.black,
    );

    final entry = PolylineEntry(
      polyline: polyline,
      type: trip.vehicleType,
      startDate: trip.startDate,
      creationDate: trip.creationDate,
      utcStartDate: trip.utcStartDate,
      utcEndDate: trip.utcEndDate,
      hasTimeRange: PolylineTools.hasClockPart(trip.startDate.toIso8601String()) && PolylineTools.hasClockPart(trip.endDate.toIso8601String()),
      isFuture: trip.utcStartDate != null && trip.utcStartDate!.isAfter(DateTime.now().toUtc()),
      tripId: int.parse(trip.uid),
    );

    final i = _polylines.indexWhere((e) => e.tripId == int.parse(trip.uid));
    if (i >= 0) {
      // Update existing
      _polylines[i] = entry;
    } else {
      _polylines.add(entry);
    }
    notifyListeners();
  }

  void removePolylineByTripId(int tripId) {
    _polylines.removeWhere((e) => e.tripId == tripId);
    notifyListeners();
  }

  // --- Styling / temporal -----------------------------------------------------

  bool _isFutureUtc(DateTime? utcStart) =>
      utcStart != null && utcStart.isAfter(_nowUtc);

  bool _isOngoing(PolylineEntry e) {
    if (!e.hasTimeRange) return false;
    final s = e.utcStartDate;
    final en = e.utcEndDate;
    if (s == null || en == null) return false;
    en.add(const Duration(minutes: 1)); // inclusive end
    final now = _nowUtc;
    return !now.isBefore(s) && !now.isAfter(en);
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

  List<PolylineEntry> _restyleAll(List<PolylineEntry> list, Map<VehicleType, Color> palette) =>
      list.map((e) => _restyleEntry(e, palette)).toList();

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
          (isFutureNow != e.isFuture) ||          // future <-> not future
          (ongoingNow && !wasRed) ||              // became ongoing => paint red
          (!ongoingNow && wasRed);                // ended ongoing => remove red ✅

      if (shouldRestyle) {
        changed = true;
        return _restyleEntry(e, palette);
      }
      return e;
    }).toList();

    if (changed) {
      _polylines = updated;
      notifyListeners();
    }
  }


  void _scheduleNextFlip() {
    _futureFlipTimer?.cancel();

    final now = _nowUtc;
    DateTime? nextEdge;

    for (final e in _polylines) {
      final s = e.utcStartDate;
      if (s != null && s.isAfter(now)) {
        if (nextEdge == null || s.isBefore(nextEdge)) nextEdge = s;
      }
      if (e.hasTimeRange) {
        final en = e.utcEndDate;
        if (en != null && en.isAfter(now)) {
          if (nextEdge == null || en.isBefore(nextEdge)) nextEdge = en;
        }
      }
    }

    if (nextEdge == null) return;

    var delay = nextEdge.difference(now) + const Duration(milliseconds: 50);
    if (delay.isNegative) delay = const Duration(milliseconds: 50);

    _futureFlipTimer = Timer(delay, () {
      _refreshTemporalStyles();
      _scheduleNextFlip();
    });
  }

  // --- Listeners --------------------------------------------------------------

  void _onTripsChanged() {
    _syncWithTrips();
  }

  void _onSettingsChanged() {
    final settings = _settings;
    if (settings == null) return;

    // Palette changed: restyle (cheap)
    final palette = MapColorPaletteHelper.getPalette(settings.mapColorPalette);
    _polylines = _restyleAll(_polylines, palette);
    notifyListeners();

    // Reload requested by app
    // if (settings.shouldReloadPolylines) {
    //   unawaited(reload(ignoreCache: true));
    // }
  }

  Future<void> _writeCache(List<PolylineEntry> list, SettingsProvider settings) async {
    try {
      final encoded = json.encode(list.map((e) => e.toJson()).toList());
      final cf = File(AppCacheFilePath.polylines);
      await cf.writeAsString(encoded);
      //settings.setShouldReloadPolylines(false);
    } catch (e) {
      debugPrint('Failed to write polyline cache: $e');
    }
  }

  @override
  void dispose() {
    _futureFlipTimer?.cancel();
    _settings?.removeListener(_onSettingsChanged);
    _trips?.removeListener(_onTripsChanged);
    super.dispose();
  }
}
