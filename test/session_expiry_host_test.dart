import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:trainlog_app/features/user/session_expiry_host.dart';
import 'package:trainlog_app/l10n/app_localizations.dart';
import 'package:trainlog_app/providers/settings_provider.dart';
import 'package:trainlog_app/providers/trainlog_provider.dart';
import 'package:trainlog_app/providers/trips_provider.dart';
import 'package:trainlog_app/services/api/trainlog_http_client.dart';

import 'fake_trainlog_server.dart';

class _App {
  _App(this.auth, this.settings, this.adapter);
  final TrainlogProvider auth;
  final SettingsProvider settings;
  final FakeAdapter adapter;
}

/// Signed-in app whose session has expired at startup.
Future<_App> _expiredApp(WidgetTester tester, {required bool Function() signedIn}) async {
  late _App app;
  await tester.runAsync(() async {
    SharedPreferences.setMockInitialValues({'auth.username': 'alice'});
    final settings = SettingsProvider();
    await settings.ready;
    final adapter = FakeAdapter(fakeServer(signedIn: signedIn));
    final client = TrainlogHttpClient()..dio.httpClientAdapter = adapter;
    final auth = TrainlogProvider(client: client);
    await auth.tryRestoreSession(settings: settings);
    app = _App(auth, settings, adapter);
  });
  expect(app.auth.sessionExpired, isTrue);

  await tester.pumpWidget(MultiProvider(
    providers: [
      ChangeNotifierProvider<SettingsProvider>.value(value: app.settings),
      ChangeNotifierProvider<TrainlogProvider>.value(value: app.auth),
      ChangeNotifierProvider<TripsProvider>(create: (_) => TripsProvider()),
    ],
    child: MaterialApp(
      locale: const Locale('en'),
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      home: const SessionExpiryHost(
        child: Scaffold(body: Text('trips')),
      ),
    ),
  ));
  await tester.pumpAndSettle();
  return app;
}

Future<void> _submitPassword(WidgetTester tester, String password) async {
  await tester.enterText(find.byType(TextFormField).last, password);
  await tester.runAsync(() async {
    await tester.tap(find.widgetWithText(FilledButton, 'Log in').last);
    // Let the fake server answer.
    await Future<void>.delayed(const Duration(milliseconds: 50));
  });
  await tester.pumpAndSettle();
}

void main() {
  testWidgets('banner over the local data, sheet from the banner', (tester) async {
    await _expiredApp(tester, signedIn: () => false);

    expect(find.text('trips'), findsOneWidget);
    expect(find.text('Session expired: your trips are not synced'), findsOneWidget);
    expect(find.text('Session expired'), findsNothing);

    await tester.tap(find.widgetWithText(TextButton, 'Log in'));
    await tester.pumpAndSettle();
    expect(find.text('Session expired'), findsOneWidget);
  });

  testWidgets('wrong password keeps the sheet open with the reason', (tester) async {
    await _expiredApp(tester, signedIn: () => false);
    await tester.tap(find.widgetWithText(TextButton, 'Log in'));
    await tester.pumpAndSettle();

    await _submitPassword(tester, 'wrong');

    expect(find.text('Incorrect password'), findsOneWidget);
    expect(find.text('Session expired'), findsOneWidget);
  });

  testWidgets('continue offline closes the sheet; the banner and later actions reopen it', (tester) async {
    final app = await _expiredApp(tester, signedIn: () => false);
    await tester.tap(find.widgetWithText(TextButton, 'Log in'));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Continue offline'));
    await tester.pumpAndSettle();
    expect(find.text('Session expired'), findsNothing);
    expect(find.text('Session expired: your trips are not synced'), findsOneWidget);

    // The banner always reopens it.
    await tester.tap(find.widgetWithText(TextButton, 'Log in'));
    await tester.pumpAndSettle();
    expect(find.text('Session expired'), findsOneWidget);
    await tester.tap(find.text('Continue offline'));
    await tester.pumpAndSettle();

    // A new action reopens it once the in-flight requests of the dismissed
    // one have been ignored.
    await tester.runAsync(() => Future<void>.delayed(const Duration(milliseconds: 2100)));
    app.auth.requestLogin();
    await tester.pumpAndSettle();
    expect(find.text('Session expired'), findsOneWidget);
  });

  testWidgets('requests right after continue offline do not reopen the sheet', (tester) async {
    final app = await _expiredApp(tester, signedIn: () => false);
    await tester.tap(find.widgetWithText(TextButton, 'Log in'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Continue offline'));
    await tester.pumpAndSettle();

    app.auth.requestLogin();
    await tester.pumpAndSettle();
    expect(find.text('Session expired'), findsNothing);
  });

  testWidgets('right password closes the sheet and removes the banner', (tester) async {
    var signedIn = false;
    final app = await _expiredApp(tester, signedIn: () => signedIn);
    await tester.tap(find.widgetWithText(TextButton, 'Log in'));
    await tester.pumpAndSettle();

    signedIn = true;
    await _submitPassword(tester, 'secret');

    expect(app.auth.sessionExpired, isFalse);
    expect(find.text('Session expired'), findsNothing);
    expect(find.text('Session expired: your trips are not synced'), findsNothing);
    expect(find.text('trips'), findsOneWidget);
  });
}
