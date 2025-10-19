import 'dart:io';
import 'dart:ui';
import 'package:dropdown_search/dropdown_search.dart';
import 'package:flutter/material.dart';
import 'package:dio/dio.dart';
import 'package:cookie_jar/cookie_jar.dart';
import 'package:dio_cookie_manager/dio_cookie_manager.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as p;
import 'dart:convert';
import 'dart:math' as math;

import 'package:trainlog_app/data/models/trips.dart';

class TrainlogLoginResult {
  final bool success;
  final List<Cookie> cookies;
  final String? sessionCookieName;
  final Response? lastResponse;
  final String? failureReason;

  const TrainlogLoginResult({
    required this.success,
    required this.cookies,
    this.sessionCookieName,
    this.lastResponse,
    this.failureReason,
  });
}

class TrainlogService {
  static const String _baseUrl = 'https://trainlog.me';
  static const String _loginPath = '/login'; // we'll add ?raw=1 via query
  static const String _userAgent = 'TrainlogApp/1.0 (+Flutter)';
  static const String _logoPath = "$_baseUrl/static/";

  final Dio _dio;
  final CookieJar _cookieJar;

  TrainlogService._(this._dio, this._cookieJar);

  /// Non-persistent cookies (useful for tests)
  factory TrainlogService() {
    final dio = Dio(
      BaseOptions(
        baseUrl: _baseUrl,
        followRedirects: false,
        validateStatus: (s) => s != null && s >= 200 && s < 400, // general
        headers: {'User-Agent': _userAgent},
      ),
    );
    final jar = CookieJar();
    dio.interceptors.add(CookieManager(jar));
    return TrainlogService._(dio, jar);
  }

  /// Persistent cookies (survive app restarts)
  static Future<TrainlogService> persistent() async {
    final dir = await getApplicationSupportDirectory();
    final cookieDir = p.join(dir.path, 'cookies');
    final jar = PersistCookieJar(
      storage: FileStorage(cookieDir),
      persistSession: true, // keep session cookies without Expires
    );
    final dio = Dio(
      BaseOptions(
        baseUrl: _baseUrl,
        followRedirects: false,
        validateStatus: (s) => s != null && s >= 200 && s < 400,
        headers: {'User-Agent': _userAgent},
      ),
    );
    dio.interceptors.add(CookieManager(jar));
    return TrainlogService._(dio, jar);
  }

  Future<void> clearSession() async {
    _cookieJar.deleteAll();
  }

  /// Lightweight auth check without scraping:
  /// If you're authenticated, GET /login/ typically redirects away (302).
  Future<bool> checkAuthenticated() async {
    final res = await _dio.get(
      '$_loginPath/',
      options: Options(
        followRedirects: false,
        // accept 200/302 so Dio doesn't throw
        validateStatus: (s) => s == 200 || s == 302,
      ),
    );
    if (res.statusCode == 302) {
      final loc = res.headers['location']?.first ?? '';
      return !loc.contains('/login');
    }
    // 200 means login page is still shown → not authenticated
    return false;
  }

  /// New simple login using POST /login?raw=1
  Future<TrainlogLoginResult> login({
    required String username,
    required String password,
  }) async {
    // Send credentials as x-www-form-urlencoded, no hidden fields, no CSRF
    final resp = await _dio.post(
      _loginPath,
      queryParameters: const {'raw': '1'},
      data: {
        'username': username,
        'password': password,
      },
      options: Options(
        contentType: Headers.formUrlEncodedContentType,
        headers: {
          'Origin': _baseUrl,
          'Referer': '$_baseUrl$_loginPath',
        },
        // allow 40x so we can inspect failure
        validateStatus: (s) => s != null && s >= 200 && s < 500,
        followRedirects: false,
      ),
    );

    final success = resp.statusCode == 200;

    // Grab current cookies (session should now be set on success)
    final cookies = await _cookieJar.loadForRequest(Uri.parse('$_baseUrl/'));
    final sessionCookie = _findSessionCookie(cookies);

    return TrainlogLoginResult(
      success: success,
      cookies: cookies,
      sessionCookieName: sessionCookie?.name,
      lastResponse: resp,
      failureReason:
          success ? null : (resp.statusMessage ?? 'Invalid credentials'),
    );
  }

  // Expose authenticated requests
  Future<Response<T>> get<T>(String path, {Map<String, dynamic>? query}) =>
      _dio.get(path, queryParameters: query);

  Future<Response<T>> post<T>(String path, Map<String, dynamic> data) =>
      _dio.post(
        path,
        data: data,
        options: Options(contentType: Headers.formUrlEncodedContentType),
      );

  // (Optional) replace when you have a real endpoint
  Future<String?> fetchUsernameViaApi() async {
    // TODO: call Trainlog’s real endpoint to get the current user
    // Example:
    // final res = await _dio.get('/api/me', options: Options(headers: {'Accept': 'application/json'}));
    // if (res.statusCode == 200 && res.data is Map) return (res.data['username'] as String?)?.trim();
    return null;
  }

  Future<String> fetchAllTripsData(String username) async {
    final path = '/$username/export';
    try {
      final res = await _dio.get<String>(
        path,
        options: Options(
          followRedirects: true,     // follow harmless redirects
          maxRedirects: 5,
          responseType: ResponseType.plain, // get raw CSV as String
          headers: {'Accept': 'text/csv, text/plain;q=0.9, */*;q=0.8'},
          validateStatus: (s) => s != null && s >= 200 && s < 400,
        ),
      );

      // If we still ended at a redirect, check if it's a login redirect
      if (res.statusCode != null && res.statusCode! >= 300 && res.statusCode! < 400) {
        final loc = res.headers['location']?.first ?? '';
        if (loc.contains('/login')) {
          print('Not conected: redirected to login → not authenticated');
          return "";
        }
      }

      final csv = res.data ?? '';
      if (csv.isEmpty) {
        print('debugPrintFirstTrips: (empty response)');
        return "";
      }
      return csv;
    } catch (e) {
      print('debugPrintFirstTrips: error fetching $path: $e');
    }
    return '';
  }

  Future<Map<String, String>> fetchAllOperatorLogosUrl(String username) async {
    final path = '/$username/getManAndOps/train';

    final res = await _dio.get<Map<String, dynamic>>(
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

    final ops = data['operators'];
    if (ops is! Map) return {}; // not present or wrong shape

    final out = <String, String>{};
    ops.forEach((k, v) {
      final key = k?.toString().trim();
      final val = v?.toString().trim();
      if (key != null && key.isNotEmpty && val != null && val.isNotEmpty) {
        out[key] = _prefixLogo(_logoPath, val);
      }
    });
    return out;
  }

  Future<Map<String, dynamic>> fetchStatsByVehicle(String username, VehicleType type, int? year) async {
    final path = year == null
        ? '/$username/getStats/${type.toShortString()}'
        : '/$username/getStats/$year/${type.toShortString()}';

    final res = await _dio.get<Map<String, dynamic>>(
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

    return data;
  }


  // ---- helpers ----
  Cookie? _findSessionCookie(List<Cookie> cookies) {
    for (final c in cookies) {
      final n = c.name.toLowerCase();
      if (n.contains('session') || n.contains('auth') || n.contains('jwt')) {
        return c;
      }
    }
    return null;
  }

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

}
