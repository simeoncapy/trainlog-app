import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:trainlog_app/core/data/models/trips.dart';
import 'package:trainlog_app/core/providers/settings_provider.dart';
import 'package:trainlog_app/core/providers/statistics_provider.dart';
import 'package:trainlog_app/core/providers/trainlog_provider.dart';
import 'package:trainlog_app/core/providers/trips_provider.dart';
import 'package:trainlog_app/features/statistics/cupertino/statistics_cupertino_view.dart';
import 'package:trainlog_app/features/statistics/material/statistics_material_view.dart';
import 'package:trainlog_app/features/statistics/statistics_controller.dart';
import 'package:trainlog_app/features/statistics/widgets/stats_bar_chart.dart';
import 'package:trainlog_app/features/statistics/widgets/stats_pie_chart.dart';
import 'package:trainlog_app/features/statistics/widgets/stats_table_chart.dart';
import 'package:trainlog_app/features/statistics/widgets/stats_unit_scale.dart';
import 'package:trainlog_app/l10n/app_localizations.dart';
import 'package:trainlog_app/ui/cupertino/app_grouped_list.dart';
import 'package:trainlog_app/ui/cupertino/glass_menu_parts.dart';
import 'package:trainlog_app/ui/design.dart';
import 'package:trainlog_app/ui/tokens/app_theme.dart';
import 'package:trainlog_app/utils/number_formatter.dart';
import 'package:trainlog_app/utils/platform_utils.dart';

/// Serves canned stats for every vehicle.
class _FakeTrainlog implements TrainlogProvider {
  _FakeTrainlog(this.stats);

  final Map<String, dynamic> stats;

  @override
  Future<({Map<VehicleType, Map<String, dynamic>> data, Map<VehicleType, Object> errors})>
      fetchStatsForVehicleTypes(List<VehicleType> types, int? year) async =>
          (data: {for (final t in types) t: stats}, errors: <VehicleType, Object>{});

