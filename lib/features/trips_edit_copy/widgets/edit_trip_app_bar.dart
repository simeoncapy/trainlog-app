import 'package:flutter/material.dart';
import 'package:trainlog_app/features/trips_edit_copy/widgets/cupertino/edit_trip_app_bar_cupertino.dart';
import 'package:trainlog_app/features/trips_edit_copy/widgets/material/edit_trip_app_bar_material.dart';
import 'package:trainlog_app/ui/design.dart';

/// App bar of the trip form pages (edit, duplicate, Geolog note): a close
/// button, the title and an optional trailing action.
///
/// Material keeps a bar tinted with [tint] to tell the modes apart. On iOS
/// the bar blends into the page with glass buttons, and the mode shows before
/// the title instead: [appleModeIcon] in the mode colour, or a small dot of
/// that colour when there is no icon.
class EditTripAppBar extends PlatformAppBar {
  EditTripAppBar({
    super.key,
    required String title,
    required String? subtitle,
    required Color tint,
    IconData? actionIcon,
    String? actionTooltip,
    VoidCallback? onAction,

    /// iOS only: icon of the mode (edit, duplicate) before the title.
    IconData? appleModeIcon,

    /// Shows the iOS action in the destructive (red) colour.
    bool actionDestructive = false,
  }) : super(
         material: MaterialEditTripAppBar(
           title: title,
           subtitle: subtitle,
           tint: tint,
           actionIcon: actionIcon,
           actionTooltip: actionTooltip,
           onAction: onAction,
         ),
         cupertino: CupertinoEditTripAppBar(
           title: title,
           subtitle: subtitle,
           tint: tint,
           modeIcon: appleModeIcon,
           actionIcon: actionIcon,
           actionTooltip: actionTooltip,
           onAction: onAction,
           actionDestructive: actionDestructive,
         ),
       );
}
