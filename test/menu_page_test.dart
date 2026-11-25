import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:trainlog_app/core/providers/settings_provider.dart';
import 'package:trainlog_app/core/providers/trainlog_provider.dart';
import 'package:trainlog_app/core/providers/trips_provider.dart';
import 'package:trainlog_app/core/services/api/trainlog_http_client.dart';
import 'package:trainlog_app/features/menu/full_screen_menu_page.dart';
import 'package:trainlog_app/features/menu/menu_controller.dart';
import 'package:trainlog_app/features/menu/menu_explore_card.dart';
import 'package:trainlog_app/l10n/app_localizations.dart';
import 'package:trainlog_app/navigation/nav_models.dart';
import 'package:trainlog_app/ui/cupertino/app_grouped_list.dart';
import 'package:trainlog_app/ui/design.dart';
import 'package:trainlog_app/ui/tokens/app_theme.dart';
import 'package:trainlog_app/utils/platform_utils.dart';

import 'fake_trainlog_server.dart';

/// The fake server, answering 3 unread news.
Handler _server() {
  final base = fakeServer(signedIn: () => true);
  return (RequestOptions o) => o.path.startsWith('/api/news/count/')
      ? jsonBody('{"count": 3}')
      : base(o);
}

void main() {
  late SettingsProvider settings;
  late TrainlogProvider trainlog;

  Future<void> setUpProviders(WidgetTester t) => t.runAsync(() async {
    SharedPreferences.setMockInitialValues({});
    settings = SettingsProvider();
    await settings.ready;
    final client = TrainlogHttpClient()
      ..dio.httpClientAdapter = FakeAdapter(_server());
    trainlog = TrainlogProvider(client: client);
  });

  tearDown(() => AppPlatform.debugDesignOverride = null);

  testWidgets('the controller reads the unread news count', (t) async {
    await setUpProviders(t);
    final c = AppMenuController(
      trainlog: trainlog,
      settings: settings,
      trips: TripsProvider(),
    );
    expect(c.newMessageCount, isNull);
    await t.runAsync(c.loadNewsCount);
    expect(c.newMessageCount, 3);
    c.dispose();
  });

  Future<List<Object>> pump(WidgetTester t, DesignLanguage design) async {
    AppPlatform.debugDesignOverride = design;
    await setUpProviders(t);
    final taps = <Object>[];
    await t.pumpWidget(
      MultiProvider(
        providers: [
          ChangeNotifierProvider.value(value: settings),
          ChangeNotifierProvider.value(value: trainlog),
          ChangeNotifierProvider(create: (_) => TripsProvider()),
        ],
        child: MaterialApp(
          theme: AppTheme.light,
          locale: const Locale('en'),
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: FullScreenMenuPage(
            onClose: () => taps.add('close'),
            onSettingsTap: () => taps.add('settings'),
            onPageTap: taps.add,
            onInboxTap: () => taps.add('inbox'),
            onTrainlogStatusTap: () => taps.add('status'),
          ),
        ),
      ),
    );
    await t.pumpAndSettle();
    return taps;
  }

  testWidgets('iOS: titles as written, grouped lists, Log out apart', (t) async {
    t.view.physicalSize = const Size(1179, 3000);
    addTearDown(t.view.resetPhysicalSize);
    final taps = await pump(t, DesignLanguage.cupertino);

    expect(find.text('Explore'), findsOneWidget);
    expect(find.text('Menu'), findsOneWidget);
    expect(find.byType(ExploreCard), findsNWidgets(4));
    // Inbox, status, About in one section; Log out in its own.
    expect(find.byType(AppGroupedSection), findsNWidgets(2));
    expect(find.text('Log out'), findsOneWidget);

    await t.tap(find.text('Inbox'));
    await t.tap(find.text('Tags'));
    expect(taps, ['inbox', AppPageId.tags]);
  });

  testWidgets('Android: titles in capitals, compact Explore cards', (t) async {
    t.view.physicalSize = const Size(1080, 3000);
    addTearDown(t.view.resetPhysicalSize);
    final taps = await pump(t, DesignLanguage.material);

    expect(find.text('EXPLORE'), findsOneWidget);
    expect(find.text('MENU'), findsOneWidget);
    expect(find.byType(AppGroupedSection), findsNothing);
    expect(t.getSize(find.byType(ExploreCard).first).height, 64);

    await t.tap(find.text('Dashboard'));
    expect(taps, [AppPageId.dashboard]);
  });
}
