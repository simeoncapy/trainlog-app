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
  });

  final String title;

  /// Null (or empty) while the trip is still loading: only the title shows.
  final String? subtitle;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Text(
          title,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: AppTheme.displayFont.copyWith(
            fontSize: 18,
            fontWeight: FontWeight.w700,
            color: theme.colorScheme.onSurface,
          ),
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
