import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:trainlog_app/utils/platform_utils.dart';

class AdaptivePageRoute {
  static void push(
    BuildContext context,
    WidgetBuilder builder,
  ) {
    if (AppPlatform.isApple) {
      Navigator.of(context).push(
        CupertinoPageRoute(builder: builder),
      );
    } else {
      Navigator.push(
        context,
        MaterialPageRoute(builder: builder),
      );
    }
  }
}
