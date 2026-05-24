import 'package:flutter/material.dart';

final GlobalKey<ScaffoldMessengerState> rootScaffoldMessengerKey =
    GlobalKey<ScaffoldMessengerState>();
final GlobalKey<NavigatorState> rootNavigatorKey = GlobalKey<NavigatorState>();

/// Seed colour used for both the Material and Cupertino themes.
/// Change this once and all derived colours (including [kLightThemeSurface])
/// update automatically.
const Color kSeedColor = Colors.blue;

/// The surface colour of the light theme, derived from [kSeedColor].
/// Used as the logo-background colour in dark mode so operator logos
/// (designed for light backgrounds) remain legible.
final Color kLightThemeSurface = ColorScheme.fromSeed(
  seedColor: kSeedColor,
  brightness: Brightness.light,
).surface;

class AppNavigator {
  static void pop<T extends Object?>([T? result]) {
    rootNavigatorKey.currentState?.pop(result);
  }
}