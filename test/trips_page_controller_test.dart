import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:trainlog_app/core/data/models/time_moment.dart';
import 'package:trainlog_app/core/data/models/trips_filter.dart';
import 'package:trainlog_app/core/data/trips_repository.dart';
import 'package:trainlog_app/features/trips/trips_page_controller.dart';

/// Counts 10 future trips, 3 past ones, 1 with a filter.
class _FakeRepo implements TripsRepository {
  @override
  Future<int> countFilteredTrips({
    required bool showFutureTrips,
    TripsFilterResult? filter,
  }) async => filter != null ? 1 : (showFutureTrips ? 10 : 3);

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

void main() {
  late TripsPageController page;

  setUp(() {
    SharedPreferences.setMockInitialValues({
      TripsPageController.viewPrefKey: 'table',
    });
    page = TripsPageController()..repository = _FakeRepo();
  });
  tearDown(() => page.dispose());

  test('reads and saves the view mode', () async {
    expect(page.prefsLoaded, isFalse);
    await page.loadPrefs();
    expect(page.prefsLoaded, isTrue);
    expect(page.isCardView, isFalse);

    await page.setCardView(true);
    final prefs = await SharedPreferences.getInstance();
    expect(prefs.getString(TripsPageController.viewPrefKey), 'card');
  });

  test('counts the trips of Past / Future and of the filter', () async {
    await page.refreshSummaryCount();
    expect(page.summaryCount, 3);

    page.setTimeMoment(TimeMoment.future);
    await pumpEventQueue();
    expect(page.showsFutureTrips, isTrue);
    expect(page.summaryCount, 10);

    page.applyFilter(const TripsFilterResult(keyword: 'Lyon'));
    await pumpEventQueue();
    expect(page.activeFilter, isNotNull);
    expect(page.summaryCount, 1);

    page.clearFilter();
    await pumpEventQueue();
    expect(page.activeFilter, isNull);
    expect(page.summaryCount, 10);
  });

  test('an all-defaults filter is no filter', () {
    page.applyFilter(const TripsFilterResult());
    expect(page.activeFilter, isNull);
  });
}
