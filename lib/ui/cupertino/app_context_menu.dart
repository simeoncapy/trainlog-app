import 'package:flutter/cupertino.dart';
import 'package:liquid_glass_widgets/liquid_glass_widgets.dart' as lg;

/// One action of an [AppContextMenu].
class AppContextMenuAction {
  const AppContextMenuAction({
    required this.label,
    required this.icon,
    required this.onPressed,
    this.isDestructive = false,
  });

  final String label;
  final IconData icon;
  final VoidCallback onPressed;
  final bool isDestructive;
}

/// iOS 26 context menu, drawn by liquid_glass_widgets' [lg.GlassContextMenu]:
/// a long press lifts [child] out of its list above a dimmed page, next to a
/// Liquid Glass platter of [actions] (the menu closes, then the action runs).
///
/// For a row of an inset grouped list, [rowCorners] are the corners it shares
/// with its group, and [slotColor] (the page's background) fills the hole the
/// lifted row leaves.
class AppContextMenu extends StatelessWidget {
  const AppContextMenu({
    super.key,
    required this.actions,
    required this.child,
    this.rowCorners,
    this.slotColor,
    this.rowColor,
  });

  final List<AppContextMenuAction> actions;
  final Widget child;
  final BorderRadius? rowCorners;
  final Color? slotColor;

  /// The lifted row's background.
  final Color? rowColor;

  @override
  Widget build(BuildContext context) {
    return lg.GlassContextMenu(
      rowCorners: rowCorners,
      originSlotColor: slotColor,
      backgroundColor: rowColor,
      actions: [
        for (final a in actions)
          lg.GlassContextMenuAction(
            icon: Icon(a.icon),
            iconPosition: lg.GlassContextMenuIconPosition.trailing,
            isDestructive: a.isDestructive,
            onPressed: a.onPressed,
            // The app's font comes from the theme; drop San Francisco's
            // tracking.
            child: Text(a.label, style: const TextStyle(letterSpacing: 0)),
          ),
      ],
      child: child,
    );
  }
}
