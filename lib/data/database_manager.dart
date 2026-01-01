import 'dart:io' show Platform;

import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:sqflite/sqflite.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

import 'package:trainlog_app/data/trips_repository.dart';
import 'package:trainlog_app/utils/cached_data_utils.dart';

class DatabaseManager {
  static Database? _db;

  static Future<Database> get database async {
    if (_db != null) return _db!;

    // Desktop: use sqflite_common_ffi
    if (Platform.isWindows || Platform.isLinux || Platform.isMacOS) {
      sqfliteFfiInit();
      databaseFactory = databaseFactoryFfi;

      final path = AppCacheFilePath.database; // must be a valid filesystem path on desktop
      _db = await databaseFactory.openDatabase(
        path,
        options: OpenDatabaseOptions(
          version: 1,
          onCreate: (db, version) async => _createTables(db),
        ),
      );
      return _db!;
    }

    // Mobile (Android/iOS): use sqflite (no FFI)
    final dbPath = await getDatabasesPath();
    final path = p.join(dbPath, 'trainlog.db'); // choose a fixed filename

    _db = await openDatabase(
      path,
      version: 1,
      onCreate: (db, version) async => _createTables(db),
    );

    return _db!;
  }

  static Future<void> _createTables(Database db) async {
    await db.execute(TripsTable.createTableSql);
  }
}
