import 'package:flutter/material.dart';
import 'package:trainlog_app/app/theme/app_theme.dart';
import 'package:trainlog_app/data/models/trips.dart';
import 'package:trainlog_app/features/trips/detail_sheet/trip_details_common.dart';
import 'package:trainlog_app/l10n/app_localizations.dart';
import 'package:trainlog_app/utils/number_formatter.dart';

/// Summary metric cards (Distance, Average speed). The "Duration" card is
/// deliberately omitted because the timeline already surfaces the duration
/// through its central pill. Numerical values use a monospace font and are
/// preceded by a contextual icon.
class TripDetailsMetrics extends StatelessWidget {
  final Trips trip;

  const TripDetailsMetrics({super.key, required this.trip});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    final cards = <Widget>[];

    // Distance (km) — only when the trip carries a length.
    if (trip.tripLength > 0) {
      cards.add(_MetricCard(
        icon: Icons.straighten,
        value: formatNumber(context, (trip.tripLength / 1000).round()),
        unit: 'km',
        label: l10n.tripsDetailsMetricDistance,
      ));
    }

    // Average speed (km/h) — needs both a distance and a positive duration.
    final seconds = trip.duration.inSeconds;
    if (trip.tripLength > 0 && seconds > 0) {
      final speed = (trip.tripLength / 1000) / (seconds / 3600);
      cards.add(_MetricCard(
        icon: Icons.speed,
        value: formatNumber(context, speed.round()),
        unit: 'km/h',
        label: l10n.tripsDetailsMetricAvgSpeed,
      ));
    }

    if (cards.isEmpty) return const SizedBox.shrink();

    return Row(
      children: [
        for (var i = 0; i < cards.length; i++) ...[
          if (i > 0) const SizedBox(width: 12),
          Expanded(child: cards[i]),
        ],
      ],
    );
  }
}

class _MetricCard extends StatelessWidget {
  final IconData icon;
  final String value;
  final String unit;
  final String label;

  const _MetricCard({
    required this.icon,
    required this.value,
    required this.unit,
    required this.label,
  });

  @override
  Widget build(BuildContext context) {
    final muted = detailMutedColor(context);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: detailSurfaceColor(context),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: detailBorderColor(context)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Icon(icon, size: 16, color: muted),
              const SizedBox(width: 6),
              Flexible(
                child: Text.rich(
                  TextSpan(children: [
                    TextSpan(
                      text: value,
                      style: AppTheme.monoFont.copyWith(
                        fontSize: 22,
                        fontWeight: FontWeight.w700,
                        color: Theme.of(context).colorScheme.onSurface,
                      ),
                    ),
                    TextSpan(
                      text: ' $unit',
                      style: TextStyle(fontSize: 12, color: muted),
                    ),
                  ]),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: TextStyle(fontSize: 13, color: muted),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }
}
