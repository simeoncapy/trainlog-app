import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:provider/provider.dart';
import 'package:trainlog_app/data/models/trips.dart';
import 'package:trainlog_app/l10n/app_localizations.dart';
import 'package:trainlog_app/providers/settings_provider.dart';
import 'package:trainlog_app/utils/cached_data_utils.dart';
import 'package:trainlog_app/utils/map_color_palette.dart';
import 'package:trainlog_app/utils/polyline_utils.dart';
import 'package:trainlog_app/widgets/dropdown_radio_list.dart';
import 'package:trainlog_app/widgets/vehicle_type_filter_chips.dart';
import '../providers/trips_provider.dart';
import 'dart:io';
import 'dart:convert';
import 'package:geolocator/geolocator.dart';


enum YearFilter{
  all,
  past,
  future,
  years
}

class MapPage extends StatefulWidget {
  final void Function(FloatingActionButton? fab) onFabReady;

  const MapPage({super.key, required this.onFabReady});

  @override
  State<MapPage> createState() => _MapPageState();
}

class _MapPageState extends State<MapPage> {
  final MapController _mapController = MapController();

  // Default to Greenwich Observatory
  static const LatLng _greenwich = LatLng(51.476852, -0.0005);
  LatLng _center = _greenwich; //LatLng(35.681236, 139.767125);
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

  Future<void> _initCenterAndMarker(SettingsProvider settings) async {
    // Start from saved last user location or Greenwich
    final saved = settings.userPosition;
    if (mounted) setState(() => _center = saved ?? _greenwich);

    // Ask OS once (system dialog only where available), else silently fall back
    final current = await _maybeUseLocationWithSystemPrompt(settings);
    if (current != null && mounted) {
      setState(() {
        _userPosition = current;
        _center = current;
      });
      //_mapController.move(current, _zoom);
      settings.setLastUserPosition(current);
    }
  }

  Future<LatLng?> _maybeUseLocationWithSystemPrompt(SettingsProvider settings) async {
    // If already granted, try to get the position (no prompts)
    var p = await Geolocator.checkPermission();
    if (p == LocationPermission.always || p == LocationPermission.whileInUse) {
      if (settings.refusedToSharePosition) {
        settings.setRefusedToSharePosition(false); // reset flag
      }
      return await _safeGetPositionOrNull();
    }

    // If user previously refused, never ask again automatically
    if (settings.refusedToSharePosition) return null;

    // Platforms that actually show a system permission dialog
    final canShowSystemPrompt =
        kIsWeb || Platform.isAndroid || Platform.isIOS || Platform.isMacOS;

    if (!canShowSystemPrompt) {
      // Windows/Linux: no in-app OS prompt exists; don’t mark refusal
      return null;
    }

    // First time: trigger the OS dialog
    p = await Geolocator.requestPermission();

    if (p == LocationPermission.always || p == LocationPermission.whileInUse) {
      return await _safeGetPositionOrNull();
    }

    // User denied in the **system** dialog (or OS says deniedForever) → record refusal
    settings.setRefusedToSharePosition(true);
    return null;
  }

  Future<LatLng?> _safeGetPositionOrNull() async {
    // If location services are off, don’t force-open settings; just fall back
    if (!await Geolocator.isLocationServiceEnabled()) return null;

    final pos = await Geolocator.getCurrentPosition(
      locationSettings: _platformLocationSettings(),
    );
    return LatLng(pos.latitude, pos.longitude);
  }

  LocationSettings _platformLocationSettings() {
    // Use platform-specific settings where available; fall back to generic.
    if (kIsWeb) {
      return WebSettings(
        accuracy: LocationAccuracy.high,
        distanceFilter: 0,
        // timeLimit: const Duration(seconds: 10), // optional
      );
    }
    if (Platform.isAndroid) {
      return AndroidSettings(
        accuracy: LocationAccuracy.high,
        distanceFilter: 0,
        // intervalDuration: const Duration(seconds: 5), // for streams; ignored by getCurrentPosition
        // forceLocationManager: false,
      );
    }
    if (Platform.isIOS || Platform.isMacOS) {
      return AppleSettings(
        accuracy: LocationAccuracy.high, // or .best if you prefer
        distanceFilter: 0,
        // pauseLocationUpdatesAutomatically: true,
      );
    }
    // Windows, Linux, others
    return const LocationSettings(
      accuracy: LocationAccuracy.high,
      distanceFilter: 0,
    );
  }

  void _onTripsChanged() {
    // When provider finishes loading or data was refreshed, reload polylines
    if (!_trips.isLoading && _trips.repository != null) {
      _loadPolylines();
    }
  }

