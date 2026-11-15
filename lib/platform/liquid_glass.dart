import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart' show Theme, Tooltip;
import 'package:liquid_glass_widgets/liquid_glass_widgets.dart' as lg;
import 'package:trainlog_app/app/theme/app_colors.dart';

/// Apple's "Liquid Glass" material (iOS 26 / macOS 26), used only by the
/// Apple flavour of the UI. Rendered by liquid_glass_widgets: the surface
/// refracts and blurs what is behind it, with a specular rim.
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

  /// The material itself comes from liquid_glass_widgets (shader refraction,
  /// specular rim, chromatic aberration); [blur] and [shadow] are kept for
  /// the callers but the package decides them.
  @override
  Widget build(BuildContext context) {
    return lg.GlassContainer(
      useOwnLayer: true,
      quality: lg.GlassQuality.premium,
      shape: lg.LiquidRoundedSuperellipse(
        borderRadius:
            borderRadius?.topLeft.x ?? lg.GlassDefaults.capsuleRadius,
      ),
      settings: tint != null && tintStrength > 0
          ? lg.LiquidGlassSettings(
              glassColor: tint!.withValues(alpha: tintStrength))
          : null,
      padding: padding,
      child: child,
    );
  }
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

    Widget button = lg.GlassIconButton(
      icon: child ?? Icon(icon, size: iconSize, color: fg),
      onPressed: onPressed,
      size: size,
      iconSize: iconSize,
      useOwnLayer: true,
      quality: lg.GlassQuality.premium,
      // Prominent: the glass tinted with the Trainlog amber, which is how
      // the primary action of a screen stands out.
      settings: prominent
          ? lg.LiquidGlassSettings(
              glassColor: AppColors.amber.withValues(alpha: 0.88))
          : null,
      semanticLabel: tooltip,
    );

    if (tooltip != null && tooltip!.isNotEmpty) {
      button = Tooltip(message: tooltip!, child: button);
    }
    return button;
  }
}

/// A capsule of glass holding several controls side by side, like the
/// grouped toolbar items of iOS 26.
class GlassButtonGroup extends StatelessWidget {
  const GlassButtonGroup({
    super.key,
    required this.children,
    this.height = 44,
    this.direction = Axis.horizontal,
  });

  /// [GlassGroupItem]s become the package's group items (one glass pill that
  /// stretches as a whole); any other widget is laid out as is.
  final List<Widget> children;
  final double height;
  final Axis direction;

  @override
  Widget build(BuildContext context) {
    if (children.every((c) => c is GlassGroupItem && c.label == null)) {
      return lg.GlassButtonGroup.icons(
        useOwnLayer: true,
        quality: lg.GlassQuality.premium,
        direction: direction,
        borderRadius: lg.GlassDefaults.capsuleRadius,
        iconSize: 20,
        itemPadding: EdgeInsets.all((height - 20) / 2),
        items: [
          for (final c in children.cast<GlassGroupItem>())
            lg.GlassButtonGroupItem(
              icon: c.color == null ? Icon(c.icon) : Icon(c.icon, color: c.color),
              onTap: c.onPressed,
              label: c.semanticLabel,
              enabled: c.onPressed != null,
            ),
        ],
      );
    }

    return lg.GlassButtonGroup(
      useOwnLayer: true,
      quality: lg.GlassQuality.premium,
      direction: direction,
      borderRadius: lg.GlassDefaults.capsuleRadius,
      showDividers: false,
      children: [
        for (final c in children)
          direction == Axis.horizontal
              ? SizedBox(height: height, child: c)
              : SizedBox(width: height, child: c),
      ],
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
