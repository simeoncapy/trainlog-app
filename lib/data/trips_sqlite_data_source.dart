import 'package:sqflite/sqflite.dart';
import 'package:trainlog_app/data/models/trips.dart';
import 'package:trainlog_app/data/trips_repository.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as p;

class TripsSqliteDataSource implements TripsDataSource {
  @override
  Future<List<Trips>> getAllTrips() => TripsDatabase.getAllTrips();

  @override
  Future<void> saveTrips(List<Trips> trips) => TripsDatabase.insertTrips(trips);
}

class TripsDatabase {
  static Database? _db;

  static Future<Database> get database async {
    if (_db != null) return _db!;
    final dir = await getApplicationSupportDirectory();
    final path = p.join(dir.path, 'trainlog.db');

    _db = await openDatabase(
      path,
      version: 1,
      onCreate: (db, version) async {
        await db.execute('''
          CREATE TABLE trips (
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
        ''');
      },
    );

    return _db!;
  }

  static Future<void> insertTrip(Trips trip) async {
    final db = await database;
    await db.insert('trips', trip.toJson(), conflictAlgorithm: ConflictAlgorithm.replace);
  }

  static Future<void> insertTrips(List<Trips> trips) async {
    final db = await database;
    final batch = db.batch();
    for (final trip in trips) {
      batch.insert('trips', trip.toJson(), conflictAlgorithm: ConflictAlgorithm.replace);
    }
    await batch.commit();
  }

  static Future<List<Trips>> getAllTrips() async {
    final db = await database;
    final maps = await db.query('trips');
    return maps.map((map) => Trips.fromJson(map)).toList();
  }

  static Future<void> clearTrips() async {
    final db = await database;
    await db.delete('trips');
  }
}