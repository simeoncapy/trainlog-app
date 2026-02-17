import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

import 'package:trainlog_app/l10n/app_localizations.dart';
import 'package:trainlog_app/providers/settings_provider.dart';
import 'package:trainlog_app/providers/trainlog_provider.dart';
import 'package:trainlog_app/providers/trips_provider.dart';
import 'package:trainlog_app/utils/app_info_utils.dart';
import 'package:trainlog_app/utils/cached_data_utils.dart';

class SettingsVm extends ChangeNotifier {
  // Cache
  double totalCacheSize = 0.0;

  // Account settings loaded from API
  Map<String, String> accountSettings = {};
  int? accountVisibility; // 0/1/2
  bool? accountLeaderboard;
  bool? accountFriendSearch;
  bool? accountAppearGlobal;

  String accountVisibilityHelperText = "";

  int _tapOnVersion = 0;

  static const String accountSettingsKeyLeaderboard = "leaderboard";
  static const String accountSettingsKeyFriendSearch = "friend_search";
  static const String accountSettingsKeyAppearGlobal = "appear_on_global";
  static const String accountSettingsKeyVisibility = "share_level";

  static const String deleteAccountEmail = 'admin@trainlog.me';

  bool _isInitDone = false;
  bool get isInitDone => _isInitDone;

  void refreshCacheSize() {
    totalCacheSize = AppCacheFilePath.computeAllCacheFileSize();
    notifyListeners();
  }

  bool? _boolOrNull(Map<String, String> m, String key) {
    final v = m[key];
    return v == null ? null : (v == 'true');
  }

  Future<void> init({
    required SettingsProvider settings,
    required TrainlogProvider trainlog,
    required AppLocalizations l10n,
  }) async {
    refreshCacheSize();

    accountSettings = await trainlog.fetchAccountSettings();

    accountVisibility = accountSettings[accountSettingsKeyVisibility] != null
        ? int.tryParse(accountSettings[accountSettingsKeyVisibility]!)
        : null;

    accountLeaderboard = _boolOrNull(accountSettings, accountSettingsKeyLeaderboard);
    accountFriendSearch = _boolOrNull(accountSettings, accountSettingsKeyFriendSearch);
    accountAppearGlobal = _boolOrNull(accountSettings, accountSettingsKeyAppearGlobal);

    accountVisibilityHelperText = _visibilityHelperText(l10n, accountVisibility);

    if (trainlog.availableCurrencies.isEmpty) {
      await trainlog.reloadAvailableCurrencies();
    }

    _isInitDone = true;
    notifyListeners();
  }

  String _visibilityHelperText(AppLocalizations l10n, int? v) {
    switch (v) {
      case 0:
        return l10n.settingsAccountVisibilitPrivateHelper;
      case 1:
        return l10n.settingsAccountVisibilitRestrictedHelper;
      case 2:
        return l10n.settingsAccountVisibilitPublicHelper;
      default:
        return "";
    }
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
    required AppLocalizations l10n,
    required TrainlogProvider trainlog,
  }) {
    accountVisibility = value;
    accountVisibilityHelperText = _visibilityHelperText(l10n, value);
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
  }) async {
    settings.setShouldReloadPolylines(true);
    await tripsProvider.clearAll();

    await AppCacheFilePath.deleteFile(AppCacheFilePath.polylines);
    await AppCacheFilePath.deleteFile(AppCacheFilePath.preRecord);

    refreshCacheSize();
    settings.setShouldReloadPolylines(true);
  }

  Future<String> getVersionString() async {
    final v = await getAppVersionString();
    return 'v$v';
  }

  Future<void> onVersionTapped({
    required AppLocalizations l10n,
    required VoidCallback showCopiedInfo,
  }) async {
    final version = await getVersionString();
    await Clipboard.setData(ClipboardData(text: version));

    if (_tapOnVersion == 0) { // Avoid multiple toasts if multiple taps
      showCopiedInfo();
    }

    _tapOnVersion++;

    notifyListeners();
  }

  Uri buildDeleteAccountMailUri({
    required String username,
  }) {
    final body = [
      'Hello,',
      '',
      'I would like to delete my account, my username is $username.',
      '',
      'Thanks in advance,',
      '',
      'NB: message sent with Trainlog App.',
    ].join('\r\n');

    const subject = 'Request to delete my account';

    return Uri.parse(
      'mailto:$deleteAccountEmail'
      '?subject=${Uri.encodeComponent(subject)}'
      '&body=${Uri.encodeComponent(body)}',
    );
  }
}
