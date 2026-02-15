import 'dart:async';
import 'dart:io';
import 'dart:math' as math;

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:geolocator/geolocator.dart';
import 'package:latlong2/latlong.dart';
import 'package:material_symbols_icons/symbols.dart';
import 'package:provider/provider.dart';

import 'package:trainlog_app/data/models/polyline_entry.dart';
import 'package:trainlog_app/data/models/trips.dart';
import 'package:trainlog_app/l10n/app_localizations.dart';
import 'package:trainlog_app/navigation/nav_models.dart';
import 'package:trainlog_app/providers/polyline_provider.dart';
import 'package:trainlog_app/providers/settings_provider.dart';
import 'package:trainlog_app/providers/trips_provider.dart';
import 'package:trainlog_app/utils/date_utils.dart';
import 'package:trainlog_app/utils/location_utils.dart';
import 'package:trainlog_app/utils/platform_utils.dart';
import 'package:trainlog_app/widgets/dropdown_radio_list.dart';
import 'package:trainlog_app/widgets/trip_details_bottom_sheet.dart';
import 'package:trainlog_app/widgets/vehicle_type_filter_chips.dart';

enum YearFilter { all, past, future, years }

class MapPage extends StatefulWidget {
  final void Function(AppPrimaryAction? action) onPrimaryActionReady;

  const MapPage({super.key, required this.onPrimaryActionReady});

  @override
  State<MapPage> createState() => _MapPageState();
}

class _MapPageState extends State<MapPage> with WidgetsBindingObserver, AutomaticKeepAliveClientMixin {
  // --- Map state
  final MapController _mapController = MapController();
  static const LatLng _greenwich = LatLng(51.476852, -0.0005);
  LatLng _center = _greenwich;
  static const double _defaultZoom = 13.0;
  double _zoom = _defaultZoom;
  double _rotation = 0.0;
  LatLng? _userPosition;
  final LayerHitNotifier<int> hitNotifier = ValueNotifier(null);
  StreamSubscription<Position>? _posSub;
  bool _followUser = false;
  int _lastTripsRevisionSeen = -1;

  // --- UI state
  Set<int> _selectedYears = {};
  YearFilter _selectedYearFilter = YearFilter.all;
  Set<VehicleType> _lastAvailableTypes = {};
  Set<VehicleType> _userDeselectedTypes = {};
  Set<VehicleType> _selectedTypes = {};
  bool _showFilterModal = false;
  int _selectedYearFilterOption = 0;

  // --- Rendering constants
  static const double _dashLen = 20.0;
  static const double _gapLen = 20.0;
  static const Color _futureDashColor = Colors.white;

  // --- Utilities
  DateTime get _nowUtc => DateTime.now().toUtc();

  bool _isFutureUtc(DateTime? utcStart) =>
      utcStart != null && utcStart.isAfter(_nowUtc);

  bool _isOngoing(PolylineEntry e) {
    if (!e.hasTimeRange) return false;
    final s = e.utcStartDate;
    final en = e.utcEndDate;
    if (s == null || en == null) return false;
    final now = _nowUtc;
    final started = !now.isBefore(s);
    final notEnded = !now.isAfter(en);
    return started && notEnded;
  }

