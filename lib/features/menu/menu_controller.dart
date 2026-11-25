import 'package:flutter/foundation.dart';
import 'package:trainlog_app/core/providers/settings_provider.dart';
import 'package:trainlog_app/core/providers/trainlog_provider.dart';
import 'package:trainlog_app/core/providers/trips_provider.dart';

/// State and actions of the "You" menu, shared by its Material and iOS
/// views: the profile (name, trip count, server, public link), the number
/// of unread news, and logging out.
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
  int? _tripCount;

  /// The official instance, whose name the profile card does not show.
  static const officialHost = 'trainlog.me';

  String get username => _trainlog.username ?? '';

  /// Number of trips; null until counted.
  int? get tripCount => _tripCount;

  /// The instance the account is on, without its scheme ("localhost:5000"),
  /// or null on the official one.
  String? get customServer {
    final uri = Uri.tryParse(_trainlog.instanceUrl);
    if (uri == null || uri.host.isEmpty) return _trainlog.instanceUrl;
    if (uri.host == officialHost) return null;
    return uri.hasPort ? '${uri.host}:${uri.port}' : uri.host;
  }

  /// The user's public profile: `<instance>/public/<username>`.
  Uri get publicProfileUrl {
    final base = Uri.parse(_trainlog.instanceUrl);
    return base.replace(
      pathSegments: [
        ...base.pathSegments.where((s) => s.isNotEmpty),
        'public',
        username,
      ],
    );
  }

  /// Fetches the unread news and counts the trips.
  Future<void> load() => Future.wait([loadNewsCount(), loadTripCount()]);

  Future<void> loadTripCount() async {
    final count = await _trips.repository?.count();
    if (_disposed) return;
    _tripCount = count;
    notifyListeners();
  }

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
