import 'dart:async';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:geolocator/geolocator.dart';
import 'package:latlong2/latlong.dart';
import 'package:trainlog_app/core/providers/settings_provider.dart';
import 'package:trainlog_app/core/services/geo_permission_service.dart';
import 'package:trainlog_app/features/map/map_page_controller.dart';
import 'package:trainlog_app/utils/location_utils.dart';

/// The device's position for the map page: permission through
/// [GeoPermissionService], the last position kept in [SettingsProvider].
class DeviceMapLocationSource implements MapLocationSource {
  DeviceMapLocationSource(
    this._settings, [
    this._geo = const GeoPermissionService(),
  ]);

  final SettingsProvider _settings;
  final GeoPermissionService _geo;

  @override
  Future<bool> hasPermission() => _geo.hasPermission();

  @override
  Future<bool> requestPermission() => _geo.requestPermission(_settings);

  @override
  Future<LatLng?> currentPosition() => _geo.getCurrentPositionOrNull();

  @override
  LatLng? get lastKnownPosition => _settings.userPosition;

  @override
  void rememberPosition(LatLng position) =>
      _settings.setLastUserPosition(position);

  @override
  Stream<LatLng> positionUpdates() {
    // geolocator_windows emits position stream events from a non-platform
    // thread, which Flutter reports as an error and may drop or crash on.
    // Poll single fixes instead on Windows.
    if (!kIsWeb && Platform.isWindows) return _pollOnWindows();

    return Geolocator.getPositionStream(
      locationSettings: platformLocationSettings().copyWith(distanceFilter: 10),
    ).map((pos) => LatLng(pos.latitude, pos.longitude));
  }

  Stream<LatLng> _pollOnWindows() {
    Timer? timer;
    late final StreamController<LatLng> out;
    out = StreamController<LatLng>(
      onListen: () {
        timer = Timer.periodic(const Duration(seconds: 15), (_) async {
          final p = await _geo.getCurrentPositionOrNull();
          if (p != null && !out.isClosed) out.add(p);
        });
      },
      onCancel: () {
        timer?.cancel();
        return out.close();
      },
    );
    return out.stream;
  }
}
