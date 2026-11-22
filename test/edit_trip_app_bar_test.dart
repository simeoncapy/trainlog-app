import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:trainlog_app/features/trips_edit_copy/widgets/edit_trip_app_bar.dart';
import 'package:trainlog_app/ui/design.dart';
import 'package:trainlog_app/utils/platform_utils.dart';

void main() {
  tearDown(() => AppPlatform.debugDesignOverride = null);

  Widget host({IconData? modeIcon}) => MaterialApp(
    home: Scaffold(
      appBar: EditTripAppBar(
        title: 'Edit trip',
        subtitle: 'Paris → Lyon',
        tint: Colors.red.withValues(alpha: 0.2),
        appleModeIcon: modeIcon,
      ),
    ),
  );

  testWidgets('iOS shows the mode icon before the title', (t) async {
    AppPlatform.debugDesignOverride = DesignLanguage.cupertino;
    await t.pumpWidget(host(modeIcon: CupertinoIcons.square_pencil));
    final icon = t.widget<Icon>(find.byIcon(CupertinoIcons.square_pencil));
    expect(icon.color, Colors.red.withValues(alpha: 1));
    expect(find.text('Edit trip'), findsOneWidget);
  });

  testWidgets('iOS shows no mark without a mode icon (neutral page)', (
    t,
  ) async {
    AppPlatform.debugDesignOverride = DesignLanguage.cupertino;
    await t.pumpWidget(host());
    expect(
      find.descendant(
        of: find.byType(EditTripAppBar),
        matching: find.byWidgetPredicate(
          (w) =>
              w is DecoratedBox &&
              w.decoration is BoxDecoration &&
              (w.decoration as BoxDecoration).shape == BoxShape.circle,
        ),
      ),
      findsNothing,
    );
    expect(find.text('Edit trip'), findsOneWidget);
  });

  testWidgets('Android ignores the iOS mode icon', (t) async {
    AppPlatform.debugDesignOverride = DesignLanguage.material;
    await t.pumpWidget(host(modeIcon: CupertinoIcons.square_pencil));
    expect(find.byIcon(CupertinoIcons.square_pencil), findsNothing);
    expect(find.text('Edit trip'), findsOneWidget);
  });
}
