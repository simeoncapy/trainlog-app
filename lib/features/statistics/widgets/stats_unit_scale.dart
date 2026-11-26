import 'dart:math' as math;

import 'package:trainlog_app/utils/number_formatter.dart';

/// Common magnitude shared by all values of a statistics chart: the smallest
/// [UnitFactor] keeping the largest value below 1000, and its unit label.
class StatsUnitScale {
  StatsUnitScale._(this.factor, this.unitLabel, this._baseUnitFor);

  /// [baseUnitFor] gives the base unit's singular or plural form for a
  /// value (e.g. "trip" / "trips").
  /// [unitsByFactor] gives the prefixed labels (k/M/G…); without it, every
  /// factor uses [baseUnit] (e.g. durations, already in a readable base).
  factory StatsUnitScale(
    Iterable<double> values, {
    required String baseUnit,
    Map<UnitFactor, String>? unitsByFactor,
    String Function(double value)? baseUnitFor,
  }) {
    final maxValue = values.fold(0.0, math.max);

    var factor = UnitFactor.base;
    for (final f in UnitFactor.values) {
      factor = f;
      if (f.apply(maxValue) < 1000) break;
    }

    final label = unitsByFactor?[factor] ?? baseUnit;
    return StatsUnitScale._(factor, label, baseUnitFor);
  }

  final UnitFactor factor;
  final String unitLabel;

  final String Function(double value)? _baseUnitFor;

  double apply(double value) => factor.apply(value);

  /// The unit written after [scaledValue]: singular or plural ("1 trip",
  /// "2 trips") when the scale is the base unit and has a plural form,
  /// otherwise [unitLabel].
  String unitFor(double scaledValue) =>
      factor == UnitFactor.base && _baseUnitFor != null
          ? _baseUnitFor(scaledValue)
          : unitLabel;
}
