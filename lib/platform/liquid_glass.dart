import 'dart:ui' show ImageFilter;

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart' show Theme, Tooltip;
import 'package:trainlog_app/app/theme/app_colors.dart';

/// Approximation of Apple's "Liquid Glass" material (iOS 26 / macOS 26),
/// used only by the Apple flavour of the UI.
///
/// The surface blurs and saturates whatever is behind it, adds a thin
/// translucent fill, a soft diagonal sheen and a light rim that catches the
/// "light" on the top-left and bottom-right edges.
class LiquidGlass extends StatelessWidget {
  const LiquidGlass({
    super.key,
    required this.child,
    this.borderRadius,
    this.tint,
    this.tintStrength = 0.0,
    this.blur = 16,
    this.padding,
    this.shadow = true,
  });

  final Widget child;

  /// Corner radius. When null the shape is a capsule (stadium).
  final BorderRadius? borderRadius;

  /// Optional colour the glass is tinted with (e.g. amber for the prominent
  /// action). [tintStrength] controls how opaque that tint is.
  final Color? tint;
  final double tintStrength;

  final double blur;
  final EdgeInsetsGeometry? padding;
  final bool shadow;

  static bool _isDark(BuildContext context) =>
      Theme.of(context).brightness == Brightness.dark;

  /// Base fill of the glass, without any tint.
  static Color baseFill(BuildContext context) => _isDark(context)
      ? const Color(0xFF242B3A).withValues(alpha: 0.55)
      : const Color(0xFFFFFFFF).withValues(alpha: 0.62);

  @override
  Widget build(BuildContext context) {
    final isDark = _isDark(context);

    Color fill = baseFill(context);
    if (tint != null && tintStrength > 0) {
      fill = Color.alphaBlend(tint!.withValues(alpha: tintStrength), fill);
    }

    final ShapeBorder shape = borderRadius == null
        ? const StadiumBorder()
        : RoundedRectangleBorder(borderRadius: borderRadius!);

    Widget content = child;
    if (padding != null) content = Padding(padding: padding!, child: content);

    final glass = ClipPath(
      clipper: ShapeBorderClipper(shape: shape),
      child: BackdropFilter(
        filter: ImageFilter.compose(
          outer: ImageFilter.blur(sigmaX: blur, sigmaY: blur),
          inner: const ColorFilter.matrix(_saturate),
        ),
        child: CustomPaint(
          foregroundPainter: _GlassRimPainter(shape: shape, isDark: isDark),
          child: DecoratedBox(
            decoration: ShapeDecoration(shape: shape, color: fill),
            child: DecoratedBox(
              decoration: ShapeDecoration(
                shape: shape,
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    CupertinoColors.white.withValues(
                      alpha: isDark ? 0.10 : 0.30,
                    ),
                    CupertinoColors.white.withValues(alpha: 0.0),
                    CupertinoColors.white.withValues(
                      alpha: isDark ? 0.04 : 0.10,
                    ),
                  ],
                  stops: const [0.0, 0.55, 1.0],
                ),
              ),
              child: content,
            ),
          ),
        ),
      ),
    );

    if (!shadow) return glass;

    return DecoratedBox(
      decoration: ShapeDecoration(
        shape: shape,
        shadows: [
          BoxShadow(
            color: const Color(
              0xFF000000,
            ).withValues(alpha: isDark ? 0.35 : 0.12),
            blurRadius: 24,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: glass,
    );
  }
}

/// Boosts the saturation of what is behind the glass (≈ 1.6×), which is what
/// gives Liquid Glass its vivid look compared to a plain frosted blur.
const List<double> _saturate = <double>[
  1.4293, -0.3854, -0.0439, 0, 0, //
  -0.1146, 1.1717, -0.0571, 0, 0, //
  -0.1146, -0.3854, 1.5000, 0, 0, //
  0, 0, 0, 1, 0, //
];

class _GlassRimPainter extends CustomPainter {
  _GlassRimPainter({required this.shape, required this.isDark});

  final ShapeBorder shape;
  final bool isDark;

  @override
  void paint(Canvas canvas, Size size) {
    final rect = Offset.zero & size;
    final path = shape.getInnerPath(rect.deflate(0.5));
    final paint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.0
      ..shader = LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [
          CupertinoColors.white.withValues(alpha: isDark ? 0.38 : 0.85),
          CupertinoColors.white.withValues(alpha: isDark ? 0.06 : 0.25),
          CupertinoColors.white.withValues(alpha: isDark ? 0.22 : 0.55),
        ],
        stops: const [0.0, 0.5, 1.0],
      ).createShader(rect);
    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(_GlassRimPainter old) =>
      old.isDark != isDark || old.shape != shape;
}

/// Gives a glass control the "liquid" press response: it swells slightly
/// while pressed, then settles back with a soft spring.
class GlassPressable extends StatefulWidget {
  const GlassPressable({
    super.key,
    required this.child,
    required this.onPressed,
    this.pressedScale = 1.08,
  });

  final Widget child;
  final VoidCallback? onPressed;
  final double pressedScale;

  @override
  State<GlassPressable> createState() => _GlassPressableState();
}

class _GlassPressableState extends State<GlassPressable> {
  bool _pressed = false;

  void _set(bool v) {
    if (_pressed != v) setState(() => _pressed = v);
  }

  @override
  Widget build(BuildContext context) {
    final enabled = widget.onPressed != null;
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTapDown: enabled ? (_) => _set(true) : null,
      onTapUp: enabled ? (_) => _set(false) : null,
      onTapCancel: enabled ? () => _set(false) : null,
      onTap: widget.onPressed,
      child: AnimatedScale(
        scale: _pressed ? widget.pressedScale : 1.0,
        duration: Duration(milliseconds: _pressed ? 120 : 380),
        curve: _pressed ? Curves.easeOut : Curves.elasticOut,
        child: AnimatedOpacity(
          opacity: enabled ? 1.0 : 0.45,
          duration: const Duration(milliseconds: 150),
          child: widget.child,
        ),
      ),
    );
  }
}

