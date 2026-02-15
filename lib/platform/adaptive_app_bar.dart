import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:trainlog_app/utils/platform_utils.dart';

class AdaptiveAppBar extends StatelessWidget implements PreferredSizeWidget {
  final String title;
  final VoidCallback? onBack;
  final List<Widget> materialActions;
  final Widget? cupertinoTrailing; // use this if you want iOS-style trailing

  const AdaptiveAppBar({
    super.key,
    required this.title,
    this.onBack,
    this.materialActions = const [],
    this.cupertinoTrailing,
  });

  @override
  Size get preferredSize => Size.fromHeight(
        AppPlatform.isApple
            ? kMinInteractiveDimensionCupertino
            : kToolbarHeight,
      );

  @override
  Widget build(BuildContext context) {
    if (AppPlatform.isApple) {
      return CupertinoNavigationBar(
        middle: Text(title),
        leading: onBack == null
            ? null
            : CupertinoNavigationBarBackButton(
                onPressed: onBack,
              ),
        trailing: cupertinoTrailing,
      );
    }

    return AppBar(
      title: Text(title),
      leading: onBack == null
          ? null
          : IconButton(
              icon: const Icon(Icons.arrow_back),
              onPressed: onBack,
            ),
      actions: materialActions,
    );
  }
}
