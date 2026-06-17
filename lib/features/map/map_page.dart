import 'dart:async';
import 'dart:math' as math;
import 'dart:ui';

import 'package:flutter/cupertino.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:geolocator/geolocator.dart';
import 'package:latlong2/latlong.dart';
import 'package:lottie/lottie.dart' as lt;
import 'package:material_symbols_icons/symbols.dart';
import 'package:provider/provider.dart';
import 'package:trainlog_app/app/theme/app_colors.dart';
import 'package:trainlog_app/app/theme/app_nav_bar_theme.dart';
import 'package:trainlog_app/l10n/app_localizations.dart';
import 'package:trainlog_app/features/map/map_filter_widget.dart';
import 'package:trainlog_app/features/map/map_marker.dart';
import 'package:trainlog_app/navigation/nav_models.dart';
import 'package:trainlog_app/platform/adaptive_trip_card.dart';
import 'package:trainlog_app/platform/adaptive_widget.dart';
import 'package:trainlog_app/providers/polyline_provider.dart';
import 'package:trainlog_app/providers/settings_provider.dart';
import 'package:trainlog_app/providers/trips_provider.dart';
import 'package:trainlog_app/services/geo_permission_service.dart';
import 'package:trainlog_app/utils/location_utils.dart';
import 'package:trainlog_app/utils/platform_utils.dart';
import 'package:trainlog_app/widgets/rendered_polyline_layer.dart';

class MapPage extends StatefulWidget {
  final SetPrimaryActions onPrimaryActionsReady;

  const MapPage({super.key, required this.onPrimaryActionsReady});

  @override
  State<MapPage> createState() => _MapPageState();
}

