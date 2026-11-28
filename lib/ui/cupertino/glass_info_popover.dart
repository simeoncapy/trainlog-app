import 'package:flutter/cupertino.dart';
import 'package:liquid_glass_widgets/liquid_glass_widgets.dart' as lg;

/// A small ⓘ button opening a Liquid Glass popover that morphs out of it, as
/// a menu does; tapping outside closes it. For a short explanation (e.g. the
/// units of a figure), where an alert would be too heavy.
///
/// The popover is given its height, measured here offstage: in
/// liquid_glass_widgets 1.20.0, a popover measuring its own content opens
/// only once (after the first close, its measurement pass waits on a closing
/// flag that never clears), while one with a `popoverHeight` reopens fine.
class GlassInfoButton extends StatefulWidget {
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

  static const _padding = EdgeInsets.fromLTRB(16, 14, 16, 14);

  @override
  State<GlassInfoButton> createState() => _GlassInfoButtonState();
}

class _GlassInfoButtonState extends State<GlassInfoButton> {
  final _measureKey = GlobalKey();
  double? _height;

  void _measure() {
    final box = _measureKey.currentContext?.findRenderObject() as RenderBox?;
    if (!mounted || box == null || !box.hasSize) return;
    if (box.size.height != _height) setState(() => _height = box.size.height);
  }

  @override
  Widget build(BuildContext context) {
    WidgetsBinding.instance.addPostFrameCallback((_) => _measure());
    final content = Padding(padding: GlassInfoButton._padding, child: widget.child);
    return Stack(
      clipBehavior: Clip.none,
      children: [
        // The content laid out offstage at the popover's width, for its height.
        Offstage(
          child: OverflowBox(
            alignment: Alignment.topLeft,
            minWidth: widget.width,
            maxWidth: widget.width,
            maxHeight: double.infinity,
            child: KeyedSubtree(key: _measureKey, child: content),
          ),
        ),
        lg.GlassPopover(
          popoverWidth: widget.width,
          popoverHeight: _height,
          semanticLabel: widget.semanticLabel,
          triggerBuilder: (context, toggle) => CupertinoButton(
            padding: const EdgeInsets.only(left: 6),
            minimumSize: const Size(28, 28),
            onPressed: toggle,
            child: Icon(
              CupertinoIcons.info_circle,
              size: widget.iconSize,
              color: CupertinoTheme.of(context).primaryColor,
              semanticLabel: widget.semanticLabel,
            ),
          ),
          contentBuilder: (context, close) => content,
        ),
      ],
    );
  }
}
