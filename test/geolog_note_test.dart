import 'package:flutter_test/flutter_test.dart';
import 'package:trainlog_app/data/models/geolog_note.dart';
import 'package:trainlog_app/data/models/pre_record_model.dart';
import 'package:trainlog_app/data/models/trip_form_model.dart';
import 'package:trainlog_app/data/models/trips.dart';
import 'package:trainlog_app/services/geolog_note_merger.dart';
import 'package:trainlog_app/widgets/trip_visibility_selector.dart';
import 'package:trainlog_app/widgets/vehicle_energy_selector.dart';

void main() {
  group('GeologNote', () {
    test('round-trips through JSON', () {
      final note = GeologNote(
        dateTime: DateTime(2026, 10, 31, 9, 15),
        delayMinutes: -3,
        operators: const ['SNCF', 'DB'],
        line: 'TGV 9573',
        material: 'ICE 3',
        registration: '4682',
        seat: '42',
        memo: 'Window seat',
        price: 39.5,
        currency: 'EUR',
        purchaseDate: DateTime(2026, 10, 1),
        energy: EnergyType.electric,
        visibility: TripVisibility.friends,
      );

      final back = GeologNote.fromJson(note.toJson());

      expect(back.dateTime, note.dateTime);
      expect(back.delayMinutes, -3);
      expect(back.operators, ['SNCF', 'DB']);
      expect(back.line, 'TGV 9573');
      expect(back.material, 'ICE 3');
      expect(back.registration, '4682');
      expect(back.seat, '42');
      expect(back.memo, 'Window seat');
      expect(back.price, 39.5);
      expect(back.currency, 'EUR');
      expect(back.purchaseDate, DateTime(2026, 10, 1));
      expect(back.energy, EnergyType.electric);
      expect(back.visibility, TripVisibility.friends);
    });

    test('an empty note serialises to nothing and is empty', () {
      const note = GeologNote();
      expect(note.isEmpty, isTrue);
      expect(note.toJson(), isEmpty);
    });
  });

  group('PreRecordModel note', () {
    PreRecordModel record({GeologNote? note}) => PreRecordModel(
      id: 1,
      stationName: 'Paris Gare de Lyon',
      lat: 48.844,
      long: 2.374,
      dateTime: DateTime(2026, 10, 31, 8, 0),
      type: VehicleType.train,
      loaded: true,
      note: note,
    );

    test('a record without a note keeps its recorded time', () {
      final r = record();
      expect(r.hasNote, isFalse);
      expect(r.effectiveDateTime, DateTime(2026, 10, 31, 8, 0));
    });

    test('the note date and time replace the recorded ones', () {
      final r = record(
        note: GeologNote(dateTime: DateTime(2026, 10, 31, 7, 58)),
      );
      expect(r.effectiveDateTime, DateTime(2026, 10, 31, 7, 58));
      expect(r.effectiveDateTimeUtc, DateTime(2026, 10, 31, 7, 58).toUtc());
      // The recorded time itself is kept.
      expect(r.dateTime, DateTime(2026, 10, 31, 8, 0));
    });

    test('the note survives a JSON round trip and copyWith', () {
      final r = record(note: const GeologNote(seat: '12A'));
      final back = PreRecordModel.fromJson(r.toJson());
      expect(back.note?.seat, '12A');
      expect(back.copyWith(loaded: true).note?.seat, '12A');
    });

    test('a record saved before notes existed loads without one', () {
      final json = record().toJson()..remove('note');
      expect(PreRecordModel.fromJson(json).note, isNull);
    });

    test('withNote drops an empty note', () {
      final r = record(note: const GeologNote(seat: '12A'));
      expect(r.withNote(const GeologNote()).note, isNull);
      expect(r.withNote(null).note, isNull);
    });

    test('withStation changes the station and the vehicle type', () {
      final r = record(
        note: const GeologNote(seat: '12A'),
      ).withStation(stationName: null, address: null, type: VehicleType.bus);
      expect(r.stationName, isNull);
      expect(r.type, VehicleType.bus);
      expect(r.note?.seat, '12A');
      expect(r.lat, 48.844);
    });
  });

  group('GeologNoteMerger', () {
    test('concatenates text fields, departure first, without repeats', () {
      final form = TripFormModel();
      GeologNoteMerger.apply(
        form,
        departure: const GeologNote(
          line: 'TGV',
          material: 'Duplex',
          seat: '12',
          memo: 'Left on time',
          operators: ['SNCF'],
        ),
        arrival: const GeologNote(
          line: 'TGV',
          seat: '14',
          memo: 'Arrived late',
          registration: '801',
          operators: ['SNCF', 'Renfe'],
        ),
      );

      expect(form.line, 'TGV');
      expect(form.material, 'Duplex');
      expect(form.registration, '801');
      expect(form.seat, '12, 14');
      expect(form.notes, 'Left on time\nArrived late');
      expect(form.selectedOperators, ['SNCF', 'Renfe']);
    });

    test('puts each delay on its own endpoint', () {
      final form = TripFormModel();
      GeologNoteMerger.apply(
        form,
        departure: const GeologNote(delayMinutes: 2),
        arrival: const GeologNote(delayMinutes: -5),
      );
      expect(form.delayDepartureMinute, 2);
      expect(form.delayArrivalMinute, -5);
    });

    test('takes single values from whichever note has them', () {
      final form = TripFormModel();
      GeologNoteMerger.apply(
        form,
        departure: GeologNote(
          price: 20,
          currency: 'EUR',
          purchaseDate: DateTime(2026, 10, 1),
        ),
        arrival: const GeologNote(
          energy: EnergyType.thermic,
          visibility: TripVisibility.public,
        ),
      );
      expect(form.price, 20);
      expect(form.currencyCode, 'EUR');
      expect(form.purchaseDate, DateTime(2026, 10, 1));
      expect(form.energyType, EnergyType.thermic);
      expect(form.tripVisibility, TripVisibility.public);
      expect(
        GeologNoteMerger.conflicts(
          GeologNote(price: 20, currency: 'EUR'),
          const GeologNote(energy: EnergyType.thermic),
        ),
        isEmpty,
      );
    });

    test('reports price, energy and visibility conflicts', () {
      const departure = GeologNote(
        price: 20,
        currency: 'EUR',
        energy: EnergyType.electric,
        visibility: TripVisibility.private,
      );
      const arrival = GeologNote(
        price: 20,
        currency: 'CHF',
        energy: EnergyType.thermic,
        visibility: TripVisibility.public,
      );
      expect(GeologNoteMerger.conflicts(departure, arrival), [
        GeologNoteConflict.price,
        GeologNoteConflict.energy,
        GeologNoteConflict.visibility,
      ]);
      expect(GeologNoteMerger.conflicts(departure, departure), isEmpty);
      expect(GeologNoteMerger.conflicts(departure, null), isEmpty);
    });

    test('applies the side chosen for each conflict', () {
      final form = TripFormModel();
      GeologNoteMerger.apply(
        form,
        departure: GeologNote(
          price: 20,
          currency: 'EUR',
          purchaseDate: DateTime(2026, 9, 1),
          energy: EnergyType.electric,
          visibility: TripVisibility.private,
        ),
        arrival: GeologNote(
          price: 30,
          currency: 'EUR',
          purchaseDate: DateTime(2026, 9, 2),
          energy: EnergyType.thermic,
          visibility: TripVisibility.public,
        ),
        choices: const {
          GeologNoteConflict.price: GeologNoteSide.arrival,
          GeologNoteConflict.energy: GeologNoteSide.departure,
          GeologNoteConflict.visibility: GeologNoteSide.arrival,
        },
      );
      expect(form.price, 30);
      expect(form.purchaseDate, DateTime(2026, 9, 2));
      expect(form.energyType, EnergyType.electric);
      expect(form.tripVisibility, TripVisibility.public);
    });

    test('leaves the form untouched without notes', () {
      final form = TripFormModel();
      GeologNoteMerger.apply(form, departure: null, arrival: null);
      expect(form.selectedOperators, isEmpty);
      expect(form.notes, isNull);
      expect(form.energyType, EnergyType.auto);
    });
  });
}
