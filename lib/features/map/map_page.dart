import 'dart:async';
import 'dart:io';
import 'dart:math' as math;
import 'dart:ui';

import 'package:flutter/cupertino.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:geolocator/geolocator.dart';
import 'package:latlong2/latlong.dart';
import 'package:material_symbols_icons/symbols.dart';
import 'package:provider/provider.dart';
import 'package:trainlog_app/l10n/app_localizations.dart';
import 'package:trainlog_app/navigation/nav_models.dart';
import 'package:trainlog_app/platform/adaptive_trip_card.dart';
import 'package:trainlog_app/providers/polyline_provider.dart';
import 'package:trainlog_app/providers/settings_provider.dart';
import 'package:trainlog_app/providers/trips_provider.dart';
import 'package:trainlog_app/utils/location_utils.dart';
import 'package:trainlog_app/utils/platform_utils.dart';
import 'package:trainlog_app/widgets/dropdown_radio_list.dart';
import 'package:trainlog_app/widgets/rendered_polyline_layer.dart';
import 'package:trainlog_app/widgets/vehicle_type_filter_chips.dart';

class MapPage extends StatefulWidget {
  final SetPrimaryActions onPrimaryActionsReady;

  const MapPage({super.key, required this.onPrimaryActionsReady});

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
  LatLng? _userPosition;
  final LayerHitNotifier<int> hitNotifier = ValueNotifier(null);
  StreamSubscription<Position>? _posSub;
  bool _followUser = false;

  // --- UI state
  bool _showFilterModal = false;
  final ValueNotifier<double> _rotationNotifier = ValueNotifier(0.0);