class _MapPageState extends State<MapPage>
    with WidgetsBindingObserver, AutomaticKeepAliveClientMixin, SingleTickerProviderStateMixin {
  // --- Map state
  final MapController _mapController = MapController();
  final GeoPermissionService _geo = const GeoPermissionService();
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

  // Drives the slow blink of the "locked on position" pill shown while
  // [_followUser] is active.
  late final AnimationController _pillBlinkController;

  @override
  bool get wantKeepAlive => true;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);

    _pillBlinkController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    )..repeat(reverse: true);

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
    _pillBlinkController.dispose();
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

    // Never prompt for permission on load: only use the live position if the
    // user has already granted access.
    if (!await _geo.hasPermission()) return;

    final current = await _geo.getCurrentPositionOrNull();
    if (current != null && mounted) {
      setState(() {
        _userPosition = current;
        _center = current;
      });
      settings.setLastUserPosition(current);
    }
  }

  Future<void> _startUserLocationUpdates(
    SettingsProvider settings, {
    bool requestInitialFix = true,
  }) async {
    // Only stream when permission is already granted — requesting it is left to
    // explicit user actions (recenter button, settings toggle, onboarding).
    if (!await _geo.hasPermission()) return;

    if (requestInitialFix) {
      final current = await _geo.getCurrentPositionOrNull();
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

  Future<void> _stopUserLocationUpdates() async {
    await _posSub?.cancel();
    _posSub = null;
  }

  /// Ensures we have a live fix for the user's position, requesting OS
  /// permission and starting the location stream if needed.
  ///
  /// Only call from explicit user actions (recenter / follow buttons): this is
  /// allowed to prompt for permission. Returns the position, or `null` if
  /// permission was denied or no fix could be obtained.
  Future<LatLng?> _ensureUserPosition() async {
    if (_userPosition != null) return _userPosition;

    final settings = context.read<SettingsProvider>();
    final granted = await _geo.requestPermission(settings);
    if (!granted || !mounted) return null;

    final current = await _geo.getCurrentPositionOrNull();
    if (current == null || !mounted) return null;

    settings.setLastUserPosition(current);
    setState(() => _userPosition = current);
    await _startUserLocationUpdates(settings, requestInitialFix: false);
    return current;
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
        child: Padding(
          padding: const EdgeInsets.fromLTRB(8, 8, 8, 24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const SizedBox(height: 24),
              Text(appLocalizations.tripPathLoading,
                  style: const TextStyle(fontWeight: FontWeight.bold)),
              const SizedBox(height: 16),
              Expanded(child: lt.Lottie.asset('assets/animations/loading.json')),     
            ],
          ),
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
            interactionOptions: const InteractionOptions(
              rotationThreshold: 20.0,
              enableMultiFingerGestureRace: true,
            ),
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
              errorTileCallback: (tile, error, stackTrace) {},
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
                    child: const MapMarker(),
                  ),
                ],
              ),
          ],
        ),
        if (_followUser) _lockedOnPositionPill(appLocalizations),
        if (!_showFilterModal || AppPlatform.isApple) _mapButtonHelper(),
        if (_showFilterModal) ...[
          GestureDetector(
            behavior: HitTestBehavior.opaque,
            onTap: () {
              setState(() => _showFilterModal = false);
              final action = _buildPrimaryAction(context);
              widget.onPrimaryActionsReady(action == null ? const [] : [action]);
            },
          ),
          MapFilterWidget(
            onClose: () {
              setState(() => _showFilterModal = false);
              final action = _buildPrimaryAction(context);
              widget.onPrimaryActionsReady(action == null ? const [] : [action]);
            },
          ),
        ],
      ],
    );
  }

  Positioned _mapButtonHelper() { 
    final Icon recenterUserIcon = Icon(AdaptiveIcons.position);
    final Icon followUserIcon = Icon(_followUser ? Symbols.frame_person_off : Symbols.frame_person);
    final cs = Theme.of(context).colorScheme;
    final navColors = Theme.of(context).extension<AppNavBarColors>()!;

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

    Future<void> recenterFct () async {
      // No fix yet: this is an explicit user action, so it's fine to ask the
      // OS for permission now (one of the only places on the map that does so).
      final p = await _ensureUserPosition();
      if (p == null || !mounted) return;

      double z = _zoom;
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
    Future<void> followUserFct () async {
      // Turning follow off needs no location access.
      if (_followUser) {
        setState(() => _followUser = false);
        return;
      }

      // Enabling follow requires a position: prompt for permission if needed.
      final p = await _ensureUserPosition();
      if (p == null || !mounted) return;

      _mapController.move(p, _zoom);
      setState(() {
        _center = p;
        _followUser = true;
      });
    }
    void resetMapOrientationFct () {
      _mapController.rotate(0);
      _rotationNotifier.value = 0;
    }

    // On Apple the primary-action FAB sits at kNavBarClearance+16 from the
    // screen bottom and is 56 px tall, so push these controls clear of it.
    final double buttonsBottom = AppPlatform.isApple
        ? 160.0 - MediaQuery.of(context).padding.bottom
        : 16 + MediaQuery.of(context).padding.bottom + 56 + 12;

    return Positioned(
      bottom: buttonsBottom,
      right: 16,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(14),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
          child: Container(
            decoration: BoxDecoration(
              color: navColors.background,
              borderRadius: BorderRadius.circular(14),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Recenter user
                AdaptiveFilledIconButton(
                    onPressed: () => recenterFct(),
                    colorScheme: FilledButtonColorScheme.floating,
                    child: recenterUserIcon,
                ),
                // Follow user
                DecoratedBox(
                  decoration: BoxDecoration(
                    border: Border(
                      top: BorderSide(
                        color: navColors.inactive,
                        //color: CupertinoColors.separator.resolveFrom(context),
                        width: 0.5,
                      ),
                    ),
                  ),
                  child: 
                  AdaptiveFilledIconButton(
                    onPressed: () => followUserFct(),
                    colorScheme: FilledButtonColorScheme.floating,
                    child: followUserIcon,
                  ),
                ),
                // Reorientation of the map
                DecoratedBox(
                  decoration: BoxDecoration(
                    border: Border(
                      top: BorderSide(
                        color: navColors.inactive,
                        width: 0.5,
                      ),
                    ),
                  ),
                  child: 
                  AdaptiveFilledIconButton(
                    onPressed: resetMapOrientationFct,
                    colorScheme: FilledButtonColorScheme.floating, 
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

  /// A slowly blinking black pill anchored at the top of the map, shown while
  /// the map is locked on the user's position ([_followUser]).
  Widget _lockedOnPositionPill(AppLocalizations appLocalizations) {
    return Positioned(
      top: MediaQuery.of(context).padding.top + 12,
      left: 0,
      right: 0,
      child: IgnorePointer(
        child: Center(
          child: FadeTransition(
            opacity: Tween<double>(begin: 0.25, end: 1.0).animate(
              CurvedAnimation(
                parent: _pillBlinkController,
                curve: Curves.easeInOut,
              ),
            ),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(
                color: Colors.black,
                borderRadius: BorderRadius.circular(24),
              ),
              child: Text(
                appLocalizations.mapLockedOnPosition,
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ),
        ),
      ),
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
