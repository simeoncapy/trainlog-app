import 'package:flutter/widgets.dart';
import 'package:liquid_glass_widgets/liquid_glass_widgets.dart' as lg;

/// Where a [ScrollEdgeBlur] sits: on top of the content (under a header) or
/// at its bottom (above a footer).
enum ScrollEdge { top, bottom }

/// iOS 26 scroll edge effect: a progressive blur, strongest at the [edge] and
/// sharp at the other side, that frosts the content scrolling beneath a bar
/// instead of hiding it under an opaque one. Put it behind the bar (it blurs
/// what is behind it); [visible] fades it in and out.
///
/// Built on the package's [lg.ProgressiveBlur]. Not its
/// [lg.GlassScrollEdgeEffect], which wraps the scroll view and is always on:
/// the trip sheet's header blur appears only once the content scrolls under
/// it, and is tinted with the sheet's surface.
class ScrollEdgeBlur extends StatelessWidget {
  const ScrollEdgeBlur({
    super.key,
    required this.edge,
    this.visible = true,
    this.maxSigma = 14,
    this.tint,
  });

  final ScrollEdge edge;
  final bool visible;
  final double maxSigma;

  /// A wash of this colour, strong at the [edge] and clear at the other
  /// side, keeps the bar's controls legible over busy content.
  final Color? tint;

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: TweenAnimationBuilder<double>(
        tween: Tween(end: visible ? maxSigma : 0),
        duration: const Duration(milliseconds: 180),
        builder: (context, sigma, _) {
          final blur = lg.ProgressiveBlur(
            maxSigma: sigma,
            direction: edge == ScrollEdge.top
                ? lg.ProgressiveBlurDirection.topToBottom
                : lg.ProgressiveBlurDirection.bottomToTop,
          );
          final color = tint;
          if (color == null) return blur;
          final strength = maxSigma == 0 ? 0.0 : sigma / maxSigma;
          final top = edge == ScrollEdge.top;
          return Stack(
            fit: StackFit.expand,
            children: [
              blur,
              DecoratedBox(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: top ? Alignment.topCenter : Alignment.bottomCenter,
                    end: top ? Alignment.bottomCenter : Alignment.topCenter,
                    colors: [
                      color.withValues(alpha: 0.55 * strength),
                      color.withValues(alpha: 0),
                    ],
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}
