import 'package:flutter/foundation.dart';
import 'package:trainlog_app/core/data/models/trips_filter.dart';

/// Inputs of the "When" section of the trips search & filter sheet, shared by
/// its Material and iOS renderings.
///
/// Shows mutually exclusive quick ranges (All time, Future, This year, Past
/// 30 days, previous year) plus custom FROM / TO dates. The two mechanisms
/// are exclusive: the parent callbacks are expected to clear the custom
/// dates when a quick range is selected, and to deselect it when a custom
/// date is picked (see [TripsFilterController]).
///
/// When only FROM is set the filter matches that exact day, and the field's
/// label switches from "From" to "On" to make this visible.
mixin WhenSectionInputs {
  TripsQuickDateFilter? get quickFilter;
  DateTime? get fromDate;
  DateTime? get toDate;
  ValueChanged<TripsQuickDateFilter> get onQuickFilterSelected;
  ValueChanged<DateTime?> get onFromDateChanged;
  ValueChanged<DateTime?> get onToDateChanged;

  bool get isExactDate => fromDate != null && toDate == null;

  /// First date offered and date shown first, for the FROM or TO picker.
  ({DateTime initial, DateTime minimum}) pickBounds({required bool isFrom}) {
    final now = DateTime.now();
    final initial = isFrom ? (fromDate ?? now) : (toDate ?? fromDate ?? now);
    final minimum = isFrom ? DateTime(1900) : (fromDate ?? DateTime(1900));
    return (
      initial: initial.isBefore(minimum) ? minimum : initial,
      minimum: minimum,
    );
  }

  /// Applies a picked date; a TO date earlier than a new FROM is dropped to
  /// keep the range consistent.
  void applyPicked(DateTime? picked, {required bool isFrom}) {
    if (picked == null) return;
    if (isFrom) {
      onFromDateChanged(picked);
      if (toDate != null && toDate!.isBefore(picked)) onToDateChanged(null);
    } else {
      onToDateChanged(picked);
    }
  }
}
