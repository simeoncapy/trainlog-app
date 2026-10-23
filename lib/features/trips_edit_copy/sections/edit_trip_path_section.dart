import 'package:flutter/material.dart';
import 'package:trainlog_app/l10n/app_localizations.dart';
import 'package:trainlog_app/widgets/primary_action_button.dart';
import 'package:trainlog_app/widgets/trip_form/trip_form_card.dart';

/// Path block, at the bottom of the edit form: actions to modify the drawn
/// path of the trip or to replace it with a GPX file. Once the path was
/// redrawn, a note says it is waiting to be saved with the trip.
class EditTripPathSection extends StatelessWidget {
  const EditTripPathSection({
    super.key,
    required this.onModifyPath,
    required this.onImportGpx,
    this.pathEdited = false,
  });

  final VoidCallback onModifyPath;
  final VoidCallback onImportGpx;

  /// The path was redrawn and is not saved yet.
  final bool pathEdited;

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context)!;
    final theme = Theme.of(context);

    return TripFormCard(
      padding: const EdgeInsets.all(16),
      separated: false,
      children: [
        PrimaryActionButton(
          icon: Icons.timeline,
          label: loc.editTripModifyPathButton,
          variant: PrimaryActionButtonVariant.tonal,
          onPressed: onModifyPath,
        ),
        if (pathEdited) ...[
          const SizedBox(height: 8),
          Row(
            children: [
              Icon(
                Icons.check_circle,
                size: 18,
                color: theme.colorScheme.primary,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  loc.editTripPathEditedNote,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
              ),
            ],
          ),
        ],
        const SizedBox(height: 12),
        PrimaryActionButton(
          icon: Icons.upload_file,
          label: loc.editTripImportGpxButton,
          variant: PrimaryActionButtonVariant.outlined,
          onPressed: onImportGpx,
        ),
      ],
    );
  }
}
