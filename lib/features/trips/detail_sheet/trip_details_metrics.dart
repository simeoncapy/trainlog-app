import 'package:flutter/material.dart';
import 'package:trainlog_app/ui/tokens/app_colors.dart';
import 'package:trainlog_app/ui/tokens/app_theme.dart';
import 'package:trainlog_app/core/data/models/trips.dart';
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
        label: l10n.distance,
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

    final style = TripDetailsStyle.of(context);

    // iOS: no cards, a row of captioned stats like the place facts of
    // Apple Maps (caption above, icon and value below), with the duration
    // between the distance and the speed. Spread evenly when they fit,
    // scrolled sideways when they do not.
    if (!style.metricCards) {
      final stats = cards.cast<_MetricCard>().toList();
      if (!style.durationInTimeline && !trip.isUnknownPastFuture) {
        final real = trip.realDuration;
        final showReal = real != null &&
            ((real - trip.duration).inSeconds / 60).round() != 0;
        stats.insert(
          stats.isEmpty ? 0 : 1,
          _MetricCard(
            icon: Icons.schedule,
            value: showReal
                ? trip.realDurationFormatted!
                : trip.durationFormatted,
            unit: '',
            label: l10n.duration,
            valueColor: showReal
                ? (real > trip.duration ? AppColors.late : AppColors.early)
                : null,
          ),
        );
      }
      if (stats.isEmpty) return const SizedBox.shrink();
      return LayoutBuilder(
        builder: (context, constraints) => SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: ConstrainedBox(
            constraints: BoxConstraints(minWidth: constraints.maxWidth),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                for (final stat in stats)
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 10),
                    child: _MetricStat(card: stat),
                  ),
              ],
            ),
          ),
        ),
      );
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

  /// Colour of the figure; null for the normal text colour.
  final Color? valueColor;

  const _MetricCard({
    required this.icon,
    required this.value,
    required this.unit,
    required this.label,
    this.valueColor,
  });

  @override
  Widget build(BuildContext context) {
    final muted = detailMutedColor(context);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: detailFillDecoration(
        context,
        radius: TripDetailsStyle.of(context).metricRadius,
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

/// One stat of the iOS row: the caption on top in the secondary colour, the
/// icon and the figure below.
class _MetricStat extends StatelessWidget {
  final _MetricCard card;

  const _MetricStat({required this.card});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final muted = detailMutedColor(context);
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          card.label,
          style: theme.textTheme.labelLarge?.copyWith(
            color: muted,
            fontWeight: FontWeight.w600,
            letterSpacing: 0,
          ),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        const SizedBox(height: 2),
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(card.icon, size: 16, color: theme.colorScheme.onSurface),
            const SizedBox(width: 6),
            Text.rich(
              TextSpan(
                children: [
                  TextSpan(
                    text: card.value,
                    style: theme.textTheme.titleMedium
                        ?.merge(AppTheme.monoFont)
                        .copyWith(
                          color: card.valueColor ?? theme.colorScheme.onSurface,
                        ),
                  ),
                  if (card.unit.isNotEmpty)
                    TextSpan(
                      text: ' ${card.unit}',
                      style: theme.textTheme.bodySmall?.copyWith(color: muted),
                    ),
                ],
              ),
              maxLines: 1,
            ),
          ],
        ),
      ],
    );
  }
}
