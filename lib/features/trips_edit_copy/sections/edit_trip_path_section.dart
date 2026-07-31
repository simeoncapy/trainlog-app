import 'package:flutter/material.dart';
import 'package:trainlog_app/l10n/app_localizations.dart';
import 'package:trainlog_app/widgets/primary_action_button.dart';
import 'package:trainlog_app/widgets/trip_form/trip_form_card.dart';

/// Path block, at the bottom of the edit form: the drawn path of the trip is
/// edited on its own screen, which this action card opens.
class EditTripPathSection extends StatelessWidget {
  const EditTripPathSection({super.key, required this.onModifyPath});

  final VoidCallback onModifyPath;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final loc = AppLocalizations.of(context)!;

    return TripFormCard(
      padding: const EdgeInsets.all(16),
      separated: false,
      children: [
        Text(
          loc.editTripPathDescription,
          style: theme.textTheme.bodySmall?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
          ),
        ),
        const SizedBox(height: 12),
        PrimaryActionButton(
          icon: Icons.timeline,
          label: loc.editTripModifyPathButton,
          variant: PrimaryActionButtonVariant.outlined,
          onPressed: onModifyPath,
        ),
      ],
    );
  }
}
