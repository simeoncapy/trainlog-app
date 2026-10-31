import 'package:flutter/material.dart';
import 'package:trainlog_app/l10n/app_localizations.dart';
import 'package:trainlog_app/widgets/trip_form/trip_form_card.dart';

/// The blocks of the edit/duplicate form and of the Geolog note page. Each
/// one is both a pill of the anchor bar and a scroll target.
enum EditTripSection {
  route,
  station,
  operators,
  when,
  details,
  ticket,
  path;

  /// The blocks of the edit/duplicate form, in the order they appear.
  static const List<EditTripSection> trip = [
    route,
    operators,
    when,
    details,
    ticket,
    path,
  ];

  /// The blocks of the Geolog note page, in the order they appear: a single
  /// station instead of a route, and no path.
  static const List<EditTripSection> geologNote = [
    station,
    operators,
    when,
    details,
    ticket,
  ];
}

extension EditTripSectionL10n on EditTripSection {
  String label(AppLocalizations loc) {
    switch (this) {
      case EditTripSection.route:
        return loc.editTripSectionRoute;
      case EditTripSection.station:
        return loc.geologNoteSectionStation;
      case EditTripSection.operators:
        return loc.editTripSectionOperator;
      case EditTripSection.when:
        return loc.editTripSectionWhen;
      case EditTripSection.details:
        return loc.editTripSectionDetails;
      case EditTripSection.ticket:
        return loc.editTripSectionTicket;
      case EditTripSection.path:
        return loc.editTripSectionPath;
    }
  }
}

/// One block of the edit form: the section header the anchor bar scrolls to,
/// followed by the block content.
class EditTripSectionBlock extends StatelessWidget {
  const EditTripSectionBlock({
    super.key,
    required this.section,
    required this.child,
  });

  final EditTripSection section;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context)!;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        TripFormSectionLabel(section.label(loc)),
        const SizedBox(height: 8),
        child,
      ],
    );
  }
}
