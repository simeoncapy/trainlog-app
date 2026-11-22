import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:trainlog_app/app/app_globals.dart';
import 'package:trainlog_app/ui/adaptive/adaptive_information_message.dart';
import 'package:trainlog_app/ui/cupertino/glass_toast.dart';
import 'package:trainlog_app/ui/design.dart';
import 'package:trainlog_app/utils/platform_utils.dart';

void main() {
  tearDown(() {
    GlassToast.hide();
    AppPlatform.debugDesignOverride = null;
  });

  Future<void> host(WidgetTester t) => t.pumpWidget(
    MaterialApp(
      navigatorKey: rootNavigatorKey,
      scaffoldMessengerKey: rootScaffoldMessengerKey,
      home: const Scaffold(),
    ),
  );

  testWidgets('Android: showInfo shows a SnackBar', (t) async {
    AppPlatform.debugDesignOverride = DesignLanguage.material;
    await host(t);

    AdaptiveInformationMessage.showInfo('Saved');
    await t.pump();

    expect(find.widgetWithText(SnackBar, 'Saved'), findsOneWidget);
  });

  testWidgets('Android: replace clears the queued messages', (t) async {
    AppPlatform.debugDesignOverride = DesignLanguage.material;
    await host(t);

    AdaptiveInformationMessage.showInfo('First');
    AdaptiveInformationMessage.showInfo('Second', replace: true);
    await t.pumpAndSettle();

    expect(find.text('First'), findsNothing);
    expect(find.widgetWithText(SnackBar, 'Second'), findsOneWidget);
  });

  testWidgets('iOS: showInfo shows a toast, not a SnackBar', (t) async {
    AppPlatform.debugDesignOverride = DesignLanguage.cupertino;
    await host(t);

    AdaptiveInformationMessage.showInfo('Saved');
    await t.pump();

    expect(find.text('Saved'), findsOneWidget);
    expect(find.byType(SnackBar), findsNothing);

    await t.pump(const Duration(seconds: 4));
    await t.pump(const Duration(milliseconds: 300));
    await t.pump();
    expect(find.text('Saved'), findsNothing);
  });

  testWidgets('iOS: a new message replaces the previous one', (t) async {
    AppPlatform.debugDesignOverride = DesignLanguage.cupertino;
    await host(t);

    AdaptiveInformationMessage.showInfo('First');
    AdaptiveInformationMessage.showInfo('Second');
    await t.pump();

    expect(find.text('First'), findsNothing);
    expect(find.text('Second'), findsOneWidget);

    GlassToast.hide();
    await t.pump();
  });

  testWidgets('iOS: a tap dismisses the toast', (t) async {
    AppPlatform.debugDesignOverride = DesignLanguage.cupertino;
    await host(t);

    AdaptiveInformationMessage.showInfo('Saved');
    await t.pump();
    await t.pump(const Duration(milliseconds: 400));
    await t.tap(find.text('Saved'));
    await t.pump();
    await t.pump(const Duration(milliseconds: 300));
    await t.pump();

    expect(find.text('Saved'), findsNothing);
  });
}
