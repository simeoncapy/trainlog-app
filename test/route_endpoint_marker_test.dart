import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:trainlog_app/ui/tokens/app_colors.dart';
import 'package:trainlog_app/widgets/trip_form/trip_form_tiles.dart';

void main() {
  Color? fillOf(WidgetTester t) {
    final box = t.widget<Container>(
      find.descendant(
        of: find.byType(RouteEndpointMarker),
        matching: find.byType(Container),
      ),
    );
    return (box.decoration as BoxDecoration?)?.color;
  }

  Future<void> pump(WidgetTester t, Brightness b, {bool filled = false}) =>
      t.pumpWidget(
        MaterialApp(
          theme: ThemeData(brightness: b),
          home: Scaffold(
            body: RouteEndpointMarker(colour: Colors.blue, filled: filled),
          ),
        ),
      );

  testWidgets('departure centre is the light page colour', (t) async {
    await pump(t, Brightness.light);
    expect(fillOf(t), AppColors.lightBg);
  });

  testWidgets('departure centre is the dark page colour', (t) async {
    await pump(t, Brightness.dark);
    expect(fillOf(t), AppColors.darkBg);
  });

  testWidgets('arrival is filled with the route colour', (t) async {
    await pump(t, Brightness.dark, filled: true);
    expect(fillOf(t), Colors.blue);
  });
}
