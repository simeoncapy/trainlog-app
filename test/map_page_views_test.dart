import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:latlong2/latlong.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:trainlog_app/core/data/models/location_search_result.dart';
import 'package:trainlog_app/core/providers/polyline_provider.dart';
import 'package:trainlog_app/core/providers/settings_provider.dart';
import 'package:trainlog_app/features/map/cupertino/map_controls_cupertino.dart';
import 'package:trainlog_app/features/map/cupertino/map_cupertino_view.dart';
import 'package:trainlog_app/features/map/map_page.dart';
import 'package:trainlog_app/features/map/map_page_controller.dart';
import 'package:trainlog_app/features/map/material/map_controls_material.dart';
import 'package:trainlog_app/features/map/material/map_material_view.dart';
import 'package:trainlog_app/features/map/widgets/locked_on_position_pill.dart';
import 'package:trainlog_app/l10n/app_localizations.dart';
import 'package:trainlog_app/ui/design.dart';
import 'package:trainlog_app/ui/tokens/app_theme.dart';
import 'package:trainlog_app/utils/platform_utils.dart';

class _GrantedLocation implements MapLocationSource {
  @override
  Future<bool> hasPermission() async => true;
  @override
  Future<bool> requestPermission() async => true;
  @override
  Future<LatLng?> currentPosition() async => const LatLng(35.68, 139.76);
  @override
  Stream<LatLng> positionUpdates() => const Stream.empty();
  @override
  LatLng? get lastKnownPosition => null;
  @override
  void rememberPosition(LatLng position) {}
}

final _kyoto = LocationSearchResult(
  name: 'Kyoto',
  subtitle: 'Japan',
  countryCode: 'JP',
  point: const LatLng(35.01, 135.76),
  category: LocationCategory.city,
  source: LocationSearchSource.photon,
);

void main() {
  tearDown(() => AppPlatform.debugDesignOverride = null);

  Future<MapPageController> pump(WidgetTester t, DesignLanguage design) async {
    AppPlatform.debugDesignOverride = design;
    late SettingsProvider settings;
    await t.runAsync(() async {
      SharedPreferences.setMockInitialValues({});
      settings = SettingsProvider();
      await settings.ready;
    });
    final controller = MapPageController(
      location: _GrantedLocation(),
      search: (q) async => [_kyoto],
      searchDebounce: Duration.zero,
    );
    final actions = MapPageActions(
      mapController: MapController(),
      rotation: ValueNotifier(0),
      openFilter: () {},
      resetOrientation: () {},
    );
    await t.pumpWidget(
      MultiProvider(
        providers: [
          ChangeNotifierProvider.value(value: settings),
          ChangeNotifierProvider(create: (_) => PolylineProvider()),
          ChangeNotifierProvider.value(value: controller),
        ],
        child: MaterialApp(
          theme: AppTheme.light,
          locale: const Locale('en'),
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: Scaffold(
            body: PlatformView(
              material: (_) => MapMaterialView(actions: actions),
              cupertino: (_) => MapCupertinoView(actions: actions),
            ),
          ),
        ),
      ),
    );
    await t.pump();
    return controller;
  }

  for (final design in DesignLanguage.values) {
    final isMaterial = design == DesignLanguage.material;

    testWidgets('${design.name}: its own view and controls', (t) async {
      await pump(t, design);

      expect(
        find.byType(MapMaterialView),
        isMaterial ? findsOneWidget : findsNothing,
      );
      expect(
        find.byType(MapCupertinoView),
        isMaterial ? findsNothing : findsOneWidget,
      );
      expect(
        find.byType(MaterialMapSearchButton),
        isMaterial ? findsOneWidget : findsNothing,
      );
      expect(
        find.byType(CupertinoMapSearchButton),
        isMaterial ? findsNothing : findsOneWidget,
      );
      expect(find.byType(LockedOnPositionPill), findsNothing);
    });

    testWidgets('${design.name}: following shows the pill', (t) async {
      final controller = await pump(t, design);

      await t.runAsync(controller.toggleFollow);
      await t.pump();

      expect(controller.following, isTrue);
      expect(find.byType(LockedOnPositionPill), findsOneWidget);
    });

    testWidgets('${design.name}: search and pick a place', (t) async {
      final controller = await pump(t, design);

      await t.tap(
        find.byType(
          isMaterial ? MaterialMapSearchButton : CupertinoMapSearchButton,
        ),
      );
      await t.pump();
      await t.enterText(find.byType(TextField), 'Kyoto');
      await t.pump();
      await t.pump(const Duration(milliseconds: 10));
      await t.pump();

      expect(find.textContaining('Kyoto'), findsWidgets);
      await t.tap(find.text('🇯🇵 Kyoto'));
      await t.pump();

      expect(controller.searchedPlace, _kyoto);
      expect(find.byType(TextField), findsNothing);
    });
  }
}
