import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:latlong2/latlong.dart';
import 'package:trainlog_app/core/data/models/location_search_result.dart';

/// Where the map page gets the user's position from: the device, through
/// [GeoPermissionService] and the settings (see `DeviceMapLocationSource`),
/// or a fake in tests.
abstract class MapLocationSource {
  /// Whether location access is granted, checked without prompting.
  Future<bool> hasPermission();

  /// Asks the system for location access. Only after a user action.
  Future<bool> requestPermission();

  /// A fresh fix, or null when none can be had.
  Future<LatLng?> currentPosition();

  /// The position as the user moves.
  Stream<LatLng> positionUpdates();

  /// The last position remembered by the app, if any.
  LatLng? get lastKnownPosition;

  /// Remembers [position] for the next launch.
  void rememberPosition(LatLng position);
}

/// Runs a place search for [query] around what the map shows.
typedef MapPlaceSearcher =
    Future<List<LocationSearchResult>> Function(String query);

/// A camera move asked by the controller, done by the view that owns the
/// map.
sealed class MapCameraRequest {
  const MapCameraRequest();
}

/// Centre the map on [point] at [zoom].
class MapCameraMove extends MapCameraRequest {
  const MapCameraMove(this.point, this.zoom);
  final LatLng point;
  final double zoom;
}

/// Show [place]: its whole extent when it is an area, else its point at the
/// zoom of its category.
class MapCameraShowPlace extends MapCameraRequest {
  const MapCameraShowPlace(this.place);
  final LocationSearchResult place;
}

/// State and actions of the map page, shared by its Material and iOS views:
/// the user's position and the "follow me" mode, the place search, and the
/// place picked in it (shown with a pin).
///
/// The map itself (tiles, layers, camera) stays in the view; this
/// controller asks it to move through [cameraRequests] and is told where it
/// is with [onCameraChanged].
class MapPageController extends ChangeNotifier {
  MapPageController({
    required MapLocationSource location,
    required MapPlaceSearcher search,
    this.searchDebounce = const Duration(milliseconds: 350),
  }) : _location = location,
       _search = search,
       _center = location.lastKnownPosition ?? greenwich;

  /// Where the map opens when no position is known.
  static const LatLng greenwich = LatLng(51.476852, -0.0005);
  static const double defaultZoom = 13.0;

  final MapLocationSource _location;
  final MapPlaceSearcher _search;

  /// Wait after the last keystroke before searching.
  final Duration searchDebounce;

  final _camera = StreamController<MapCameraRequest>.broadcast();
  StreamSubscription<LatLng>? _positionSub;
  Timer? _debounce;
  int _searchRequestId = 0;
  bool _disposed = false;

  LatLng _center;
  double _zoom = defaultZoom;
  LatLng? _userPosition;
  bool _following = false;
  LocationSearchResult? _searchedPlace;

  String _query = '';
  List<LocationSearchResult> _results = const [];
  bool _isSearching = false;

  /// Camera moves for the view to do.
  Stream<MapCameraRequest> get cameraRequests => _camera.stream;

  /// Where the map is (or opens, before it is built).
  LatLng get center => _center;
  double get zoom => _zoom;

  /// The user's position, once known.
  LatLng? get userPosition => _userPosition;

  /// The map moves with the user.
  bool get following => _following;

  /// Place picked in the search, shown with a pin until tapped.
  LocationSearchResult? get searchedPlace => _searchedPlace;

  /// The search as typed.
  String get query => _query;
  List<LocationSearchResult> get results => _results;
  bool get isSearching => _isSearching;

  /// The place search is open.
  bool get searchOpen => _searchOpen;
  bool _searchOpen = false;

  /// A search was typed and found nothing.
  bool get hasNoResult =>
      !_isSearching && _results.isEmpty && _query.trim().isNotEmpty;

  // ── Location ──────────────────────────────────────────────────────────

  /// Page opened: centres on the live position when access is already
  /// granted (never prompts), then follows the position updates.
  Future<void> start() async {
    if (await _location.hasPermission()) {
      final current = await _location.currentPosition();
      if (_disposed) return;
      if (current != null) {
        _userPosition = current;
        _center = current;
        _location.rememberPosition(current);
        notifyListeners();
      }
    }
    await _startUpdates(requestInitialFix: false);
  }

  /// App back in the foreground.
  Future<void> resume() => _startUpdates();

  /// App in the background: stop listening to the position.
  Future<void> pause() => _stopUpdates();

