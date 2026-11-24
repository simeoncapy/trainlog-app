import 'dart:collection';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:trainlog_app/core/data/models/trips.dart';
import 'package:trainlog_app/core/data/models/trips_filter.dart';
import 'package:trainlog_app/core/data/trips_repository.dart';
import 'package:trainlog_app/core/providers/settings_provider.dart';
import 'package:trainlog_app/core/providers/trainlog_provider.dart';
import 'package:trainlog_app/features/trips/search_filter_sheet/cupertino/trips_filter_cupertino_view.dart';
import 'package:trainlog_app/features/trips/search_filter_sheet/material/trips_filter_material_view.dart';
import 'package:trainlog_app/features/trips/search_filter_sheet/trips_search_filter_sheet.dart';
import 'package:trainlog_app/l10n/app_localizations.dart';
import 'package:trainlog_app/ui/design.dart';
import 'package:trainlog_app/ui/tokens/app_theme.dart';
import 'package:trainlog_app/utils/platform_utils.dart';

/// Seven trips match whatever the filter.
class _FakeRepo implements TripsRepository {
  @override
  Future<int> countFilteredTrips({
    required bool showFutureTrips,
    TripsFilterResult? filter,
  }) async => 7;

  @override
  Future<LinkedHashMap<String, ({int past, int future})>>
  fetchOperatorsByTripPF({TripsFilterResult? filter}) async =>
      LinkedHashMap();

  @override
  Future<LinkedHashMap<String, ({int past, int future})>>
  fetchCountriesByTripPF({TripsFilterResult? filter}) async =>
      LinkedHashMap();

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

void main() {
  tearDown(() => AppPlatform.debugDesignOverride = null);

  Future<List<TripsFilterResult>> pump(
    WidgetTester t,
    DesignLanguage design,
  ) async {
    AppPlatform.debugDesignOverride = design;
    final changes = <TripsFilterResult>[];
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
          ChangeNotifierProvider(create: (_) => TrainlogProvider()),
        ],
        child: MaterialApp(
          theme: AppTheme.light,
          locale: const Locale('en'),
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: Scaffold(
            body: TripsSearchFilterSheet(
              repo: _FakeRepo(),
              countryOptions: const {'FR': 'France'},
              typeOptions: const [VehicleType.train, VehicleType.bus],
              showFutureTrips: false,
              onChanged: changes.add,
            ),
          ),
        ),
      ),
    );
    await t.pumpAndSettle();
    return changes;
  }

  testWidgets('material: the "Show N trips" button', (t) async {
    await pump(t, DesignLanguage.material);
    expect(find.byType(TripsFilterMaterialView), findsOneWidget);
    expect(find.text('Show 7 trips'), findsOneWidget);
  });

  testWidgets('cupertino: no button, the count under the title', (t) async {
    final changes = await pump(t, DesignLanguage.cupertino);
    expect(find.byType(TripsFilterCupertinoView), findsOneWidget);
    expect(find.text('Show 7 trips'), findsNothing);
    expect(find.text('7 trips'), findsOneWidget);

    // Each change is reported, so closing the sheet can apply it.
    await t.enterText(find.byType(EditableText), 'Kyoto');
    await t.pumpAndSettle();
    expect(changes.last.keyword, 'Kyoto');
  });
}
