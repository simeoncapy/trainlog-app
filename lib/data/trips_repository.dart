import 'dart:ffi';
import 'dart:io';
import 'package:csv/csv.dart';
import 'package:sqflite/sqflite.dart';
import 'package:trainlog_app/data/models/trips.dart';
import 'package:trainlog_app/data/database_manager.dart';
import 'package:google_polyline_algorithm/google_polyline_algorithm.dart';

// TripsTable defined lower

class TripsRepository {
  final Database _db;

  TripsRepository(this._db);

  static Future<TripsRepository> loadFromCsv(String csvPath, {bool replace = false}) async {
    if (!File(csvPath).existsSync()) {
      throw FileSystemException('CSV file not found', csvPath);
    }

    final content = await File(csvPath).readAsString();
    final trips = await parseCsv(content);
    final db = await DatabaseManager.database;
    final repo = TripsRepository(db);

    if (replace) {
      await repo.clearAllTrips();
    }

    await repo.insertTrips(trips);
    return repo;
  }

  Future<void> loadFromApi() async {
    throw UnimplementedError('API loading not implemented');
  }

  static Future<TripsRepository> loadFromDatabase() async {
    final db = await DatabaseManager.database;
    return TripsRepository(db);
  }

  Future<List<Trips>> getAllTrips() async {
    final maps = await _db.query(TripsTable.tableName);
    return maps.map((map) => Trips.fromJson(map)).toList();
  }

  Future<int> count() async {
    final result = await _db.rawQuery('SELECT COUNT(*) FROM ${TripsTable.tableName}');
    return Sqflite.firstIntValue(result) ?? 0;
  }

  Future<List<String>> getPaths() async {
    final maps = await _db.query(
      TripsTable.tableName,
      columns: ['path'],
      where: 'path IS NOT NULL AND path != ""',
    );
    return maps.map((m) => m['path'] as String).toList();
  }

  Future<List<Map<String, dynamic>>> getPathExtendedData() async {
    final maps = await _db.query(
      TripsTable.tableName,
      columns: [
        'uid',
        'path',
        'type',
        'origin_station',
        'destination_station',
        'start_datetime',
        'end_datetime',
      ],
      where: 'path IS NOT NULL AND path != ""',
    );

    return maps.map((e) {
      final typeEnum = VehicleType.fromString(e['type']?.toString());
      return {
        ...e,
        'type': typeEnum,
      };
    }).toList();
  }

  Future<void> insertTrip(Trips trip) async {
    await _db.insert(
      TripsTable.tableName,
      trip.toJson(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<void> insertTrips(List<Trips> trips) async {
    final batch = _db.batch();
    for (final trip in trips) {
      batch.insert(
        TripsTable.tableName,
        trip.toJson(),
        conflictAlgorithm: ConflictAlgorithm.replace,
      );
    }
    await batch.commit(noResult: true);
  }

  Future<void> clearAllTrips() async {
    await _db.delete(TripsTable.tableName);
  }

  static Future<List<Trips>> parseCsv(String csvContent) async {
    print('🧪 Inside isolate: parsing CSV...');
    final rows = const CsvToListConverter(eol: '\n', shouldParseNumbers: false).convert(csvContent);
    print('📊 Parsed ${rows.length} rows');

    final header = rows.first.map((e) => e.toString().trim()).toList();
    final dataRows = rows.skip(1);

    final trips = <Trips>[];

    for (int r = 0; r < dataRows.length; r++) {
      final row = dataRows.elementAt(r);
      final map = <String, String>{};

      for (int i = 0; i < header.length && i < row.length; i++) {
        map[header[i]] = row[i]?.toString().trim() ?? '';
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
}

class TripsTable {
  static const String tableName = 'trips';

  static const String createTableSql = '''
    CREATE TABLE IF NOT EXISTS $tableName (
      uid TEXT PRIMARY KEY,
      username TEXT,
      origin_station TEXT,
      destination_station TEXT,
      start_datetime TEXT,
      end_datetime TEXT,
      estimated_trip_duration REAL,
      manual_trip_duration REAL,
      trip_length REAL,
      operator TEXT,
      countries TEXT,
      utc_start_datetime TEXT,
      utc_end_datetime TEXT,
      line_name TEXT,
      created TEXT,
      last_modified TEXT,
      type TEXT,
      material_type TEXT,
      seat TEXT,
      reg TEXT,
      waypoints TEXT,
      notes TEXT,
      price REAL,
      currency TEXT,
      purchasing_date TEXT,
      path TEXT
    )
  ''';
}
