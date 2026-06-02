import 'package:country_picker/country_picker.dart';
import 'package:firebase_crashlytics/firebase_crashlytics.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import 'package:trainlog_app/app/app_colors.dart';
import 'package:trainlog_app/app/app_globals.dart';
import 'package:trainlog_app/app/app_theme.dart';
import 'package:trainlog_app/app/home_gate.dart';
import 'package:trainlog_app/l10n/app_localizations.dart';
import 'package:trainlog_app/providers/settings_provider.dart';
import 'package:trainlog_app/utils/platform_utils.dart';

class CrashlyticsNavigationObserver extends NavigatorObserver {
  @override
  void didPush(Route route, Route? previousRoute) {
    FirebaseCrashlytics.instance.log(
      'Navigated to ${route.settings.name}',
    );
  }

  @override
  void didPop(Route route, Route? previousRoute) {
    FirebaseCrashlytics.instance.log(
      'Popped ${route.settings.name}',
    );
  }
}

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
      navigatorKey: rootNavigatorKey,
      navigatorObservers: kDebugMode ? [] : [
        CrashlyticsNavigationObserver(),
      ],
      locale: settings.locale,
      localizationsDelegates: [
        ...AppLocalizations.localizationsDelegates,
        CountryLocalizations.delegate,
      ],
      supportedLocales: AppLocalizations.supportedLocales,
      theme: AppTheme.light,
      darkTheme: AppTheme.dark,
      themeMode: settings.themeMode,
      builder: (context, child) {
        final isDark = Theme.of(context).brightness == Brightness.dark;
        return AnnotatedRegion<SystemUiOverlayStyle>(
          value: isDark
              ? SystemUiOverlayStyle.light
              : const SystemUiOverlayStyle(
                  statusBarColor: Colors.transparent,
                  statusBarIconBrightness: Brightness.dark,
                  statusBarBrightness: Brightness.light,
                ),
          child: child!,
        );
      },
      home: HomeGate(signedInBuilder: signedInBuilder),
    );
  }

  Widget _buildCupertinoApp(SettingsProvider settings) {
    final brightness =
        settings.themeMode == ThemeMode.dark ? Brightness.dark : Brightness.light;

    return CupertinoApp(
      navigatorKey: rootNavigatorKey,
      locale: settings.locale,
      localizationsDelegates: [
        ...AppLocalizations.localizationsDelegates,
        CountryLocalizations.delegate,
      ],
      supportedLocales: AppLocalizations.supportedLocales,
      theme: CupertinoThemeData(
        brightness: brightness,
        primaryColor: const CupertinoDynamicColor.withBrightness(
          color: AppColors.amber,
          darkColor: AppColors.amber,
        ),
      ),

      builder: (_, child) {
        final themeData =
            brightness == Brightness.dark ? AppTheme.dark : AppTheme.light;
        return Theme(
          data: themeData,
          child: ScaffoldMessenger(
            key: rootScaffoldMessengerKey,
            child: child!,
          ),
        );
      },

      home: HomeGate(signedInBuilder: signedInBuilder),
    );
  }
}
