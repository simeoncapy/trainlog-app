import 'dart:ui';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:path/path.dart';
import 'package:trainlog_app/data/models/trips.dart';
import 'package:trainlog_app/providers/settings_provider.dart';
import 'package:trainlog_app/utils/text_utils.dart';
import '../services/trainlog_service.dart';
import 'package:latlong2/latlong.dart';
import "package:unorm_dart/unorm_dart.dart" as unorm;

typedef StationInfo = (
  String label,
  LatLng coords,
  String address,
  bool isManual
);

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

  String generateUserUrl(String? suffix, {bool publicPage = false}) {
    return publicPage ? "${_service.baseUrl}/$suffix" : "${_service.baseUrl}/u/$username/$suffix";
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
  
  bool hasOperatorLogo(String operatorName) {
    return _listOperatorsLogoUrl.containsKey(operatorName);
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

  /// Return up to [limit] operators that match [query] by
  /// substring match first, then fuzzy Levenshtein distance.
  List<String> getClosestOperators(String query, {int limit = 10}) {
    if (query.isEmpty) return [];

    final q = query.toLowerCase();

    // All available operators (keys of _listOperatorsLogoUrl)
    final ops = _listOperatorsLogoUrl.keys.toList();
    if (ops.isEmpty) return [];

    // 1) SUBSTRING MATCHES (higher priority)
    final substringMatches = ops
        .where((op) => op.toLowerCase().contains(q))
        .toList();

    // If enough matches found, return top results
    if (substringMatches.length >= limit) {
      substringMatches.sort(
        (a, b) => a.toLowerCase().indexOf(q).compareTo(b.toLowerCase().indexOf(q)),
      );
      return substringMatches.take(limit).toList();
    }

    // 2) FUZZY MATCHES (Levenshtein distance)
    final fuzzyMatches = <String, int>{};

    for (final op in ops) {
      final dist = _levenshteinDistance(q, op.toLowerCase());
      fuzzyMatches[op] = dist;
    }

    // Sort by closeness (smallest distance first)
    final sortedFuzzy = fuzzyMatches.entries.toList()
      ..sort((a, b) => a.value.compareTo(b.value));

    // Combine substring + fuzzy (without duplicates)
    final combined = [
      ...substringMatches,
      ...sortedFuzzy.map((e) => e.key).where((op) => !substringMatches.contains(op))
    ];

    return combined.take(limit).toList();
  }

  /// Basic Levenshtein distance implementation.
  int _levenshteinDistance(String s, String t) {
    if (s == t) return 0;
    if (s.isEmpty) return t.length;
    if (t.isEmpty) return s.length;

    final m = s.length;
    final n = t.length;

    final dp = List<List<int>>.generate(
      m + 1,
      (_) => List<int>.filled(n + 1, 0),
    );

    for (int i = 0; i <= m; i++) dp[i][0] = i;
    for (int j = 0; j <= n; j++) dp[0][j] = j;

    for (int i = 1; i <= m; i++) {
      for (int j = 1; j <= n; j++) {
        final cost = s[i - 1] == t[j - 1] ? 0 : 1;
        dp[i][j] = [
          dp[i - 1][j] + 1,     // deletion
          dp[i][j - 1] + 1,     // insertion
          dp[i - 1][j - 1] + cost, // replacement
        ].reduce((a, b) => a < b ? a : b);
      }
    }

    return dp[m][n];
  }

  String _normalize(String input) {
    // Decompose Unicode characters (NFD)
    final decomposed = unorm.nfd(input.toLowerCase());

    // Remove diacritic marks
    return decomposed.replaceAll(RegExp(r'[\u0300-\u036f]'), '');
  }

  int visitCount(String label, Map<String, int> visits) {
    return visits[label] ?? 0;
  }

  String cleanLabel(String label) {
    return removeFlagPrefix(label).toLowerCase();
  }

  Future<List<StationInfo>> fetchStations(
    String query,
    VehicleType type,
  ) async {
    if (_username == null) return [];

    // Run all three in parallel
    final manualFuture =
        service.fetchAllManualStationsSuffixed(_username!, type);
    final osmFuture = service.fetchStations(query, type);
    final visitsFuture =
        service.fetchAllVisitedStations(_username!, type);

    final manualMap = await manualFuture;
    final osmMap = await osmFuture;
    final visits = await visitsFuture; // Map<String, int>

    final normalizedQuery = _normalize(query);

    // ---- Manual stations (filtered by query) ----
    final manualList = manualMap.entries
        .map((e) => (
              e.key,         // label with flag
              e.value.$1,    // LatLng
              e.value.$2,    // address
              true,          // isManual
            ))
        .where((entry) {
          final label   = _normalize(entry.$1);
          //final address = _normalize(entry.$3);
          return label.contains(normalizedQuery)/* ||
                address.contains(normalizedQuery)*/;
        })
        .toList();

    // ---- OSM stations (already filtered by query in API) ----
    final osmList = osmMap.entries
        .map((e) => (
              e.key,
              e.value.$1,
              e.value.$2,
              false,
            ))
        .toList();

    // ---- Combine + attach visit counts ----
    // (label, coords, address, isManual, visits)
    final combined = <(
      String,
      LatLng,
      String,
      bool,
      int
    )>[];

    int visitCount(String label) => visits[label] ?? 0;
    String cleanLabel(String label) =>
        removeFlagPrefix(label).toLowerCase();

    for (final m in manualList) {
      combined.add((m.$1, m.$2, m.$3, m.$4, visitCount(m.$1)));
    }
    for (final o in osmList) {
      combined.add((o.$1, o.$2, o.$3, o.$4, visitCount(o.$1)));
    }

    // ---- Sort: 1) visits DESC, 2) alphabetical ignoring flag ----
    combined.sort((a, b) {
      final visitsDiff = b.$5.compareTo(a.$5); // most visited first
      if (visitsDiff != 0) return visitsDiff;

      return cleanLabel(a.$1).compareTo(cleanLabel(b.$1));
    });

    // ---- Back to StationInfo (label, coords, address, isManual) ----
    return combined.map((e) => (e.$1, e.$2, e.$3, e.$4)).toList();
  }

  List<StationInfo> _mergeStationLists(
    List<StationInfo> osm,
    List<StationInfo> manual,
  ) {
    final merged = <StationInfo>[];
    int i = 0;

    for (final osmItem in osm) {
      final osmKey =
          removeFlagPrefix(osmItem.$1).toLowerCase(); // key without emoji

      while (i < manual.length) {
        final manualKey =
            removeFlagPrefix(manual[i].$1).toLowerCase(); // key without emoji

        if (manualKey.compareTo(osmKey) < 0) {
          merged.add(manual[i]);
          i++;
        } else {
          break;
        }
      }

      merged.add(osmItem);
    }

    // Remaining manual items
    while (i < manual.length) {
      merged.add(manual[i]);
      i++;
    }

    return merged;
  }
}
