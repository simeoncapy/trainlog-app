import 'package:flutter/material.dart';
import 'package:trainlog_app/ui/tokens/app_theme.dart';

/// App bar heading of the edit/duplicate form: the mode title with, right
/// under it, a muted one-line reminder of the trip being worked on
/// ("Frankfurt → Offenburg • 30 Mar 2026"), ellipsised when the station names
/// do not fit.
class EditTripAppBarTitle extends StatelessWidget {
  const EditTripAppBarTitle({
    super.key,
    required this.title,
    required this.subtitle,
    this.accent,
    this.accentIcon,
  });

  final String title;

  /// Null (or empty) while the trip is still loading: only the title shows.
  final String? subtitle;

  /// Set on iOS, where the bar itself is not tinted: the mode colour, used
  /// for [accentIcon].
  final Color? accent;

  /// The mode icon (edit, duplicate) leading the title, in [accent]. None on
  /// a neutral page such as the Geolog note.
  final IconData? accentIcon;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (accent != null && accentIcon != null) ...[
              Icon(accentIcon, size: 17, color: accent),
              const SizedBox(width: 6),
            ],
            Flexible(
              child: Text(
                title,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: AppTheme.displayFont.copyWith(
                  fontSize: accent != null ? 17 : 18,
                  fontWeight: FontWeight.w700,
                  color: theme.colorScheme.onSurface,
                ),
              ),
            ),
          ],
        ),
        if (subtitle != null && subtitle!.isNotEmpty)
          Text(
            subtitle!,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            textAlign: TextAlign.center,
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
      ],
    );
  }
}