  @override
  void dispose() {
    _trips.removeListener(_onTripsChanged);
    super.dispose();
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
        final cachedPolylines = decoded.map((e) => PolylineEntry.fromJson(e)).toList();
        if (mounted) {
          setState(() {
            _polylines = cachedPolylines;
            _loading = false;            
            _selectedYears = years.toSet();
            _selectedTypes = types.toSet();
          });
          widget.onFabReady(buildFloatingActionButton(context)!);
          debugPrint("Polylines loaded from cache");
        }
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

      if (mounted) {
        setState(() {
          _polylines = polylines;
          _loading = false;
          _selectedYears = years.toSet();
          _selectedTypes = types.toSet();
        });
        widget.onFabReady(buildFloatingActionButton(context)!);

        debugPrint("Polylines loaded from DB");

        if(polylines.isEmpty) return;

        // Save to cache (in background)
        Future(() async {
        try {
          final encoded = json.encode(polylines.map((e) => e.toJson()).toList());
          final cacheFile = File(AppCacheFilePath.polylines);
          await cacheFile.writeAsString(encoded);
          settings.setShouldReloadPolylines(false);
        } catch (e) {
          debugPrint('Failed to write cache: $e');
        }
      });
      }
    }
  }

  void _sortedPolylines(List<PolylineEntry> filteredPolylines, PathDisplayOrder displayOrder)
  {
    switch (displayOrder) {
      case PathDisplayOrder.creationDate:
        filteredPolylines.sort((a, b) =>
            (a.creationDate ?? DateTime(0)).compareTo(b.creationDate ?? DateTime(0)));
        break;
      case PathDisplayOrder.tripDate:
        filteredPolylines.sort((a, b) =>
            (a.startDate ?? DateTime(0)).compareTo(b.startDate ?? DateTime(0)));
        break;
      case PathDisplayOrder.tripDatePlaneOver:
        final nonAir = filteredPolylines
            .where((e) => e.type != VehicleType.plane)
            .toList()
          ..sort((a, b) => (a.startDate ?? DateTime(0)).compareTo(b.startDate ?? DateTime(0)));
        final air = filteredPolylines
            .where((e) => e.type == VehicleType.plane)
            .toList()
          ..sort((a, b) => (a.creationDate ?? DateTime(0)).compareTo(b.creationDate ?? DateTime(0)));
        filteredPolylines
          ..clear()
          ..addAll(nonAir)
          ..addAll(air);
        break;
    }
  }

  void _changePolylineColor(Map<VehicleType, Color> newPalette)
  {
    setState(() {
      _polylines = _polylines.map((entry) {
        final newColor = newPalette[entry.type] ?? Colors.grey;

        return PolylineEntry(
          type: entry.type,
          startDate: entry.startDate,
          creationDate: entry.creationDate,
          isFuture: entry.isFuture,
          polyline: Polyline(
            points: entry.polyline.points,
            color: newColor,
            pattern: entry.isFuture
                ? StrokePattern.dashed(segments: [20, 20])
                : StrokePattern.solid(),
            strokeWidth: 4.0,
          ),
        );
      }).toList();
    });
  }

  List<PolylineEntry> _sortPolylinesByTime(List<PolylineEntry> polylines)
  {
    switch (_selectedYearFilter)
    {
      case YearFilter.past:
        final now = DateTime.now();
        return polylines.where((e) =>
          (e.startDate != null && e.startDate!.isBefore(now)) &&
          (_selectedTypes.isEmpty || _selectedTypes.contains(e.type))
        ).toList();
      case YearFilter.future:
        final now = DateTime.now();
        return polylines.where((e) =>
          (e.startDate != null && e.startDate!.isAfter(now)) &&
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


  @override
Widget build(BuildContext context) {
  final appLocalizations = AppLocalizations.of(context)!;
  final settings = context.watch<SettingsProvider>();
  final displayOrder = settings.pathDisplayOrder;
  final newPalette = MapColorPaletteHelper.getPalette(settings.mapColorPalette);
  final trips = context.watch<TripsProvider>();
  final years = trips.years;
  final types = trips.vehicleTypes;

  if(newPalette != _colours)
  {
    _colours = newPalette;
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
                        Text(appLocalizations.yearTitle, style: Theme.of(context).textTheme.titleLarge),
                        const SizedBox(height: 8),
                        _yearFilterBuilder(years),
                        const SizedBox(height: 16),
                        Text(appLocalizations.typeTitle, style: Theme.of(context).textTheme.titleLarge),
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
                            icon: Icon(Icons.close),
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
        MultiLevelItem(title: AppLocalizations.of(context)!.yearYearList,
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
              _selectedYears = sub.asMap().entries
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
      child: Icon(Icons.filter_alt),
    );
  }
}

