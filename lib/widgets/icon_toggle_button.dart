import 'package:flutter/material.dart';

/// A small square, outlined icon button used for compact toggle controls
/// (alphabetical/value, sort direction, …) across the Ranking and Statistics
/// features.
///
/// Two visual variants, selected with [onScaffold], keep the original looks:
///  * [onScaffold] true (default) — sits on the scaffold: an opaque surface/white fill
///    when inactive and an [ColorScheme.outlineVariant] border (used by the
///    ranking filter rows).
///  * [onScaffold] false — sits on a card: a transparent fill and an
///    [ColorScheme.outline] border (used by the statistics sort button).
///
/// When [active] the button takes a primary-tinted fill and border. When not
/// [enabled] it is dimmed and non-interactive.
class IconToggleButton extends StatelessWidget {
  final IconData icon;
  final String tooltip;
  final VoidCallback onTap;

  /// Highlights the button with a primary-tinted fill/border (an "on" state).
  final bool active;

  /// When false the button is dimmed and ignores taps.
  final bool enabled;

  /// Whether the button sits on the scaffold (opaque fill, [outlineVariant] border)
  /// or on a card (transparent fill, [outline] border).
  final bool onScaffold;

  const IconToggleButton({
    super.key,
    required this.icon,
    required this.tooltip,
    required this.onTap,
    this.active = false,
    this.enabled = true,
    this.onScaffold = true,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final inactiveFill =
        onScaffold ? (isDark ? cs.surface : Colors.white) : Colors.transparent;
    final inactiveBorder =
        (onScaffold ? cs.outlineVariant : cs.outline).withValues(alpha: 0.4);

    final button = Tooltip(
      message: tooltip,
      child: GestureDetector(
        onTap: enabled ? onTap : null,
        child: Container(
          padding: EdgeInsets.all(onScaffold ? 9 : 8),
          decoration: BoxDecoration(
            color: active ? cs.primary.withValues(alpha: 0.15) : inactiveFill,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(
              color: active
                  ? cs.primary.withValues(alpha: 0.6)
                  : inactiveBorder,
              width: 1.2,
            ),
          ),
          child: Icon(icon, size: 18, color: cs.primary),
        ),
      ),
    );

    return enabled ? button : Opacity(opacity: 0.4, child: button);
  }
}
