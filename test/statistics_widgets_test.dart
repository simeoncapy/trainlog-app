import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:trainlog_app/features/statistics/widgets/stats_bar_chart.dart';
import 'package:trainlog_app/features/statistics/widgets/stats_table_chart.dart';

Widget _wrap(Widget child) => MaterialApp(
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
}
