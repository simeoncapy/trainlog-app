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

  /// The raw, full-precision value of [unit] for [entry], expressed in the base
  /// unit (km, kg, g/km…), for a "tap to reveal" tooltip.
  ///
  /// Returns null for metrics that are already shown exactly — a plain trip
  /// count is neither rounded nor SI-prefixed, so it needs no tooltip.
  static String? rawTooltip(
    BuildContext context,
    RankingDisplayEntry entry,
    RankingSortUnit unit,
  ) {
    final loc = AppLocalizations.of(context)!;
    final locale = Localizations.localeOf(context);
    switch (unit) {
      case RankingSortUnit.distance:
        return '${NumberFormatter.precise(entry.distanceKm, locale: locale)} '
            '${MeasurementUnit.distance.baseUnit(loc)}';
      case RankingSortUnit.totalCarbon:
        return '${NumberFormatter.precise(entry.totalCarbonKg, locale: locale)} '
            '${MeasurementUnit.co2.baseUnit(loc)}';
      case RankingSortUnit.carbonPerKm:
        return '${NumberFormatter.precise(entry.carbonPerKmG, locale: locale)} '
            'g/km';
      case RankingSortUnit.trips:
        return null;
    }
  }

  /// The raw-value tooltip for the primary metric, or null when the displayed
  /// value is already exact. World-squares shows a percentage with no SI prefix
  /// and the country view a plain count, so neither needs a tooltip.
  static String? primaryTooltip(
    BuildContext context,
    RankingDisplayEntry entry,
    RankingSelection selection,
    RankingSortUnit unit,
  ) {
    if (selection.isWorldSquares || selection.isCountry) return null;
    return rawTooltip(context, entry, unit);
  }

  /// The primary metric (the active [unit], the percentage for world-squares,
  /// or the country count for the country view) as a value + unit pair.
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
    if (selection.isCountry) {
      final loc = AppLocalizations.of(context)!;
      return (
        value: NumberFormatter.decimal(entry.countryCount,
            locale: Localizations.localeOf(context)),
        unit: loc.rankingCountryCountLabel(entry.countryCount),
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
    return inline(primary(context, entry, selection, unit));
  }

  /// The non-primary metrics, each as its inline string plus the optional
  /// raw-value tooltip, in display order. Empty for world-squares and the
  /// country view (both are single-metric).
  static List<RankingMetricText> secondaryMetrics(
    BuildContext context,
    RankingDisplayEntry entry,
    RankingSelection selection,
    RankingSortUnit unit,
  ) {
    if (selection.isWorldSquares || selection.isCountry) return const [];
    return [
      for (final u in unitsFor(selection.type))
        if (u != unit)
          (
            inline: inline(format(context, entry, u)),
            tooltip: rawTooltip(context, entry, u),
          ),
    ];
  }

  /// The non-primary metrics, formatted inline, in display order. Empty for
  /// world-squares.
  static List<String> secondaries(
    BuildContext context,
    RankingDisplayEntry entry,
    RankingSelection selection,
    RankingSortUnit unit,
  ) =>
      [
        for (final m in secondaryMetrics(context, entry, selection, unit))
          m.inline,
      ];
}

/// A formatted metric: the [inline] display string and, when the displayed value
/// is rounded or SI-prefixed, the raw base-unit [tooltip] to reveal on tap.
typedef RankingMetricText = ({String inline, String? tooltip});