  @override
  bool get wantKeepAlive => true;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);

    final settings = context.read<SettingsProvider>();
    _initCenterAndMarker(settings);
    _startUserLocationUpdates(settings);

    // kick loading once providers exist
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<PolylineProvider>().ensureLoaded();
      widget.onPrimaryActionReady(_buildPrimaryAction(context));
    });
  }

  @override
  void dispose() {
    _stopUserLocationUpdates();
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      _startUserLocationUpdates(context.read<SettingsProvider>());
    } else if (state == AppLifecycleState.paused) {
      _stopUserLocationUpdates();
    }
  }

  // --- Location
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
    final pos = await Geolocator.getCurrentPosition(locationSettings: platformLocationSettings());
    return LatLng(pos.latitude, pos.longitude);
  }

  Future<void> _startUserLocationUpdates(SettingsProvider settings) async {
    final current = await _maybeUseLocationWithSystemPrompt(settings);
    if (current == null) return;

    if (!mounted) return;
    setState(() => _userPosition = current);

    await _posSub?.cancel();

    _posSub = Geolocator.getPositionStream(
      locationSettings: platformLocationSettings().copyWith(distanceFilter: 10),
    ).listen(
      (pos) {
        final p = LatLng(pos.latitude, pos.longitude);
        if (!mounted) return;
        setState(() => _userPosition = p);
        settings.setLastUserPosition(p);

        if (_followUser) {
          _mapController.move(p, _zoom);
          setState(() => _center = p);
        }
      },
      onError: (e) => debugPrint('Location stream error: $e'),
    );
  }

  Future<void> _stopUserLocationUpdates() async {
    await _posSub?.cancel();
    _posSub = null;
  }

  // --- Filtering / sorting / rendering
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
        final y = _selectedYears;
        y.add(unknownPast.year);
        y.add(unknownFuture.year);
        return polylines.where((e) =>
          (y.isEmpty || y.contains(e.startDate?.year)) &&
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
            .where((e) => e.type != VehicleType.plane && e.type != VehicleType.helicopter)
            .toList()
          ..sort((a, b) =>
              (a.startDate ?? DateTime(0)).compareTo(b.startDate ?? DateTime(0)));

        final air = list
            .where((e) => e.type == VehicleType.plane || e.type == VehicleType.helicopter)
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

  void _reconcileFiltersWithTrips(TripsProvider trips) {
    final availableYears = trips.years.toSet();
    final availableTypes = trips.vehicleTypes.toSet();

    // ---- Years
    if (_selectedYearFilter == YearFilter.all) {
      // "All" should always mean: all available years
      _selectedYears = availableYears;
      _selectedYearFilterOption = 0;
    } else if (_selectedYearFilter == YearFilter.years) {
      final inter = _selectedYears.intersection(availableYears);
      if (inter.isEmpty) {
        // avoid showing nothing after reload
        _selectedYearFilter = YearFilter.all;
        _selectedYearFilterOption = 0;
        _selectedYears = availableYears;
      } else {
        _selectedYears = inter;
      }
    } else {
      // past/future: leave years set alone (not used in those modes)
    }

    // ---- Types
    if (_selectedTypes.isEmpty) {
      // First time: default to all available
      _selectedTypes = availableTypes;

      // IMPORTANT: don't mark anything as deselected here
      // (keep _userDeselectedTypes as-is)
    } else {
      // 1) Remove types that no longer exist
      _selectedTypes = _selectedTypes.intersection(availableTypes);

      // 2) Respect explicit user deselections
      _selectedTypes.removeAll(_userDeselectedTypes);

      // 3) Auto-select newly added types (unless user had explicitly deselected them before)
      final newlyAdded = availableTypes.difference(_lastAvailableTypes);
      _selectedTypes.addAll(newlyAdded.difference(_userDeselectedTypes));

      // 4) Optional safety: if we ended up with nothing selected BUT user didn't deselect everything,
      // fall back to "all available minus deselected" to avoid empty map.
      final allDeselected = _userDeselectedTypes.containsAll(availableTypes);
      if (_selectedTypes.isEmpty && !allDeselected) {
        _selectedTypes = availableTypes.difference(_userDeselectedTypes);
      }
    }

    // Update snapshot for next reconciliation
    _lastAvailableTypes = availableTypes;
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

      // Ongoing: base already red (provider); no overlay
      if (_isOngoing(e)) return [base];

      // Future: overlay dashed white
      final isFuture = !_isOngoing(e) && _isFutureUtc(e.utcStartDate);
      //debugPrint("${e.tripId} future:$isFuture (${e.utcStartDate}, now:$_nowUtc)");
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

  @override
  Widget build(BuildContext context) {
    super.build(context);
    final appLocalizations = AppLocalizations.of(context)!;
    final settings = context.watch<SettingsProvider>();
    final trips = context.watch<TripsProvider>();
    final poly = context.watch<PolylineProvider>();

    final rev = trips.revision;
    if (!trips.isLoading && trips.repository != null && rev != _lastTripsRevisionSeen) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        setState(() {
          _lastTripsRevisionSeen = rev;
          _reconcileFiltersWithTrips(trips);
        });
      });
    }

    // Initialize default filter sets once data exists
    if (_selectedYears.isEmpty && trips.years.isNotEmpty && _selectedYearFilter == YearFilter.all) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        setState(() => _selectedYears = trips.years.toSet());
      });
    }
    if (_selectedTypes.isEmpty && trips.vehicleTypes.isNotEmpty) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        setState(() => _selectedTypes = trips.vehicleTypes.toSet());
      });
    }

    if (poly.isLoading) {
      // While loading, don’t show FAB
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        widget.onPrimaryActionReady(null);
      });

      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const CircularProgressIndicator(),
            const SizedBox(height: 16),
            Text(appLocalizations.tripPathLoading,
                style: const TextStyle(fontWeight: FontWeight.bold)),
          ],
        ),
      );
    }

    // After loading, show FAB if filter modal is closed
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      widget.onPrimaryActionReady(_buildPrimaryAction(context));
    });

    final filtered = _filterBySelection(poly.polylines);
    _sortInPlace(filtered, settings.pathDisplayOrder);
    final toDraw = _toRenderPolylines(filtered);

    debugPrint('poly=${poly.polylines.length} filtered=${filtered.length} '
    'yearsSel=${_selectedYears.length} typesSel=${_selectedTypes.length} '
    'availYears=${trips.years.length} availTypes=${trips.vehicleTypes.length}');

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
                  _rotation = pos.rotation;
                });
              }
            },
          ),
          children: [
            TileLayer(
              urlTemplate: "https://tile.openstreetmap.org/{z}/{x}/{y}.png",
              userAgentPackageName: 'me.trainlog.app',
            ),
            GestureDetector(
              onTapUp: (_) async {
                final LayerHitResult<int>? result = hitNotifier.value;
                if (result == null) return;

                final repo = context.read<TripsProvider>().repository;
                if (repo == null) return;

                for (final hit in result.hitValues) {
                  final tappedTrip = await repo.getTripById(hit);
                  if (tappedTrip != null) {
                    showModalBottomSheet(
                      context: context,
                      useSafeArea: true,
                      isScrollControlled: true,
                      builder: (ctx) {
                        final mq = MediaQuery.of(ctx);
                        final bottom = math.max(mq.viewPadding.bottom, mq.viewInsets.bottom);
                        return Padding(
                          padding: EdgeInsets.only(bottom: bottom),
                          child: TripDetailsBottomSheet(trip: tappedTrip),
                        );
                      },
                    );
                    break;
                  }
                }
              },
              child: PolylineLayer<int>(
                hitNotifier: hitNotifier,
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
        if (!_showFilterModal) _mapButtonHelper(),
        if (_showFilterModal) _filterModalHelper(context, appLocalizations),
      ],
    );
  }

  Positioned _filterModalHelper(BuildContext context, AppLocalizations appLocalizations) {
    final tripsProvider = context.watch<TripsProvider>();
    return Positioned(
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
              _yearFilterBuilder(tripsProvider.years),
              const SizedBox(height: 16),
              Text(appLocalizations.typeTitle, style: Theme.of(context).textTheme.titleLarge),
              const SizedBox(height: 8),
              VehicleTypeFilterChips(
                availableTypes: tripsProvider.vehicleTypes,
                selectedTypes: _selectedTypes,
                onTypeToggle: (type, selected) {
                  setState(() {
                    if (selected) {
                      _selectedTypes.add(type);
                      _userDeselectedTypes.remove(type); // user explicitly wants it ON
                    } else {
                      _selectedTypes.remove(type);
                      _userDeselectedTypes.add(type);    // remember explicit OFF
                    }
                  });
                },
              ),
              const SizedBox(height: 16),
              Align(
                alignment: Alignment.centerRight,
                child: ElevatedButton.icon(
                  onPressed: () {
                    setState(() => _showFilterModal = false);
                    widget.onPrimaryActionReady(_buildPrimaryAction(context));
                  },
                  icon: const Icon(Icons.close),
                  label: Text(MaterialLocalizations.of(context).closeButtonLabel),
                ),
              )
            ],
          ),
        ),
      ),
    );
  }

  Positioned _mapButtonHelper() {
    final bkg = Theme.of(context).colorScheme.tertiaryContainer;
    final forg = Theme.of(context).colorScheme.onTertiaryContainer;

    return Positioned(
      right: 16,
      bottom: 16 + 56 + 12,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          FloatingActionButton.small(
            heroTag: 'map_btn_my_location',
            backgroundColor: bkg,
            foregroundColor: forg,
            onPressed: () {
              final p = _userPosition;
              double z = _zoom;
              if (p == null) return;
              if (_center == p) {
                _mapController.move(p, _defaultZoom);
                z = _defaultZoom;
              } else {
                _mapController.move(p, _zoom);
              }
              setState(() {
                _center = p;
                _zoom = z;
              });
            },
            child: const Icon(Icons.my_location),
          ),
          const SizedBox(height: 8),
          FloatingActionButton.small(
            heroTag: 'map_btn_follow',
            backgroundColor: bkg,
            foregroundColor: forg,
            onPressed: () => setState(() => _followUser = !_followUser),
            child: Icon(_followUser ? Symbols.frame_person_off : Symbols.frame_person),
          ),
          const SizedBox(height: 8),
          FloatingActionButton.small(
            heroTag: 'map_btn_compass',
            backgroundColor: bkg,
            foregroundColor: forg,
            onPressed: () {
              _mapController.rotate(0);
              setState(() => _rotation = 0);
            },
            child: Transform.rotate(
              angle: -(_rotation + 45.0) * (math.pi / 180.0),
              child: const Icon(Icons.explore),
            ),
          ),
        ],
      ),
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
            case 0:
              _selectedYears = years.toSet();
              _selectedYearFilter = YearFilter.all;
              break;
            case 1:
              _selectedYearFilter = YearFilter.past;
              break;
            case 2:
              _selectedYearFilter = YearFilter.future;
              break;
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

  AppPrimaryAction? _buildPrimaryAction(BuildContext context) {
    if (_showFilterModal) return null;
    return AppPrimaryAction(
      icon: AdaptiveIcons.filter, // add if missing
      tooltip: AppLocalizations.of(context)!.filterButton,
      onPressed: () {
        setState(() => _showFilterModal = true);
        widget.onPrimaryActionReady(null);
      },
    );
  }
}
