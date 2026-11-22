import 'dart:collection';

import 'package:flutter_test/flutter_test.dart';
import 'package:trainlog_app/core/data/models/trips.dart';
import 'package:trainlog_app/core/data/models/trips_filter.dart';
import 'package:trainlog_app/core/data/trips_repository.dart';
import 'package:trainlog_app/features/trips/search_filter_sheet/trips_filter_controller.dart';

/// Answers the three queries the filter controller makes.
class _FakeRepo implements TripsRepository {
  final filters = <TripsFilterResult?>[];

  @override
  Future<int> countFilteredTrips({
    required bool showFutureTrips,
    TripsFilterResult? filter,
  }) async {
    filters.add(filter);
    return filter?.countries.length ?? 0;
  }

  @override
  Future<LinkedHashMap<String, ({int past, int future})>>
  fetchOperatorsByTripPF({TripsFilterResult? filter}) async => LinkedHashMap.of(
    {'SNCF': (past: 3, future: 1), 'JR': (past: 2, future: 0)},
  );

  @override
  Future<LinkedHashMap<String, ({int past, int future})>>
  fetchCountriesByTripPF({TripsFilterResult? filter}) async =>
      LinkedHashMap.of({'FR': (past: 5, future: 0)});

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

void main() {
  late _FakeRepo repo;
  late TripsFilterController filter;

  setUp(() {
    repo = _FakeRepo();
    filter = TripsFilterController(
      repo: repo,
      countryCodes: ['JP', 'FR'],
      typeOptions: [VehicleType.train, VehicleType.bus],
      showFutureTrips: false,
    );
  });
  tearDown(() => filter.dispose());

  test('loads counts: countries with trips first, then the others', () async {
    await filter.load();
    expect(filter.countryChoices, [
      (value: 'FR', count: 5),
      (value: 'JP', count: 0),
    ]);
    expect(filter.operatorChoices.first, (value: 'SNCF', count: 4));
  });

  test(
    'a custom date clears the quick chip, a quick chip clears the dates',
    () {
      filter.setFromDate(DateTime(2026, 1, 1));
      expect(filter.quickFilter, isNull);
      filter.selectQuickFilter(TripsQuickDateFilter.thisYear);
      expect(filter.fromDate, isNull);
      expect(filter.quickFilter, TripsQuickDateFilter.thisYear);
    },
  );

  test('all types selected is no type restriction', () {
    expect(filter.result.types, isEmpty);
    filter.setTypeSelected(VehicleType.bus, false);
    expect(filter.result.types, [VehicleType.train]);
    filter.selectAllTypes();
    expect(filter.allTypesSelected, isTrue);
    expect(filter.result.types, isEmpty);
  });

  test('changes refresh the preview count after a debounce', () async {
    filter.setCountrySelected('FR', true);
    filter.setCountrySelected('JP', true);
    await Future<void>.delayed(
      TripsFilterController.countDebounce + const Duration(milliseconds: 50),
    );
    expect(repo.filters, hasLength(1));
    expect(filter.matchCount, 2);
  });

  test('reset clears everything', () {
    filter
      ..setKeyword('Paris')
      ..setCountrySelected('FR', true)
      ..clearTypes()
      ..reset();
    final r = filter.result;
    expect(r.keyword, isEmpty);
    expect(r.countries, isEmpty);
    expect(r.types, isEmpty);
    expect(filter.quickFilter, TripsQuickDateFilter.allTime);
  });
}
