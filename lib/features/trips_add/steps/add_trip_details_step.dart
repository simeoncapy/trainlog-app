import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:trainlog_app/app/theme/app_theme.dart';
import 'package:trainlog_app/data/models/trip_form_model.dart';
import 'package:trainlog_app/l10n/app_localizations.dart';
import 'package:trainlog_app/widgets/trip_form/trip_form_card.dart';
import 'package:trainlog_app/widgets/trip_form/trip_form_tiles.dart';

/// Step 5 of the "Add Trip" wizard: optional trip details.
///
/// A bold headline with an "all optional" subtitle, then a grouped card of
/// free-text line items (line name, material, registration number, seat)
/// and a standalone note card whose field grows with its content. All
/// values are written straight into [TripFormModel]; the step is skippable
/// and never blocks progression.
class AddTripDetailsStep extends StatefulWidget {
  const AddTripDetailsStep({super.key});

  @override
  State<AddTripDetailsStep> createState() => _AddTripDetailsStepState();
}

class _AddTripDetailsStepState extends State<AddTripDetailsStep> {
  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final model = context.watch<TripFormModel>();

    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(24, 8, 24, 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            loc.addTripDetailsTitle,
            style: AppTheme.displayFont.copyWith(
              fontSize: 26,
              fontWeight: FontWeight.w700,
              color: theme.colorScheme.onSurface,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            loc.addTripDetailsSubtitle,
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 20),

          TripFormCard(
            children: [
              TripFormFieldTile(
                icon: Icons.route,
                label: loc.addTripLineName,
                initialValue: model.line,
                onChanged: (value) {
                  setState(() => model.line = value);
                },
              ),
              TripFormFieldTile(
                icon: Icons.sell_outlined,
                label: loc.material,
                initialValue: model.material,
                onChanged: (value) {
                  setState(() => model.material = value);
                },
              ),
              TripFormFieldTile(
                icon: Icons.tag,
                label: loc.addTripRegistrationNumber,
                initialValue: model.registration,
                onChanged: (value) {
                  setState(() => model.registration = value);
                },
              ),
              TripFormFieldTile(
                icon: Icons.event_seat_outlined,
                label: loc.seat,
                initialValue: model.seat,
                onChanged: (value) {
                  setState(() => model.seat = value);
                },
              ),
            ],
          ),
          const SizedBox(height: 20),

          TripFormSectionLabel(loc.addTripNotes),
          const SizedBox(height: 8),
          TripFormNotesCard(
            initialValue: model.notes,
            onChanged: (value) {
              setState(() => model.notes = value);
            },
          ),
        ],
      ),
    );
  }
}
