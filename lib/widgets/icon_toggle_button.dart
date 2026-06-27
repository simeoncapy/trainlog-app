import 'package:flutter/material.dart';

/// A small square, outlined icon button used for compact toggle controls
/// (alphabetical/value, sort direction, …) across the Ranking and Statistics
/// features.
///
/// Two visual variants, selected with [onCard], keep the original looks:
///  * [onCard] true (default) — sits on a card: an opaque surface/white fill
///    when inactive and an [ColorScheme.outlineVariant] border (used by the
///    ranking filter rows).
///  * [onCard] false — sits directly on the scaffold: a transparent fill and an
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

  /// Whether the button sits on a card (opaque fill, [outlineVariant] border)
  /// or directly on the scaffold (transparent fill, [outline] border).
  final bool onCard;

  const IconToggleButton({
    super.key,
    required this.icon,
    required this.tooltip,
    required this.onTap,
    this.active = false,
    this.enabled = true,
    this.onCard = true,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final inactiveFill =
        onCard ? (isDark ? cs.surface : Colors.white) : Colors.transparent;
    final inactiveBorder =
        (onCard ? cs.outlineVariant : cs.outline).withValues(alpha: 0.4);

    final button = Tooltip(
      message: tooltip,
      child: GestureDetector(
        onTap: enabled ? onTap : null,
        child: Container(
          padding: EdgeInsets.all(onCard ? 9 : 8),
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
