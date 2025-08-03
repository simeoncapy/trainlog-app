import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:sqflite/sqflite.dart';
import 'package:trainlog_app/data/trips_repository.dart';
import 'package:trainlog_app/utils/cached_data_utils.dart';

class DatabaseManager {
  static Database? _db;
  static Future<Database> get database async {
    if (_db != null) return _db!;

    // Use FFI for desktop support
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;

    final path = AppCacheFilePath.database;

    _db = await databaseFactory.openDatabase(path, options: OpenDatabaseOptions(
      version: 1,
      onCreate: (db, version) async {
        await _createTables(db);
      },
    ));

    return _db!;
  }

  static Future<void> _createTables(Database db) async {
    // This will be populated by each table class separately.
    await db.execute(TripsTable.createTableSql);
    // Future tables can add more here
  }
}