import 'package:flutter/cupertino.dart';
import 'package:liquid_glass_widgets/liquid_glass_widgets.dart' as lg;

/// A small ⓘ button opening a Liquid Glass popover that morphs out of it, as
/// a menu does; tapping outside closes it. For a short explanation (e.g. the
/// units of a figure), where an alert would be too heavy.
class GlassInfoButton extends StatelessWidget {
  const GlassInfoButton({
    super.key,
    required this.semanticLabel,
    required this.child,
    this.width = 240,
    this.iconSize = 18,
  });

  final String semanticLabel;

  /// The popover's content, padded by the popover.
  final Widget child;
  final double width;
  final double iconSize;

  @override
  Widget build(BuildContext context) {
    return lg.GlassPopover(
      popoverWidth: width,
      semanticLabel: semanticLabel,
      triggerBuilder: (context, toggle) => CupertinoButton(
        padding: const EdgeInsets.only(left: 6),
        minimumSize: const Size(28, 28),
        onPressed: toggle,
        child: Icon(
          CupertinoIcons.info_circle,
          size: iconSize,
          color: CupertinoTheme.of(context).primaryColor,
          semanticLabel: semanticLabel,
        ),
      ),
      contentBuilder: (context, close) => Padding(
        padding: const EdgeInsets.fromLTRB(16, 14, 16, 14),
        child: child,
      ),
    );
  }
}