  @override
  Future<Map<String, dynamic>> fetchStatsForVehicleType(VehicleType type, int? year) async =>
      stats;

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

Map<String, dynamic> _country(String code, int past, int future) =>
    {"country": code, "pastTrips": past, "plannedFutureTrips": future};

void main() {
  group('StatisticsController', () {
    test('changes the view and the sort, and notifies', () {
      final c = StatisticsController();
      var notified = 0;
      c.addListener(() => notified++);
      expect(c.view, StatisticsView.bar);
      expect(c.canSort, isTrue);
      c.view = StatisticsView.pie;
      expect(c.canSort, isFalse);
      c.toggleSort();
      expect(c.sortedAlpha, isTrue);
      c.view = StatisticsView.pie; // unchanged: no notification
      expect(notified, 2);
    });

    test('orders by total or by label, "Other" last', () {
      final stats = {
        'Other': (past: 50.0, future: 0.0),
        'b': (past: 1.0, future: 1.0),
        'a': (past: 1.0, future: 0.0),
        'c': (past: 5.0, future: 0.0),
      };
      expect(
        StatisticsController.ordered(stats, alpha: false, otherLabel: 'Other').keys,
        ['c', 'b', 'a', 'Other'],
      );
      expect(
        StatisticsController.ordered(stats, alpha: true, otherLabel: 'Other').keys,
        ['a', 'b', 'c', 'Other'],
      );
      // Sorted on the displayed label, not the key.
      expect(
        StatisticsController.ordered(
          stats,
          alpha: true,
          otherLabel: 'Other',
          labelOf: (k) => {'a': 'z', 'b': 'y', 'c': 'x'}[k] ?? k,
        ).keys,
        ['c', 'b', 'a', 'Other'],
      );
    });

    test('the table shows only the total for a past year', () {
      bool only(int? y) => StatisticsController.tableOnlyTotal(y, currentYear: 2026);
      expect(only(null), isFalse);
      expect(only(0), isFalse);
      expect(only(2026), isFalse);
      expect(only(2024), isTrue);
    });
  });

  test('the trips unit is singular for one trip', () {
    String unit(double v) => v == 1 ? 'trip' : 'trips';
    final small = StatsUnitScale([1, 4], baseUnit: 'trips', baseUnitFor: unit);
    expect(small.unitFor(1), 'trip');
    expect(small.unitFor(4), 'trips');
    final big = StatsUnitScale(
      [1, 4000],
      baseUnit: 'trips',
      baseUnitFor: unit,
      unitsByFactor: {
        UnitFactor.base: 'trips',
        UnitFactor.thousand: 'k trips',
        UnitFactor.million: 'M trips',
        UnitFactor.billion: 'G trips',
      },
    );
    // Prefixed units keep their own label.
    expect(big.unitFor(1), 'k trips');
  });

  Future<StatisticsController> pump(
    WidgetTester t,
    DesignLanguage design, {
    StatisticsView view = StatisticsView.bar,
    GraphUnit unit = GraphUnit.trip,
  }) async {
    AppPlatform.debugDesignOverride = design;
    late SettingsProvider settings;
    late StatisticsProvider stats;
    await t.runAsync(() async {
      SharedPreferences.setMockInitialValues({});
      settings = SettingsProvider();
      await settings.ready;
      stats = StatisticsProvider(
        _FakeTrainlog({
          "countries": [_country("JP", 3, 1), _country("FR", 1, 0)],
        }),
        allVehicles: [VehicleType.train],
      );
      stats.vehicle = VehicleType.train;
      stats.graph = GraphType.country;
      stats.unit = unit;
      await stats.load();
    });
    final controller = StatisticsController(view: view);
    await t.pumpWidget(
      MultiProvider(
        providers: [
          ChangeNotifierProvider.value(value: settings),
          ChangeNotifierProvider(create: (_) => TripsProvider()),
          ChangeNotifierProvider.value(value: stats),
          ChangeNotifierProvider.value(value: controller),
        ],
        child: MaterialApp(
          theme: AppTheme.light,
          locale: const Locale('en'),
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: Scaffold(
            body: PlatformView(
              material: (_) => const StatisticsMaterialView(),
              cupertino: (_) => const StatisticsCupertinoView(),
            ),
          ),
        ),
      ),
    );
    await t.pump(const Duration(milliseconds: 500));
    return controller;
  }

  tearDown(() => AppPlatform.debugDesignOverride = null);

  testWidgets('iOS: year, mode and unit menus, dimension heading, total', (t) async {
    t.view.physicalSize = const Size(1179, 2556);
    addTearDown(t.view.resetPhysicalSize);
    final controller = await pump(t, DesignLanguage.cupertino);

    expect(find.byType(StatisticsCupertinoView), findsOneWidget);
    expect(find.text('Statistics'), findsOneWidget);
    // Year, mode and unit menus; the sort menu; the dimension as a heading.
    expect(find.byType(GlassMenuCapsule), findsNWidgets(3));
    expect(find.text('Year'), findsOneWidget);
    expect(find.byType(GlassMenuIconButton), findsOneWidget);
    expect(find.byType(GlassMenuHeading), findsOneWidget);
    expect(find.text('Country'), findsOneWidget);
    // 5 trips in all, a bar per country.
    expect(find.text('5 trips'), findsOneWidget);
    expect(find.byType(StatsBarChart), findsOneWidget);

    // The pie has no sort.
    controller.view = StatisticsView.pie;
    await t.pump(const Duration(milliseconds: 500));
    expect(find.byType(StatsPieChart), findsOneWidget);
    // The pie has no sort.
    expect(find.byType(GlassMenuIconButton), findsNothing);
    // "1 trip", singular, in the legend.
    expect(find.text('1 trip'), findsOneWidget);
  });

  testWidgets('iOS: the ⓘ opens the units popover, again after a close', (t) async {
    t.view.physicalSize = const Size(1290, 2796);
    addTearDown(t.view.resetPhysicalSize);
    await pump(t, DesignLanguage.cupertino, unit: GraphUnit.distance);

    await t.tap(find.byIcon(CupertinoIcons.info_circle));
    for (var i = 0; i < 30; i++) {
      await t.pump(const Duration(milliseconds: 50));
    }
    // The popover's title and the scale, figures right-aligned in a table.
    expect(find.text('Unit'), findsOneWidget);
    expect(find.byType(Table), findsOneWidget);

    Future<void> settle() async {
      for (var i = 0; i < 40; i++) {
        await t.pump(const Duration(milliseconds: 50));
      }
    }

    // A tap outside closes it; the ⓘ opens it again.
    await t.tapAt(const Offset(20, 800));
    await settle();
    expect(find.text('Unit'), findsNothing);
    await t.tap(find.byIcon(CupertinoIcons.info_circle));
    await settle();
    expect(find.text('Unit'), findsOneWidget);

    // And again: it reopens every time (see GlassInfoButton).
    await t.tapAt(const Offset(20, 800));
    await settle();
    expect(find.text('Unit'), findsNothing);
    await t.tap(find.byIcon(CupertinoIcons.info_circle));
    await settle();
    expect(find.text('Unit'), findsOneWidget);
  });

  testWidgets('iOS: the table is an inset grouped list', (t) async {
    t.view.physicalSize = const Size(1179, 2556);
    addTearDown(t.view.resetPhysicalSize);
    await pump(t, DesignLanguage.cupertino, view: StatisticsView.table);

    expect(find.byType(StatsTableChart), findsNothing);
    expect(find.byType(AppGroupedSection), findsOneWidget);
    expect(find.byType(AppListTile), findsNWidgets(2));
    // Past and future under the name (Japan: 3 + 1).
    expect(find.textContaining('Past 3 · Future 1', findRichText: true), findsOneWidget);
  });

  testWidgets('Android: the card view, table on demand', (t) async {
    t.view.physicalSize = const Size(1290, 2796);
    addTearDown(t.view.resetPhysicalSize);
    await pump(t, DesignLanguage.material, view: StatisticsView.table);

    expect(find.byType(StatisticsMaterialView), findsOneWidget);
    expect(find.byType(GlassMenuCapsule), findsNothing);
    expect(find.byType(StatsTableChart), findsOneWidget);
    expect(find.text('Total 5 trips'), findsOneWidget);
  });
}
