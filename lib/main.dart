import 'dart:async';

import 'package:firebase_crashlytics/firebase_crashlytics.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';

import 'package:trainlog_app/app/app_providers.dart';
import 'package:trainlog_app/navigation/platform_shell.dart';
import 'package:trainlog_app/providers/settings_provider.dart';
import 'package:trainlog_app/providers/trainlog_provider.dart';
import 'package:trainlog_app/services/api/trainlog_http_client.dart';
import 'package:trainlog_app/services/secure_cookie_storage.dart';
import 'package:trainlog_app/utils/cached_data_utils.dart';

import 'package:firebase_core/firebase_core.dart';
import 'package:trainlog_app/utils/platform_utils.dart';
import 'package:trainlog_app/utils/timezone_utils.dart';
import 'firebase_options.dart';

import 'package:country_codes_plus/country_codes_plus.dart';

bool _isOsmTileNetworkError(Object error) {
  final msg = error.toString();
  return msg.contains('tile.openstreetmap.org') &&
      (msg.contains('SocketException') || msg.contains('ClientException'));
}

Future<void> _initFirebase() async {
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  if (!kIsWeb &&
      (defaultTargetPlatform == TargetPlatform.android ||
      defaultTargetPlatform == TargetPlatform.iOS)) {

    FlutterError.onError = (errorDetails) {
      if (_isOsmTileNetworkError(errorDetails.exception)) return;
      FirebaseCrashlytics.instance.recordFlutterFatalError(errorDetails);
    };

    PlatformDispatcher.instance.onError = (error, stack) {
      if (_isOsmTileNetworkError(error)) return true;
      FirebaseCrashlytics.instance.recordError(error, stack, fatal: true);
      return true;
    };
  }
}

// Everything awaited before runApp keeps the native splash screen on, so only
// local work belongs here, run in parallel where possible. Network calls (the
// session check) and the timezone database are deferred until after the
// first frame.
Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Starts loading the persisted settings immediately.
  final settings = SettingsProvider();

  // Settings must be fully loaded before reading the persisted username,
  // instance URL and install flags below. Cache paths are needed by the
  // local database.
  await Future.wait([
    _initFirebase(),
    AppCacheFilePath.init(),
    settings.ready,
  ]);

  // The iOS Keychain survives uninstall, so leftover session cookies would
  // log a reinstalled app straight back in. SharedPreferences do get wiped
  // on uninstall: both flags missing means fresh install. (Checking
  // onboardingCompleted too keeps users updating from a pre-flag version
  // logged in.) Must complete before the cookie jar below reads them.
  if (!settings.hasRunBefore && !settings.onboardingCompleted) {
    await SecureCookieStorage.clearAllCookies();
  }

  // Talk to the instance the user logged in to, otherwise the session check
  // would run against the default server and always fail for other ones.
  final savedInstanceUrl = settings.lastUsedInstanceUrl;
  final clientFuture = TrainlogHttpClient.persistent(
    baseUrl: (savedInstanceUrl == null || savedInstanceUrl.isEmpty)
        ? TrainlogHttpClient.urlLegacy
        : savedInstanceUrl,
  );
  await Future.wait([
    clientFuture,
    settings.markHasRunBefore(),
    if (AppPlatform.isMobile) CountryCodes.init(settings.locale),
  ]);

  final auth = TrainlogProvider(client: await clientFuture);
  // Not awaited: the session check goes over the network. HomeGate shows the
  // loading screen until it completes (bounded by the HTTP timeouts).
  unawaited(auth.tryRestoreSession(settings: settings));

  LicenseRegistry.addLicense(() async* {
    final licenseText = await rootBundle.loadString('assets/licenses/lottie_simple.txt');
    yield LicenseEntryWithLineBreaks(
      ['LottieFiles (animations)'],
      'App and Trip Loading animation by LK Jing.\n'
      'New Trip Loading animation by Igor Tcherepoff.\n\n$licenseText',
    );
  });

  runApp(
    AppProviders(
      settings: settings,
      auth: auth,
      signedInBuilder: (_) => const PlatformShell(),
    ),
  );

  // Only needed by the trip forms, which load it on demand if this hasn't
  // run yet.
  WidgetsBinding.instance.addPostFrameCallback((_) => TimeZones.ensureInitialized());
}