  /// The map moved (gesture or camera request).
  void onCameraChanged(LatLng center, double zoom) {
    _center = center;
    _zoom = zoom;
  }

  /// Centres on the user, asking for access if needed. A second tap, when
  /// already centred, also resets the zoom.
  Future<void> recenter() async {
    final p = await _ensureUserPosition();
    if (p == null || _disposed) return;

    final zoom = _center == p ? defaultZoom : _zoom;
    _camera.add(MapCameraMove(p, zoom));
    _center = p;
    _zoom = zoom;
    notifyListeners();
  }

  /// Turns "follow me" on (asking for access if needed) or off.
  Future<void> toggleFollow() async {
    if (_following) {
      _following = false;
      notifyListeners();
      return;
    }

    final p = await _ensureUserPosition();
    if (p == null || _disposed) return;

    _camera.add(MapCameraMove(p, _zoom));
    _center = p;
    _following = true;
    notifyListeners();
  }

  Future<void> _startUpdates({bool requestInitialFix = true}) async {
    if (!await _location.hasPermission()) return;

    if (requestInitialFix) {
      final current = await _location.currentPosition();
      if (_disposed) return;
      if (current != null) {
        _userPosition = current;
        notifyListeners();
      }
    }

    await _stopUpdates();
    if (_disposed) return;
    _positionSub = _location.positionUpdates().listen(
      _onUserPosition,
      onError: (Object e) => debugPrint('Location stream error: $e'),
    );
  }

  void _onUserPosition(LatLng p) {
    if (_disposed) return;
    _userPosition = p;
    _location.rememberPosition(p);
    if (_following) {
      _camera.add(MapCameraMove(p, _zoom));
      _center = p;
    }
    notifyListeners();
  }

  Future<void> _stopUpdates() async {
    final sub = _positionSub;
    _positionSub = null;
    await sub?.cancel();
  }

  /// The position, asking for access first when there is none yet. Only
  /// from a user action (recenter, follow): this may prompt.
  Future<LatLng?> _ensureUserPosition() async {
    if (_userPosition != null) return _userPosition;

    if (!await _location.requestPermission() || _disposed) return null;
    final current = await _location.currentPosition();
    if (current == null || _disposed) return null;

    _location.rememberPosition(current);
    _userPosition = current;
    notifyListeners();
    await _startUpdates(requestInitialFix: false);
    return current;
  }

  // ── Place search ──────────────────────────────────────────────────────

  /// The search opens empty.
  void openSearch() {
    _searchOpen = true;
    _debounce?.cancel();
    _searchRequestId++;
    _query = '';
    _results = const [];
    _isSearching = false;
    notifyListeners();
  }

  /// The search closes: a pending or running search is dropped.
  void closeSearch() {
    _debounce?.cancel();
    _searchRequestId++;
    _isSearching = false;
    if (_searchOpen) {
      _searchOpen = false;
      if (!_disposed) notifyListeners();
    }
  }

  /// Typed: searches once typing pauses.
  void queryChanged(String query) {
    _query = query;
    _debounce?.cancel();
    _debounce = Timer(searchDebounce, () => _runSearch(query));
    notifyListeners();
  }

  /// Submitted: searches now.
  Future<void> submitQuery(String query) {
    _query = query;
    _debounce?.cancel();
    return _runSearch(query);
  }

  Future<void> _runSearch(String query) async {
    final requestId = ++_searchRequestId;

    if (query.trim().isEmpty) {
      _results = const [];
      _isSearching = false;
      notifyListeners();
      return;
    }

    _isSearching = true;
    notifyListeners();

    final results = await _search(query);
    // Closed, disposed or overtaken by a newer search: drop the answer.
    if (_disposed || requestId != _searchRequestId) return;

    _results = results;
    _isSearching = false;
    notifyListeners();
  }

  /// A result was picked: the map goes there, stops following the user, and
  /// shows a pin on it.
  void choosePlace(LocationSearchResult place) {
    closeSearch();
    _camera.add(MapCameraShowPlace(place));
    _following = false;
    _searchedPlace = place;
    notifyListeners();
  }

  /// The pin was tapped: it goes away.
  void clearSearchedPlace() {
    _searchedPlace = null;
    notifyListeners();
  }

  @override
  void dispose() {
    _disposed = true;
    _debounce?.cancel();
    _positionSub?.cancel();
    _camera.close();
    super.dispose();
  }
}
