import 'package:flutter/material.dart';
import 'package:trainlog_app/app/theme/app_theme.dart';

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
  });

  final String title;

  /// Null (or empty) while the trip is still loading: only the title shows.
  final String? subtitle;

  /// When set, a small dot of this colour leads the title (the mode colour
  /// on Apple, where the bar itself is not tinted).
  final Color? accent;

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
            if (accent != null) ...[
              DecoratedBox(
                decoration: BoxDecoration(color: accent, shape: BoxShape.circle),
                child: const SizedBox.square(dimension: 8),
              ),
              const SizedBox(width: 7),
            ],
            Flexible(
              child: Text(
                title,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: AppTheme.displayFont.copyWith(
                  fontSize: accent != null ? 17 : 18,
                  fontWeight: accent != null ? FontWeight.w600 : FontWeight.w700,
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
