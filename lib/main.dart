import 'package:firebase_crashlytics/firebase_crashlytics.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:timezone/data/latest.dart' as tz;

import 'package:trainlog_app/app/app_providers.dart';
import 'package:trainlog_app/navigation/platform_shell.dart';
import 'package:trainlog_app/providers/settings_provider.dart';
import 'package:trainlog_app/providers/trainlog_provider.dart';
import 'package:trainlog_app/services/trainlog_service.dart';
import 'package:trainlog_app/utils/cached_data_utils.dart';

import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';

bool _isOsmTileNetworkError(Object error) {
  final msg = error.toString();
  return msg.contains('tile.openstreetmap.org') &&
      (msg.contains('SocketException') || msg.contains('ClientException'));
}

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  // Pass all uncaught "fatal" errors from the framework to Crashlytics
  FlutterError.onError = (errorDetails) {
    if (_isOsmTileNetworkError(errorDetails.exception)) return;
    FirebaseCrashlytics.instance.recordFlutterFatalError(errorDetails);
  };
  // Pass all uncaught asynchronous errors that aren't handled by the Flutter framework to Crashlytics
  PlatformDispatcher.instance.onError = (error, stack) {
    if (_isOsmTileNetworkError(error)) return true;
    FirebaseCrashlytics.instance.recordError(error, stack, fatal: true);
    return true;
  };

  await AppCacheFilePath.init();
  tz.initializeTimeZones();

  final settings = SettingsProvider();

  final service = await TrainlogService.persistent();
  final auth = TrainlogProvider(service: service);
  await auth.tryRestoreSession(settings: settings);

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
