import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:geolocator/geolocator.dart';
// import 'package:latlong2/latlong.dart';
// import 'package:trainlog_app/providers/settings_provider.dart';


LocationSettings platformLocationSettings() {
  if (kIsWeb) {
    return WebSettings(accuracy: LocationAccuracy.high, distanceFilter: 0);
  }
  if (Platform.isAndroid) {
    return AndroidSettings(accuracy: LocationAccuracy.high, distanceFilter: 0);
  }
  if (Platform.isIOS || Platform.isMacOS) {
    return AppleSettings(accuracy: LocationAccuracy.high, distanceFilter: 0);
  }
  return const LocationSettings(accuracy: LocationAccuracy.high, distanceFilter: 0);
}

extension LocationSettingsCopy on LocationSettings {
  LocationSettings copyWith({
    LocationAccuracy? accuracy,
    int? distanceFilter,
    Duration? timeLimit,
  }) {
    // Web
    if (kIsWeb && this is WebSettings) {
      final s = this as WebSettings;
      return WebSettings(
        accuracy: accuracy ?? s.accuracy,
        distanceFilter: distanceFilter ?? s.distanceFilter,
        timeLimit: timeLimit ?? s.timeLimit,
      );
    }

    // Android
    if (!kIsWeb && Platform.isAndroid && this is AndroidSettings) {
      final s = this as AndroidSettings;
      return AndroidSettings(
        accuracy: accuracy ?? s.accuracy,
        distanceFilter: distanceFilter ?? s.distanceFilter,
        timeLimit: timeLimit ?? s.timeLimit,
        // Keep existing platform-specific fields if you ever set them:
        forceLocationManager: s.forceLocationManager,
        intervalDuration: s.intervalDuration,
        foregroundNotificationConfig: s.foregroundNotificationConfig,
      );
    }

    // Apple (iOS/macOS)
    if (!kIsWeb && (Platform.isIOS || Platform.isMacOS) && this is AppleSettings) {
      final s = this as AppleSettings;
      return AppleSettings(
        accuracy: accuracy ?? s.accuracy,
        distanceFilter: distanceFilter ?? s.distanceFilter,
        timeLimit: timeLimit ?? s.timeLimit,
        // Keep existing Apple-specific fields if you ever set them:
        activityType: s.activityType,
        pauseLocationUpdatesAutomatically: s.pauseLocationUpdatesAutomatically,
        showBackgroundLocationIndicator: s.showBackgroundLocationIndicator,
        allowBackgroundLocationUpdates: s.allowBackgroundLocationUpdates,
      );
    }

    // Fallback (generic)
    return LocationSettings(
      accuracy: accuracy ?? this.accuracy,
      distanceFilter: distanceFilter ?? this.distanceFilter,
      timeLimit: timeLimit ?? this.timeLimit,
    );
  }
}