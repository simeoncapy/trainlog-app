import 'package:flutter/material.dart';
import 'package:trainlog_app/l10n/app_localizations.dart';
import 'package:trainlog_app/widgets/primary_action_button.dart';
import 'package:trainlog_app/widgets/trip_form/trip_form_card.dart';

/// Path block, at the bottom of the edit form: actions to modify the drawn
/// path of the trip or to replace it with a GPX file.
class EditTripPathSection extends StatelessWidget {
  const EditTripPathSection({
    super.key,
    required this.onModifyPath,
    required this.onImportGpx,
  });

  final VoidCallback onModifyPath;
  final VoidCallback onImportGpx;

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context)!;

    return TripFormCard(
      padding: const EdgeInsets.all(16),
      separated: false,
      children: [
        PrimaryActionButton(
          icon: Icons.timeline,
          label: loc.editTripModifyPathButton,
          variant: PrimaryActionButtonVariant.outlined,
          onPressed: onModifyPath,
        ),
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
