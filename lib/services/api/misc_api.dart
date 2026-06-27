import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:trainlog_app/data/models/news_model.dart';
import 'package:trainlog_app/data/models/trips.dart';
import 'package:trainlog_app/services/api/trainlog_http_client.dart';

/// Miscellaneous endpoints that don't warrant their own domain: per-vehicle
/// stats, visited stations, operator logos and the news feed.
class MiscApi {
  final TrainlogHttpClient _client;

  MiscApi(this._client);

  Future<Map<String, dynamic>> fetchStatsByVehicle(String username, VehicleType type, int? year) async {
    final path = year == null
        ? '/u/$username/getStats/${type.toShortString()}'
        : '/u/$username/getStats/$year/${type.toShortString()}';

    final res = await _client.safeGet<Map<String, dynamic>>(path);

    final data = res.data; // already decoded JSON
    if (data == null) return {};

    return data;
  }

  Future<Map<String, int>> fetchAllVisitedStations(String username, VehicleType type) async {
    final path = '/u/$username/getManAndOps/${type.toShortString()}';

    final res = await _client.dio.get<Map<String, dynamic>>(
      path,
      options: Options(
        followRedirects: true,
        maxRedirects: 5,
        responseType: ResponseType.json,
        validateStatus: (s) => s != null && s >= 200 && s < 400,
      ),
    );

    final data = res.data; // already decoded JSON
    if (data == null) return {};

    final ops = data['visitedStations'];
    if (ops is! Map) return {}; // not present or wrong shape

    final out = <String, int>{};
    ops.forEach((k, v) {
      final key = k?.toString().trim();
      final val = _toInt(v);
      if (key != null && key.isNotEmpty && val != null) {
        out[key] = val;
      }
    });
    return out;
  }

  Future<Map<String, String>> fetchAllOperatorLogosUrl(String username) async {
    final path = '/u/$username/getManAndOps/train';

    final res = await _client.safeGet<Map<String, dynamic>>(path);

    final data = res.data; // already decoded JSON
    if (data == null) return {};

    final ops = data['operators'];
    if (ops is! Map) return {}; // not present or wrong shape

    final out = <String, String>{};
    ops.forEach((k, v) {
      final key = k?.toString().trim();
      final val = v?.toString().trim();
      if (key != null && key.isNotEmpty && val != null && val.isNotEmpty) {
        out[key] = _prefixLogo(_client.logoPath, val);
      }
    });
    return out;
  }

  Future<int> fetchNewsCount(DateTime lastVisit) async {
    final path = '/api/news/count/app/${lastVisit.toIso8601String()}';

    try {
      final res = await _client.safeGet<Map<String, dynamic>>(path);
      final data = res.data;
      if (data == null) return 0;

      final count = data["count"] is int ? data["count"] : int.tryParse(data["count"].toString()) ?? 0;

      return count;
    } catch (e) {
      debugPrint('🛑 fetchNewsCount failed: $e');
      return 0;
    }
  }

  Future<List<NewsModel>> fetchNews(DateTime lastVisit) async {
    final path = '/api/news/app/';

    try {
      final res = await _client.safeGet<List<dynamic>>(path);
      final data = res.data;
      if (data == null || data.isEmpty) return [];

      return data
        .map((json) => NewsModel.fromJson(json as Map<String, dynamic>, lastVisit: lastVisit))
        .toList();

    } catch (e) {
      debugPrint('🛑 fetchNews failed: $e');
      return [];
    }
  }

  /// Resolves the static SVG flag asset for an ISO country code (`"JP"`) or an
  /// ISO 3166-2 subdivision code (`"JP-13"`), normalising it to lowercase and
  /// mapping it onto the backend vector route:
  /// `/static/images/flags/<code>.svg`.
  ///
  /// Returns the fully-qualified URL so it can be handed straight to a network
  /// SVG widget. Mirrors the logo-URL resolution used for operator logos.
  String fetchFlag(String code) {
    final normalized = code.trim().toLowerCase();
    return _prefixLogo(_client.logoPath, 'images/flags/$normalized.svg');
  }

  /// Downloads the raw SVG markup for a flag [code] (country or ISO 3166-2
  /// subdivision), or `null` when the backend has no asset for it. Used by the
  /// flag cache so vectors are fetched once and reused/persisted, rather than
  /// re-requested over the network on every scroll.
  Future<String?> fetchFlagSvg(String code) async {
    Future<String?> fetch(String flagCode) async {
      final path = '/static/images/flags/${flagCode.trim().toLowerCase()}.svg';

      final res = await _client.safeGet<String>(
        path,
        responseType: ResponseType.plain,
      );

      final data = res.data;
      if (data == null || data.trim().isEmpty) return null;
      return data;
    }

    final normalizedCode = code.trim().toLowerCase();

    try {
      return await fetch(normalizedCode);
    } on DioException catch (e) {
      // If the subdivision flag doesn't exist, fall back to the country flag.
      if (e.response?.statusCode == 404 && normalizedCode.contains('-')) {
        final countryCode = normalizedCode.split('-').first;

        try {
          return await fetch(countryCode);
        } catch (_) {
          // Ignore and let the outer handler return null.
        }
      }

      debugPrint('🛑 fetchFlagSvg($code) failed: $e');
      return null;
    } catch (e) {
      debugPrint('🛑 fetchFlagSvg($code) failed: $e');
      return null;
    }
  }

  // ---- helpers ----
  String _prefixLogo(String base, String path) {
    if (path.isEmpty) return path;

    final p = path.toLowerCase();
    // Don't touch absolute or data URLs
    if (p.startsWith('http://') || p.startsWith('https://') || p.startsWith('data:')) {
      return path;
    }

    // Ensure base ends with a slash, then resolve relative path
    final baseWithSlash = base.endsWith('/') ? base : '$base/';
    final rel = path.startsWith('/') ? path.substring(1) : path;
    return Uri.parse(baseWithSlash).resolve(rel).toString();
  }

  int? _toInt(dynamic v) {
    if (v == null) return null;
    if (v is int) return v;
    if (v is double) return v.toInt();
    if (v is String) return int.tryParse(v);
    return null;
  }
}
