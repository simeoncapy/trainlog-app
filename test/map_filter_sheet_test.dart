import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:trainlog_app/core/data/models/polyline_filter_state.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:trainlog_app/core/providers/polyline_provider.dart';
import 'package:trainlog_app/core/providers/settings_provider.dart';
import 'package:trainlog_app/ui/tokens/app_theme.dart';
import 'package:trainlog_app/features/map/filter/cupertino/map_filter_cupertino_view.dart';
import 'package:trainlog_app/features/map/filter/map_filter_sheet.dart';
import 'package:trainlog_app/features/map/filter/material/map_filter_material_view.dart';
import 'package:trainlog_app/l10n/app_localizations.dart';
import 'package:trainlog_app/ui/design.dart';
import 'package:trainlog_app/utils/platform_utils.dart';

void main() {
  tearDown(() => AppPlatform.debugDesignOverride = null);

  Future<PolylineProvider> pump(WidgetTester t, DesignLanguage design) async {
    AppPlatform.debugDesignOverride = design;
    final poly = PolylineProvider();
    late SettingsProvider settings;
    await t.runAsync(() async {
      SharedPreferences.setMockInitialValues({});
      settings = SettingsProvider();
      await settings.ready;
    });
    await t.pumpWidget(
      MultiProvider(
        providers: [
          ChangeNotifierProvider.value(value: settings),
          ChangeNotifierProvider.value(value: poly),
        ],
        child: MaterialApp(
          theme: AppTheme.light,
          locale: const Locale('en'),
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: Scaffold(body: MapFilterSheet(onClose: () {})),
        ),
      ),
    );
    await t.pump();
    return poly;
  }

  for (final design in DesignLanguage.values) {
    testWidgets('${design.name}: shows its own view and switches to Years', (
      t,
    ) async {
      final poly = await pump(t, design);

      expect(
        find.byType(MapFilterMaterialView),
        design == DesignLanguage.material ? findsOneWidget : findsNothing,
      );
      expect(
        find.byType(MapFilterCupertinoView),
        design == DesignLanguage.cupertino ? findsOneWidget : findsNothing,
      );
      expect(poly.yearFilterChoice, PolylineYearFilter.all);
      // iOS: no "Show N trips" button, the count is under the title.
      expect(
        find.text('No matching trips'),
        design == DesignLanguage.cupertino ? findsOneWidget : findsNothing,
      );
      expect(
        find.text('Show no trips'),
        design == DesignLanguage.material ? findsOneWidget : findsNothing,
      );

      await t.tap(find.text('Years').first);
      await t.pump();
      expect(poly.yearFilterChoice, PolylineYearFilter.years);
    });
  }
}
