import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:trainlog_app/data/models/trip_form_model.dart';
import 'package:trainlog_app/l10n/app_localizations.dart';
import 'package:trainlog_app/widgets/trip_form/trip_form_card.dart';
import 'package:trainlog_app/widgets/trip_form/trip_form_tiles.dart';

/// Details block of the edit form: the same free-text line items as the
/// add-trip details step (line name, material, registration, seat) followed
/// by the note card.
class EditTripDetailsSection extends StatefulWidget {
  const EditTripDetailsSection({super.key});

  @override
  State<EditTripDetailsSection> createState() => _EditTripDetailsSectionState();
}

class _EditTripDetailsSectionState extends State<EditTripDetailsSection> {
  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context)!;
    final model = context.watch<TripFormModel>();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        TripFormCard(
          children: [
            TripFormFieldTile(
              icon: Icons.route,
              label: loc.addTripLineName,
              initialValue: model.line,
              onChanged: (value) => setState(() => model.line = value),
            ),
            TripFormFieldTile(
              icon: Icons.sell_outlined,
              label: loc.material,
              initialValue: model.material,
              onChanged: (value) => setState(() => model.material = value),
            ),
            TripFormFieldTile(
              icon: Icons.tag,
              label: loc.addTripRegistrationNumber,
              initialValue: model.registration,
              onChanged: (value) => setState(() => model.registration = value),
            ),
            TripFormFieldTile(
              icon: Icons.event_seat_outlined,
              label: loc.seat,
              initialValue: model.seat,
              onChanged: (value) => setState(() => model.seat = value),
            ),
          ],
        ),
        const SizedBox(height: 20),
        TripFormSectionLabel(loc.addTripNotes),
        const SizedBox(height: 8),
        TripFormNotesCard(
          initialValue: model.notes,
          onChanged: (value) => setState(() => model.notes = value),
        ),
      ],
    );
  }
}
