import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:trainlog_app/platform/liquid_glass.dart';
import 'package:trainlog_app/platform/widget/adaptive_app_bar_square_button.dart';
import 'package:trainlog_app/utils/platform_utils.dart';

class AdaptiveAppBar extends StatelessWidget implements PreferredSizeWidget {
  final String title;

  /// Optional rich title rendered instead of [title] (e.g. a flag + name row).
  /// When provided, [title] is ignored for display.
  final Widget? titleWidget;
  final VoidCallback? onBack;
  final List<Widget> materialActions;
  final Widget? cupertinoTrailing; // use this if you want iOS-style trailing

  const AdaptiveAppBar({
    super.key,
    required this.title,
    this.titleWidget,
    this.onBack,
    this.materialActions = const [],
    this.cupertinoTrailing,
  });

  @override
  Size get preferredSize => Size.fromHeight(
        AppPlatform.isApple
            ? kMinInteractiveDimensionCupertino + 8
            : kToolbarHeight,
      );

  /// Square back button matching the size used by [AdaptiveAppBarSquareButton]
  /// elsewhere (e.g. the menu page top bar).
  Widget _backButton(BuildContext context) {
    return AdaptiveAppBarSquareButton(
      icon: Icons.chevron_left,
      onPressed: onBack!,
      tooltip: MaterialLocalizations.of(context).backButtonTooltip,
    );
  }

  @override
  Widget build(BuildContext context) {
    if (AppPlatform.isApple) {
      // iOS 26: no hairline, the bar blends into the page and its controls
      // float as glass buttons.
      return CupertinoNavigationBar(
        backgroundColor: CupertinoTheme.of(context).scaffoldBackgroundColor,
        border: null,
        padding: const EdgeInsetsDirectional.symmetric(horizontal: 12),
        middle: titleWidget ?? Text(title),
        leading: onBack == null
            ? null
            : Center(
                widthFactor: 1,
                child: GlassIconButton(
                  icon: CupertinoIcons.chevron_back,
                  size: 40,
                  shadow: false,
                  onPressed: onBack,
                  tooltip: MaterialLocalizations.of(context).backButtonTooltip,
                ),
              ),
        trailing: cupertinoTrailing,
      );
    }

    return AppBar(
      title: titleWidget ?? Text(title),
      leading: onBack == null ? null : Center(child: _backButton(context)),
      actions: materialActions,
    );
  }
}
