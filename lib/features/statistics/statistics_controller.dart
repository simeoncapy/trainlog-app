import 'dart:collection';

import 'package:flutter/foundation.dart';

/// How the statistics are drawn.
enum StatisticsView { bar, pie, table }

/// One entry of the statistics: its past and planned-future values.
typedef StatisticsEntry = ({double past, double future});

/// The Statistics page's own state: the chosen view and the sort order. The
/// data (dimension, vehicle, unit, year) stays in `StatisticsProvider`.
class StatisticsController extends ChangeNotifier {
  StatisticsController({StatisticsView view = StatisticsView.bar})
      : _view = view;

  StatisticsView _view;
  bool _sortedAlpha = false;

  StatisticsView get view => _view;

  /// Alphabetical order instead of the biggest value first.
  bool get sortedAlpha => _sortedAlpha;

  /// The pie keeps its own order (biggest slice first), so it has no sort.
  bool get canSort => _view != StatisticsView.pie;

  set view(StatisticsView value) {
    if (value == _view) return;
    _view = value;
    notifyListeners();
  }

  set sortedAlpha(bool value) {
    if (value == _sortedAlpha) return;
    _sortedAlpha = value;
    notifyListeners();
  }

  void toggleSort() => sortedAlpha = !_sortedAlpha;

  /// [stats] in the page's order: alphabetical on the displayed label
  /// ([labelOf], e.g. a country's name) or biggest total first, with
  /// [otherLabel] always last.
  static LinkedHashMap<String, StatisticsEntry> ordered(
    Map<String, StatisticsEntry> stats, {
    required bool alpha,
    required String otherLabel,
    String Function(String key)? labelOf,
  }) {
    final entries = stats.entries.toList();
    final other = entries.where((e) => e.key == otherLabel).toList();
    final rest = entries.where((e) => e.key != otherLabel).toList();

    String sortKey(String key) => (labelOf?.call(key) ?? key).toLowerCase();

    if (alpha) {
      rest.sort((a, b) => sortKey(a.key).compareTo(sortKey(b.key)));
    } else {
      rest.sort((a, b) {
        final ta = a.value.past + a.value.future;
        final tb = b.value.past + b.value.future;
        final cmp = tb.compareTo(ta);
        return cmp != 0 ? cmp : sortKey(a.key).compareTo(sortKey(b.key));
      });
    }
    return LinkedHashMap.fromEntries([...rest, ...other]);
  }

  /// The table shows only the total for a past year (nothing is planned
  /// there); all years and the current year keep past and future.
  static bool tableOnlyTotal(int? year, {required int currentYear}) =>
      switch (year) {
        null || 0 => false,
        final y when y == currentYear => false,
        _ => true,
      };
}
