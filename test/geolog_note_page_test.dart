import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:trainlog_app/app/theme/app_theme.dart';
import 'package:trainlog_app/data/models/geolog_note.dart';
import 'package:trainlog_app/data/models/pre_record_model.dart';
import 'package:trainlog_app/data/models/trips.dart';
import 'package:trainlog_app/features/spr/geolog_note_page.dart';
import 'package:trainlog_app/features/spr/widgets/pre_record_tile.dart';
import 'package:trainlog_app/l10n/app_localizations.dart';
import 'package:trainlog_app/providers/settings_provider.dart';
import 'package:trainlog_app/providers/trainlog_provider.dart';
import 'package:trainlog_app/services/api/trainlog_http_client.dart';

import 'fake_trainlog_server.dart';

PreRecordModel _record({GeologNote? note}) => PreRecordModel(
  id: 7,
  stationName: 'Lyon Part-Dieu',
  lat: 45.760585,
  long: 4.859435,
  dateTime: DateTime(2026, 10, 31, 8, 0),
  type: VehicleType.train,
  loaded: true,
  note: note,
);

Future<void> _pump(WidgetTester tester, Widget home) async {
  late SettingsProvider settings;
  late TrainlogProvider trainlog;
  await tester.runAsync(() async {
    SharedPreferences.setMockInitialValues({});
    settings = SettingsProvider();
    await settings.ready;
    final client = TrainlogHttpClient()
      ..dio.httpClientAdapter = FakeAdapter(fakeServer(signedIn: () => true));
    trainlog = TrainlogProvider(client: client);
  });

  await tester.pumpWidget(
    MultiProvider(
      providers: [
        ChangeNotifierProvider<SettingsProvider>.value(value: settings),
        ChangeNotifierProvider<TrainlogProvider>.value(value: trainlog),
      ],
      child: MaterialApp(
        theme: AppTheme.light,
        locale: const Locale('en'),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: home,
      ),
    ),
  );
  await tester.pumpAndSettle();
}

void main() {
  testWidgets('the card tells a Geolog with a note from one without', (
    tester,
  ) async {
    await _pump(
      tester,
      Scaffold(
        body: Column(
          children: [
            PreRecordTile(
              record: _record(),
              selected: false,
              selectionIndex: -1,
              onTap: () {},
              onNote: () {},
            ),
            PreRecordTile(
              record: _record(note: const GeologNote(seat: '12')),
              selected: false,
              selectionIndex: -1,
              onTap: () {},
              onNote: () {},
            ),
          ],
        ),
      ),
    );

    expect(find.text('Add note'), findsOneWidget);
    expect(find.text('Edit note'), findsOneWidget);
    expect(find.byTooltip('This Geolog has a note'), findsOneWidget);
  });

  testWidgets('the note page shows the station, its position and the note', (
    tester,
  ) async {
    GeologNoteResult? result;
    await _pump(
      tester,
      Builder(
        builder: (context) => Scaffold(
          body: TextButton(
            onPressed: () async {
              result = await Navigator.of(context).push<GeologNoteResult>(
                MaterialPageRoute(
                  builder: (_) => GeologNotePage(
                    record: _record(
                      note: const GeologNote(seat: '12', delayMinutes: 4),
                    ),
                  ),
                ),
              );
            },
            child: const Text('open'),
          ),
        ),
      ),
    );

    await tester.tap(find.text('open'));
    await tester.pumpAndSettle();

    expect(find.text('Geolog note'), findsOneWidget);
    expect(find.text('Lyon Part-Dieu'), findsOneWidget);
    expect(find.text('45.760585, 4.859435'), findsOneWidget);
    expect(find.byTooltip('Delete note'), findsOneWidget);
    // No path block on a note.
    expect(find.text('PATH'), findsNothing);

    await tester.tap(find.text('Save note'));
    await tester.pumpAndSettle();

    expect(result, isNotNull);
    expect(result!.station, isNull);
    expect(result!.note?.seat, '12');
    expect(result!.note?.delayMinutes, 4);
  });
}
