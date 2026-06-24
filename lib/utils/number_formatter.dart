import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:intl/intl.dart';
import 'package:trainlog_app/l10n/app_localizations.dart';

/// SI-style magnitude factors (×1, ×10³, ×10⁶, ×10⁹) used to compact large
/// numbers.
///
/// Moved here from the deprecated `logo_bar_chart.dart` so it can be the single
/// source of truth shared by Statistics and Ranking.
enum UnitFactor {
  base     (1,   ''),
  thousand (1e3, 'k'),
  million  (1e6, 'M'),
  billion  (1e9, 'G');

  const UnitFactor(this.multiplier, this.suffix);

  final double multiplier;
  final String suffix;

  double apply(double value) => value / multiplier;

  /// The largest factor that keeps `|value|` below 1000 (or [base] when the
  /// value is already small enough).
  static UnitFactor factorFor(num value) {
    final abs = value.abs();
    if (abs >= billion.multiplier) return billion;
    if (abs >= million.multiplier) return million;
    if (abs >= thousand.multiplier) return thousand;
    return base;
  }
}

/// A measurable quantity together with its SI-prefixed unit labels.
///
/// Single source of truth for the per-[UnitFactor] labels previously hard-coded
/// in `StatisticsProvider.unitsByFactor`, so both Statistics and Ranking format
/// distances and CO₂ identically.
enum MeasurementUnit {
  /// Counts; base values are plain numbers.
  trips,

  /// Distances; base values are expressed in kilometres.
  distance,

  /// CO₂e; base values are expressed in kilograms.
  co2;

  /// The unprefixed unit label.
  String baseUnit(AppLocalizations loc) {
    switch (this) {
      case MeasurementUnit.trips:
        return loc.statisticsTripsUnitBase;
      case MeasurementUnit.distance:
        return 'km';
      case MeasurementUnit.co2:
        return 'kg';
    }
  }

  /// The unit label for each [UnitFactor], using SI prefixes for distance/CO₂.
  Map<UnitFactor, String> unitsByFactor(AppLocalizations loc) {
    switch (this) {
      case MeasurementUnit.trips:
        return {
          UnitFactor.base: loc.statisticsTripsUnitBase,
          UnitFactor.thousand: loc.statisticsTripsUnitKilo,
          UnitFactor.million: loc.statisticsTripsUnitMega,
          UnitFactor.billion: loc.statisticsTripsUnitGiga,
        };
      case MeasurementUnit.distance:
        return const {
          UnitFactor.base: 'km',
          UnitFactor.thousand: 'Mm',
          UnitFactor.million: 'Gm',
          UnitFactor.billion: 'Tm',
        };
      case MeasurementUnit.co2:
        return const {
          UnitFactor.base: 'kg',
          UnitFactor.thousand: 't',
          UnitFactor.million: 'Gg',
          UnitFactor.billion: 'Tg',
        };
    }
  }
}

/// A scaled value and its matching unit label, kept separate so callers can lay
/// them out independently (e.g. on two lines).
typedef CompactNumber = ({String value, String unit});

/// Page-agnostic number formatting.
///
/// Every method takes an explicit [Locale] (never a `BuildContext`) so the class
/// can be reused anywhere — widgets, providers, tests — and act as the single
/// source of truth for number formatting across the app. The thin top-level
/// helpers below adapt it to a `BuildContext` for existing call sites.
abstract final class NumberFormatter {
  /// Grouped decimal number; trailing decimals are stripped unless [noDecimal].
  static String decimal(
    num value, {
    required Locale locale,
    bool noDecimal = false,
  }) {
    final pattern = noDecimal ? '#,##0' : '#,##0.##';
    return NumberFormat(pattern, locale.toString()).format(value);
  }

