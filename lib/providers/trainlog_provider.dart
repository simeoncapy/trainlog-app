import 'dart:ui';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:trainlog_app/data/models/trips.dart';
import 'package:trainlog_app/providers/settings_provider.dart';
import '../services/trainlog_service.dart';

class TrainlogProvider extends ChangeNotifier {
  final TrainlogService _service;

  bool _loading = false;
  bool _isAuthenticated = false;
  String? _error;
  String? _username;
  TrainlogLoginResult? _session;
  Map<String, String> _listOperatorsLogoUrl = Map();
  Map<String, String> _listOperators = Map();

  TrainlogProvider({TrainlogService? service})
      : _service = service ?? TrainlogService();

  bool get loading => _loading;
  bool get isAuthenticated => _isAuthenticated;
  String? get error => _error;
  String? get username => _username;
  TrainlogLoginResult? get session => _session;
  TrainlogService get service => _service;
  Map<String, String> get listOperators => _listOperators;

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
        _listOperatorsLogoUrl = await _service.fetchAllOperatorLogosUrl(username);
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

  Future<void> reloadOperatorList() async {
    if (_username == null) return;
    _listOperatorsLogoUrl = await _service.fetchAllOperatorLogosUrl(_username ?? "");
  }

  List<Image> getOperatorImages(
    String operatorName, {
    required double maxWidth,
    required double maxHeight,
    String separator = "&&"
  }) {
    if (_listOperatorsLogoUrl.isEmpty) reloadOperatorList();

    // Split multiple operators by &&
    final operators = operatorName.split(separator).map((s) => s.trim()).toList();

    // Return one image per operator
    return operators.map((op) {
      final url = _listOperatorsLogoUrl[op];

      if (url == null || url.trim().isEmpty) {
        return Image.asset(
          'assets/images/logo_fallback.png',
          width: maxWidth,
          height: maxHeight,
          fit: BoxFit.contain,
        );
      }

      return Image.network(
        url,
        width: maxWidth,
        height: maxHeight,
        fit: BoxFit.contain,
        loadingBuilder: (context, child, progress) {
          if (progress == null) return child;
          final expected = progress.expectedTotalBytes;
          final loaded = progress.cumulativeBytesLoaded;
          final value = expected != null ? loaded / expected : null;

          return SizedBox(
            width: maxWidth,
            height: maxHeight,
            child: Center(
              child: CircularProgressIndicator(
                strokeWidth: 2,
                value: value,
              ),
            ),
          );
        },
        errorBuilder: (context, error, stack) => Image.asset(
          'assets/images/logo_fallback.png',
          width: maxWidth,
          height: maxHeight,
          fit: BoxFit.contain,
        ),
      );
    }).toList();
  }

  Image getOperatorImage(
    String operatorName, {
    required double maxWidth,
    required double maxHeight,
  }) {
    final images = getOperatorImages(
      operatorName,
      maxWidth: maxWidth,
      maxHeight: maxHeight,
    );
    return images.first; // use first image only
  }

  Future<Map<String, dynamic>> fetchStatsForVehicleType(VehicleType type, int? year) async {
    if (_username == null) return {};
    return await _service.fetchStatsByVehicle(_username ?? "", type, year);
  }
}
