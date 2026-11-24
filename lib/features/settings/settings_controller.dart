import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

import 'package:trainlog_app/core/providers/settings_provider.dart';
import 'package:trainlog_app/core/providers/trainlog_provider.dart';
import 'package:trainlog_app/core/providers/trips_provider.dart';
import 'package:trainlog_app/core/services/flag_cache.dart';
import 'package:trainlog_app/utils/app_info_utils.dart';
import 'package:trainlog_app/utils/cached_data_utils.dart';
import 'package:trainlog_app/utils/date_utils.dart';

/// State and actions of the settings page that are not app-wide settings
/// (those live in [SettingsProvider]): the cache size, the account settings
/// stored on the server, and the version easter egg.
class SettingsController extends ChangeNotifier {
  // Cache
  double totalCacheSize = 0.0;

  // Account settings loaded from API
  Map<String, String> accountSettings = {};
  int? accountVisibility; // 0/1/2
  bool? accountLeaderboard;
  bool? accountFriendSearch;
  bool? accountAppearGlobal;

  int _tapOnVersion = 0;

  static const String accountSettingsKeyLeaderboard = "leaderboard";
  static const String accountSettingsKeyFriendSearch = "friend_search";
  static const String accountSettingsKeyAppearGlobal = "appear_on_global";
  static const String accountSettingsKeyVisibility = "share_level";

  bool _isInitDone = false;
  bool get isInitDone => _isInitDone;

  bool _disposed = false;

  @override
  void dispose() {
    _disposed = true;
    super.dispose();
  }

  void refreshCacheSize() {
    totalCacheSize = AppCacheFilePath.computeAllCacheFileSize();
    debugPrint('Cache size refreshed: $totalCacheSize bytes');
    notifyListeners();
  }

  bool? _boolOrNull(Map<String, String> m, String key) {
    final v = m[key];
    return v == null ? null : (v == 'true');
  }

  Future<void> init({
    required SettingsProvider settings,
    required TrainlogProvider trainlog,
  }) async {
    refreshCacheSize();

    accountSettings = await trainlog.fetchAccountSettings();
    if (_disposed) return;

    accountVisibility = accountSettings[accountSettingsKeyVisibility] != null
        ? int.tryParse(accountSettings[accountSettingsKeyVisibility]!)
        : null;

    accountLeaderboard = _boolOrNull(
      accountSettings,
      accountSettingsKeyLeaderboard,
    );
    accountFriendSearch = _boolOrNull(
      accountSettings,
      accountSettingsKeyFriendSearch,
    );
    accountAppearGlobal = _boolOrNull(
      accountSettings,
      accountSettingsKeyAppearGlobal,
    );

    if (trainlog.availableCurrencies.isEmpty) {
      await trainlog.reloadAvailableCurrencies();
      if (_disposed) return;
    }

    _isInitDone = true;
    notifyListeners();
  }

  void updateAccountSetting(TrainlogProvider trainlog) {
    final data = {
      accountSettingsKeyVisibility: accountVisibility,
      accountSettingsKeyLeaderboard: accountLeaderboard,
      accountSettingsKeyFriendSearch: accountFriendSearch,
      accountSettingsKeyAppearGlobal: accountAppearGlobal,
    };
    trainlog.updateAccountSettings(data);
  }

  void setAccountVisibility({
    required int value,
    required TrainlogProvider trainlog,
  }) {
    accountVisibility = value;
    notifyListeners();
    updateAccountSetting(trainlog);
  }

  void setAccountLeaderboard({
    required bool value,
    required TrainlogProvider trainlog,
  }) {
    accountLeaderboard = value;
    notifyListeners();
    updateAccountSetting(trainlog);
  }

  void setAccountFriendSearch({
    required bool value,
    required TrainlogProvider trainlog,
  }) {
    accountFriendSearch = value;
    notifyListeners();
    updateAccountSetting(trainlog);
  }

  void setAccountAppearGlobal({
    required bool value,
    required TrainlogProvider trainlog,
  }) {
    accountAppearGlobal = value;
    notifyListeners();
    updateAccountSetting(trainlog);
  }

  Future<void> clearCache({
    required SettingsProvider settings,
    required TripsProvider tripsProvider,
    bool clearGeologs = true,
  }) async {
    settings.setShouldReloadPolylines(true);
    settings.setLastFetchingTrips(forceRefreshDate.toUtc());
    await tripsProvider.clearAll();
    FlagCache.clearCache();

    await AppCacheFilePath.deleteFile(AppCacheFilePath.polylines);
    if (clearGeologs) {
      await AppCacheFilePath.deleteFile(AppCacheFilePath.preRecord);
    }

    refreshCacheSize();
    settings.setShouldReloadPolylines(true);
  }

  Future<String> getVersionString() async {
    final v = await getAppVersionString();
    return 'v$v';
  }

  Future<void> onVersionTapped({
    required VoidCallback showCopiedInfo,
    required VoidCallback openSnakeGame,
  }) async {
    final version = await getVersionString();
    await Clipboard.setData(ClipboardData(text: version));

    if (_tapOnVersion == 0) {
      // Avoid multiple toasts if multiple taps
      showCopiedInfo();
    }

    _tapOnVersion++;
    if (_tapOnVersion == 3) {
      _tapOnVersion = 0;
      openSnakeGame();
    }

    notifyListeners();
  }
}
