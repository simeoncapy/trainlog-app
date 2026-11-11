import 'dart:io';

import 'package:device_info_plus/device_info_plus.dart';
import 'package:flutter/foundation.dart';
import 'package:package_info_plus/package_info_plus.dart';

/// User-Agent strings sent to the Trainlog server.
///
/// The server (and its Matomo analytics) classifies any request whose UA
/// contains `TrainlogApp/` as coming from the app, so that token must stay,
/// slash included. The rest of the HTTP UA mimics the system browser format
/// so Matomo can still detect the OS, its version and the device model.
///
/// Call [init] once at startup, before the HTTP client is created.
class AppUserAgent {
  static String _version = '0.0.0';
  static String? _http;

  /// Token appended to WebView UAs and used to classify traffic as "app".
  static String get token => 'TrainlogApp/$_version';

  /// Full UA for API requests (Dio). Falls back to [token] alone on
  /// platforms without a dedicated format, or before [init] completes.
  static String get http => _http ?? token;

  static Future<void> init() async {
    try {
      _version = (await PackageInfo.fromPlatform()).version;
      if (kIsWeb) return;
      final deviceInfo = DeviceInfoPlugin();
      if (Platform.isAndroid) {
        final a = await deviceInfo.androidInfo;
        _http = 'Mozilla/5.0 (Linux; Android ${a.version.release}; ${a.model}) $token';
      } else if (Platform.isIOS) {
        final i = await deviceInfo.iosInfo; // model is "iPhone" / "iPad"
        _http = 'Mozilla/5.0 (${i.model}; CPU ${i.model} OS '
            '${i.systemVersion.replaceAll('.', '_')} like Mac OS X) $token';
      }
      debugPrint('AppUserAgent.init: $_http');
    } catch (e) {
      // Keep the TrainlogApp/<version> fallback rather than block startup.
      debugPrint('AppUserAgent.init failed: $e');
    }
  }
}
