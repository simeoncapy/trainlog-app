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