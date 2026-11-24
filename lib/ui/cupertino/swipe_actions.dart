import 'package:flutter/cupertino.dart';
import 'package:liquid_glass_widgets/liquid_glass_widgets.dart' as lg;

/// One button revealed by swiping a [SwipeActions] row to the left.
class SwipeAction {
  const SwipeAction({
    required this.icon,
    required this.label,
    required this.onPressed,
    this.color,
    this.isDestructive = false,
  });

  final IconData icon;
  final String label;
  final VoidCallback onPressed;

  /// The button's tint; red when [isDestructive] and none is given.
  final Color? color;
  final bool isDestructive;
}

/// An iOS 26 list row with swipe actions, drawn by liquid_glass_widgets'
/// [lg.GlassSwipeActions]: swiping left reveals round glass buttons on the
/// trailing side, a full swipe runs the outermost one (with a haptic tick),
/// and tapping outside closes the row. Put the list in a [SwipeActionsScope]
/// so only one row is open at a time and scrolling closes it.
class SwipeActions extends StatelessWidget {
  const SwipeActions({super.key, required this.actions, required this.child});

  /// The first one sits against the trailing edge and is the full-swipe
  /// action; the others follow inwards.
  final List<SwipeAction> actions;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    if (actions.isEmpty) return child;
    // The app's font, without San Francisco's tracking.
    final labelStyle = CupertinoTheme.of(
      context,
    ).textTheme.tabLabelTextStyle.copyWith(letterSpacing: 0);
    return lg.GlassSwipeActions(
      trailingActions: [
        for (final a in actions)
          lg.GlassSwipeAction(
            icon: Icon(a.icon),
            label: Text(a.label, style: labelStyle),
            semanticLabel: a.label,
            backgroundColor: a.color,
            isDestructive: a.isDestructive,
            onTap: a.onPressed,
          ),
      ],
      child: child,
    );
  }
}

/// Coordinates the [SwipeActions] rows below it: one open at a time, closed
/// when the list scrolls.
class SwipeActionsScope extends StatelessWidget {
  const SwipeActionsScope({super.key, required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) => lg.GlassSwipeActionScope(child: child);
}
