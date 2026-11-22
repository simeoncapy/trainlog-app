import 'package:flutter/material.dart';
import 'package:trainlog_app/features/trips_edit_copy/widgets/edit_trip_app_bar_title.dart';

/// Trip form app bar, Material: tinted with [tint] to tell the modes apart.
class MaterialEditTripAppBar extends StatelessWidget
    implements PreferredSizeWidget {
  const MaterialEditTripAppBar({
    super.key,
    required this.title,
    required this.subtitle,
    required this.tint,
    this.actionIcon,
    this.actionTooltip,
    this.onAction,
  });

  final String title;
  final String? subtitle;
  final Color tint;
  final IconData? actionIcon;
  final String? actionTooltip;
  final VoidCallback? onAction;

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);

  @override
  Widget build(BuildContext context) {
    final closeTooltip = MaterialLocalizations.of(context).closeButtonTooltip;
    void close() => Navigator.of(context).maybePop();

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
}
