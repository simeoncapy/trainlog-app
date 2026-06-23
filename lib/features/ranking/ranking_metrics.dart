import 'package:flutter/widgets.dart';

import 'package:trainlog_app/features/ranking/ranking_type.dart';
import 'package:trainlog_app/l10n/app_localizations.dart';
import 'package:trainlog_app/utils/number_formatter.dart';

/// Shared metric formatting for the Ranking feature.
///
/// Both the list rows and the user-position block need the same "what does each
/// metric look like for this entry" logic — primary value + unit, and the
/// remaining (secondary) metrics in display order. Centralising it here keeps
/// the two widgets in sync.
abstract final class RankingMetrics {
  /// The metrics applicable to [type], in their display order.
  ///
  /// World-squares is excluded — it only has a percentage, handled separately.
  static List<RankingSortUnit> unitsFor(RankingType type) {
    switch (type) {
      case RankingType.carbon:
        return const [
          RankingSortUnit.distance,
          RankingSortUnit.totalCarbon,
          RankingSortUnit.carbonPerKm,
        ];
      default:
        return const [RankingSortUnit.distance, RankingSortUnit.trips];
    }
  }

  /// Formats a single [unit] for [entry] as a value + unit pair.
  static CompactNumber format(
    BuildContext context,
    RankingDisplayEntry entry,
    RankingSortUnit unit,
  ) {
    final loc = AppLocalizations.of(context)!;
    final locale = Localizations.localeOf(context);
    switch (unit) {
      case RankingSortUnit.distance:
        return NumberFormatter.compactParts(
          entry.distanceKm,
          locale: locale,
          unitsByFactor: MeasurementUnit.distance.unitsByFactor(loc),
        );
      case RankingSortUnit.trips:
        return (
          value: NumberFormatter.decimal(entry.trips, locale: locale),
          unit: loc.menuTripCountLabel(entry.trips),
        );
      case RankingSortUnit.totalCarbon:
        return NumberFormatter.compactParts(
          entry.totalCarbonKg,
          locale: locale,
          unitsByFactor: MeasurementUnit.co2.unitsByFactor(loc),
        );
      case RankingSortUnit.carbonPerKm:
        return (
          value: NumberFormatter.decimal(entry.carbonPerKmG,
              locale: locale, noDecimal: true),
          unit: 'g/km',
        );
    }
  }

  /// Joins a [CompactNumber] as `"<value> <unit>"` (or just the value when the
  /// unit is empty).
  static String inline(CompactNumber n) =>
      n.unit.isEmpty ? n.value : '${n.value} ${n.unit}';

  /// The primary metric (the active [unit], or the percentage for
  /// world-squares) as a value + unit pair.
  static CompactNumber primary(
    BuildContext context,
    RankingDisplayEntry entry,
    RankingSelection selection,
    RankingSortUnit unit,
  ) {
    if (selection.isWorldSquares) {
      return (
        value: NumberFormatter.decimal(entry.percent ?? 0,
            locale: Localizations.localeOf(context)),
        unit: '%',
      );
    }
    return format(context, entry, unit);
  }

  /// The primary metric as a single inline string. World-squares uses the
  /// locale-aware percent (e.g. the French space before `%`).
  static String primaryInline(
    BuildContext context,
    RankingDisplayEntry entry,
    RankingSelection selection,
    RankingSortUnit unit,
  ) {
    if (selection.isWorldSquares) {
      return NumberFormatter.percent(
        entry.percent ?? 0,
        locale: Localizations.localeOf(context),
      );
    }
    return inline(format(context, entry, unit));
  }

  /// The non-primary metrics, formatted inline, in display order. Empty for
  /// world-squares.
  static List<String> secondaries(
    BuildContext context,
    RankingDisplayEntry entry,
    RankingSelection selection,
    RankingSortUnit unit,
  ) {
    if (selection.isWorldSquares) return const [];
    return [
      for (final u in unitsFor(selection.type))
        if (u != unit) inline(format(context, entry, u)),
    ];
  }
}