/// A circular glass icon button, the iOS 26 style for navigation bar and
/// floating controls (back, close, settings, search…).
///
/// When [prominent] is true the glass is tinted with the Trainlog amber, which
/// is how the primary action of a screen stands out.
class GlassIconButton extends StatelessWidget {
  const GlassIconButton({
    super.key,
    required this.icon,
    required this.onPressed,
    this.size = 44,
    this.iconSize = 20,
    this.tooltip,
    this.prominent = false,
    this.color,
    this.child,
    this.shadow = true,
  });

  final IconData icon;
  final VoidCallback? onPressed;
  final double size;
  final double iconSize;
  final String? tooltip;
  final bool prominent;

  /// Icon colour override.
  final Color? color;

  /// Replaces the icon when provided (e.g. the Trainlog logo).
  final Widget? child;

  /// Drop shadow under the glass. Turn off inside bars that clip their
  /// children (e.g. [CupertinoNavigationBar]), where it would be cut square.
  final bool shadow;

  @override
  Widget build(BuildContext context) {
    final fg =
        color ??
        (prominent
            ? AppColors.navy
            : CupertinoColors.label.resolveFrom(context));

    Widget button = GlassPressable(
      onPressed: onPressed,
      child: SizedBox.square(
        dimension: size,
        child: LiquidGlass(
          tint: prominent ? AppColors.amber : null,
          tintStrength: prominent ? 0.88 : 0,
          shadow: shadow,
          child: Center(
            child: child ?? Icon(icon, size: iconSize, color: fg),
          ),
        ),
      ),
    );

    if (tooltip != null && tooltip!.isNotEmpty) {
      button = Tooltip(message: tooltip!, child: button);
    }
    return Semantics(button: true, label: tooltip, child: button);
  }
}

/// A capsule of glass holding several controls side by side, like the
/// grouped toolbar items of iOS 26.
class GlassButtonGroup extends StatelessWidget {
  const GlassButtonGroup({super.key, required this.children, this.height = 44});

  final List<Widget> children;
  final double height;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: height,
      child: LiquidGlass(
        padding: const EdgeInsets.symmetric(horizontal: 4),
        child: Row(mainAxisSize: MainAxisSize.min, children: children),
      ),
    );
  }
}

/// A bare icon button sized for use inside a [GlassButtonGroup].
class GlassGroupItem extends StatelessWidget {
  const GlassGroupItem({
    super.key,
    required this.icon,
    required this.onPressed,
    this.label,
    this.color,
    this.semanticLabel,
  });

  final IconData icon;
  final VoidCallback? onPressed;
  final String? label;
  final Color? color;
  final String? semanticLabel;

  @override
  Widget build(BuildContext context) {
    final fg = color ?? CupertinoColors.label.resolveFrom(context);
    return Semantics(
      button: true,
      label: semanticLabel ?? label,
      child: GlassPressable(
        onPressed: onPressed,
        pressedScale: 1.15,
        child: Padding(
          padding: EdgeInsets.symmetric(horizontal: label == null ? 8 : 12),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, size: 20, color: fg),
              if (label != null) ...[
                const SizedBox(width: 6),
                Text(
                  label!,
                  style: TextStyle(
                    color: fg,
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
