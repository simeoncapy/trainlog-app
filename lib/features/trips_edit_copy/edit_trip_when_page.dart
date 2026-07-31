import 'package:flutter/material.dart';
import 'package:trainlog_app/features/trips_add/steps/add_trip_when_step.dart';
import 'package:trainlog_app/l10n/app_localizations.dart';
import 'package:trainlog_app/widgets/primary_action_button.dart';

/// Full temporal editing screen of the edit form, opened from the read-only
/// "When" summary card.
///
/// It hosts the wizard's own [AddTripWhenStep] — precise / date / unknown
/// modes, delays and durations — so both flows edit the schedule the same
/// way. The step writes straight into the [TripFormModel] the caller has to
/// provide above this page.
class EditTripWhenPage extends StatelessWidget {
  const EditTripWhenPage({super.key});

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context)!;

    return Scaffold(
      appBar: AppBar(title: Text(loc.editTripSectionWhen)),
      body: SafeArea(
        child: Column(
          children: [
            const Expanded(child: AddTripWhenStep()),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              child: PrimaryActionButton(
                label: loc.validateButton,
                onPressed: () => Navigator.of(context).pop(),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
