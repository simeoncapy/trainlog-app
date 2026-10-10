import 'dart:math' as math;

import 'package:trainlog_app/utils/number_formatter.dart';

/// Common magnitude shared by all values of a statistics chart: the smallest
/// [UnitFactor] keeping the largest value below 1000, and its unit label.
class StatsUnitScale {
  StatsUnitScale._(this.factor, this.unitLabel);

  /// [unitsByFactor] gives the prefixed labels (k/M/G…); without it, every
  /// factor uses [baseUnit] (e.g. durations, already in a readable base).
  factory StatsUnitScale(
    Iterable<double> values, {
    required String baseUnit,
    Map<UnitFactor, String>? unitsByFactor,
  }) {
    final maxValue = values.fold(0.0, math.max);

    var factor = UnitFactor.base;
    for (final f in UnitFactor.values) {
      factor = f;
      if (f.apply(maxValue) < 1000) break;
    }

    final label = unitsByFactor?[factor] ?? baseUnit;
    return StatsUnitScale._(factor, label);
  }

  final UnitFactor factor;
  final String unitLabel;

  double apply(double value) => factor.apply(value);
}
