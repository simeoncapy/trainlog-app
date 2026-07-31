import 'package:flutter/material.dart';
import 'package:trainlog_app/data/models/trips.dart';
import 'package:trainlog_app/l10n/app_localizations.dart';
import 'package:trainlog_app/widgets/trip_form/trip_form_card.dart';

/// Card at the top of the edit form showing the vehicle type of the trip,
/// with a trailing "Change >" button opening the isolated vehicle type page.
class EditTripVehicleCard extends StatelessWidget {
  const EditTripVehicleCard({
    super.key,
    required this.type,
    required this.colour,
    required this.onChange,
  });

  final VehicleType type;

  /// Vehicle colour from the user's map palette.
  final Color colour;

  final VoidCallback onChange;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final loc = AppLocalizations.of(context)!;

    return TripFormCard(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      children: [
        Row(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: colour.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(10),
              ),
              child: IconTheme(
                data: IconThemeData(color: colour, size: 22),
                child: Center(child: type.icon()),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  TripFormSectionLabel(loc.editTripVehicleTypeLabel),
                  const SizedBox(height: 2),
                  Text(
                    type.label(context),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
            TextButton(
              onPressed: onChange,
              style: TextButton.styleFrom(
                foregroundColor: theme.colorScheme.primary,
                visualDensity: VisualDensity.compact,
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    loc.editTripChangeButton,
                    style: const TextStyle(fontWeight: FontWeight.w700),
                  ),
                  const Icon(Icons.chevron_right, size: 18),
                ],
              ),
            ),
          ],
        ),
      ],
    );
  }
}
