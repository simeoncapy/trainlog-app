import 'package:flutter/foundation.dart';
import 'package:trainlog_app/data/models/trips.dart';

/// Quick date filters shown as mutually exclusive choice chips in the
/// "When" section of the trips search & filter sheet.
enum TripsQuickDateFilter {
  allTime,
  future,
  thisYear,
  past30Days,

  /// The previous calendar year — its chip label is computed dynamically
  /// (e.g. "2025" when the current year is 2026).
  previousYear,
}

/// Immutable description of the trips search & filter state.
///
/// Date semantics: either a [quickDateFilter] chip OR a custom
/// [customStartDate] / [customEndDate] pair is active, never both (the sheet
/// enforces the mutual exclusivity; a null [quickDateFilter] means custom
/// dates are in charge). When only [customStartDate] is set the filter means
/// "ON that exact day".
class TripsFilterResult {
  final String keyword;

  /// Selected quick chip; null while custom dates are active.
  final TripsQuickDateFilter? quickDateFilter;

  /// Custom range start ("From"). If [customEndDate] is null this is an
  /// exact-day match ("On").
  final DateTime? customStartDate;

  /// Custom range end ("To") — always optional.
  final DateTime? customEndDate;

  /// Selected ISO country codes. Empty means "no country restriction".
  final Set<String> countries;

  /// Selected (decoded) operator names. Empty means "no operator restriction".
  final Set<String> operators;

  /// Selected vehicle types. Empty means "no type restriction".
  final List<VehicleType> types;

  const TripsFilterResult({
    this.keyword = '',
    this.quickDateFilter = TripsQuickDateFilter.allTime,
    this.customStartDate,
    this.customEndDate,
    this.countries = const {},
    this.operators = const {},
    this.types = const [],
  });

  /// True when the "From" date acts as an exact-day ("On") filter.
  bool get isExactDate => customStartDate != null && customEndDate == null;

  bool get hasCustomDates => customStartDate != null || customEndDate != null;

  /// Resolves the active date constraint into a half-open interval
  /// [start, end). Either bound may be null (unbounded).
  ({DateTime? start, DateTime? end}) dateRange({DateTime? now}) {
    final ref = now ?? DateTime.now();

    if (hasCustomDates) {
      DateTime? start;
      DateTime? end;
      final from = customStartDate;
      final to = customEndDate;
      if (from != null) {
        start = DateTime(from.year, from.month, from.day);
      }
      if (to != null) {
        end = DateTime(to.year, to.month, to.day).add(const Duration(days: 1));
      } else if (from != null) {
        // "On" semantics: match that exact day only.
        end = start!.add(const Duration(days: 1));
      }
      return (start: start, end: end);
    }

    switch (quickDateFilter) {
      case null:
      case TripsQuickDateFilter.allTime:
        return (start: null, end: null);
      case TripsQuickDateFilter.future:
        return (start: ref, end: null);
      case TripsQuickDateFilter.thisYear:
        return (start: DateTime(ref.year), end: DateTime(ref.year + 1));
      case TripsQuickDateFilter.past30Days:
        return (start: ref.subtract(const Duration(days: 30)), end: ref);
      case TripsQuickDateFilter.previousYear:
        return (start: DateTime(ref.year - 1), end: DateTime(ref.year));
    }
  }

  /// Whether this filter narrows down the trips by date. When true the
  /// page-level past/future scoping is overridden by the range.
  bool get hasDateConstraint {
    final range = dateRange();
    return range.start != null || range.end != null;
  }

  /// True when nothing is filtered — treat the same as "no filter".
  bool get isEmpty =>
      keyword.trim().isEmpty &&
      !hasDateConstraint &&
      countries.isEmpty &&
      operators.isEmpty &&
      types.isEmpty;

  TripsFilterResult copyWith({
    String? keyword,
    TripsQuickDateFilter? quickDateFilter,
    bool clearQuickDateFilter = false,
    DateTime? customStartDate,
    bool clearCustomStartDate = false,
    DateTime? customEndDate,
    bool clearCustomEndDate = false,
    Set<String>? countries,
    Set<String>? operators,
    List<VehicleType>? types,
  }) {
    return TripsFilterResult(
      keyword: keyword ?? this.keyword,
      quickDateFilter: clearQuickDateFilter
          ? null
          : (quickDateFilter ?? this.quickDateFilter),
      customStartDate:
          clearCustomStartDate ? null : (customStartDate ?? this.customStartDate),
      customEndDate:
          clearCustomEndDate ? null : (customEndDate ?? this.customEndDate),
      countries: countries ?? this.countries,
      operators: operators ?? this.operators,
      types: types ?? this.types,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is TripsFilterResult &&
        other.keyword == keyword &&
        other.quickDateFilter == quickDateFilter &&
        other.customStartDate == customStartDate &&
        other.customEndDate == customEndDate &&
        setEquals(other.countries, countries) &&
        setEquals(other.operators, operators) &&
        listEquals(other.types, types);
  }

  @override
  int get hashCode => Object.hash(
        keyword,
        quickDateFilter,
        customStartDate,
        customEndDate,
        Object.hashAllUnordered(countries),
        Object.hashAllUnordered(operators),
        Object.hashAll(types),
      );
}
