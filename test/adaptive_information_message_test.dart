import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:liquid_glass_widgets/liquid_glass_widgets.dart' as lg;
import 'package:trainlog_app/app/app_globals.dart';
import 'package:trainlog_app/ui/adaptive/adaptive_information_message.dart';
import 'package:trainlog_app/ui/cupertino/app_glass_toast.dart';
import 'package:trainlog_app/ui/design.dart';
import 'package:trainlog_app/utils/platform_utils.dart';

void main() {
  tearDown(() {
    AppGlassToast.hide();
    AppPlatform.debugDesignOverride = null;
  });

  late BuildContext screen;

  Future<void> host(WidgetTester t) => t.pumpWidget(
    MaterialApp(
      navigatorKey: rootNavigatorKey,
      scaffoldMessengerKey: rootScaffoldMessengerKey,
      home: Scaffold(
        body: Builder(
          builder: (c) {
            screen = c;
            return const SizedBox.expand();
          },
        ),
      ),
    ),
  );

  /// Lets the package toast run out, so no timer is left pending.
  Future<void> settlePackageToast(WidgetTester t) async {
    await t.pump(const Duration(seconds: 4));
    await t.pump(const Duration(seconds: 1));
  }

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
    await t.pump(const Duration(milliseconds: 500));
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

    AppGlassToast.hide();
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
    await t.pump(const Duration(milliseconds: 500));
    await t.pump();

    expect(find.text('Saved'), findsNothing);
  });

  testWidgets('Android: showInfoWithIcon shows the same SnackBar', (t) async {
    AppPlatform.debugDesignOverride = DesignLanguage.material;
    await host(t);

    AdaptiveInformationMessage.showInfoWithIcon(screen, 'Saved');
    await t.pump();

    expect(find.widgetWithText(SnackBar, 'Saved'), findsOneWidget);
    expect(find.byType(lg.GlassToast), findsNothing);
  });

  testWidgets('iOS: showInfoWithIcon shows the package toast', (t) async {
    AppPlatform.debugDesignOverride = DesignLanguage.cupertino;
    await host(t);

    AdaptiveInformationMessage.showInfoWithIcon(
      screen,
      'Saved',
      kind: AdaptiveMessageKind.success,
    );
    await t.pump();

    final toast = t.widget<lg.GlassToast>(find.byType(lg.GlassToast));
    expect(toast.message, 'Saved');
    expect(toast.type, lg.GlassToastType.success);
    expect(toast.position, lg.GlassToastPosition.top);
    expect(find.byType(SnackBar), findsNothing);

    await settlePackageToast(t);
    expect(find.byType(lg.GlassToast), findsNothing);
  });

  testWidgets('iOS: the next message replaces a package toast', (t) async {
    AppPlatform.debugDesignOverride = DesignLanguage.cupertino;
    await host(t);

    AdaptiveInformationMessage.showInfoWithIcon(screen, 'First');
    await t.pump();
    AdaptiveInformationMessage.showInfo('Second');
    await t.pump();

    expect(find.byType(lg.GlassToast), findsNothing);
    expect(find.text('First'), findsNothing);
    expect(find.text('Second'), findsOneWidget);

    AppGlassToast.hide();
    await settlePackageToast(t);
  });

  testWidgets('iOS: a package toast replaces the text-only one', (t) async {
    AppPlatform.debugDesignOverride = DesignLanguage.cupertino;
    await host(t);

    AdaptiveInformationMessage.showInfo('First');
    await t.pump();
    AdaptiveInformationMessage.showInfoWithIcon(screen, 'Second');
    await t.pump();

    expect(find.text('First'), findsNothing);
    expect(find.byType(lg.GlassToast), findsOneWidget);

    await settlePackageToast(t);
  });
}
