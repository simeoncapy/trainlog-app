import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:trainlog_app/features/trips_edit_copy/widgets/edit_trip_app_bar_title.dart';
import 'package:trainlog_app/ui/cupertino/liquid_glass.dart';

/// Trip form app bar, iOS: blends into the page with glass buttons; the
/// mode shows before the title: [modeIcon] in the mode colour, if any.
class CupertinoEditTripAppBar extends StatelessWidget
    implements PreferredSizeWidget {
  const CupertinoEditTripAppBar({
    super.key,
    required this.title,
    required this.subtitle,
    required this.tint,
    this.modeIcon,
    this.actionIcon,
    this.actionTooltip,
    this.onAction,
    this.actionDestructive = false,
  });

  final String title;
  final String? subtitle;
  final Color tint;
  final IconData? modeIcon;
  final IconData? actionIcon;
  final String? actionTooltip;
  final VoidCallback? onAction;
  final bool actionDestructive;

  static const double _height = 56;

  @override
  Size get preferredSize => const Size.fromHeight(_height);

  @override
  Widget build(BuildContext context) {
    final closeTooltip = MaterialLocalizations.of(context).closeButtonTooltip;
    void close() => Navigator.of(context).maybePop();

    // The tint is a translucent wash on Material; the mark needs it opaque.
    final accent = tint.withValues(alpha: 1);

    return ColoredBox(
      color: CupertinoTheme.of(context).scaffoldBackgroundColor,
      child: SafeArea(
        bottom: false,
        child: SizedBox(
          height: _height,
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
                    accentIcon: modeIcon,
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
