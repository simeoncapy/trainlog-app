import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:trainlog_app/core/data/models/time_moment.dart';
import 'package:trainlog_app/core/data/models/trip_visibility.dart';
import 'package:trainlog_app/core/data/models/trips.dart';
import 'package:trainlog_app/core/data/models/trips_filter.dart';
import 'package:trainlog_app/core/data/trips_repository.dart';
import 'package:trainlog_app/core/providers/polyline_provider.dart';
import 'package:trainlog_app/core/providers/settings_provider.dart';
import 'package:trainlog_app/core/providers/trainlog_provider.dart';
import 'package:trainlog_app/core/providers/trips_provider.dart';
import 'package:trainlog_app/core/services/api/trainlog_http_client.dart';
import 'package:trainlog_app/features/trips/cupertino/trips_list_cupertino.dart';
import 'package:trainlog_app/features/trips/trips_list_controller.dart';
import 'package:trainlog_app/l10n/app_localizations.dart';
import 'package:trainlog_app/ui/cupertino/app_grouped_list.dart';
import 'package:trainlog_app/ui/design.dart';
import 'package:trainlog_app/ui/tokens/app_theme.dart';
import 'package:trainlog_app/utils/platform_utils.dart';

import 'fake_trainlog_server.dart';

Trips _trip(int i, DateTime start) => Trips(
  uid: '$i',
  username: 'simtester',
  originStation: 'Origin $i',
  destinationStation: 'Destination $i',
  startDatetime: start,
  endDatetime: start.add(const Duration(hours: 2)),
  estimatedTripDuration: 7200,
  tripLength: 427000,
  operatorName: '',
  countries: '{"FR": 427000}',
  lineName: 'TGV',
  created: DateTime(2026, 10, 1),
  lastModified: DateTime(2026, 10, 1),
  type: VehicleType.train,
  path: '',
  visibility: TripVisibility.private,
);

/// Past trips, newest first: 3 in November 2026, 2 in October 2026.
final _trips = [
  _trip(1, DateTime(2026, 11, 20, 8)),
  _trip(2, DateTime(2026, 11, 10, 8)),
  _trip(3, DateTime(2026, 11, 2, 8)),
  _trip(4, DateTime(2026, 10, 25, 8)),
  _trip(5, DateTime(2026, 10, 3, 8)),
];

class _FakeRepo implements TripsRepository {
  final pages = <(int?, int?)>[];

  @override
  Future<int> countFilteredTrips({
    required bool showFutureTrips,
    TripsFilterResult? filter,
  }) async => _trips.length;

  @override
  Future<List<Trips>> getTripsFiltered({
    required bool showFutureTrips,
    int? limit,
    int? offset,
    String? orderBy,
    TripsFilterResult? filter,
  }) async {
    pages.add((offset, limit));
    return _trips.skip(offset ?? 0).take(limit ?? _trips.length).toList();
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

void main() {
  group('TripsListController', () {
    test('loads page by page and groups by month', () async {
      final repo = _FakeRepo();
      final list = TripsListController(
        repo: repo,
        filter: null,
        timeMoment: TimeMoment.past,
        pageSize: 2,
      );
      await list.load();
      expect(list.total, 5);
      expect(list.hasMore, isTrue);
      expect(list.months.map((m) => m.trips.length), [2]);

      await list.loadMore();
      await list.loadMore();
      expect(list.hasMore, isFalse);
      final months = list.months;
      expect(months.map((m) => m.month), [11, 10]);
      expect(months.map((m) => m.trips.length), [3, 2]);
      expect(repo.pages, [(0, 2), (2, 2), (4, 2)]);
      list.dispose();
    });

    test('a refresh keeps as many trips as were shown', () async {
      final repo = _FakeRepo();
      final list = TripsListController(
        repo: repo,
        filter: null,
        timeMoment: TimeMoment.past,
        pageSize: 2,
      );
      await list.load();
      await list.loadMore();
      await list.load(showLoader: false);
      expect(repo.pages.last, (0, 4));
      expect(list.months.expand((m) => m.trips).length, 4);
      list.dispose();
    });
  });

  group('TripsListCupertino', () {
    tearDown(() => AppPlatform.debugDesignOverride = null);

    Future<void> pump(WidgetTester t) async {
      AppPlatform.debugDesignOverride = DesignLanguage.cupertino;
      late SettingsProvider settings;
      late TrainlogProvider trainlog;
      await t.runAsync(() async {
        SharedPreferences.setMockInitialValues({});
        settings = SettingsProvider();
        await settings.ready;
        final client = TrainlogHttpClient()
          ..dio.httpClientAdapter = FakeAdapter(
            fakeServer(signedIn: () => true),
          );
        trainlog = TrainlogProvider(client: client);
      });
      await t.pumpWidget(
        MultiProvider(
          providers: [
            ChangeNotifierProvider.value(value: settings),
            ChangeNotifierProvider.value(value: trainlog),
            ChangeNotifierProvider(create: (_) => TripsProvider()),
            ChangeNotifierProvider(create: (_) => PolylineProvider()),
          ],
          child: MaterialApp(
            theme: AppTheme.light,
            locale: const Locale('en'),
            localizationsDelegates: AppLocalizations.localizationsDelegates,
            supportedLocales: AppLocalizations.supportedLocales,
            home: Scaffold(
              body: TripsListCupertino(
                repo: _FakeRepo(),
                filter: null,
                timeMoment: TimeMoment.past,
                revision: 0,
              ),
            ),
          ),
        ),
      );
      await t.pumpAndSettle();
    }

    testWidgets('one titled group per month, a row per trip', (t) async {
      await pump(t);
      expect(find.text('November 2026'), findsOneWidget);
      expect(find.text('October 2026'), findsOneWidget);
      expect(find.text('Origin 1 → Destination 1'), findsOneWidget);
      expect(find.text('Origin 5 → Destination 5'), findsOneWidget);
      expect(find.byType(AppGroupedSection), findsNWidgets(2));
      expect(find.byType(AppListTile), findsNWidgets(5));
    });

    testWidgets('swiping a row left shows Delete and Edit', (t) async {
      await pump(t);
      expect(find.text('Delete'), findsNothing);

      await t.drag(
        find.text('Origin 1 → Destination 1'),
        const Offset(-200, 0),
      );
      await t.pumpAndSettle();
      expect(find.text('Edit'), findsOneWidget);
      expect(find.text('Delete'), findsOneWidget);

      // Tapping the open row closes it.
      await t.tap(find.text('Origin 1 → Destination 1'));
      await t.pumpAndSettle();
      expect(find.text('Delete'), findsNothing);
    });
  });
}
