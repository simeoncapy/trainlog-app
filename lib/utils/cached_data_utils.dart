import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as p;
import 'dart:io';

class AppCacheFileNames {
  static const database = "trainlog.db";
  static const polylines = "polylines_cache.json";
  static const preRecord = "prerecord.json";
  static const flagFolder = "flag_cache/";

  static const all = <String>[
    database,
    polylines,
    preRecord,
    flagFolder,
  ];
}

class AppCacheFilePath {
  static late String database;
  static late String polylines;
  static late String preRecord;
  static late String flagFolder;

  static late List<String> all;

  static Future<void> init() async {
    final dir = await getApplicationSupportDirectory();
    database = p.join(dir.path, AppCacheFileNames.database);
    polylines = p.join(dir.path, AppCacheFileNames.polylines);
    preRecord = p.join(dir.path, AppCacheFileNames.preRecord);
    flagFolder = p.join(dir.path, AppCacheFileNames.flagFolder);

    all = [database, polylines, preRecord, flagFolder];
  }

  static double computeCacheFileSize(String path) {
    if (path.characters.last == "/") return computeCacheFolderSize(path);
    final file = File(path);
    if (!file.existsSync()) return 0.0;

    final bytes = file.lengthSync();
    const bytesPerMB = 1024 * 1024;

    return bytes / bytesPerMB;
  }

  static double computeAllCacheFileSize() {
    return AppCacheFilePath.all.fold<double>(
      0.0,
      (sum, path) => sum + computeCacheFileSize(path),
    );
  }

  static double computeCacheFolderSize(String path) {
    final folder = Directory(path);
    if (!folder.existsSync()) return 0.0;

    int totalBytes = 0;

    try {
      for (final entity in folder.listSync(recursive: true, followLinks: false)) {
        if (entity is File) {
          totalBytes += entity.lengthSync();
        }
      }
    } catch (_) {
      // Ignore files that cannot be accessed.
    }

    const bytesPerMB = 1024 * 1024;
    return totalBytes / bytesPerMB;
  }

  static Future<FileSystemEntity> deleteFile(String path) async {
    return File(path)
      .delete()
      .catchError((e) {
        debugPrint('Failed to delete $path: $e');
        return File(path);
      });
  }
}

