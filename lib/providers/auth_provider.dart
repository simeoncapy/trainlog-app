import 'package:flutter/foundation.dart';
import 'package:dio/dio.dart';
import 'package:trainlog_app/providers/settings_provider.dart';
import '../services/trainlog_service.dart';

class AuthProvider extends ChangeNotifier {
  final TrainlogService _service;

  bool _loading = false;
  bool _isAuthenticated = false;
  String? _error;
  String? _username;
  TrainlogLoginResult? _session;

  AuthProvider({TrainlogService? service})
      : _service = service ?? TrainlogService();

  bool get loading => _loading;
  bool get isAuthenticated => _isAuthenticated;
  String? get error => _error;
  String? get username => _username;
  TrainlogLoginResult? get session => _session;
  TrainlogService get service => _service;

  Future<bool> login({
    required String username,
    required String password,
    SettingsProvider? settings
  }) async {
    _loading = true;
    _error = null;
    notifyListeners();

    try {
      final res = await _service.login(username: username, password: password);
      _session = res;
      _isAuthenticated = res.success;
      if (res.success) {
        _username = username;              // keep what the user typed
        settings?.setUsername(username);
      } else {
        _username = null;
        _error = res.failureReason ?? 'Invalid username or password';
      }
      return _isAuthenticated;
    } catch (e) {
      _error = 'Login failed: $e';
      _isAuthenticated = false;
      return false;
    } finally {
      _loading = false;
      notifyListeners();
    }
  }

  Future<void> logout({SettingsProvider? settings}) async {
    _loading = true;
    _error = null;
    notifyListeners();
    try {
      await _service.clearSession();
      settings?.clearUsername();
    } finally {
      _session = null;
      _isAuthenticated = false;
      _username = null;
      _loading = false;
      notifyListeners();
    }
  }

  Future<void> tryRestoreSession({SettingsProvider? settings}) async {
    _loading = true;
    _error = null;
    notifyListeners();
    try {
      final ok = await _service.checkAuthenticated();
      _isAuthenticated = ok;
      // (Optional) fetch/display username if there’s a profile endpoint
      if (ok) {
        // 1) Load last known username (saved at login)
        _username = settings?.authUsername;

        // 2) Optional: if not present, ask the API once (no scraping).
        if (_username == null) {
          final apiName = await _service.fetchUsernameViaApi(); // TODO wire real API
          if (apiName != null) {
            _username = apiName;
            settings?.setUsername(apiName);
          }
        }
      } else {
        _username = null;
      }
    } catch (e) {
      _isAuthenticated = false;
      _error = 'Session check failed: $e';
    } finally {
      _loading = false;
      notifyListeners();
    }
  }

  // Expose authenticated requests for the rest of the app.
  Future<Response<T>> get<T>(String path, {Map<String, dynamic>? query}) =>
      _service.get<T>(path, query: query);

  Future<Response<T>> post<T>(String path, Map<String, dynamic> data) =>
      _service.post<T>(path, data);
}
