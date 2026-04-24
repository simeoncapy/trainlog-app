import 'dart:io' show Platform;

import 'package:flutter/foundation.dart' show debugPrint;
import 'package:flutter/services.dart';
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
      await _runMigrations(_db!);
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

    await _runMigrations(_db!);
    return _db!;
  }

  static Future<void> _createTables(Database db) async {
    await db.execute(TripsTable.createTableSql);
  }

  static Future<void> _runMigrations(Database db) async {
    await db.execute('''
      CREATE TABLE IF NOT EXISTS _migrations (
        migration_id INTEGER PRIMARY KEY,
        applied_at TEXT NOT NULL
      )
    ''');

    final result = await db.rawQuery('SELECT MAX(migration_id) AS max_id FROM _migrations');
    final lastAppliedId = (result.first['max_id'] as int?) ?? 0;

    final pending = await _loadPendingMigrations(lastAppliedId);

    if (pending.isNotEmpty) {
      await db.transaction((txn) async {
        for (final migration in pending) {
          for (final statement in migration.statements) {
            await txn.execute(statement);
          }
          await txn.insert('_migrations', {
            'migration_id': migration.id,
            'applied_at': DateTime.now().toIso8601String(),
          });
          debugPrint('✅ Applied migration ${migration.id}');
        }
      });
    }

    // Legacy fallback: ensure any columns added outside of migrations are present.
    await TripsTable.ensureSchema(db);
  }

  static Future<List<_Migration>> _loadPendingMigrations(int lastAppliedId) async {
    const migrationsAssetPrefix = 'assets/migrations/';

    AssetManifest manifest;
    try {
      manifest = await AssetManifest.loadFromAssetBundle(rootBundle);
    } catch (e) {
      debugPrint('⚠️ Could not load asset manifest for migrations: $e');
      return [];
    }

    final sqlAssets = manifest
        .listAssets()
        .where((path) => path.startsWith(migrationsAssetPrefix) && path.endsWith('.sql'))
        .toList();

    final migrations = <_Migration>[];
    for (final assetPath in sqlAssets) {
      final filename = assetPath.split('/').last;
      final match = RegExp(r'^(\d+)_').firstMatch(filename);
      if (match == null) continue;

      final id = int.parse(match.group(1)!);
      if (id <= lastAppliedId) continue;

      String sql;
      try {
        sql = await rootBundle.loadString(assetPath);
      } catch (e) {
        debugPrint('⚠️ Could not load migration file $assetPath: $e');
        continue;
      }

      final statements = sql
          .split(';')
          .map((s) => s.trim())
          .where((s) => s.isNotEmpty)
          .toList();

      migrations.add(_Migration(id: id, statements: statements));
    }

    migrations.sort((a, b) => a.id.compareTo(b.id));
    return migrations;
  }
}

class _Migration {
  final int id;
  final List<String> statements;

  const _Migration({required this.id, required this.statements});
}
