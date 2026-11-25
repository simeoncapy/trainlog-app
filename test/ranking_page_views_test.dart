import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:trainlog_app/core/data/models/ranking_model.dart';
import 'package:trainlog_app/core/providers/settings_provider.dart';
import 'package:trainlog_app/core/providers/trainlog_provider.dart';
import 'package:trainlog_app/features/ranking/cupertino/ranking_cupertino_view.dart';
import 'package:trainlog_app/features/ranking/cupertino/ranking_position_card_cupertino.dart';
import 'package:trainlog_app/features/ranking/material/ranking_material_view.dart';
import 'package:trainlog_app/features/ranking/ranking_page.dart';
import 'package:trainlog_app/features/ranking/widgets/ranking_user_position_block.dart';
import 'package:trainlog_app/l10n/app_localizations.dart';
import 'package:trainlog_app/ui/cupertino/glass_search_bar.dart';
import 'package:trainlog_app/ui/design.dart';
import 'package:trainlog_app/ui/tokens/app_theme.dart';
import 'package:trainlog_app/utils/platform_utils.dart';

/// Serves a fixed "all vehicles" leaderboard, signed in as `me`.
class _FakeTrainlog extends ChangeNotifier implements TrainlogProvider {
  @override
  String? get username => 'me';

  @override
  Future<RankingResult<LeaderboardEntry>> fetchRankingAll() async =>
      RankingResult([
        for (final (name, km) in [
          ('lea.voyage', 152340),
          ('railfan_kyoto', 128905),
          ('me', 48210),
          ('leandro', 21880),
        ])
          LeaderboardEntry(
            username: name,
            lastModified: null,
            trips: 10,
            length: km * 1000.0,
          ),
      ]);

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

void main() {
  tearDown(() => AppPlatform.debugDesignOverride = null);

  Future<void> pump(WidgetTester t, DesignLanguage design) async {
    AppPlatform.debugDesignOverride = design;
    late SettingsProvider settings;
    await t.runAsync(() async {
      SharedPreferences.setMockInitialValues({});
      settings = SettingsProvider();
      await settings.ready;
    });
    await t.binding.setSurfaceSize(const Size(400, 900));
    addTearDown(() => t.binding.setSurfaceSize(null));
    await t.pumpWidget(
      MultiProvider(
        providers: [
          ChangeNotifierProvider.value(value: settings),
          ChangeNotifierProvider<TrainlogProvider>.value(value: _FakeTrainlog()),
        ],
        child: MaterialApp(
          theme: AppTheme.light,
          locale: const Locale('en'),
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: const Scaffold(body: RankingPage()),
        ),
      ),
    );
    // Let the leaderboard load.
    await t.pump();
    await t.pump();
  }

  for (final design in DesignLanguage.values) {
    final isMaterial = design == DesignLanguage.material;

    testWidgets('${design.name}: its own view, position and rows', (t) async {
      await pump(t, design);

      expect(
        find.byType(RankingMaterialView),
        isMaterial ? findsOneWidget : findsNothing,
      );
      expect(
        find.byType(RankingCupertinoView),
        isMaterial ? findsNothing : findsOneWidget,
      );
      expect(
        find.byType(
          isMaterial ? RankingUserPositionBlock : RankingPositionCardCupertino,
        ),
        findsOneWidget,
      );
      expect(find.text('lea.voyage'), findsOneWidget);
      // Pull to refresh on both designs.
      expect(
        find.byType(
          isMaterial ? RefreshIndicator : CupertinoSliverRefreshControl,
          // The iOS control has no height until pulled.
          skipOffstage: false,
        ),
        findsOneWidget,
      );
      // The user's own row, and the card's username.
      expect(find.text('me'), findsNWidgets(2));
    });
  }

  testWidgets('cupertino: the search bar filters the rows', (t) async {
    await pump(t, DesignLanguage.cupertino);

    await t.tap(find.bySemanticsLabel('Search users…').first);
    await t.pump();
    expect(find.byType(AppGlassSearchBar), findsOneWidget);
    expect(find.byType(RankingPositionCardCupertino), findsNothing);

    await t.enterText(
      find.descendant(
        of: find.byType(AppGlassSearchBar),
        matching: find.byType(EditableText),
      ),
      'lea',
    );
    await t.pump();
    expect(find.text('lea.voyage'), findsOneWidget);
    expect(find.text('leandro'), findsOneWidget);
    expect(find.text('railfan_kyoto'), findsNothing);

    await t.tap(find.byIcon(CupertinoIcons.xmark));
    await t.pump();
    expect(find.byType(AppGlassSearchBar), findsNothing);
    expect(find.text('railfan_kyoto'), findsOneWidget);
  });
}
