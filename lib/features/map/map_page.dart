import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:lottie/lottie.dart' as lt;
import 'package:provider/provider.dart';
import 'package:trainlog_app/core/providers/polyline_provider.dart';
import 'package:trainlog_app/core/providers/settings_provider.dart';
import 'package:trainlog_app/core/data/models/location_search_result.dart';
import 'package:trainlog_app/core/providers/trainlog_provider.dart';
import 'package:trainlog_app/features/map/cupertino/map_cupertino_view.dart';
import 'package:trainlog_app/features/map/filter/map_filter_sheet.dart';
import 'package:trainlog_app/features/map/location_category_icons.dart';
import 'package:trainlog_app/features/map/map_location_source.dart';
import 'package:trainlog_app/features/map/map_page_controller.dart';
import 'package:trainlog_app/features/map/material/map_material_view.dart';
import 'package:trainlog_app/features/map/widgets/map_controls.dart';
import 'package:trainlog_app/features/trips_add/open_add_trip_wizard.dart';
import 'package:trainlog_app/l10n/app_localizations.dart';
import 'package:trainlog_app/navigation/nav_models.dart';
import 'package:trainlog_app/ui/adaptive/adaptive_sheet.dart';
import 'package:trainlog_app/ui/design.dart';
import 'package:trainlog_app/utils/platform_utils.dart';

/// What the map page views can ask the page for.
class MapPageActions {
  const MapPageActions({
    required this.mapController,
    required this.rotation,
    required this.openFilter,
    required this.resetOrientation,
  });

  /// The flutter_map camera, owned by the page.
  final MapController mapController;

  /// Map rotation in degrees, for the compass.
  final ValueNotifier<double> rotation;

  /// Opens the map filter sheet.
  final VoidCallback openFilter;

  /// Turns the map back to north up.
  final VoidCallback resetOrientation;
}

/// Map page entry: holds the [MapPageController] and the map's camera,
/// shows the loading animation while the trips' paths load, hands the shell
/// the "New trip" action, then picks the Material or iOS view.
class MapPage extends StatefulWidget {
  /// Android: show the "New trip" FAB with its label (extended FAB) or as a
  /// plain round + button. iOS always shows a round + in the tab bar.
  static const bool newTripFabShowsLabel = true;

  final SetPrimaryActions onPrimaryActionsReady;

  const MapPage({super.key, required this.onPrimaryActionsReady});

  @override
  State<MapPage> createState() => _MapPageState();
}

class _MapPageState extends State<MapPage>
    with WidgetsBindingObserver, AutomaticKeepAliveClientMixin {
  final MapController _mapController = MapController();
  final ValueNotifier<double> _rotation = ValueNotifier(0.0);
  late final MapPageController _controller;
  late final StreamSubscription<MapCameraRequest> _cameraSub;

  @override
  bool get wantKeepAlive => true;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);

    final settings = context.read<SettingsProvider>();
    _controller = MapPageController(
      location: DeviceMapLocationSource(settings),
      search: _searchPlaces,
    );
    _cameraSub = _controller.cameraRequests.listen(_moveCamera);
    _controller.start();

    // kick loading once providers exist
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<PolylineProvider>().ensureLoaded();
      widget.onPrimaryActionsReady([_newTripAction()]);
    });
  }

  @override
  void dispose() {
    _cameraSub.cancel();
    _controller.dispose();
    _rotation.dispose();
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      _controller.resume();
    } else if (state == AppLifecycleState.paused) {
      _controller.pause();
    }
  }

  /// Searches around what the map shows, in the app's language.
  Future<List<LocationSearchResult>> _searchPlaces(String query) {
    return context.read<TrainlogProvider>().searchLocation(
      query,
      visibleBounds: _mapController.camera.visibleBounds,
      languageCode: context.read<SettingsProvider>().locale.languageCode,
    );
  }

  void _moveCamera(MapCameraRequest request) {
    switch (request) {
      case MapCameraMove(:final point, :final zoom):
        _mapController.move(point, zoom);
      case MapCameraShowPlace(:final place):
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
    }
  }

  void _resetOrientation() {
    _mapController.rotate(0);
    _rotation.value = 0;
  }

  void _openFilter() {
    showAdaptiveContentSheet<void>(
      context: context,
      useRootNavigator: true,
      materialBackgroundColor: Colors.transparent,
      appleHeaderBesideGrabber: true,
      builder: (sheetContext) =>
          MapFilterSheet(onClose: () => Navigator.of(sheetContext).pop()),
    );
  }

  AppPrimaryAction _newTripAction() {
    final loc = AppLocalizations.of(context)!;
    return AppPrimaryAction(
      icon: AdaptiveIcons.add,
      tooltip: loc.tripsAddButton,
      label: MapPage.newTripFabShowsLabel ? loc.tripsAddButton : null,
      onPressed: () => openAddTripWizard(context),
    );
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    final isLoading = context.select((PolylineProvider p) => p.isLoading);

    // No "New trip" button while the paths load.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      widget.onPrimaryActionsReady(isLoading ? const [] : [_newTripAction()]);
    });

    if (isLoading) return const _MapLoadingView();

    final actions = MapPageActions(
      mapController: _mapController,
      rotation: _rotation,
      openFilter: _openFilter,
      resetOrientation: _resetOrientation,
    );

    return ChangeNotifierProvider.value(
      value: _controller,
      child: PlatformView(
        material: (_) => MapMaterialView(actions: actions),
        cupertino: (_) => MapCupertinoView(actions: actions),
      ),
    );
  }
}

/// Shown while the trips' paths load.
class _MapLoadingView extends StatelessWidget {
  const _MapLoadingView();

  @override
  Widget build(BuildContext context) {
    final appLocalizations = AppLocalizations.of(context)!;
    return MapLoadingSafeArea(
      child: Center(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(8, 8, 8, 24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const SizedBox(height: 24),
              Text(
                appLocalizations.tripPathLoading,
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 16),
              Expanded(
                child: lt.Lottie.asset('assets/animations/loading.json'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
