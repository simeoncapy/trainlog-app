import 'dart:io';
import 'package:trainlog_app/data/models/trips.dart';
import 'package:trainlog_app/data/trips_csv_data_source.dart';
import 'package:trainlog_app/data/trips_sqlite_data_source.dart';

class TripsRepository {
  final TripsDataSource _dataSource;

  TripsRepository._(this._dataSource);

  static Future<TripsRepository> loadFromCsvOrDb({String? csvPath}) async {
    if (csvPath != null) {
      return loadFromCsv(csvPath);
    } else {
      return loadFromDb();
    }
  }

  static Future<TripsRepository> loadFromCsv(String csvPath) async {
    if (File(csvPath).existsSync()) {
      final csvSource = await TripsCsvDataSource.load(csvPath: csvPath);
      final trips = await csvSource.getAllTrips();
      await TripsDatabase.insertTrips(trips);
      return TripsRepository._(TripsSqliteDataSource());
    } else {
      throw FileSystemException('CSV file not found', csvPath);
    }
  }

  static Future<TripsRepository> loadFromDb() async {
      return TripsRepository._(TripsSqliteDataSource());
  }

  Future<List<Trips>> getAllTrips() => _dataSource.getAllTrips();
  Future<void> saveTrips(List<Trips> trips) => _dataSource.saveTrips(trips);

  // Placeholder for future API integration
  Future<void> loadFromApi() async {
    // TODO: implement API call and then insert into SQLite
    throw UnimplementedError('loadFromApi() has not been implemented yet.');    
  }

  Future<void> loadFromDbOrApi() async {
    // TODO: implement API call and then insert into SQLite
    throw UnimplementedError('loadFromDbOrApi() has not been implemented yet.');    
  }
}


abstract class TripsDataSource {
  Future<List<Trips>> getAllTrips();
  Future<void> saveTrips(List<Trips> trips);
}
