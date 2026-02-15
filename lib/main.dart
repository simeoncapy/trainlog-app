import 'package:flutter/widgets.dart';
import 'package:timezone/data/latest.dart' as tz;

import 'package:trainlog_app/app/app_providers.dart';
import 'package:trainlog_app/navigation/platform_shell.dart';
import 'package:trainlog_app/providers/settings_provider.dart';
import 'package:trainlog_app/providers/trainlog_provider.dart';
import 'package:trainlog_app/services/trainlog_service.dart';
import 'package:trainlog_app/utils/cached_data_utils.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await AppCacheFilePath.init();
  tz.initializeTimeZones();

  final settings = SettingsProvider();

  final service = await TrainlogService.persistent();
  final auth = TrainlogProvider(service: service);
  await auth.tryRestoreSession(settings: settings);

  runApp(
    AppProviders(
      settings: settings,
      auth: auth,
      signedInBuilder: (_) => const PlatformShell(),
    ),
  );
}
