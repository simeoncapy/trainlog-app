import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart' show Theme;
import 'package:liquid_glass_widgets/liquid_glass_widgets.dart' as lg;

// An iOS inset grouped list built on liquid_glass_widgets: [AppListTile] is
// the package's [lg.GlassListTile] (press highlight, swipe actions, context
// menu) and [AppGroupedSection] its section card. The card is drawn here
// rather than by [lg.GlassGroupedSection] because the package's solid card
// has fixed system colours (#1C1C1E in dark mode), not the app's surface.

const double _sectionRadius = 26;

/// One button revealed by swiping an [AppListTile] to the left.
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

/// One action of an [AppListTile]'s context menu (long press).
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

/// Coordinates the swipeable [AppListTile]s below it: one open at a time,
/// closed when the list scrolls.
class SwipeActionsScope extends StatelessWidget {
  const SwipeActionsScope({super.key, required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) => lg.GlassSwipeActionScope(child: child);
}

/// An inset grouped section: a solid card with big continuous corners in the
/// app's surface colour, hairlines between the rows (inset on both sides),
/// and each row told which corners it shares with the card, so its press
/// highlight, swipe buttons and context menu lift keep them.
class AppGroupedSection extends StatelessWidget {
  const AppGroupedSection({
    super.key,
    required this.children,
    this.dividerIndent = 16,
  });

  final List<Widget> children;

  /// Start inset of the hairlines (where the rows' text starts).
  final double dividerIndent;

  @override
  Widget build(BuildContext context) {
    const corner = Radius.circular(_sectionRadius);
    final separator = CupertinoColors.separator.resolveFrom(context);
    return ClipRSuperellipse(
      borderRadius: const BorderRadius.all(corner),
      child: ColoredBox(
        color: Theme.of(context).colorScheme.surface,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            for (int i = 0; i < children.length; i++) ...[
              if (i > 0)
                lg.GlassDivider(
                  indent: dividerIndent,
                  endIndent: 16,
                  color: separator,
                ),
              lg.InheritedGlassSectionRow(
                corners: BorderRadius.vertical(
                  top: i == 0 ? corner : Radius.zero,
                  bottom: i == children.length - 1 ? corner : Radius.zero,
                ),
                child: children[i],
              ),
            ],
          ],
        ),
      ),
    );
  }
}

/// A row of an [AppGroupedSection]: the package's [lg.GlassListTile] with
/// the app's fonts, swipe actions on the trailing side (the first one
/// against the edge, run by a full swipe) and a context menu on long press
/// (icons leading, as on iOS 26).
class AppListTile extends StatelessWidget {
  const AppListTile({
    super.key,
    required this.title,
    this.subtitle,
    this.leading,
    this.trailing,
    this.onTap,
    this.swipeActions = const [],
    this.contextMenuActions = const [],
  });

  final Widget title;
  final Widget? subtitle;
  final Widget? leading;
  final Widget? trailing;
  final VoidCallback? onTap;
  final List<SwipeAction> swipeActions;
  final List<AppContextMenuAction> contextMenuActions;

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    // The app's font, without San Francisco's tracking.
    final labelStyle = CupertinoTheme.of(
      context,
    ).textTheme.tabLabelTextStyle.copyWith(letterSpacing: 0);
    return lg.GlassListTile(
      leading: leading,
      title: title,
      subtitle: subtitle,
      trailing: trailing,
      onTap: onTap,
      titleStyle: text.bodyLarge?.copyWith(
        fontWeight: FontWeight.w600,
        color: CupertinoColors.label.resolveFrom(context),
      ),
      subtitleStyle: text.bodyMedium?.copyWith(
        color: CupertinoColors.secondaryLabel.resolveFrom(context),
      ),
      trailingSwipeActions: [
        for (final a in swipeActions)
          lg.GlassSwipeAction(
            icon: Icon(a.icon),
            label: Text(a.label, style: labelStyle),
            semanticLabel: a.label,
            backgroundColor: a.color,
            isDestructive: a.isDestructive,
            onTap: a.onPressed,
          ),
      ],
      contextMenuActions: contextMenuActions.isEmpty
          ? null
          : [
              for (final a in contextMenuActions)
                lg.GlassContextMenuAction(
                  icon: Icon(a.icon),
                  isDestructive: a.isDestructive,
                  onPressed: a.onPressed,
                  child: Text(
                    a.label,
                    style: const TextStyle(letterSpacing: 0),
                  ),
                ),
            ],
    );
  }
}

/// Background of a section header pinned over a scrolling list: the page's
/// colour, and once rows scroll beneath it ([overlaps]) the package's
/// progressive blur (iOS 26 scroll edge effect) under a lighter wash.
class PinnedHeaderBackground extends StatelessWidget {
  const PinnedHeaderBackground({
    super.key,
    required this.overlaps,
    required this.child,
  });

  final bool overlaps;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final background = CupertinoTheme.of(context).scaffoldBackgroundColor;
    return Stack(
      fit: StackFit.expand,
      children: [
        if (overlaps) const lg.ProgressiveBlur(maxSigma: 12),
        DecoratedBox(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                background,
                background.withValues(alpha: overlaps ? 0.75 : 1),
              ],
            ),
          ),
        ),
        child,
      ],
    );
  }
}
