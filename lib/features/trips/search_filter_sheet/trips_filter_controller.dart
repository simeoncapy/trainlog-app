import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:trainlog_app/core/data/models/trips.dart';
import 'package:trainlog_app/core/data/models/trips_filter.dart';
import 'package:trainlog_app/core/data/trips_repository.dart';

/// State and actions of the trips search & filter sheet, shared by its
/// Material and iOS views.
///
/// Holds the working copy of the filter (keyword, period, countries,
/// operators, vehicle types), loads the trip counts per country and
/// operator, and keeps [matchCount] (the "Show N trips" preview) up to date
/// against the repository. [result] is what the sheet returns when the user
/// confirms.
class TripsFilterController extends ChangeNotifier {
  TripsFilterController({
    required TripsRepository repo,
    required List<String> countryCodes,
    required this.typeOptions,
    required bool showFutureTrips,
    TripsFilterResult? initialFilter,
  }) : _repo = repo,
       _countryCodes = countryCodes,
       _showFutureTrips = showFutureTrips {
    final f = initialFilter;
    if (f != null) {
      _keyword = f.keyword;
      _quickFilter = f.quickDateFilter;
      _fromDate = f.customStartDate;
      _toDate = f.customEndDate;
      _countries = Set.of(f.countries);
      _operators = Set.of(f.operators);
      _types = f.types.isEmpty ? Set.of(typeOptions) : Set.of(f.types);
    } else {
      _countries = {};
      _operators = {};
      _types = Set.of(typeOptions);
    }
  }

  final TripsRepository _repo;

  /// Every country present in the user's trips (ISO codes).
  final List<String> _countryCodes;

  /// Every vehicle type present in the user's trips.
  final List<VehicleType> typeOptions;

  /// Page-level Past/Future scope, used for the preview count when the
  /// filter itself carries no date constraint.
  final bool _showFutureTrips;

  /// Delay before the preview count is refreshed after a change.
  static const countDebounce = Duration(milliseconds: 250);

  String _keyword = '';
  TripsQuickDateFilter? _quickFilter = TripsQuickDateFilter.allTime;
  DateTime? _fromDate;
  DateTime? _toDate;
  late Set<String> _countries;
  late Set<String> _operators;
  late Set<VehicleType> _types;

  /// value → number of trips, ordered by count (descending).
  Map<String, int> _countryTripCounts = const {};
  Map<String, int> _operatorTripCounts = const {};

  int _matchCount = 0;
  Timer? _countTimer;
  bool _disposed = false;

  // ── State ──────────────────────────────────────────────────────────────────

  String get keyword => _keyword;
  TripsQuickDateFilter? get quickFilter => _quickFilter;
  DateTime? get fromDate => _fromDate;
  DateTime? get toDate => _toDate;
  Set<String> get countries => Set.unmodifiable(_countries);
  Set<String> get operators => Set.unmodifiable(_operators);
  Set<VehicleType> get types => Set.unmodifiable(_types);

  /// Number of trips the current filter matches.
  int get matchCount => _matchCount;

  bool get allTypesSelected =>
      typeOptions.isNotEmpty && typeOptions.every(_types.contains);

  /// Countries with their trip count: those with trips first, by count,
  /// then any other known country (count 0).
  List<({String value, int count})> get countryChoices {
    final seen = <String>{};
    return [
      for (final e in _countryTripCounts.entries)
        if (seen.add(e.key)) (value: e.key, count: e.value),
      for (final code in _countryCodes)
        if (seen.add(code)) (value: code, count: 0),
    ];
  }

  /// Operators with their trip count, by count.
  List<({String value, int count})> get operatorChoices => [
    for (final e in _operatorTripCounts.entries) (value: e.key, count: e.value),
  ];

  /// The filter to apply, as the sheet returns it.
  TripsFilterResult get result {
    // A selection covering every available type is no restriction at all.
    final restrictsTypes =
        _types.length < typeOptions.length || !_types.containsAll(typeOptions);
    return TripsFilterResult(
      keyword: _keyword.trim(),
      quickDateFilter: _quickFilter,
      customStartDate: _fromDate,
      customEndDate: _toDate,
      countries: Set.of(_countries),
      operators: Set.of(_operators),
      types: restrictsTypes
          ? typeOptions.where(_types.contains).toList()
          : const [],
    );
  }

  // ── Loading ────────────────────────────────────────────────────────────────

  /// Loads the per-country and per-operator trip counts and the first
  /// preview count.
  Future<void> load() async {
    unawaited(_refreshCount());
    final operatorCounts = await _repo.fetchOperatorsByTripPF();
    final countryCounts = await _repo.fetchCountriesByTripPF();
    if (_disposed) return;
    _operatorTripCounts = {
      for (final e in operatorCounts.entries)
        e.key: e.value.past + e.value.future,
    };
    _countryTripCounts = {
      for (final e in countryCounts.entries)
        e.key: e.value.past + e.value.future,
    };
    notifyListeners();
  }

  // ── Actions ────────────────────────────────────────────────────────────────

  void setKeyword(String value) {
    if (value == _keyword) return;
    _keyword = value;
    _changed();
  }

  /// Picks a quick period chip; it clears any custom dates.
  void selectQuickFilter(TripsQuickDateFilter? value) {
    _quickFilter = value;
    _fromDate = null;
    _toDate = null;
    _changed();
  }

  /// Switches to a custom date range (no quick chip), keeping the dates.
  void selectCustomRange() {
    _quickFilter = null;
    _changed();
  }

  /// Touching the custom range deselects the quick chip.
  void setFromDate(DateTime? date) {
    _fromDate = date;
    _quickFilter = null;
    _changed();
  }

  void setToDate(DateTime? date) {
    _toDate = date;
    _quickFilter = null;
    _changed();
  }

  void setCountrySelected(String code, bool selected) {
    selected ? _countries.add(code) : _countries.remove(code);
    _changed();
  }

  void selectAllCountries() {
    _countries
      ..clear()
      ..addAll(countryChoices.map((e) => e.value));
    _changed();
  }

  void clearCountries() {
    _countries.clear();
    _changed();
  }

  void setOperatorSelected(String name, bool selected) {
    selected ? _operators.add(name) : _operators.remove(name);
    _changed();
  }

  void selectAllOperators() {
    _operators
      ..clear()
      ..addAll(_operatorTripCounts.keys);
    _changed();
  }

  void clearOperators() {
    _operators.clear();
    _changed();
  }

  void setTypeSelected(VehicleType type, bool selected) {
    selected ? _types.add(type) : _types.remove(type);
    _changed();
  }

  void selectAllTypes() {
    _types = Set.of(typeOptions);
    _changed();
  }

  void clearTypes() {
    _types.clear();
    _changed();
  }

  /// Back to no filter at all.
  void reset() {
    _keyword = '';
    _quickFilter = TripsQuickDateFilter.allTime;
    _fromDate = null;
    _toDate = null;
    _countries.clear();
    _operators.clear();
    _types = Set.of(typeOptions);
    _changed();
  }

  // ── Internals ──────────────────────────────────────────────────────────────

  void _changed() {
    notifyListeners();
    _countTimer?.cancel();
    _countTimer = Timer(countDebounce, _refreshCount);
  }

  Future<void> _refreshCount() async {
    final count = await _repo.countFilteredTrips(
      showFutureTrips: _showFutureTrips,
      filter: result,
    );
    if (_disposed) return;
    _matchCount = count;
    notifyListeners();
  }

  @override
  void dispose() {
    _disposed = true;
    _countTimer?.cancel();
    super.dispose();
  }
}
