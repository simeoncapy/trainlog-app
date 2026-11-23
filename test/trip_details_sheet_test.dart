import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:trainlog_app/core/data/models/trip_visibility.dart';
import 'package:trainlog_app/core/data/models/trips.dart';
import 'package:trainlog_app/core/providers/polyline_provider.dart';
import 'package:trainlog_app/core/providers/settings_provider.dart';
import 'package:trainlog_app/core/providers/trainlog_provider.dart';
import 'package:trainlog_app/core/providers/trips_provider.dart';
import 'package:trainlog_app/core/services/api/trainlog_http_client.dart';
import 'package:trainlog_app/features/trips/detail_sheet/cupertino/trip_details_sheet_cupertino.dart';
import 'package:trainlog_app/features/trips/detail_sheet/material/trip_details_sheet_material.dart';
import 'package:trainlog_app/features/trips/detail_sheet/trip_details_bottom_sheet.dart';
import 'package:trainlog_app/features/trips/detail_sheet/trip_details_common.dart';
import 'package:trainlog_app/l10n/app_localizations.dart';
import 'package:trainlog_app/ui/design.dart';
import 'package:trainlog_app/ui/tokens/app_theme.dart';
import 'package:trainlog_app/utils/platform_utils.dart';

import 'fake_trainlog_server.dart';

Trips _trip() => Trips(
  uid: '42',
  username: 'simtester',
  originStation: 'Lyon Part-Dieu',
  destinationStation: 'Paris Gare de Lyon',
  startDatetime: DateTime(2026, 10, 31, 8),
  endDatetime: DateTime(2026, 10, 31, 10),
  estimatedTripDuration: 7200,
  tripLength: 427000,
  operatorName: 'SNCF',
  countries: '{"FR": 427000}',
  lineName: 'TGV',
  created: DateTime(2026, 10, 1),
  lastModified: DateTime(2026, 10, 1),
  type: VehicleType.train,
  path: '',
  visibility: TripVisibility.private,
  notes: 'Window seat',
);

void main() {
  tearDown(() => AppPlatform.debugDesignOverride = null);

  for (final design in DesignLanguage.values) {
    testWidgets('${design.name}: draws its own sheet with the sections', (
      t,
    ) async {
      AppPlatform.debugDesignOverride = design;
      late SettingsProvider settings;
      late TrainlogProvider trainlog;
      await t.runAsync(() async {
        SharedPreferences.setMockInitialValues({});
        settings = SettingsProvider();
        await settings.ready;
        final client = TrainlogHttpClient()
          ..dio.httpClientAdapter = FakeAdapter(
            fakeServer(signedIn: () => true),
          );
        trainlog = TrainlogProvider(client: client);
      });
      await t.pumpWidget(
        MultiProvider(
          providers: [
            ChangeNotifierProvider.value(value: settings),
            ChangeNotifierProvider.value(value: trainlog),
            ChangeNotifierProvider(create: (_) => TripsProvider()),
            ChangeNotifierProvider(create: (_) => PolylineProvider()),
          ],
          child: MaterialApp(
            theme: AppTheme.light,
            locale: const Locale('en'),
            localizationsDelegates: AppLocalizations.localizationsDelegates,
            supportedLocales: AppLocalizations.supportedLocales,
            home: Scaffold(
              body: SizedBox(
                height: 700,
                child: TripDetailsBottomSheet(trip: _trip()),
              ),
            ),
          ),
        ),
      );
      await t.pump();

      final cupertino = design == DesignLanguage.cupertino;
      expect(
        find.byType(TripDetailsMaterialSheet),
        cupertino ? findsNothing : findsOneWidget,
      );
      expect(
        find.byType(TripDetailsCupertinoSheet),
        cupertino ? findsOneWidget : findsNothing,
      );
      expect(find.text('Lyon Part-Dieu'), findsWidgets);
      // iOS closes with a cross, Android with a down chevron.
      expect(
        find.byIcon(
          cupertino ? CupertinoIcons.xmark : Icons.keyboard_arrow_down,
        ),
        findsOneWidget,
      );

      // Notes are no longer italic, on both designs.
      final note = t.widget<Text>(find.text('Window seat'));
      expect(note.style?.fontStyle, isNot(FontStyle.italic));

      // The actions stay at the bottom, under the scroll view, on both.
      final edit = find.bySemanticsLabel('Edit');
      expect(edit, findsOneWidget);
      expect(
        find.ancestor(of: edit, matching: find.byType(Scrollable)),
        findsNothing,
      );

      // iOS: the duration has no pill, distance and speed are captioned
      // stats rather than cards (both read from TripDetailsStyle).
      final style = TripDetailsStyle.of(
        t.element(find.text('Distance').first),
      );
      expect(style.durationPill, !cupertino);
      expect(style.metricCards, !cupertino);
      expect(style.chip != null, cupertino);

      // Section titles and field labels: as written in the ARB on iOS,
      // in capitals on Android.
      expect(style.capsTitles, !cupertino);
      expect(find.text('Details'), cupertino ? findsOneWidget : findsNothing);
      expect(find.text('DETAILS'), cupertino ? findsNothing : findsOneWidget);
      expect(find.text('Vehicle'), cupertino ? findsOneWidget : findsNothing);
      expect(find.text('VEHICLE'), cupertino ? findsNothing : findsOneWidget);
    });
  }
}
