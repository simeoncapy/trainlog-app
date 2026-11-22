import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:trainlog_app/utils/platform_utils.dart';

class AdaptivePageRoute {
  static void push(
    BuildContext context,
    WidgetBuilder builder,
  ) {
    Navigator.of(context).push(route(builder));
  }

  /// The platform's page route, for callers that already hold a
  /// [NavigatorState] — e.g. when the pushing widget's own context is about to
  /// go away (a modal sheet closing itself before opening a page).
  static Route<T> route<T>(WidgetBuilder builder) {
    return AppPlatform.isApple
        ? CupertinoPageRoute<T>(builder: builder)
        : MaterialPageRoute<T>(builder: builder);
  }
}
