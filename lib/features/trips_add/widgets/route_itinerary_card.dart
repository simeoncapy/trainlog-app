import 'package:flutter/material.dart';

/// Kind of timeline marker shown in front of a [RouteItineraryStop] row.
enum RouteItineraryMarker {
  /// Hollow rounded square tinted with the route colour.
  departure,

  /// Small muted dot, used by intermediate waypoints ("via stops").
  via,

  /// Filled rounded square tinted with the route colour.
  arrival,
}

/// One location row of a [RouteItineraryCard].
class RouteItineraryStop {
  const RouteItineraryStop({
    required this.title,
    this.subtitle,
    required this.marker,
  });

  /// Location name (station, airport, stop…).
  final String title;

  /// Muted line under the title, e.g. "Departure · 20:03".
  final String? subtitle;

  final RouteItineraryMarker marker;
}

/// Trip itinerary card of the add-trip flow: an ordered timeline of location
/// rows, each with a geometric route marker tinted with the vehicle colour.
///
/// The card renders any list of stops, so intermediate waypoint rows
/// ([RouteItineraryMarker.via]) can be added between the departure and the
/// arrival without touching the layout.
class RouteItineraryCard extends StatelessWidget {
  const RouteItineraryCard({
    super.key,
    required this.stops,
    required this.markerColour,
  });

  /// Ordered locations of the itinerary, departure first.
  final List<RouteItineraryStop> stops;

  /// Primary colour of the selected vehicle type, used to tint the
  /// departure/arrival markers.
  final Color markerColour;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      decoration: BoxDecoration(
        color: theme.cardColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: theme.colorScheme.outline),
      ),
      child: Column(
        children: [
          for (var i = 0; i < stops.length; i++) ...[
            if (i > 0) Divider(height: 1, color: theme.dividerColor),
            _StopRow(stop: stops[i], markerColour: markerColour),
          ],
        ],
      ),
    );
  }
}

class _StopRow extends StatelessWidget {
  const _StopRow({required this.stop, required this.markerColour});

  final RouteItineraryStop stop;
  final Color markerColour;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        children: [
          SizedBox(
            width: 14,
            child: Center(child: _marker(theme)),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  stop.title,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: theme.textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.w700,
                    color: theme.colorScheme.onSurface,
                  ),
                ),
                if (stop.subtitle != null) ...[
                  const SizedBox(height: 2),
                  Text(
                    stop.subtitle!,
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  /// Departure/arrival use the square timeline markers of the route step;
  /// via stops use a small muted dot so the endpoints stay dominant.
  Widget _marker(ThemeData theme) {
    switch (stop.marker) {
      case RouteItineraryMarker.departure:
      case RouteItineraryMarker.arrival:
        final filled = stop.marker == RouteItineraryMarker.arrival;
        return Container(
          width: 14,
          height: 14,
          decoration: BoxDecoration(
            color: filled ? markerColour : Colors.transparent,
            borderRadius: BorderRadius.circular(4),
            border: Border.all(color: markerColour, width: 2.5),
          ),
        );
      case RouteItineraryMarker.via:
        return Container(
          width: 10,
          height: 10,
          decoration: BoxDecoration(
            color: theme.colorScheme.onSurfaceVariant,
            shape: BoxShape.circle,
          ),
        );
    }
  }
}
