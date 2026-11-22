import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:trainlog_app/l10n/app_localizations.dart';
import 'package:trainlog_app/ui/adaptive/adaptive_dialog.dart';
import 'package:trainlog_app/ui/design.dart';
import 'package:trainlog_app/utils/platform_utils.dart';

void main() {
  tearDown(() => AppPlatform.debugDesignOverride = null);

  Future<BuildContext> host(WidgetTester t) async {
    late BuildContext ctx;
    await t.pumpWidget(
      MaterialApp(
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
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

  List<AdaptiveDialogAction> deleteActions() => const [
    AdaptiveDialogAction(
      label: 'Delete',
      result: AdaptiveDialogResult.primary,
      isDestructive: true,
    ),
    AdaptiveDialogAction(
      label: 'Cancel',
      result: AdaptiveDialogResult.cancelled,
      isDefault: true,
    ),
  ];

  testWidgets('iOS: a destructive confirmation is an action sheet', (t) async {
    AppPlatform.debugDesignOverride = DesignLanguage.cupertino;
    final ctx = await host(t);

    final result = AdaptiveDialog.show(
      context: ctx,
      title: 'Delete trip?',
      message: 'This cannot be undone.',
      useActionSheetOnIOS: true,
      barrierDismissible: true,
      actions: deleteActions(),
    );
    await t.pumpAndSettle();

    expect(find.byType(CupertinoActionSheet), findsOneWidget);
    final cancel = t.widget<CupertinoActionSheetAction>(
      find.ancestor(
        of: find.text('Cancel'),
        matching: find.byType(CupertinoActionSheetAction),
      ),
    );
    expect(cancel.isDefaultAction, isTrue);

    await t.tap(find.text('Delete'));
    await t.pumpAndSettle();
    expect(await result, AdaptiveDialogResult.primary);
  });

  testWidgets('Android: the same call is a Material alert', (t) async {
    AppPlatform.debugDesignOverride = DesignLanguage.material;
    final ctx = await host(t);

    final result = AdaptiveDialog.show(
      context: ctx,
      title: 'Delete trip?',
      message: 'This cannot be undone.',
      useActionSheetOnIOS: true,
      actions: deleteActions(),
    );
    await t.pumpAndSettle();

    expect(find.byType(AlertDialog), findsOneWidget);
    await t.tap(find.text('Cancel'));
    await t.pumpAndSettle();
    expect(await result, AdaptiveDialogResult.cancelled);
  });
}
