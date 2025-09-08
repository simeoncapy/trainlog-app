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
import 'package:trainlog_app/widgets/vehicle_type_filter_chips.dart';

enum YearFilter { all, past, future, years }

class MapPage extends StatefulWidget {
  final void Function(FloatingActionButton? fab) onFabReady;

  const MapPage({super.key, required this.onFabReady});

  @override
  State<MapPage> createState() => _MapPageState();
}

class _MapPageState extends State<MapPage> with WidgetsBindingObserver {
  final MapController _mapController = MapController();
  Timer? _futureFlipTimer;

  // Default to Greenwich Observatory
  static const LatLng _greenwich = LatLng(51.476852, -0.0005);
  LatLng _center = _greenwich;
  double _zoom = 13.0;
  LatLng? _userPosition;

  List<PolylineEntry> _polylines = [];
  bool _loading = true;
  late Map<VehicleType, Color> _colours;

  Set<int> _selectedYears = {};
  YearFilter _selectedYearFilter = YearFilter.all;
  Set<VehicleType> _selectedTypes = {};
  bool _showFilterModal = false;
  int _selectedYearFilterOption = 0;

  late TripsProvider _trips;

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

    // Trigger FAB rebuild after first frame
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
      _refreshFutureStyles(force: true);
      _scheduleNextFlip();
    }
  }

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
      if (settings.refusedToSharePosition) {
        settings.setRefusedToSharePosition(false);
      }
      return await _safeGetPositionOrNull();
    }

    if (settings.refusedToSharePosition) return null;

    final canShowSystemPrompt =
        kIsWeb || Platform.isAndroid || Platform.isIOS || Platform.isMacOS;
    if (!canShowSystemPrompt) return null;

    p = await Geolocator.requestPermission();

    if (p == LocationPermission.always || p == LocationPermission.whileInUse) {
      return await _safeGetPositionOrNull();
    }

    settings.setRefusedToSharePosition(true);
    return null;
  }

  Future<LatLng?> _safeGetPositionOrNull() async {
    if (!await Geolocator.isLocationServiceEnabled()) return null;

    final pos = await Geolocator.getCurrentPosition(
      locationSettings: _platformLocationSettings(),
    );
    return LatLng(pos.latitude, pos.longitude);
  }

  LocationSettings _platformLocationSettings() {
    if (kIsWeb) {
      return WebSettings(
        accuracy: LocationAccuracy.high,
        distanceFilter: 0,
      );
    }
    if (Platform.isAndroid) {
      return AndroidSettings(
        accuracy: LocationAccuracy.high,
        distanceFilter: 0,
      );
    }
    if (Platform.isIOS || Platform.isMacOS) {
      return AppleSettings(
        accuracy: LocationAccuracy.high,
        distanceFilter: 0,
      );
    }
    return const LocationSettings(
      accuracy: LocationAccuracy.high,
      distanceFilter: 0,
    );
  }

  void _onTripsChanged() {
    if (!_trips.isLoading && _trips.repository != null) {
      _loadPolylines();
    } else {
      _refreshFutureStyles();
      _scheduleNextFlip();
    }
  }

  bool _computeIsFuture(DateTime? d) => d != null && d.isAfter(DateTime.now());

  Polyline _rebuildPolyline(Polyline src, {required bool isFuture, required Color color}) {
    // Build a fresh Polyline preserving geometry and width; enforce pattern & color
    return Polyline(
      points: src.points,
      color: color,
      pattern: isFuture ? StrokePattern.dashed(segments: const [20, 20]) : const StrokePattern.solid(),
      strokeWidth: src.strokeWidth,
    );
  }

  PolylineEntry _withStyle(PolylineEntry e, {Map<VehicleType, Color>? palette}) {
    final isFutureNow = _computeIsFuture(e.startDate);
    final color = (palette ?? _colours)[e.type] ?? e.polyline.color;

    return PolylineEntry(
      type: e.type,
      startDate: e.startDate,
      creationDate: e.creationDate,
      isFuture: isFutureNow,
      polyline: _rebuildPolyline(e.polyline, isFuture: isFutureNow, color: color),
    );
  }

  void _refreshFutureStyles({bool force = false}) {
    bool changed = false;
    final updated = _polylines.map((e) {
      final newIsFuture = _computeIsFuture(e.startDate);
      if (force || newIsFuture != e.isFuture) {
        changed = true;
        return _withStyle(e);
      }
      return e;
    }).toList();

    if (changed && mounted) {
      setState(() => _polylines = updated);
    }
  }

  void _scheduleNextFlip() {
    _futureFlipTimer?.cancel();

    final now = DateTime.now();
    DateTime? next;
    for (final e in _polylines) {
      final d = e.startDate;
      if (d != null && d.isAfter(now)) {
        if (next == null || d.isBefore(next!)) next = d;
      }
    }
    if (next == null) return;

    final delay = next!.difference(now) + const Duration(milliseconds: 50);
    _futureFlipTimer = Timer(delay, () {
      _refreshFutureStyles(force: true);
      _scheduleNextFlip();
    });
  }

  Future<void> _loadPolylines() async {
    final repo = context.read<TripsProvider>().repository;
    final settings = context.read<SettingsProvider>();
    final cacheFile = File(AppCacheFilePath.polylines);
    final years = _trips.years;
    final types = _trips.vehicleTypes;

    // Try loading from cache first
    if (!settings.shouldReloadPolylines && await cacheFile.exists()) {
      try {
        final cachedJson = await cacheFile.readAsString();
        final decoded = json.decode(cachedJson) as List<dynamic>;
        final cachedPolylines = decoded
            .map((e) => PolylineEntry.fromJson(e as Map<String, dynamic>))
            .toList();

        // Re-style from *now* and current palette; ignore cached isFuture/pattern
        final restyled = cachedPolylines.map((e) => _withStyle(e, palette: _colours)).toList();

        if (mounted) {
          setState(() {
            _polylines = restyled;
            _loading = false;
            _selectedYears = years.toSet();
            _selectedTypes = types.toSet();
          });
          widget.onFabReady(buildFloatingActionButton(context)!);
          debugPrint("Polylines loaded from cache");
        }

        _scheduleNextFlip();
        return;
      } catch (e) {
        debugPrint('Failed to load cache: $e');
      }
    }

    // Else, load from DB
    if (repo != null) {
      final pathData = await repo.getPathExtendedData(settings.pathDisplayOrder);

      final args = {
        'entries': pathData,
        'colors': _colours,
      };
      final polylines = await compute(decodePolylinesBatch, args);

      // Re-style again here to ensure "now" semantics (in case isolate time differed)
      final restyled = polylines.map((e) => _withStyle(e, palette: _colours)).toList();

      if (mounted) {
        setState(() {
          _polylines = restyled;
          _loading = false;
          _selectedYears = years.toSet();
          _selectedTypes = types.toSet();
        });
        widget.onFabReady(buildFloatingActionButton(context)!);
        debugPrint("Polylines loaded from DB");

        if (restyled.isNotEmpty) {
          // Save to cache (fire-and-forget)
          Future(() async {
            try {
              final encoded = json.encode(restyled.map((e) => e.toJson()).toList());
              final cf = File(AppCacheFilePath.polylines);
              await cf.writeAsString(encoded);
              settings.setShouldReloadPolylines(false);
            } catch (e) {
              debugPrint('Failed to write cache: $e');
            }
          });
        }
        _scheduleNextFlip();
      }
    }
  }

  void _sortedPolylines(List<PolylineEntry> filteredPolylines, PathDisplayOrder displayOrder) {
    switch (displayOrder) {
      case PathDisplayOrder.creationDate:
        filteredPolylines.sort((a, b) =>
            (a.creationDate ?? DateTime(0)).compareTo(b.creationDate ?? DateTime(0)));
        break;
      case PathDisplayOrder.tripDate:
        filteredPolylines.sort(
            (a, b) => (a.startDate ?? DateTime(0)).compareTo(b.startDate ?? DateTime(0)));
        break;
      case PathDisplayOrder.tripDatePlaneOver:
        final nonAir = filteredPolylines.where((e) => e.type != VehicleType.plane).toList()
          ..sort((a, b) => (a.startDate ?? DateTime(0)).compareTo(b.startDate ?? DateTime(0)));
        final air = filteredPolylines.where((e) => e.type == VehicleType.plane).toList()
          ..sort((a, b) => (a.creationDate ?? DateTime(0)).compareTo(b.creationDate ?? DateTime(0)));
        filteredPolylines
          ..clear()
          ..addAll(nonAir)
          ..addAll(air);
        break;
    }
  }

  void _changePolylineColor(Map<VehicleType, Color> newPalette) {
    setState(() {
      _polylines = _polylines.map((e) => _withStyle(e, palette: newPalette)).toList();
      _colours = newPalette;
    });
    _scheduleNextFlip();
  }

  List<PolylineEntry> _sortPolylinesByTime(List<PolylineEntry> polylines) {
    switch (_selectedYearFilter) {
      case YearFilter.past:
        final now = DateTime.now();
        return polylines
            .where((e) =>
                (e.startDate != null && e.startDate!.isBefore(now)) &&
                (_selectedTypes.isEmpty || _selectedTypes.contains(e.type)))
            .toList();
      case YearFilter.future:
        final now = DateTime.now();
        return polylines
            .where((e) =>
                (e.startDate != null && e.startDate!.isAfter(now)) &&
                (_selectedTypes.isEmpty || _selectedTypes.contains(e.type)))
            .toList();
      case YearFilter.all:
      case YearFilter.years:
        return polylines
            .where((e) =>
                (_selectedYears.isEmpty || _selectedYears.contains(e.startDate?.year)) &&
                (_selectedTypes.isEmpty || _selectedTypes.contains(e.type)))
            .toList();
    }
  }

  @override
  Widget build(BuildContext context) {
    final appLocalizations = AppLocalizations.of(context)!;
    final settings = context.watch<SettingsProvider>();
    final displayOrder = settings.pathDisplayOrder;
    final newPalette = MapColorPaletteHelper.getPalette(settings.mapColorPalette);
    final trips = context.watch<TripsProvider>();
    final years = trips.years;
    final types = trips.vehicleTypes;

    if (newPalette != _colours) {
      _changePolylineColor(newPalette);
    }

    List<PolylineEntry> filteredPolylines = _sortPolylinesByTime(_polylines);
    _sortedPolylines(filteredPolylines, displayOrder);

    return _loading
        ? Center(
            child: Stack(
              alignment: Alignment.center,
              children: [
                const CircularProgressIndicator(),
                const SizedBox(height: 16),
                Text(
                  appLocalizations.tripPathLoading,
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
              ],
            ),
          )
        : Stack(
            children: [
              FlutterMap(
                mapController: _mapController,
                options: MapOptions(
                  initialCenter: _center,
                  initialZoom: _zoom,
                  keepAlive: true,
                  onPositionChanged: (position, hasGesture) {
                    if (hasGesture) {
                      setState(() {
                        _center = position.center;
                        _zoom = position.zoom;
                      });
                    }
                  },
                ),
                children: [
                  TileLayer(
                    urlTemplate: "https://tile.openstreetmap.org/{z}/{x}/{y}.png",
                    userAgentPackageName: 'me.trainlog.app',
                  ),
                  PolylineLayer(
                    polylines: filteredPolylines.map((e) => e.polyline).toList(),
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
                          _yearFilterBuilder(years),
                          const SizedBox(height: 16),
                          Text(appLocalizations.typeTitle,
                              style: Theme.of(context).textTheme.titleLarge),
                          const SizedBox(height: 8),
                          VehicleTypeFilterChips(
                            availableTypes: types,
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
            subItems: years.map((e) => e.toString()).toList()),
      ],
      selectedTopIndex: _selectedYearFilterOption,
      selectedSubStates: {3: years.map((y) => _selectedYears.contains(y)).toList()},
      onChanged: (top, sub) {
        setState(() {
          switch (top) {
            case 0: // all
              _selectedYears = years.toSet();
              _selectedYearFilter = YearFilter.all;
              break;
            case 1: // past
              _selectedYearFilter = YearFilter.past;
              break;
            case 2: // future
              _selectedYearFilter = YearFilter.future;
              break;
            case 3: // years
              _selectedYearFilter = YearFilter.years;
              _selectedYears = sub
                  .asMap()
                  .entries
                  .where((e) => e.value)
                  .map((e) => years[e.key])
                  .toSet();
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
          widget.onFabReady(null); // Hide FAB
        });
      },
      child: const Icon(Icons.filter_alt),
    );
  }
}
