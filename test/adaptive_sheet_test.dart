import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:liquid_glass_widgets/liquid_glass_widgets.dart' as lg;
import 'package:trainlog_app/ui/adaptive/adaptive_sheet.dart';

void main() {
  Future<BuildContext> host(WidgetTester t) async {
    late BuildContext ctx;
    await t.pumpWidget(
      MaterialApp(
        home: Builder(
          builder: (c) {
            ctx = c;
            return const Scaffold();
          },
        ),
      ),
    );
    return ctx;
  }

  testWidgets('detent sheet lays out scroll + pinned footer', (t) async {
    final ctx = await host(t);
    showAppleDetentSheet<void>(
      context: ctx,
      halfSize: 0.55,
      builder: (_) => Column(
        children: [
          Expanded(
            child: SingleChildScrollView(
              child: Column(
                children: List.generate(
                  40,
                  (i) => ListTile(title: Text('row $i')),
                ),
              ),
            ),
          ),
          const SafeArea(top: false, child: Text('footer')),
        ],
      ),
    );
    await t.pumpAndSettle();
    expect(find.text('footer'), findsOneWidget);
    expect(find.text('row 0'), findsOneWidget);
    await t.drag(find.text('row 2'), const Offset(0, -300));
    await t.pumpAndSettle();
    expect(t.takeException(), isNull);
  });

  testWidgets('large-only detent sheet', (t) async {
    final ctx = await host(t);
    showAppleDetentSheet<void>(
      context: ctx,
      detents: const {lg.GlassSheetDetent.large},
      initialState: lg.GlassSheetState.full,
      builder: (_) => const Column(
        children: [
          Expanded(child: TextField()),
          Text('go'),
        ],
      ),
    );
    await t.pumpAndSettle();
    expect(find.text('go'), findsOneWidget);
  });

  testWidgets('content sheet with Flexible list (picker shape)', (t) async {
    final ctx = await host(t);
    // Exercise the Apple branch directly.
    lg.GlassSheet.show<void>(
      context: ctx,
      isScrollable: false,
      builder: (c) => Material(
        type: MaterialType.transparency,
        child: ConstrainedBox(
          constraints: BoxConstraints(
            maxHeight: MediaQuery.sizeOf(c).height * 0.8,
          ),
          child: SafeArea(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text('title'),
                Flexible(
                  child: ListView.builder(
                    shrinkWrap: true,
                    itemCount: 60,
                    itemBuilder: (_, i) =>
                        InkWell(onTap: () {}, child: Text('opt $i')),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
    await t.pumpAndSettle();
    expect(find.text('title'), findsOneWidget);
    await t.tap(find.text('opt 1'));
    await t.pumpAndSettle();
  });
}
