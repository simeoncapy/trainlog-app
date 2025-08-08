import 'dart:ffi';
import 'dart:io';
import 'package:csv/csv.dart';
import 'package:flutter/material.dart';
import 'package:sqflite/sqflite.dart';
import 'package:trainlog_app/data/models/trips.dart';
import 'package:trainlog_app/data/database_manager.dart';
import 'package:trainlog_app/providers/settings_provider.dart';
import 'package:diacritic/diacritic.dart';
import 'dart:convert';
import 'package:country_picker/country_picker.dart';
import 'package:trainlog_app/widgets/trips_filter_dialog.dart';

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

  Future<List<Trips>> getAllTrips({int? limit, int? offset, String? orderBy}) async {
    final maps = await _db.query(
      TripsTable.tableName,
      limit: limit,
      offset: offset,
      orderBy: orderBy,
    );
    return maps.map((map) => Trips.fromJson(map)).toList();
  }

  Future<List<Trips>> getTripsFiltered({
    required bool showFutureTrips,
    int? limit,
    int? offset,
    String? orderBy,
    TripsFilterResult? filter,
  }) async {
    final whereInfo  = _buildWhereClause(showFutureTrips: showFutureTrips, filter: filter);

    final maps = await _db.query(
      TripsTable.tableName,
      where: whereInfo['where'] as String,
      whereArgs: whereInfo['args'] as List<dynamic>,
      limit: limit,
      offset: offset,
      orderBy: orderBy,
    );

    return maps.map((map) => Trips.fromJson(map)).toList();
  }

  Future<int> count() async {
    final result = await _db.rawQuery('SELECT COUNT(*) FROM ${TripsTable.tableName}');
    return Sqflite.firstIntValue(result) ?? 0;
  }

  Future<int> countFilteredTrips({required bool showFutureTrips, TripsFilterResult? filter,}) async {
    final whereInfo = _buildWhereClause(showFutureTrips: showFutureTrips, filter: filter);

    final result = await _db.rawQuery(
      'SELECT COUNT(*) FROM ${TripsTable.tableName} WHERE ${whereInfo['where']}',
      whereInfo['args'] as List<dynamic>,
    );

    return Sqflite.firstIntValue(result) ?? 0;
  }

  Map<String, dynamic> _buildWhereClause({
    required bool showFutureTrips,
    TripsFilterResult? filter,
  }) {
    final now = DateTime.now().toIso8601String();
    final clauses = <String>[];
    final args = <dynamic>[];

    // Time filter
    clauses.add('start_datetime ${showFutureTrips ? '>' : '<='} ?');
    args.add(now);

    // Keyword
    if (filter?.keyword.trim().isNotEmpty ?? false) {
      final keyword = removeDiacritics(filter!.keyword.trim().toLowerCase());
      clauses.add('('
          'LOWER(origin_station) LIKE ? OR '
          'LOWER(destination_station) LIKE ? OR '
          'LOWER(material_type) LIKE ? OR '
          'LOWER(line_name) LIKE ?'
          ')');
      for (int i = 0; i < 4; i++) {
        args.add('%$keyword%');
      }
    }

    // Operator
    if (filter?.operatorName != null && filter!.operatorName != 'All') {
      clauses.add('operator = ?');
      args.add(Uri.encodeComponent(filter.operatorName!));
    }

    // Country
    if (filter?.country != null && filter!.country != 'All') {
      // JSON string contains country code as key like "JP"
      clauses.add('countries LIKE ?');
      args.add('%"${filter.country}"%');
    }

    // Types
    if (filter?.types.isNotEmpty ?? false) {
      final types = filter!.types.map((t) => t.toShortString()).toList();
      final placeholders = List.filled(types.length, '?').join(',');
      clauses.add('type IN ($placeholders)');
      args.addAll(types);
    }

    // Dates
    if (filter?.startDate != null) {
      clauses.add('start_datetime >= ?');
      args.add(filter!.startDate!.toIso8601String());
    }
    if (filter?.endDate != null) {
      clauses.add('end_datetime <= ?');
      args.add(filter!.endDate!.toIso8601String());
    }

    return {
      'where': clauses.join(' AND '),
      'args': args,
    };
  }

  Future<List<String>> getPaths() async {
    final maps = await _db.query(
      TripsTable.tableName,
      columns: ['path'],
      where: 'path IS NOT NULL AND path != ""',
    );
    return maps.map((m) => m['path'] as String).toList();
  }

  Future<List<Map<String, dynamic>>> getPathExtendedData([
    PathDisplayOrder order = PathDisplayOrder.creationDate,
  ]) async {
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
        'created', // Needed for sorting by creationDate
      ],
      where: 'path IS NOT NULL AND path != ""',
    );

    final list = maps.map((e) {
      final typeEnum = VehicleType.fromString(e['type']?.toString());
      return {
        ...e,
        'type': typeEnum,
      };
    }).toList();

    switch (order) {
      case PathDisplayOrder.creationDate:
        //list.sort((a, b) => a['uid'].compareTo(b['uid']));
        break;

      case PathDisplayOrder.tripDate:
        list.sort((a, b) =>
            DateTime.parse(a['start_datetime'] as String).compareTo(DateTime.parse(b['start_datetime'] as String)));
        break;

      case PathDisplayOrder.tripDatePlaneOver:
        final nonAir = list
            .where((e) => e['type'] != VehicleType.plane)
            .toList()
          ..sort((a, b) =>
              DateTime.parse(a['start_datetime'] as String).compareTo(DateTime.parse(b['start_datetime'] as String)));
        final air = list
            .where((e) => e['type'] == VehicleType.plane)
            .toList()
          ..sort((a, b) => DateTime.parse(a['created'] as String).compareTo(DateTime.parse(b['created'] as String)));

        return [...nonAir, ...air];
    }

    return list;
  }

  Future<List<VehicleType>> fetchListOfTypes() async {
    final maps = await _db.query(
      TripsTable.tableName,
      columns: ['type'],
      where: 'type IS NOT NULL AND type != ""',
    );

    final types = maps
        .map((map) => VehicleType.fromString(map['type'] as String))
        .where((name) => name != VehicleType.unknown)
        .toSet()
        .toList()
        ..sort((a, b) => a.index.compareTo(b.index));

    return types;
  }

  Future<List<String>> fetchListOfOperators() async {
    final maps = await _db.query(
      TripsTable.tableName,
      columns: ['operator'],
      where: 'operator IS NOT NULL AND operator != ""',
    );

    final operators = maps
        .map((map) => Uri.decodeComponent(map['operator'] as String))
        .where((name) => name.trim().isNotEmpty)
        .toSet()
        .toList();

      // Sort alphabetically, ignoring case and diacritics
      operators.sort((a, b) =>
        removeDiacritics(a).toLowerCase().compareTo(removeDiacritics(b).toLowerCase())
      );

    return operators;
  }

  Future<List<int>> fetchListOfYears() async {
    final maps = await _db.query(
      TripsTable.tableName,
      columns: ['start_datetime'],
      where: 'start_datetime IS NOT NULL AND start_datetime != ""',
    );

    final dates = maps
        .map((map) => DateTime.parse(map['start_datetime'] as String).year)
        .toSet()
        .toList()
        ..sort();

    return dates;
  }

  Future<List<String>> fetchListOfCountryCode() async {
    final maps = await _db.query(
      TripsTable.tableName,
      columns: ['countries'],
      where: 'countries IS NOT NULL AND countries != ""',
    );

    final Set<String> countryCodes = {};

    for (final map in maps) {
      final raw = map['countries'] as String;
      final decoded = Uri.decodeComponent(raw);

      try {
        final Map<String, dynamic> json = jsonDecode(decoded);
        countryCodes.addAll(json.keys);
      } catch (e) {
        print('⚠️ Failed to decode country JSON: $decoded');
      }
    }

    final sorted = countryCodes.toList()
      ..sort((a, b) => a.toLowerCase().compareTo(b.toLowerCase()));
    return sorted;
  }

  Future<Map<String, String>> fetchMapOfCountries(BuildContext context) async {
    final details = CountryLocalizations.of(context);
    final listCodes = await fetchListOfCountryCode();

    final Map<String, String> map = {
      for (final code in listCodes)
        code: details?.countryName(countryCode: code) ?? code,
    };

    final sorted = Map.fromEntries(
      map.entries.toList()
        ..sort((a, b) => a.value.toLowerCase().compareTo(b.value.toLowerCase())),
    );

    return sorted;
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
