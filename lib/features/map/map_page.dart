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
import 'package:trainlog_app/data/models/location_search_result.dart';
import 'package:trainlog_app/l10n/app_localizations.dart';
import 'package:trainlog_app/features/map/location_category_icons.dart';
import 'package:trainlog_app/features/map/map_filter_widget.dart';
import 'package:trainlog_app/features/map/map_marker.dart';
import 'package:trainlog_app/features/trips_add/widgets/full_screen_search_overlay.dart';
import 'package:trainlog_app/navigation/nav_models.dart';
import 'package:trainlog_app/platform/adaptive_trip_card.dart';
import 'package:trainlog_app/platform/adaptive_widget.dart';
import 'package:trainlog_app/providers/polyline_provider.dart';
import 'package:trainlog_app/providers/settings_provider.dart';
import 'package:trainlog_app/providers/trainlog_provider.dart';
import 'package:trainlog_app/providers/trips_provider.dart';
import 'package:trainlog_app/services/geo_permission_service.dart';
import 'package:trainlog_app/utils/location_utils.dart';
import 'package:trainlog_app/utils/platform_utils.dart';
import 'package:trainlog_app/utils/text_utils.dart';
import 'package:trainlog_app/widgets/osm_mark.dart';
import 'package:trainlog_app/widgets/rendered_polyline_layer.dart';
import 'package:trainlog_app/widgets/trip_direction_chevron_layer.dart';

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
  final ValueNotifier<double> _rotationNotifier = ValueNotifier(0.0);

  // Drives the slow blink of the "locked on position" pill shown while
  // [_followUser] is active.
  late final AnimationController _pillBlinkController;

  // --- Place search
  OverlayEntry? _searchOverlay;
  final TextEditingController _searchCtl = TextEditingController();
  final FocusNode _searchFocusNode = FocusNode();
  List<LocationSearchResult> _searchResults = [];
  bool _isSearching = false;
  int _searchRequestId = 0;
  Timer? _searchDebounce;

  /// Place picked in the search, shown with a pin until tapped.
  LocationSearchResult? _searchedPlace;

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
    _searchDebounce?.cancel();
    _searchOverlay?.remove();
    _searchOverlay = null;
    _searchCtl.dispose();
    _searchFocusNode.dispose();
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
            // Both bounds must stay finite. A fast pinch can make flutter_map
            // feed a non-positive scale to log() (its guard checks
            // details.scale, but the value used is details.scale plus an
            // internal gesture-race corrector), producing an infinite or NaN
            // zoom. MapCamera then asserts on it. Finite limits let clampZoom
            // absorb that frame instead: -infinity lands on minZoom, NaN on
            // maxZoom. 0 is a fully zoomed-out world; 22 is past anything
            // usable, so over-zoom above OSM's native zoom 19 still works as
            // before.
            minZoom: 0,
            maxZoom: 22,
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
            if (settings.mapDisplayTripDirection)
              const TripDirectionChevronLayer(),
            if (_userPosition != null && settings.mapDisplayUserLocationMarker)
              MarkerLayer(
                markers: [
                  Marker(
                    width: 30,
                    height: 30,
                    point: _userPosition!,
                    child: const MapMarker(),
                  ),
                ],
              ),
            if (_searchedPlace != null)
              MarkerLayer(
                markers: [
                  Marker(
                    width: 40,
                    height: 40,
                    point: _searchedPlace!.point,
                    alignment: Alignment.topCenter,
                    child: GestureDetector(
                      onTap: () => setState(() => _searchedPlace = null),
                      child: Icon(
                        Icons.location_on,
                        size: 40,
                        color: Theme.of(context).colorScheme.error,
                      ),
                    ),
                  ),
                ],
              ),
          ],
        ),

        const OsmMark(
          isCompact: false,
          alignment: Alignment.topLeft,
          //orientation: MarkOrientation.vertical,
          //margin: EdgeInsets.only(left: 6, bottom: 80, right: 6, top: 6),
        ),

        if (_followUser) _lockedOnPositionPill(appLocalizations),
        _searchButton(appLocalizations),
        _mapButtonHelper(),        
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

  /// Round search button in the top-right corner of the map.
  Widget _searchButton(AppLocalizations appLocalizations) {
    final navColors = Theme.of(context).extension<AppNavBarColors>()!;

    return Positioned(
      top: MediaQuery.of(context).padding.top + 12,
      right: 16,
      child: Tooltip(
        message: appLocalizations.mapSearchLocationButton,
        child: ClipOval(
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
            child: Container(
              color: navColors.background,
              child: AdaptiveFilledIconButton(
                onPressed: _openSearchOverlay,
                colorScheme: FilledButtonColorScheme.floating,
                child: Icon(AdaptiveIcons.search),
              ),
            ),
          ),
        ),
      ),
    );
  }

  OverlayEntry _buildSearchOverlay() {
    final loc = AppLocalizations.of(context)!;

    return OverlayEntry(
      builder: (context) {
        final theme = Theme.of(context);
        final showNoResult = !_isSearching &&
            _searchResults.isEmpty &&
            _searchCtl.text.trim().isNotEmpty;

        return FullScreenSearchOverlay<LocationSearchResult>(
          controller: _searchCtl,
          focusNode: _searchFocusNode,
          items: _searchResults,
          isLoading: _isSearching,
          hintText: loc.mapSearchLocationHint,
          belowSearchField: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(
                    Icons.info_outline,
                    size: 16,
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      loc.mapSearchLocationTip,
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ),
                ],
              ),
              if (showNoResult) ...[
                const SizedBox(height: 12),
                Text(
                  loc.mapSearchLocationNoResult,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
            ],
          ),
          onChanged: (query) {
            _searchDebounce?.cancel();
            _searchDebounce = Timer(const Duration(milliseconds: 350), () {
              _performLocationSearch(query);
            });
          },
          onSubmitted: (query) {
            _searchDebounce?.cancel();
            _performLocationSearch(query);
          },
          itemBuilder: (context, place) {
            final flag = place.countryCode.isEmpty
                ? ''
                : '${countryCodeToEmoji(place.countryCode)} ';
            final category = loc.mapSearchLocationCategory(place.category.name);
            final subtitle = place.subtitle.isEmpty
                ? category
                : '$category · ${place.subtitle}';

            return ListTile(
              leading: Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: theme.colorScheme.onSurface.withValues(alpha: 0.06),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(
                  place.category.icon,
                  size: 20,
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
              title: Text(
                '$flag${place.name}',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(fontWeight: FontWeight.w600),
              ),
              subtitle: Text(
                subtitle,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
            );
          },
          onSelected: (place) {
            _closeSearchOverlay();
            _goToPlace(place);
          },
          onClose: _closeSearchOverlay,
        );
      },
    );
  }

  void _openSearchOverlay() {
    if (_searchOverlay != null) return;

    _searchCtl.clear();
    _searchResults = [];
    _isSearching = false;

    _searchOverlay = _buildSearchOverlay();
    Overlay.of(context).insert(_searchOverlay!);

    Future.microtask(() => _searchFocusNode.requestFocus());
  }

  void _closeSearchOverlay() {
    _searchDebounce?.cancel();
    // Drop any in-flight response.
    _searchRequestId++;
    _searchOverlay?.remove();
    _searchOverlay = null;
    _searchFocusNode.unfocus();
  }

  Future<void> _performLocationSearch(String query) async {
    final int requestId = ++_searchRequestId;

    if (query.trim().isEmpty) {
      _searchResults = [];
      _isSearching = false;
      _searchOverlay?.markNeedsBuild();
      return;
    }

    _isSearching = true;
    _searchOverlay?.markNeedsBuild();

    final results = await context.read<TrainlogProvider>().searchLocation(
          query,
          visibleBounds: _mapController.camera.visibleBounds,
          languageCode:
              context.read<SettingsProvider>().locale.languageCode,
        );

    if (!mounted || _searchOverlay == null || requestId != _searchRequestId) {
      return;
    }

    _searchResults = results;
    _isSearching = false;
    _searchOverlay?.markNeedsBuild();
  }

  void _goToPlace(LocationSearchResult place) {
    final extent = place.extent;
    if (extent != null &&
        extent.north > extent.south &&
        extent.east > extent.west) {
      _mapController.fitCamera(
        CameraFit.bounds(
          bounds: extent,
          padding: const EdgeInsets.all(48),
          maxZoom: 17,
        ),
      );
    } else {
      _mapController.move(place.point, place.category.focusZoom);
    }

    setState(() {
      _followUser = false;
      _searchedPlace = place;
    });
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
    return AppPrimaryAction(
      icon: AdaptiveIcons.filter, // add if missing
      tooltip: AppLocalizations.of(context)!.filterButton,
      onPressed: _openFilterSheet,
    );
  }

  void _openFilterSheet() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      useRootNavigator: true,
      backgroundColor: Colors.transparent,
      builder: (sheetContext) => MapFilterWidget(
        onClose: () => Navigator.of(sheetContext).pop(),
      ),
    );
  }
}
