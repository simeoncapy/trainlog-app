import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:trainlog_app/features/trips_edit_copy/widgets/edit_trip_app_bar_title.dart';
import 'package:trainlog_app/platform/liquid_glass.dart';
import 'package:trainlog_app/utils/platform_utils.dart';

/// App bar of the trip form pages (edit, duplicate, Geolog note): a close
/// button, the [EditTripAppBarTitle] and an optional trailing action.
///
/// Material keeps a bar tinted with [tint] to tell the modes apart. On Apple
/// the bar blends into the page with glass buttons, and the mode colour shows
/// as a small dot before the title instead.
class EditTripAppBar extends StatelessWidget implements PreferredSizeWidget {
  const EditTripAppBar({
    super.key,
    required this.title,
    required this.subtitle,
    required this.tint,
    this.actionIcon,
    this.actionTooltip,
    this.onAction,
    this.actionDestructive = false,
  });

  final String title;
  final String? subtitle;

  /// Mode colour: the Material bar background, the Apple title dot.
  final Color tint;

  final IconData? actionIcon;
  final String? actionTooltip;
  final VoidCallback? onAction;

  /// Shows the Apple action in the destructive (red) colour.
  final bool actionDestructive;

  static const double _appleHeight = 56;

  @override
  Size get preferredSize =>
      Size.fromHeight(AppPlatform.isApple ? _appleHeight : kToolbarHeight);

  @override
  Widget build(BuildContext context) {
    final closeTooltip = MaterialLocalizations.of(context).closeButtonTooltip;
    void close() => Navigator.of(context).maybePop();

    if (!AppPlatform.isApple) {
      return AppBar(
        centerTitle: true,
        titleSpacing: 0,
        leading: IconButton(
          icon: const Icon(Icons.close),
          tooltip: closeTooltip,
          onPressed: close,
        ),
        title: EditTripAppBarTitle(title: title, subtitle: subtitle),
        actions: [
          if (actionIcon != null)
            IconButton(
              icon: Icon(actionIcon),
              tooltip: actionTooltip,
              onPressed: onAction,
            ),
        ],
        backgroundColor: tint,
      );
    }

    // The tint is a translucent wash on Material; the dot needs it opaque.
    final accent = tint.withValues(alpha: 1);

    return ColoredBox(
      color: CupertinoTheme.of(context).scaffoldBackgroundColor,
      child: SafeArea(
        bottom: false,
        child: SizedBox(
          height: _appleHeight,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              children: [
                GlassIconButton(
                  icon: CupertinoIcons.xmark,
                  size: 40,
                  iconSize: 17,
                  tooltip: closeTooltip,
                  onPressed: close,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: EditTripAppBarTitle(
                    title: title,
                    subtitle: subtitle,
                    accent: accent,
                  ),
                ),
                const SizedBox(width: 8),
                if (actionIcon != null)
                  GlassIconButton(
                    icon: actionIcon!,
                    size: 40,
                    iconSize: 18,
                    color: actionDestructive
                        ? CupertinoColors.systemRed.resolveFrom(context)
                        : null,
                    tooltip: actionTooltip,
                    onPressed: onAction,
                  )
                else
                  // Keeps the title centred.
                  const SizedBox(width: 40),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
