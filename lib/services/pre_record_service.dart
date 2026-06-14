import 'dart:convert';
import 'dart:io';

import 'package:trainlog_app/data/models/pre_record_model.dart';
import 'package:trainlog_app/utils/cached_data_utils.dart';

/// File persistence for the Smart Prerecorder records (prerecord.json).
class PreRecordService {
  const PreRecordService();

  File get _file => File(AppCacheFilePath.preRecord);

  /// Loads all records, dropping incomplete ones left over from an
  /// interrupted recording.
  Future<List<PreRecordModel>> loadAll() async {
    final file = _file;
    if (!await file.exists()) {
      await file.create(recursive: true);
      await file.writeAsString(jsonEncode([]));
      return [];
    }

    final content = await file.readAsString();
    if (content.trim().isEmpty) return [];

    final List decoded = jsonDecode(content);
    return decoded
        .map((e) => PreRecordModel.fromJson(e))
        .where((r) => r.loaded)
        .toList();
  }

  Future<void> saveAll(List<PreRecordModel> records) async {
    await _file.writeAsString(
      jsonEncode(records.map((e) => e.toJson()).toList()),
      flush: true,
    );
  }

  /// Removes the given records from the store. Used after a trip has been
  /// created from them (see AddTripPage).
  Future<void> deleteByIds(List<int> ids) async {
    final file = _file;
    if (!await file.exists()) return;

    final content = await file.readAsString();
    if (content.trim().isEmpty) return;

    final List decoded = jsonDecode(content);
    final records = decoded.map((e) => PreRecordModel.fromJson(e)).toList();
    records.removeWhere((r) => ids.contains(r.id));
    await saveAll(records);
  }
}
