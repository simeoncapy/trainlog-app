import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:geolocator/geolocator.dart';
import 'package:latlong2/latlong.dart';
import 'package:provider/provider.dart';

import 'package:trainlog_app/data/models/trips.dart';
import 'package:trainlog_app/l10n/app_localizations.dart';
import 'package:trainlog_app/providers/settings_provider.dart';
import 'package:trainlog_app/providers/trips_provider.dart';
import 'package:trainlog_app/utils/cached_data_utils.dart';
import 'package:trainlog_app/utils/map_color_palette.dart';
import 'package:trainlog_app/utils/polyline_utils.dart';
import 'package:trainlog_app/widgets/dropdown_radio_list.dart';
import 'package:trainlog_app/widgets/trip_details_bottom_sheet.dart';
import 'package:trainlog_app/widgets/vehicle_type_filter_chips.dart';

enum YearFilter { all, past, future, years }

class MapPage extends StatefulWidget {
  final void Function(FloatingActionButton? fab) onFabReady;

  const MapPage({super.key, required this.onFabReady});

  @override
  State<MapPage> createState() => _MapPageState();
}

class _MapPageState extends State<MapPage> with WidgetsBindingObserver {
  // --- Map state
  final MapController _mapController = MapController();
  static const LatLng _greenwich = LatLng(51.476852, -0.0005);
  LatLng _center = _greenwich;
  double _zoom = 13.0;
  LatLng? _userPosition;
  final LayerHitNotifier<int> hitNotifier = ValueNotifier(null);

  // --- Data/state
  List<PolylineEntry> _polylines = [];
  bool _loading = true;
  late Map<VehicleType, Color> _colours;

  Set<int> _selectedYears = {};
  YearFilter _selectedYearFilter = YearFilter.all;
  Set<VehicleType> _selectedTypes = {};
  bool _showFilterModal = false;
  int _selectedYearFilterOption = 0;

  late TripsProvider _trips;

  // --- Future/ongoing flip timer
  Timer? _futureFlipTimer;

  // --- Rendering constants
  static const double _dashLen = 20.0;
  static const double _gapLen  = 20.0;
  static const Color  _futureDashColor = Colors.white;
  static const Color  _ongoingColor = Colors.red;

  // --- Utilities --------------------------------------------------------------
  DateTime get _nowUtc => DateTime.now().toUtc();

  bool _isFutureUtc(DateTime? utcStart) =>
      utcStart != null && utcStart.isAfter(_nowUtc);

  bool _isOngoing(PolylineEntry e) {
    if (!e.hasTimeRange) return false; // apply only when times exist
    final s = e.utcStartDate;
    final en = e.utcEndDate;
    if (s == null || en == null) return false;
    final now = _nowUtc;
    final started  = !now.isBefore(s); // now >= s
    final notEnded = !now.isAfter(en); // now <= en
    return started && notEnded;
  }