  @override
  bool get wantKeepAlive => true;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);

    final settings = context.read<SettingsProvider>();
    _initCenterAndMarker(settings);
    _startUserLocationUpdates(settings, requestInitialFix: false);

    // kick loading once providers exist
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<PolylineProvider>().ensureLoaded();
      final action = _buildPrimaryAction(context);
      widget.onPrimaryActionsReady(action == null ? const [] : [action]);
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
    try {
      final pos = await Geolocator.getCurrentPosition(
        locationSettings: platformLocationSettings().copyWith(
          timeLimit: const Duration(seconds: 3),
        ),
      );
      return LatLng(pos.latitude, pos.longitude);
    } catch (_) {
      final lastKnown = await Geolocator.getLastKnownPosition();
      if (lastKnown == null) return null;
      return LatLng(lastKnown.latitude, lastKnown.longitude);
    }
  }

  Future<void> _startUserLocationUpdates(
    SettingsProvider settings, {
    bool requestInitialFix = true,
  }) async {
    final granted = await _hasLocationAccess(settings);
    if (!granted) return;

    if (requestInitialFix) {
      final current = await _safeGetPositionOrNull();
      if (current != null && mounted) {
        setState(() => _userPosition = current);
      }
    }

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

  Future<bool> _hasLocationAccess(SettingsProvider settings) async {
    var p = await Geolocator.checkPermission();
    if (p == LocationPermission.always || p == LocationPermission.whileInUse) {
      if (settings.refusedToSharePosition) settings.setRefusedToSharePosition(false);
      return true;
    }

    if (settings.refusedToSharePosition) return false;

    final canShowSystemPrompt =
        kIsWeb || Platform.isAndroid || Platform.isIOS || Platform.isMacOS;
    if (!canShowSystemPrompt) return false;

    p = await Geolocator.requestPermission();
    final granted = p == LocationPermission.always || p == LocationPermission.whileInUse;
    if (!granted) {
      settings.setRefusedToSharePosition(true);
    }
    return granted;
  }

  Future<void> _stopUserLocationUpdates() async {
    await _posSub?.cancel();
    _posSub = null;
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    final appLocalizations = AppLocalizations.of(context)!;
    final settings = context.watch<SettingsProvider>();
    final poly = context.watch<PolylineProvider>();   

    if (poly.isLoading) {
      // While loading, don’t show FAB
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        widget.onPrimaryActionsReady(const []);
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
      final action = _buildPrimaryAction(context);
      widget.onPrimaryActionsReady(action == null ? const [] : [action]);
    });

    return Stack(
      children: [
        FlutterMap(
          mapController: _mapController,
          options: MapOptions(
            initialCenter: _center,
            initialZoom: _zoom,
            keepAlive: true,
            onPositionChanged: (pos, hasGesture) {
              _center = pos.center;
              _zoom = pos.zoom;
              _rotationNotifier.value = pos.rotation;
            },
          ),
          children: [
            TileLayer(
              urlTemplate: "https://tile.openstreetmap.org/{z}/{x}/{y}.png",
              userAgentPackageName: 'me.trainlog.app',
            ),
            RenderedPolylineLayer(
              onTripTap: (tripId) async {
                final repo = context.read<TripsProvider>().repository;
                if (repo == null) return;

                final tappedTrip = await repo.getTripById(tripId);
                if (tappedTrip == null || !context.mounted) return;

                await showAdaptiveTripBottomSheet(context, trip: tappedTrip);
              },
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
        if (!_showFilterModal || AppPlatform.isApple) _mapButtonHelper(),
        if (_showFilterModal) _filterModalHelper(context, appLocalizations),
      ],
    );
  }

  Widget _vehicleTypeTiltleWithButtonsHelper(AppLocalizations appLocalizations, PolylineProvider polyProvider) {
    return Row(
      children: [
        Expanded(
          child: Text(
            appLocalizations.typeTitle,
            style: Theme.of(context).textTheme.titleLarge,
          ),
        ),
        TextButton(
          onPressed: () {
            context.read<PolylineProvider>().selectAllVehicleTypes(
              polyProvider.availableTypesWithoutPoi,
            );
          },
          style: TextButton.styleFrom(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            minimumSize: Size.zero,
            tapTargetSize: MaterialTapTargetSize.shrinkWrap,
            visualDensity: VisualDensity.compact,
          ),
          child: Text(appLocalizations.mapFilterVehicleTypeAllBtn),
        ),
        const SizedBox(width: 4),
        TextButton(
          onPressed: () {
            context.read<PolylineProvider>().unselectAllVehicleTypes(
              polyProvider.availableTypesWithoutPoi,
            );
          },
          style: TextButton.styleFrom(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            minimumSize: Size.zero,
            tapTargetSize: MaterialTapTargetSize.shrinkWrap,
            visualDensity: VisualDensity.compact,
          ),
          child: Text(appLocalizations.mapFilterVehicleTypeNoneBtn),
        ),
      ],
    );
  }

  Positioned _filterModalHelper(BuildContext context, AppLocalizations appLocalizations) {
    final polyProvider = context.watch<PolylineProvider>();
    final mediaQuery = MediaQuery.of(context);
    final maxHeight =
        (mediaQuery.size.height - mediaQuery.padding.top - mediaQuery.padding.bottom) * 0.7;

    return Positioned(
      bottom: 16,
      left: 16,
      right: 16,
      child: Material(
        elevation: 4,
        borderRadius: BorderRadius.circular(16),
        color: Theme.of(context).cardColor,
        child: ConstrainedBox(
          constraints: BoxConstraints(maxHeight: maxHeight),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Flexible(
                fit: FlexFit.loose,
                child: SingleChildScrollView(
                  padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        appLocalizations.yearTitle,
                        style: Theme.of(context).textTheme.titleLarge,
                      ),
                      const SizedBox(height: 8),
                      _yearFilterBuilder(
                        years: polyProvider.availableYears,
                        selectedTopIndex: polyProvider.selectedYearFilterOption,
                        selectedYears: polyProvider.selectedYears,
                      ),
                      const SizedBox(height: 16),
                      _vehicleTypeTiltleWithButtonsHelper(appLocalizations, polyProvider),
                      const SizedBox(height: 8),
                      VehicleTypeFilterChips(
                        availableTypes: polyProvider.availableTypesWithoutPoi,
                        selectedTypes: polyProvider.selectedTypes,
                        onTypeToggle: (type, selected) {
                          context.read<PolylineProvider>().toggleType(type, selected);
                        },
                      ),
                    ],
                  ),
                ),
              ),
              const Divider(height: 1),
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
                child: Align(
                  alignment: Alignment.centerRight,
                  child: ElevatedButton.icon(
                    onPressed: () {
                      setState(() => _showFilterModal = false);
                      final action = _buildPrimaryAction(context);
                      widget.onPrimaryActionsReady(action == null ? const [] : [action]);
                    },
                    icon: const Icon(Icons.close),
                    label: Text(MaterialLocalizations.of(context).closeButtonLabel),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Positioned _mapButtonHelper() { 
    final Icon recenterUserIcon = Icon(AdaptiveIcons.position);
    final Icon followUserIcon = Icon(_followUser ? Symbols.frame_person_off : Symbols.frame_person);

    Widget orientationIconBuilder() {
      return ValueListenableBuilder<double>(
        valueListenable: _rotationNotifier,
        builder: (context, rotation, _) {
          return Transform.rotate(
            angle: -(rotation + 45.0) * (math.pi / 180.0),
            child: Icon(AdaptiveIcons.compass),
          );
        },
      );
    }

    void recenterFct () {
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
    }
    void followUserFct () => setState(() => _followUser = !_followUser);
    void resetMapOrientationFct () {
      _mapController.rotate(0);
      _rotationNotifier.value = 0;
    };

    if(AppPlatform.isApple) {
      return Positioned(
        top: 70,
        right: 12,
        child: ClipRRect(
          borderRadius: BorderRadius.circular(14),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
            child: Container(
              decoration: BoxDecoration(
                color: CupertinoColors.systemGrey6.withValues(alpha: 0.7),
                borderRadius: BorderRadius.circular(14),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Recenter user
                  CupertinoButton(
                    padding: const EdgeInsets.all(10),
                    onPressed: recenterFct,
                    child: recenterUserIcon,
                  ),
                  // Follow user
                  DecoratedBox(
                    decoration: BoxDecoration(
                      border: Border(
                        top: BorderSide(
                          color: CupertinoColors.separator.resolveFrom(context),
                          width: 0.5,
                        ),
                      ),
                    ),
                    child: CupertinoButton(
                      padding: const EdgeInsets.all(10),
                      onPressed: followUserFct,
                      child: followUserIcon,
                    ),
                  ),
                  // Reorientation of the map
                  DecoratedBox(
                    decoration: BoxDecoration(
                      border: Border(
                        top: BorderSide(
                          color: CupertinoColors.separator.resolveFrom(context),
                          width: 0.5,
                        ),
                      ),
                    ),
                    child: CupertinoButton(
                      padding: const EdgeInsets.all(10),
                      onPressed: resetMapOrientationFct,
                      child: orientationIconBuilder(),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      );
    }

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
            onPressed: recenterFct,
            child: recenterUserIcon,
          ),
          const SizedBox(height: 8),
          FloatingActionButton.small(
            heroTag: 'map_btn_follow',
            backgroundColor: bkg,
            foregroundColor: forg,
            onPressed: followUserFct,
            child: followUserIcon,
          ),
          const SizedBox(height: 8),
          FloatingActionButton.small(
            heroTag: 'map_btn_compass',
            backgroundColor: bkg,
            foregroundColor: forg,
            onPressed: resetMapOrientationFct,
            child: orientationIconBuilder(),
          ),
        ],
      ),
    );
  }

  DropdownRadioList _yearFilterBuilder({
    required List<int> years,
    required int selectedTopIndex,
    required Set<int> selectedYears,
  }) {
    final l10n = AppLocalizations.of(context)!;

    Widget yearButtons() {
      return Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          TextButton(
            onPressed: () {
              context.read<PolylineProvider>().selectAllYears(years);
            },
            style: TextButton.styleFrom(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              minimumSize: Size.zero,
              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
              visualDensity: VisualDensity.compact,
            ),
            child: Text(l10n.mapFilterYearsAllBtn),
          ),
          const SizedBox(width: 4),
          TextButton(
            onPressed: () {
              context.read<PolylineProvider>().unselectAllYears();
            },
            style: TextButton.styleFrom(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              minimumSize: Size.zero,
              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
              visualDensity: VisualDensity.compact,
            ),
            child: Text(l10n.mapFilterYearsNoneBtn),
          ),
        ],
      );
    }

    return DropdownRadioList(
      items: [
        MultiLevelItem(
          title: Text(l10n.yearAllList),
          selectedTitle: Text(l10n.yearAllList),
          subItems: const [],
        ),
        MultiLevelItem(
          title: Text(l10n.yearPastList),
          selectedTitle: Text(l10n.yearPastList),
          subItems: const [],
        ),
        MultiLevelItem(
          title: Text(l10n.yearFutureList),
          selectedTitle: Text(l10n.yearFutureList),
          subItems: const [],
        ),
        MultiLevelItem(
          title: Text(l10n.yearYearList),
          selectedTitle: Text(l10n.yearYearList),
          trailing: yearButtons(),
          subItems: years.map((e) => e.toString()).toList(),
        ),
      ],
      selectedTopIndex: selectedTopIndex,
      selectedSubStates: {
        3: years.map((y) => selectedYears.contains(y)).toList(),
      },
      onChanged: (top, sub) {
        context.read<PolylineProvider>().updateYearFilter(
          topIndex: top,
          years: years,
          subSelection: sub,
        );
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
        widget.onPrimaryActionsReady(const []);
      },
    );
  }
}
