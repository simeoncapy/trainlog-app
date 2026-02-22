import 'package:flutter/material.dart';

final GlobalKey<ScaffoldMessengerState> rootScaffoldMessengerKey =
    GlobalKey<ScaffoldMessengerState>();
final GlobalKey<NavigatorState> rootNavigatorKey = GlobalKey<NavigatorState>();

class AppNavigator {
  static void pop<T extends Object?>([T? result]) {
    rootNavigatorKey.currentState?.pop(result);
  }
}