import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:trainlog_app/data/models/trip_form_model.dart';
import 'package:trainlog_app/features/trips_add/add_trip_wizard_page.dart';

/// Opens the add trip wizard and returns `true` when a trip was saved.
///
/// Shared by the Map and Trips pages' "New trip" buttons. The wizard goes on
/// the root navigator: on iOS the tab's own navigator sits under the floating
/// tab bar, which would cover the wizard's footer button.
Future<bool> openAddTripWizard(BuildContext context) async {
  final didSave = await Navigator.of(context, rootNavigator: true).push<bool>(
    PageRouteBuilder(
      pageBuilder: (_, __, ___) => ChangeNotifierProvider(
        create: (_) => TripFormModel(),
        child: const AddTripWizardPage(),
      ),
      transitionDuration: Duration.zero,
      reverseTransitionDuration: Duration.zero,
    ),
  );
  return didSave == true;
}
