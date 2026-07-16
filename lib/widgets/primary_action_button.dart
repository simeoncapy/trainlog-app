import 'package:flutter/material.dart';

/// The app's prominent full-width primary action button: 52 px tall, 14 px
/// corner radius and a bold title-medium label, coloured by the theme's
/// elevated-button style (amber with navy content).
///
/// Used as the main button of the map filter sheet, the trip search filter
/// sheet and the add-trip wizard footer.
class PrimaryActionButton extends StatelessWidget {
  const PrimaryActionButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.icon,
  });

  final String label;

  /// Null renders the disabled state.
  final VoidCallback? onPressed;

  /// Optional leading icon.
  final IconData? icon;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final style = ElevatedButton.styleFrom(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      textStyle:
          theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700),
    );
    final labelText = Text(
      label,
      maxLines: 1,
      overflow: TextOverflow.ellipsis,
    );

    return SizedBox(
      width: double.infinity,
      height: 52,
      child: icon == null
          ? ElevatedButton(
              onPressed: onPressed,
              style: style,
              child: labelText,
            )
          : ElevatedButton.icon(
              onPressed: onPressed,
              style: style,
              icon: Icon(icon, size: 20),
              label: labelText,
            ),
    );
  }
}
