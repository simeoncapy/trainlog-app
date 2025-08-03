import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as p;
import 'dart:io';

class AppCacheFileNames {
  static const database = "trainlog.db";
  static const polylines = "polylines_cache.json";
}

class AppCacheFilePath {
  static late String database;
  static late String polylines;

  static Future<void> init() async {
    final dir = await getApplicationSupportDirectory();
    database = p.join(dir.path, AppCacheFileNames.database);
    polylines = p.join(dir.path, AppCacheFileNames.polylines);
  }
}

double computeCacheFileSize(String path) {
  final file = File(path);
  if (!file.existsSync()) return 0.0;

  final bytes = file.lengthSync();
  const bytesPerMB = 1024 * 1024;

  return bytes / bytesPerMB;
}