  PolylineEntry _restyleEntry(PolylineEntry e, {Map<VehicleType, Color>? palette}) {
    final ongoing = _isOngoing(e);
    final isFuture = !ongoing && _isFutureUtc(e.utcStartDate);
    final baseColor = ongoing
        ? _ongoingColor
        : (palette ?? _colours)[e.type] ?? e.polyline.color;

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

  List<PolylineEntry> _restyleAll(List<PolylineEntry> list, {Map<VehicleType, Color>? palette}) =>
      list.map((e) => _restyleEntry(e, palette: palette)).toList();

  void _applyLoaded(List<PolylineEntry> entries, Set<int> years, Set<VehicleType> types) {
    if (!mounted) return;
    setState(() {
      _polylines = entries;
      _loading = false;
      _selectedYears = years;
      _selectedTypes = types;
    });
    widget.onFabReady(buildFloatingActionButton(context)!);
    _scheduleNextFlip();
  }

  void _scheduleNextFlip() {
    _futureFlipTimer?.cancel();

    final now = _nowUtc;
    DateTime? nextEdge;

    for (final e in _polylines) {
      // future->ongoing at start
      final s = e.utcStartDate;
      if (s != null && s.isAfter(now)) {
        if (nextEdge == null || s.isBefore(nextEdge!)) nextEdge = s;
      }
      // ongoing->past at end (only if we have a time range)
      if (e.hasTimeRange) {
        final en = e.utcEndDate;
        if (en != null && en.isAfter(now)) {
          if (nextEdge == null || en.isBefore(nextEdge!)) nextEdge = en;
        }
      }
    }
    if (nextEdge == null) return;

    var delay = nextEdge!.difference(now) + const Duration(milliseconds: 50);
    if (delay.isNegative) delay = const Duration(milliseconds: 50);

    _futureFlipTimer = Timer(delay, () {
      _refreshTemporalStyles(force: true);
      _scheduleNextFlip();
    });
  }

  void _refreshTemporalStyles({bool force = false}) {
    bool changed = false;
    final updated = _polylines.map((e) {
      final newOngoing = _isOngoing(e);
      final newIsFuture = !newOngoing && _isFutureUtc(e.utcStartDate);
      if (force || newIsFuture != e.isFuture || (newOngoing && e.polyline.color != _ongoingColor)) {
        changed = true;
        return _restyleEntry(e);
      }
      return e;
    }).toList();

    if (changed && mounted) setState(() => _polylines = updated);
  }

  // --- Lifecycle --------------------------------------------------------------
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);

    final settings = context.read<SettingsProvider>();
    _colours = MapColorPaletteHelper.getPalette(settings.mapColorPalette);

    _initCenterAndMarker(settings);

    _trips = context.read<TripsProvider>();
    _trips.addListener(_onTripsChanged);

