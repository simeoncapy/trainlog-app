import 'package:firebase_crashlytics/firebase_crashlytics.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:timezone/data/latest.dart' as tz;

import 'package:trainlog_app/app/app_providers.dart';
import 'package:trainlog_app/navigation/platform_shell.dart';
import 'package:trainlog_app/providers/settings_provider.dart';
import 'package:trainlog_app/providers/trainlog_provider.dart';
import 'package:trainlog_app/services/api/trainlog_http_client.dart';
import 'package:trainlog_app/services/secure_cookie_storage.dart';
import 'package:trainlog_app/utils/cached_data_utils.dart';

import 'package:firebase_core/firebase_core.dart';
import 'package:trainlog_app/utils/platform_utils.dart';
import 'firebase_options.dart';

import 'package:country_codes_plus/country_codes_plus.dart';

bool _isOsmTileNetworkError(Object error) {
  final msg = error.toString();
  return msg.contains('tile.openstreetmap.org') &&
      (msg.contains('SocketException') || msg.contains('ClientException'));
}

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

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

  await AppCacheFilePath.init();
  tz.initializeTimeZones();

  final settings = SettingsProvider();
  // Settings must be fully loaded before tryRestoreSession reads the
  // persisted username and instance URL.
  await settings.ready;

  // The iOS Keychain survives uninstall, so leftover session cookies would
  // log a reinstalled app straight back in. SharedPreferences do get wiped
  // on uninstall: both flags missing means fresh install. (Checking
  // onboardingCompleted too keeps users updating from a pre-flag version
  // logged in.)
  if (!settings.hasRunBefore && !settings.onboardingCompleted) {
    await SecureCookieStorage.clearAllCookies();
  }
  await settings.markHasRunBefore();

  final client = await TrainlogHttpClient.persistent();
  final auth = TrainlogProvider(client: client);
  await auth.tryRestoreSession(settings: settings);

  if (AppPlatform.isMobile) await CountryCodes.init(settings.locale);

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
}
