import 'package:flutter/foundation.dart';
import 'package:trainlog_app/core/providers/settings_provider.dart';
import 'package:trainlog_app/core/providers/trainlog_provider.dart';
import 'package:trainlog_app/core/providers/trips_provider.dart';

/// State and actions of the "You" menu, shared by its Material and iOS
/// views: the number of unread news, and logging out.
class AppMenuController extends ChangeNotifier {
  AppMenuController({
    required TrainlogProvider trainlog,
    required SettingsProvider settings,
    required TripsProvider trips,
  }) : _trainlog = trainlog,
       _settings = settings,
       _trips = trips;

  final TrainlogProvider _trainlog;
  final SettingsProvider _settings;
  final TripsProvider _trips;
  bool _disposed = false;

  int? _newMessageCount;

  /// Unread news in the inbox; null until fetched.
  int? get newMessageCount => _newMessageCount;

  Future<void> loadNewsCount() async {
    final count = await _trainlog.fetchNewsCount(_settings);
    if (_disposed) return;
    _newMessageCount = count;
    notifyListeners();
  }

  Future<void> logout() => _trainlog.logout(_settings, _trips);

  @override
  void dispose() {
    _disposed = true;
    super.dispose();
  }
}
