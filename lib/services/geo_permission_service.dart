import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:geolocator/geolocator.dart';
import 'package:latlong2/latlong.dart';
import 'package:trainlog_app/providers/settings_provider.dart';
import 'package:trainlog_app/utils/location_utils.dart';

/// Centralises all device-level location permission and access logic.
///
/// This is the single place that talks to the operating system about
/// location permissions. Widgets should go through this service instead of
/// calling [Geolocator] permission APIs directly, so that the related
/// configuration in [SettingsProvider] (notably
/// [SettingsProvider.refusedToSharePosition]) stays consistent everywhere.
class GeoPermissionService {
  const GeoPermissionService();

  /// Platforms on which the OS can present a permission dialog. On
  /// unsupported platforms we never attempt to prompt.
  bool get canShowSystemPrompt =>
      kIsWeb || Platform.isAndroid || Platform.isIOS || Platform.isMacOS;

  /// Reads the current device-level permission status without prompting.
  Future<LocationPermission> checkPermission() => Geolocator.checkPermission();

  /// Whether location access is currently granted, checked silently.
  ///
  /// This never shows a system prompt and is safe to call on screen load.
  Future<bool> hasPermission() async {
    return _isGranted(await Geolocator.checkPermission());
  }

  /// Requests location permission from the operating system.
  ///
  /// Should only be invoked as the result of an explicit user action (e.g.
  /// tapping "Activate location", the recenter button, or enabling the
  /// location marker). Updates [settings.refusedToSharePosition] to reflect
  /// the outcome: cleared when access is granted, set when the user declines.
  ///
  /// Returns `true` if access is granted.
  Future<bool> requestPermission(SettingsProvider settings) async {
    var p = await Geolocator.checkPermission();
    if (_isGranted(p)) {
      if (settings.refusedToSharePosition) {
        settings.setRefusedToSharePosition(false);
      }
      return true;
    }

    if (!canShowSystemPrompt) return false;

    p = await Geolocator.requestPermission();
    final granted = _isGranted(p);
    settings.setRefusedToSharePosition(!granted);
    return granted;
  }

  /// Records that the user explicitly declined to share their position
  /// without going through a system prompt (e.g. the onboarding "Skip"
  /// action).
  void declineSharing(SettingsProvider settings) {
    settings.setRefusedToSharePosition(true);
  }

  /// Returns the current position if location services are enabled and a fix
  /// can be obtained, otherwise `null`. Does not request permission.
  Future<LatLng?> getCurrentPositionOrNull() async {
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

  bool _isGranted(LocationPermission p) =>
      p == LocationPermission.always || p == LocationPermission.whileInUse;
}
