import 'package:flutter/material.dart';

/// Rounded "pill" of the app's horizontal selector bars.
///
/// Selected pills are filled with the inverse surface, unselected ones keep
/// the surface colour with a hairline outline; disabled pills are faded out
/// and non-interactive. The optional [icon] keeps its own [accentColor] so a
/// bar can tint each entry (e.g. the ranking vehicle colours).
///
/// Used by the ranking category bar and the edit-trip section anchor bar.
class SelectorPill extends StatelessWidget {
  const SelectorPill({
    super.key,
    required this.label,
    required this.selected,
    required this.onTap,
    this.icon,
    this.accentColor,
    this.enabled = true,
    this.trailing,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  /// Optional leading icon; sized and tinted by the pill.
  final Widget? icon;

  /// Colour of [icon]. Defaults to the pill foreground.
  final Color? accentColor;

  final bool enabled;

  /// Optional trailing widget (e.g. a chevron); tinted with the foreground.
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    final Color bg;
    final Color fg;
    if (selected) {
      bg = cs.inverseSurface;
      fg = cs.onInverseSurface;
    } else if (enabled) {
      bg = cs.surface;
      fg = cs.onSurface;
    } else {
      bg = cs.surface.withValues(alpha: 0.5);
      fg = cs.onSurfaceVariant.withValues(alpha: 0.5);
    }

    final accent = enabled
        ? (accentColor ?? fg)
        : cs.onSurfaceVariant.withValues(alpha: 0.4);

    return Opacity(
      opacity: enabled ? 1 : 0.6,
      child: Material(
        color: bg,
        borderRadius: BorderRadius.circular(22),
        child: InkWell(
          borderRadius: BorderRadius.circular(22),
          onTap: enabled ? onTap : null,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(22),
              border: Border.all(
                color:
                    selected ? Colors.transparent : cs.outline.withValues(alpha: 0.3),
                width: 1.2,
              ),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (icon != null) ...[
                  IconTheme(
                    data: IconThemeData(size: 16, color: accent),
                    child: icon!,
                  ),
                  const SizedBox(width: 8),
                ],
                Text(
                  label,
                  style: Theme.of(context).textTheme.labelLarge?.copyWith(
                        color: fg,
                        fontWeight: FontWeight.w700,
                      ),
                ),
                if (trailing != null) ...[
                  const SizedBox(width: 6),
                  IconTheme(
                    data: IconThemeData(size: 18, color: fg),
                    child: trailing!,
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}
