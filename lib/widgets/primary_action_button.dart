import 'package:flutter/material.dart';

/// Visual variants of [PrimaryActionButton].
enum PrimaryActionButtonVariant {
  /// Filled with the theme's elevated-button colours (amber with navy
  /// content) — the main action.
  filled,

  /// Outlined with a transparent background — a secondary action shown next
  /// to a filled one (e.g. "Validate and continue the journey").
  outlined,
}

/// The app's prominent full-width primary action button: 52 px tall, 14 px
/// corner radius and a bold title-medium label, coloured by the theme's
/// elevated-button style (amber with navy content) or rendered as an
/// outlined secondary variant.
///
/// Used as the main button of the map filter sheet, the trip search filter
/// sheet and the add-trip wizard footer.
class PrimaryActionButton extends StatelessWidget {
  const PrimaryActionButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.icon,
    this.variant = PrimaryActionButtonVariant.filled,
  });

  final String label;

  /// Null renders the disabled state.
  final VoidCallback? onPressed;

  /// Optional leading icon.
  final IconData? icon;

  final PrimaryActionButtonVariant variant;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final shape =
        RoundedRectangleBorder(borderRadius: BorderRadius.circular(14));
    final textStyle =
        theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700);
    final labelText = Text(
      label,
      maxLines: 1,
      overflow: TextOverflow.ellipsis,
    );
    final iconWidget = icon == null ? null : Icon(icon, size: 20);

    final Widget button;
    switch (variant) {
      case PrimaryActionButtonVariant.filled:
        final style = ElevatedButton.styleFrom(
          shape: shape,
          textStyle: textStyle,
        );
        button = iconWidget == null
            ? ElevatedButton(
                onPressed: onPressed, style: style, child: labelText)
            : ElevatedButton.icon(
                onPressed: onPressed,
                style: style,
                icon: iconWidget,
                label: labelText,
              );
      case PrimaryActionButtonVariant.outlined:
        final style = OutlinedButton.styleFrom(
          shape: shape,
          textStyle: textStyle,
        );
        button = iconWidget == null
            ? OutlinedButton(
                onPressed: onPressed, style: style, child: labelText)
            : OutlinedButton.icon(
                onPressed: onPressed,
                style: style,
                icon: iconWidget,
                label: labelText,
              );
    }

    return SizedBox(
      width: double.infinity,
      height: 52,
      child: button,
    );
  }
}
