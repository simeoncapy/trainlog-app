import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:trainlog_app/core/services/flag_cache.dart';
import 'package:trainlog_app/core/data/models/ranking_model.dart';
import 'package:trainlog_app/features/ranking/cupertino/rail_area_ranking_cupertino_view.dart';
import 'package:trainlog_app/features/ranking/cupertino/ranking_position_card_cupertino.dart';
import 'package:trainlog_app/features/ranking/material/rail_area_ranking_material_view.dart';
import 'package:trainlog_app/features/ranking/rail_area_ranking_controller.dart';
import 'package:trainlog_app/features/ranking/rail_area_ranking_page.dart';
import 'package:trainlog_app/features/ranking/widgets/ranking_user_position_block.dart';
import 'package:trainlog_app/l10n/app_localizations.dart';
import 'package:trainlog_app/ui/cupertino/glass_search_bar.dart';
import 'package:trainlog_app/ui/design.dart';
import 'package:trainlog_app/ui/tokens/app_theme.dart';
import 'package:trainlog_app/utils/platform_utils.dart';

const _entry = RailPercentageEntry(
  code: 'LU',
  data: [
    RailCoverage(
      percent: 100,
      users: [
        RankedUser(username: 'zoe'),
        RankedUser(username: 'Me'),
      ],
    ),
    RailCoverage(percent: 42.5, users: [RankedUser(username: 'adam')]),
  ],
);

void main() {
  group('RailAreaRankingController', () {
    RailAreaRankingController make() =>
        RailAreaRankingController(entry: _entry, currentUsername: 'me');

    test('ranks by coverage, ties share a rank', () {
      final c = make();
      expect(c.ranked.map((r) => r.username), ['Me', 'zoe', 'adam']);
      expect(c.ranked.map((r) => r.rank), [1, 1, 3]);
      expect(c.myRow?.username, 'Me');
    });

    test('sorts by name and reverses without changing ranks', () {
      final c = make()..toggleAlphabetical();
      expect(c.displayRows.map((r) => r.username), ['adam', 'Me', 'zoe']);
      c.toggleDirection();
      expect(c.displayRows.map((r) => r.username), ['zoe', 'Me', 'adam']);
      expect(c.displayRows.first.rank, 1);
    });

    test('a tied row hides its rank unless sorted by name', () {
      final c = make();
      final rows = c.displayRows;
      expect(
        [for (var i = 0; i < 3; i++) c.showsRank(rows, i)],
        [true, false, true],
      );
      c.toggleAlphabetical();
      final byName = c.displayRows;
      expect(
        [for (var i = 0; i < 3; i++) c.showsRank(byName, i)],
        [true, true, true],
      );
    });

    test('search filters by name; closing clears it', () {
      final c = make()..openSearch();
      c.query = ' ZO ';
      expect(c.displayRows.map((r) => r.username), ['zoe']);
      c.closeSearch();
      expect(c.searchOpen, isFalse);
      expect(c.query, isEmpty);
      expect(c.displayRows, hasLength(3));
    });
  });

  group('RailAreaRankingPage', () {
    tearDown(() => AppPlatform.debugDesignOverride = null);

    Future<void> pump(WidgetTester t, DesignLanguage design) async {
      AppPlatform.debugDesignOverride = design;
      await t.binding.setSurfaceSize(const Size(400, 900));
      addTearDown(() => t.binding.setSurfaceSize(null));
      await t.pumpWidget(
        Provider<FlagCache>.value(
          value: FlagCache((_) async => null),
          child: MaterialApp(
            theme: AppTheme.light,
            locale: const Locale('en'),
            localizationsDelegates: AppLocalizations.localizationsDelegates,
            supportedLocales: AppLocalizations.supportedLocales,
            home: const RailAreaRankingPage(
              entry: _entry,
              displayName: 'Luxembourg',
              flagCode: 'LU',
              currentUsername: 'me',
            ),
          ),
        ),
      );
      await t.pump();
    }

    for (final design in DesignLanguage.values) {
      final isMaterial = design == DesignLanguage.material;

      testWidgets('${design.name}: its own view, position and rows', (t) async {
        await pump(t, design);
        expect(
          find.byType(RailAreaRankingMaterialView),
          isMaterial ? findsOneWidget : findsNothing,
        );
        expect(
          find.byType(RailAreaRankingCupertinoView),
          isMaterial ? findsNothing : findsOneWidget,
        );
        expect(
          find.byType(
            isMaterial ? RankingUserPositionBlock : PositionCardCupertino,
          ),
          findsOneWidget,
        );
        expect(find.text('zoe'), findsOneWidget);
        expect(find.text('adam'), findsOneWidget);
        expect(find.text('Luxembourg'), findsOneWidget);
      });
    }

    testWidgets('cupertino: the search bar filters the rows', (t) async {
      await pump(t, DesignLanguage.cupertino);

      await t.tap(find.bySemanticsLabel('Search users…').first);
      await t.pump();
      expect(find.byType(AppGlassSearchBar), findsOneWidget);
      expect(find.byType(PositionCardCupertino), findsNothing);

      await t.enterText(
        find.descendant(
          of: find.byType(AppGlassSearchBar),
          matching: find.byType(EditableText),
        ),
        'ad',
      );
      await t.pump();
      expect(find.text('adam'), findsOneWidget);
      expect(find.text('zoe'), findsNothing);
    });
  });
}