  /// Full-precision grouped number, used for "raw value" tooltips: keeps up to
  /// [maxDecimals] fractional digits (trailing zeros stripped) so the underlying
  /// value is shown without SI scaling or the display rounding applied by
  /// [decimal] / [compactParts].
  static String precise(
    num value, {
    required Locale locale,
    int maxDecimals = 3,
  }) {
    final pattern = '#,##0.${'#' * maxDecimals}';
    return NumberFormat(pattern, locale.toString()).format(value);
  }

  /// Currency-style grouped number with an optional explicit sign.
  static String currency(
    num amount, {
    required Locale locale,
    bool showDecimal = true,
    bool showSign = false,
  }) {
    final formatter = NumberFormat.decimalPatternDigits(
      locale: locale.toString(),
      decimalDigits: showDecimal ? 2 : 0,
    );
    if (showSign) {
      if (amount > 0) return '+${formatter.format(amount.abs())}';
      if (amount < 0) return '-${formatter.format(amount.abs())}';
      return '0';
    }
    return formatter.format(amount);
  }

  /// Locale-aware percentage; [value] is already in the 0–100 range, so e.g.
  /// French renders `2,27 %` (with its space) and English `2.27%`.
  static String percent(
    num value, {
    required Locale locale,
    int maxDecimals = 2,
  }) {
    final formatter = NumberFormat.percentPattern(locale.toString())
      ..maximumFractionDigits = maxDecimals
      ..minimumFractionDigits = 0;
    // percentPattern multiplies by 100 internally; undo the 0–100 scaling.
    return formatter.format(value / 100);
  }

  /// Scales [value] by the best [UnitFactor] and returns the formatted number
  /// and the matching unit label from [unitsByFactor] (SI prefixes for
  /// distance/CO₂). Trailing decimals are stripped, up to [maxDecimals].
  static CompactNumber compactParts(
    num value, {
    required Locale locale,
    required Map<UnitFactor, String> unitsByFactor,
    int maxDecimals = 2,
  }) {
    final factor = UnitFactor.factorFor(value);
    final scaled = factor.apply(value.toDouble());
    final pattern =
        maxDecimals > 0 ? '#,##0.${'#' * maxDecimals}' : '#,##0';
    final number = NumberFormat(pattern, locale.toString()).format(scaled);
    return (value: number, unit: unitsByFactor[factor] ?? '');
  }

  /// Convenience join of [compactParts] as `"<value> <unit>"` (non-breaking
  /// space), or just the value when the unit is empty.
  static String compact(
    num value, {
    required Locale locale,
    required Map<UnitFactor, String> unitsByFactor,
    int maxDecimals = 2,
  }) {
    final parts = compactParts(
      value,
      locale: locale,
      unitsByFactor: unitsByFactor,
      maxDecimals: maxDecimals,
    );
    return parts.unit.isEmpty ? parts.value : '${parts.value} ${parts.unit}';
  }
}

// ── Backward-compatible BuildContext helpers ─────────────────────────────────
// These delegate to [NumberFormatter] so the logic lives in one place.

String formatCurrency(
  BuildContext context,
  double amount,
  bool showDecimal, {
  bool showSign = false,
}) =>
    NumberFormatter.currency(
      amount,
      locale: Localizations.localeOf(context),
      showDecimal: showDecimal,
      showSign: showSign,
    );

String formatNumber(BuildContext context, num value, {bool noDecimal = false}) =>
    NumberFormatter.decimal(
      value,
      locale: Localizations.localeOf(context),
      noDecimal: noDecimal,
    );

String formatPercent(BuildContext context, num value, {int maxDecimals = 2}) =>
    NumberFormatter.percent(
      value,
      locale: Localizations.localeOf(context),
      maxDecimals: maxDecimals,
    );

class DecimalTextInputFormatter extends TextInputFormatter {
  final RegExp _regExp = RegExp(r'^\d*([.,]\d*)?$');

  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    if (_regExp.hasMatch(newValue.text)) {
      return newValue;
    }
    return oldValue;
  }
}
