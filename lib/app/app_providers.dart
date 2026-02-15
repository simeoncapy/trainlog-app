import 'package:flutter/widgets.dart';
import 'package:provider/provider.dart';

import 'package:trainlog_app/app/app_root.dart';
import 'package:trainlog_app/providers/polyline_provider.dart';
import 'package:trainlog_app/providers/settings_provider.dart';
import 'package:trainlog_app/providers/trainlog_provider.dart';
import 'package:trainlog_app/providers/trips_provider.dart';

class AppProviders extends StatelessWidget {
  final SettingsProvider settings;
  final TrainlogProvider auth;

  /// This is the widget you want to show when the user is authenticated,
  /// e.g. (_) => const MyApp()
  final WidgetBuilder signedInBuilder;

  const AppProviders({
    super.key,
    required this.settings,
    required this.auth,
    required this.signedInBuilder,
  });

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider<SettingsProvider>.value(value: settings),
        ChangeNotifierProvider<TrainlogProvider>.value(value: auth),

        ChangeNotifierProxyProvider2<TrainlogProvider, SettingsProvider, TripsProvider>(
          create: (_) => TripsProvider(),
          update: (_, auth, settings, trips) {
            final instance = trips ?? TripsProvider();
            instance.updateDeps(
              service: auth.service,
              settings: settings,
              username: auth.username,
            );
            return instance;
          },
        ),

        ChangeNotifierProxyProvider2<TripsProvider, SettingsProvider, PolylineProvider>(
          create: (_) => PolylineProvider(),
          update: (_, trips, settings, poly) {
            final instance = poly ?? PolylineProvider();
            instance.updateDependencies(trips: trips, settings: settings);
            return instance;
          },
        ),
      ],
      child: AppRoot(signedInBuilder: signedInBuilder),
    );
  }
}
