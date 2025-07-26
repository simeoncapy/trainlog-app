import 'dart:io';
import 'package:csv/csv.dart';
import 'package:flutter/services.dart';
import 'package:trainlog_app/data/models/trips.dart';
import 'package:trainlog_app/data/trips_repository.dart';
import 'package:flutter/foundation.dart';

class TripsCsvDataSource implements TripsDataSource {
  final String csvContent;
  final String? csvPath;

  TripsCsvDataSource._(this.csvContent, this.csvPath);

  /// Factory to create a CSV source from a path or content
  static Future<TripsCsvDataSource> load({String? csvPath, String? csvContent}) async {
    try {
      if (csvPath != null) {
        final file = File(csvPath);

        final exists = await file.exists();
        if (!exists) {
          throw FileSystemException('File not found at: $csvPath');
        }

        final content = await file.readAsString();
        print('✅ CSV content loaded: ${content.length} characters');
        return TripsCsvDataSource._(content, csvPath);
      } else if (csvContent != null) {
        print('✅ CSV content loaded from string input.');
        return TripsCsvDataSource._(csvContent, null);
      } else {
        throw ArgumentError('Either csvPath or csvContent must be provided');
      }
    } catch (e, stack) {
      print('❌ Error reading CSV: $e\n$stack');
      rethrow;
    }
  }

  @override
  Future<List<Trips>> getAllTrips() async {
    print('🧪 Starting CSV parse in isolate...');
    final trips = await compute(_parseTripsCsv, csvContent);
    print('✅ Parsed ${trips.length} trips');
    return trips;
  }

  List<Trips> _parseTripsCsv(String csvContent) {
    print('🧪 Inside isolate: parsing CSV...');
    final rows = const CsvToListConverter(eol: '\n', shouldParseNumbers: false).convert(csvContent);
    print('📊 Parsed ${rows.length} rows');

    final header = rows.first.map((e) => e.toString()).toList();
    final dataRows = rows.skip(1);

    final trips = <Trips>[];

    for (int r = 0; r < dataRows.length; r++) {
      final row = dataRows.elementAt(r);
      final map = <String, String>{};

      for (int i = 0; i < header.length && i < row.length; i++) {
        map[header[i]] = row[i]?.toString() ?? '';
      }

      try {
        final trip = Trips.fromJson(map);
        trips.add(trip);
      } catch (e, stack) {
        print('❌ Error parsing row $r: $e');
        print('🧵 Stack: $stack');
        print('🔎 Row data: $map');
      }

      if (r % 100 == 0) print('➡️ Parsed $r trips');
    }

    return trips;
  }

  @override
  Future<void> saveTrips(List<Trips> trips) async {
    final csv = const ListToCsvConverter().convert([
      [
        'uid', 'username', 'origin_station', 'destination_station',
        'start_datetime', 'end_datetime', 'estimated_trip_duration',
        'manual_trip_duration', 'trip_length', 'operator', 'countries',
        'utc_start_datetime', 'utc_end_datetime', 'line_name', 'created',
        'last_modified', 'type', 'material_type', 'seat', 'reg', 'waypoints',
        'notes', 'price', 'currency', 'purchasing_date', 'path',
      ],
      ...trips.map((t) => [
        t.uid, t.username, t.originStation, t.destinationStation,
        t.startDatetime.toIso8601String(), t.endDatetime.toIso8601String(),
        t.estimatedTripDuration, t.manualTripDuration, t.tripLength, t.operatorName,
        t.countries, t.utcStartDatetime?.toIso8601String(), t.utcEndDatetime?.toIso8601String(),
        t.lineName, t.created.toIso8601String(), t.lastModified.toIso8601String(), t.type,
        t.materialType ?? '', t.seat ?? '', t.reg ?? '', t.waypoints ?? '', t.notes ?? '',
        t.price ?? '', t.currency ?? '', t.purchasingDate?.toIso8601String() ?? '', t.path
      ])
    ]);

    if (csvPath != null) {
      final file = File(csvPath!);
      await file.writeAsString(csv);
    } else {
      print(csv); // fallback
    }
  }
}
