import 'package:country_picker/country_picker.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'package:trainlog_app/app/app_globals.dart';
import 'package:trainlog_app/app/home_gate.dart';
import 'package:trainlog_app/l10n/app_localizations.dart';
import 'package:trainlog_app/providers/settings_provider.dart';
import 'package:trainlog_app/utils/platform_utils.dart';

class AppRoot extends StatelessWidget {
  final WidgetBuilder signedInBuilder;

  const AppRoot({
    super.key,
    required this.signedInBuilder,
  });

  @override
  Widget build(BuildContext context) {
    return Consumer<SettingsProvider>(
      builder: (_, settings, __) {
        if (AppPlatform.isApple) {
          return _buildCupertinoApp(settings);
        }
        return _buildMaterialApp(settings);
      },
    );
  }

  Widget _buildMaterialApp(SettingsProvider settings) {
    return MaterialApp(
      scaffoldMessengerKey: rootScaffoldMessengerKey,
      locale: settings.locale,
      localizationsDelegates: [
        ...AppLocalizations.localizationsDelegates,
        CountryLocalizations.delegate,
      ],
      supportedLocales: AppLocalizations.supportedLocales,
      theme: ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(
          seedColor: Colors.blue,
          brightness: Brightness.light,
        ),
      ),
      darkTheme: ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(
          seedColor: Colors.blue,
          brightness: Brightness.dark,
        ),
      ),
      themeMode: settings.themeMode,
      home: HomeGate(signedInBuilder: signedInBuilder),
    );
  }

  Widget _buildCupertinoApp(SettingsProvider settings) {
    final brightness =
        settings.themeMode == ThemeMode.dark ? Brightness.dark : Brightness.light;

    return CupertinoApp(
      locale: settings.locale,
      localizationsDelegates: [
        ...AppLocalizations.localizationsDelegates,
        CountryLocalizations.delegate,
      ],
      supportedLocales: AppLocalizations.supportedLocales,
      theme: CupertinoThemeData(
        brightness: brightness,
        primaryColor: CupertinoColors.systemBlue,
      ),

      // Keep using the same ScaffoldMessengerKey for both apps.
      builder: (_, child) {
        return ScaffoldMessenger(
          key: rootScaffoldMessengerKey,
          child: child!,
        );
      },

      home: HomeGate(signedInBuilder: signedInBuilder),
    );
  }
}