    if (!_trips.isLoading && _trips.repository != null) {
      _loadPolylines();
    }

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) setState(() {});
    });
  }

  @override
  void dispose() {
    _futureFlipTimer?.cancel();
    WidgetsBinding.instance.removeObserver(this);
    _trips.removeListener(_onTripsChanged);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      _refreshTemporalStyles(force: true);
      _scheduleNextFlip();
    }
  }

  // --- Location ---------------------------------------------------------------
  Future<void> _initCenterAndMarker(SettingsProvider settings) async {
    final saved = settings.userPosition;
    if (mounted) setState(() => _center = saved ?? _greenwich);

    final current = await _maybeUseLocationWithSystemPrompt(settings);
    if (current != null && mounted) {
      setState(() {
        _userPosition = current;
        _center = current;
      });
      settings.setLastUserPosition(current);
    }
  }

  Future<LatLng?> _maybeUseLocationWithSystemPrompt(SettingsProvider settings) async {
    var p = await Geolocator.checkPermission();
    if (p == LocationPermission.always || p == LocationPermission.whileInUse) {
      if (settings.refusedToSharePosition) settings.setRefusedToSharePosition(false);
      return _safeGetPositionOrNull();
    }

    if (settings.refusedToSharePosition) return null;

    final canShowSystemPrompt =
        kIsWeb || Platform.isAndroid || Platform.isIOS || Platform.isMacOS;
    if (!canShowSystemPrompt) return null;

    p = await Geolocator.requestPermission();
    if (p == LocationPermission.always || p == LocationPermission.whileInUse) {
      return _safeGetPositionOrNull();
    }

    settings.setRefusedToSharePosition(true);
    return null;
  }

  Future<LatLng?> _safeGetPositionOrNull() async {
    if (!await Geolocator.isLocationServiceEnabled()) return null;
    final pos = await Geolocator.getCurrentPosition(locationSettings: _platformLocationSettings());
    return LatLng(pos.latitude, pos.longitude);
  }

  LocationSettings _platformLocationSettings() {
    if (kIsWeb) {
      return WebSettings(accuracy: LocationAccuracy.high, distanceFilter: 0);
    }
    if (Platform.isAndroid) {
      return AndroidSettings(accuracy: LocationAccuracy.high, distanceFilter: 0);
    }
    if (Platform.isIOS || Platform.isMacOS) {
      return AppleSettings(accuracy: LocationAccuracy.high, distanceFilter: 0);
    }
    return const LocationSettings(accuracy: LocationAccuracy.high, distanceFilter: 0);
  }

  // --- Trips provider hook ----------------------------------------------------
  void _onTripsChanged() {
    if (!_trips.isLoading && _trips.repository != null) {
      _loadPolylines();
    } else {
      _refreshTemporalStyles();
      _scheduleNextFlip();
    }
  }

  // --- Load & cache -----------------------------------------------------------
  Future<void> _loadPolylines() async {
    final repo = context.read<TripsProvider>().repository;
    final settings = context.read<SettingsProvider>();
    final cacheFile = File(AppCacheFilePath.polylines);
    final years = _trips.years.toSet();
    final types = _trips.vehicleTypes.toSet();

    // 1) Try cache
    if (!settings.shouldReloadPolylines && await cacheFile.exists()) {
      try {
        final cachedJson = await cacheFile.readAsString();
        final decoded = (json.decode(cachedJson) as List<dynamic>)
            .map((e) => PolylineEntry.fromJson(e as Map<String, dynamic>))
            .toList();

        final restyled = _restyleAll(decoded);
        _applyLoaded(restyled, years, types);
        return;
      } catch (e) {
        debugPrint('Failed to load cache: $e');
      }
    }

    // 2) Load from DB
    if (repo == null) return;

    final pathData = await repo.getPathExtendedData(context.read<SettingsProvider>().pathDisplayOrder);
    final decoded = await compute(
      decodePolylinesBatch,
      {'entries': pathData, 'colors': _colours},
    );
    final restyled = _restyleAll(decoded);
    _applyLoaded(restyled, years, types);

    // Persist cache (fire-and-forget)
    if (restyled.isNotEmpty) {
      unawaited(_writeCache(restyled, settings));
    }
  }

  Future<void> _writeCache(List<PolylineEntry> list, SettingsProvider settings) async {
    try {
      final encoded = json.encode(list.map((e) => e.toJson()).toList());
      final cf = File(AppCacheFilePath.polylines);
      await cf.writeAsString(encoded);
      settings.setShouldReloadPolylines(false);
    } catch (e) {
      debugPrint('Failed to write cache: $e');
    }
  }

  // --- Filtering / sorting / rendering ---------------------------------------
  List<PolylineEntry> _filterBySelection(List<PolylineEntry> polylines) {
    switch (_selectedYearFilter) {
      case YearFilter.past:
        final now = _nowUtc;
        return polylines.where((e) =>
          (e.utcStartDate?.isBefore(now) ?? false) &&
          (_selectedTypes.isEmpty || _selectedTypes.contains(e.type))
        ).toList();

      case YearFilter.future:
        final now = _nowUtc;
        return polylines.where((e) =>
          (e.utcStartDate?.isAfter(now) ?? false) &&
          (_selectedTypes.isEmpty || _selectedTypes.contains(e.type))
        ).toList();

      case YearFilter.all:
      case YearFilter.years:
        return polylines.where((e) =>
          (_selectedYears.isEmpty || _selectedYears.contains(e.startDate?.year)) &&
          (_selectedTypes.isEmpty || _selectedTypes.contains(e.type))
        ).toList();
    }
  }

  void _sortInPlace(List<PolylineEntry> list, PathDisplayOrder order) {
    switch (order) {
      case PathDisplayOrder.creationDate:
        list.sort((a, b) =>
            (a.creationDate ?? DateTime(0)).compareTo(b.creationDate ?? DateTime(0)));
        break;
      case PathDisplayOrder.tripDate:
        list.sort((a, b) =>
            (a.startDate ?? DateTime(0)).compareTo(b.startDate ?? DateTime(0)));
        break;
      case PathDisplayOrder.tripDatePlaneOver:
        final nonAir = list
            .where((e) =>
                e.type != VehicleType.plane &&
                e.type != VehicleType.helicopter) // exclude both
            .toList()
          ..sort((a, b) =>
              (a.startDate ?? DateTime(0)).compareTo(b.startDate ?? DateTime(0)));

        final air = list
            .where((e) =>
                e.type == VehicleType.plane || e.type == VehicleType.helicopter) // include both
            .toList()
          ..sort((a, b) =>
              (a.creationDate ?? DateTime(0)).compareTo(b.creationDate ?? DateTime(0)));

        list
          ..clear()
          ..addAll(nonAir)
          ..addAll(air);
        break;
    }
  }

  /// Past: single base polyline.
  /// Future: base + dashed overlay (white).
  /// Ongoing: base painted red (no overlay).
  List<Polyline<int>> _toRenderPolylines(List<PolylineEntry> entries) {
    return entries.expand((e) {
      final base = Polyline<int>(
        points: e.polyline.points,
        color: e.polyline.color,
        strokeWidth: e.polyline.strokeWidth,
        borderColor: e.polyline.borderColor,
        borderStrokeWidth: e.polyline.borderStrokeWidth,
        pattern: e.polyline.pattern,
        hitValue: e.tripId, // assign the trip ID as hitValue to detect on touch
      );

      // Ongoing: base already red; no overlay
      if (_isOngoing(e)) return [base];

      // Future: overlay dashed white
      if (e.isFuture) {
        final overlay = Polyline<int>(
          points: e.polyline.points,
          color: _futureDashColor,
          strokeWidth: e.polyline.strokeWidth,
          pattern: StrokePattern.dashed(
            segments: const [_dashLen, _gapLen],
          ),
          hitValue: e.tripId,
        );
        return [base, overlay];
      }

      // Past
      return [base];
    }).toList();
  }

  // --- UI --------------------------------------------------------------------
  @override
  Widget build(BuildContext context) {
    final appLocalizations = AppLocalizations.of(context)!;
    final settings = context.watch<SettingsProvider>();
    final displayOrder = settings.pathDisplayOrder;
    final repo = context.read<TripsProvider>().repository;

    // Palette change: restyle and re-arm timer
    final newPalette = MapColorPaletteHelper.getPalette(settings.mapColorPalette);
    if (newPalette != _colours) {
      _colours = newPalette;
      setState(() => _polylines = _restyleAll(_polylines, palette: _colours));
      _scheduleNextFlip();
    }

    if (_loading) {
      return Center(
        child: Stack(
          alignment: Alignment.center,
          children: [
            const CircularProgressIndicator(),
            const SizedBox(height: 16),
            Text(appLocalizations.tripPathLoading,
                style: const TextStyle(fontWeight: FontWeight.bold)),
          ],
        ),
      );
    }

    final filtered = _filterBySelection(_polylines);
    _sortInPlace(filtered, displayOrder);
    final toDraw = _toRenderPolylines(filtered);

    return Stack(
      children: [
        FlutterMap(
          mapController: _mapController,
          options: MapOptions(
            initialCenter: _center,
            initialZoom: _zoom,
            keepAlive: true,
            onPositionChanged: (pos, hasGesture) {
              if (hasGesture) {
                setState(() {
                  _center = pos.center;
                  _zoom = pos.zoom;
                });
              }
            },
          ),
          children: [
            TileLayer(
              urlTemplate: "https://tile.openstreetmap.org/{z}/{x}/{y}.png",
              userAgentPackageName: 'me.trainlog.app',
            ),
            //PolylineLayer<int>(polylines: toDraw),
            GestureDetector(
              onTapUp: (details) async {
                final LayerHitResult<int>? result = hitNotifier.value;
                if (result == null) return;

                for (final hit in result.hitValues) {
                  //debugPrint('👆 Tapped polyline with tripId $hit');
                  final tappedEntry = await repo?.getTripById(hit);

                  if (tappedEntry != null) {
                    showModalBottomSheet(
                      context: context,
                      isScrollControlled: true,
                      builder: (_) => TripDetailsBottomSheet(trip: tappedEntry),
                    );
                    break;
                  }
                }
                //debugPrint('📍 Touch at map coordinate: ${result.coordinate}');
              },
              child: PolylineLayer<int>(
                hitNotifier: hitNotifier, // 👈 Enable tap hit detection
                polylines: toDraw,
              ),
            ),
            if (_userPosition != null && settings.mapDisplayUserLocationMarker)
              MarkerLayer(
                markers: [
                  Marker(
                    width: 40,
                    height: 40,
                    point: _userPosition!,
                    child: const Icon(Icons.my_location, size: 28, color: Colors.red),
                  ),
                ],
              ),
          ],
        ),
        if (_showFilterModal)
          Positioned(
            bottom: 16,
            left: 16,
            right: 16,
            child: Material(
              elevation: 4,
              borderRadius: BorderRadius.circular(16),
              color: Theme.of(context).cardColor,
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(appLocalizations.yearTitle,
                        style: Theme.of(context).textTheme.titleLarge),
                    const SizedBox(height: 8),
                    _yearFilterBuilder(context.watch<TripsProvider>().years),
                    const SizedBox(height: 16),
                    Text(appLocalizations.typeTitle,
                        style: Theme.of(context).textTheme.titleLarge),
                    const SizedBox(height: 8),
                    VehicleTypeFilterChips(
                      availableTypes: context.watch<TripsProvider>().vehicleTypes,
                      selectedTypes: _selectedTypes,
                      onTypeToggle: (type, selected) {
                        setState(() {
                          selected ? _selectedTypes.add(type) : _selectedTypes.remove(type);
                        });
                      },
                    ),
                    const SizedBox(height: 16),
                    Align(
                      alignment: Alignment.centerRight,
                      child: ElevatedButton.icon(
                        onPressed: () {
                          setState(() {
                            _showFilterModal = false;
                            widget.onFabReady(buildFloatingActionButton(context)!);
                          });
                        },
                        icon: const Icon(Icons.close),
                        label: Text(MaterialLocalizations.of(context).closeButtonLabel),
                      ),
                    )
                  ],
                ),
              ),
            ),
          ),
      ],
    );
  }

  DropdownRadioList _yearFilterBuilder(List<int> years) {
    return DropdownRadioList(
      items: [
        MultiLevelItem(title: AppLocalizations.of(context)!.yearAllList, subItems: []),
        MultiLevelItem(title: AppLocalizations.of(context)!.yearPastList, subItems: []),
        MultiLevelItem(title: AppLocalizations.of(context)!.yearFutureList, subItems: []),
        MultiLevelItem(
          title: AppLocalizations.of(context)!.yearYearList,
          subItems: years.map((e) => e.toString()).toList(),
        ),
      ],
      selectedTopIndex: _selectedYearFilterOption,
      selectedSubStates: {3: years.map((y) => _selectedYears.contains(y)).toList()},
      onChanged: (top, sub) {
        setState(() {
          switch (top) {
            case 0: _selectedYears = years.toSet(); _selectedYearFilter = YearFilter.all; break;
            case 1: _selectedYearFilter = YearFilter.past;   break;
            case 2: _selectedYearFilter = YearFilter.future; break;
            case 3:
              _selectedYearFilter = YearFilter.years;
              _selectedYears = sub.asMap().entries.where((e) => e.value).map((e) => years[e.key]).toSet();
              break;
          }
          _selectedYearFilterOption = top;
        });
      },
    );
  }

  FloatingActionButton? buildFloatingActionButton(BuildContext context) {
    if (_showFilterModal) return null;
    return FloatingActionButton(
      onPressed: () {
        setState(() {
          _showFilterModal = true;
          widget.onFabReady(null);
        });
      },
      child: const Icon(Icons.filter_alt),
    );
  }
}
