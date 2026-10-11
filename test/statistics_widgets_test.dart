import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:trainlog_app/features/statistics/widgets/stats_bar_chart.dart';
import 'package:trainlog_app/features/statistics/widgets/stats_pie_chart.dart';
import 'package:trainlog_app/features/statistics/widgets/stats_table_chart.dart';
import 'package:trainlog_app/l10n/app_localizations.dart';
import 'package:trainlog_app/utils/number_formatter.dart';

Widget _wrap(Widget child) => MaterialApp(
      locale: const Locale('en'),
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      home: Scaffold(body: SingleChildScrollView(child: child)),
    );

void main() {
  testWidgets('bar chart renders one coloured part per segment', (tester) async {
    await tester.pumpWidget(_wrap(StatsBarChart(
      stats: const {"JR East": (past: 13, future: 3), "SNCF": (past: 5, future: 0)},
      images: const [Text("1"), Text("2")],
      baseUnit: "trips",
      segments: const [
        [
          (color: Colors.red, past: 10, future: 1),
          (color: Colors.green, past: 3, future: 2),
        ],
        [(color: Colors.red, past: 5, future: 0)],
      ],
    )));

    expect(tester.takeException(), isNull);
    // Track + 4 non-empty parts on row 1, track + 1 part on row 2.
    final colored = tester
        .widgetList<Container>(find.byType(Container))
        .map((c) => c.color)
        .where((c) => c != null && c.a == 1)
        .toList();
    expect(colored.where((c) => c == Colors.red).length, 2);
    expect(colored.where((c) => c == Colors.green).length, 1);
  });

  testWidgets('table renders a detail line per sub-row', (tester) async {
    await tester.pumpWidget(_wrap(StatsTableChart(
      stats: const {"JR East": (past: 13, future: 3)},
      valueFormatter: (v) => v.toStringAsFixed(0),
      subRows: const {
        "JR East": [
          (icon: Icon(Icons.train), color: Colors.red, label: "Train", past: 10, future: 1, raw: null),
          (icon: Icon(Icons.subway), color: Colors.green, label: "Metro", past: 3, future: 2, raw: null),
        ],
      },
    )));

    expect(tester.takeException(), isNull);
    expect(find.text("JR East"), findsOneWidget);
    expect(find.text("Train"), findsOneWidget);
    expect(find.text("Metro"), findsOneWidget);
    expect(find.text("16"), findsOneWidget); // entry total
    expect(find.text("5"), findsOneWidget); // metro total
  });

  group('pie chart', () {
    // Distances in km; "Other" deliberately not the smallest nor last.
    final stats = <String, ({double past, double future})>{
      "Other": (past: 4000, future: 0),
      "JR East": (past: 9000, future: 1000),
      "SNCF": (past: 3000, future: 0),
    };

    Future<void> pumpPie(WidgetTester tester) async {
      tester.view.physicalSize = const Size(600, 1400);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);
      await tester.pumpWidget(_wrap(StatsPieChart(
        stats: stats,
        baseUnit: "km",
        unitsByFactor: const {
          UnitFactor.base: "km",
          UnitFactor.thousand: "Mm",
          UnitFactor.million: "Gm",
          UnitFactor.billion: "Tm",
        },
        otherLabel: "Other",
      )));
    }

    testWidgets('legend keeps the given order with "Other" last', (tester) async {
      await pumpPie(tester);
      expect(tester.takeException(), isNull);

      final y = [for (final l in ["JR East", "SNCF", "Other"]) tester.getTopLeft(find.text(l).last).dy];
      expect(y[0] < y[1] && y[1] < y[2], isTrue);
    });

    testWidgets('values use the same unit scaling as the bar chart', (tester) async {
      await pumpPie(tester);
      expect(find.text("10 Mm"), findsOneWidget); // JR East in the legend
      expect(find.text("17 Mm"), findsOneWidget); // total in the centre
    });

    testWidgets('tapping a legend row selects it, tapping again clears', (tester) async {
      await pumpPie(tester);
      expect(find.text("SNCF"), findsOneWidget);

      await tester.tap(find.text("SNCF"));
      await tester.pumpAndSettle();
      expect(find.text("SNCF"), findsNWidgets(2)); // legend + centre
      expect(find.text("3 Mm"), findsNWidgets(2));

      await tester.tap(find.text("SNCF").last);
      await tester.pumpAndSettle();
      expect(find.text("SNCF"), findsOneWidget);
      expect(find.text("17 Mm"), findsOneWidget);
    });
  });
}
