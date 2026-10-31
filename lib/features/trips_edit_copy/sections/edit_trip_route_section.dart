import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:trainlog_app/data/models/trip_form_model.dart';
import 'package:trainlog_app/l10n/app_localizations.dart';
import 'package:trainlog_app/widgets/trip_form/trip_form_card.dart';
import 'package:trainlog_app/widgets/trip_form/trip_form_tiles.dart';

/// Route block of the edit form: departure and arrival as plain text fields —
/// no chevron, no search overlay — since only their displayed name can be
/// changed here, which the helper note under the card spells out.
class EditTripRouteSection extends StatelessWidget {
  const EditTripRouteSection({super.key, required this.markerColour});

  /// Vehicle colour of the trip, used by the endpoint markers.
  final Color markerColour;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final loc = AppLocalizations.of(context)!;
    final model = context.watch<TripFormModel>();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        TripFormCard(
          children: [
            TripFormFieldTile(
              leading: RouteEndpointMarker(colour: markerColour, filled: false),
              label: loc.addTripDeparture,
              initialValue: model.departureStationName,
              onChanged: model.setDepartureDisplayName,
            ),
            TripFormFieldTile(
              leading: RouteEndpointMarker(colour: markerColour, filled: true),
              label: loc.addTripArrival,
              initialValue: model.arrivalStationName,
              onChanged: model.setArrivalDisplayName,
            ),
          ],
        ),
        const SizedBox(height: 8),
        Text(
          loc.editTripStationNameHelper,
          style: theme.textTheme.bodySmall?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
          ),
        ),
      ],
    );
  }
}
