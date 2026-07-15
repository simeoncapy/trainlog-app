import 'package:flutter/material.dart';
import 'package:trainlog_app/data/models/trip_form_model.dart';

/// Returns true when the data owned by a wizard step is valid and the wizard
/// may progress to the next step.
typedef WizardStepValidator = bool Function(TripFormModel model);

/// Declarative definition of one sub-page of the "Add Trip" wizard.
///
/// The wizard page keeps an ordered list of these; the total step count and
/// the progress indicator are derived from that list, so adding or removing
/// a step here automatically updates the whole flow.
class AddTripWizardStep {
  const AddTripWizardStep({
    required this.builder,
    this.validate,
  });

  /// Builds the page content for this step.
  final WidgetBuilder builder;

  /// Validates the step before progressing. A null validator means the step
  /// is always considered valid.
  final WizardStepValidator? validate;
}
