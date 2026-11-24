import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:trainlog_app/ui/tokens/app_theme.dart';
import 'package:trainlog_app/core/providers/settings_provider.dart';
import 'package:trainlog_app/utils/platform_utils.dart';

/// Brightness of the map, from the "Map theme" setting: light, dark, or the
/// same as the app ([ThemeMode.system]), on every platform.
///
/// Read it above any [MapThemeScope] to get the app's brightness for "same
/// as app"; inside one both are equal anyway.
Brightness mapBrightness(BuildContext context) {
  final mode = context.select<SettingsProvider, ThemeMode>(
    (s) => s.mapThemeMode,
  );
  return switch (mode) {
    ThemeMode.dark => Brightness.dark,
    ThemeMode.light => Brightness.light,
    ThemeMode.system => Theme.of(context).brightness,
  };
}

/// Apple only: themes its subtree (the map page's buttons, the tab bar over
/// the map, and sheets opened from the map) with the map's brightness rather
/// than the app's, so the glass chrome reads well over the tiles. Android
/// keeps the app theme everywhere.
class MapThemeScope extends StatelessWidget {
  const MapThemeScope({super.key, required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    if (!AppPlatform.isApple) return child;
    final brightness = mapBrightness(context);
    if (brightness == Theme.of(context).brightness &&
        CupertinoTheme.brightnessOf(context) == brightness) {
      return child;
    }
    return Theme(
      data: brightness == Brightness.dark ? AppTheme.dark : AppTheme.light,
      // Inside the Material theme, which would otherwise derive a plain
      // Cupertino theme and lose the app's colours.
      child: CupertinoTheme(data: AppTheme.cupertino(brightness), child: child),
    );
  }
}
