import 'package:dio/dio.dart';
import 'package:cookie_jar/cookie_jar.dart';
import 'package:dio_cookie_manager/dio_cookie_manager.dart';
import 'package:flutter/foundation.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as p;
import 'package:trainlog_app/services/secure_cookie_storage.dart';

/// Shared transport layer for all Trainlog API domains.
///
/// Owns the [Dio] instance, the cookie jar (persistent or in-memory) and the
/// low-level request helpers (`get` / `post` passthroughs, plus the retrying
/// `safeGet` / `safePost`). Each API domain (`AuthApi`, `TripsApi`, …) takes
/// one of these in its constructor and shares the same authenticated session.
class TrainlogHttpClient {
  static const String urlLocalhost = 'http://localhost:5000';
  static const String urlLegacy = 'https://trainlog.me';
  static const String urlDev = 'https://dev.trainlog.me';
  static const String _userAgent = 'TrainlogApp/1.0 (+Flutter)';

  final Dio dio;
  final CookieJar cookieJar;

  TrainlogHttpClient._(this.dio, this.cookieJar);

  String get baseUrl => dio.options.baseUrl;
  set baseUrl(String url) {
    dio.options.baseUrl = url;
  }

  String get logoPath => '$baseUrl/static/';

  /// Non-persistent cookies (useful for tests)
  factory TrainlogHttpClient({String baseUrl = TrainlogHttpClient.urlLegacy}) {
    final dio = Dio(
      BaseOptions(
        baseUrl: baseUrl,
        followRedirects: false,
        validateStatus: (s) => s != null && s >= 200 && s < 400, // general
        headers: {'User-Agent': _userAgent},
      ),
    );
    final jar = CookieJar();
    dio.interceptors.add(CookieManager(jar));
    return TrainlogHttpClient._(dio, jar);
  }

  /// Persistent cookies (survive app restarts), encrypted at rest via the
  /// platform keychain/keystore when available.
  static Future<TrainlogHttpClient> persistent({String baseUrl = TrainlogHttpClient.urlLegacy}) async {
    final dir = await getApplicationSupportDirectory();
    final cookieDir = p.join(dir.path, 'cookies');

    Storage cookieStorage;
    if (await SecureCookieStorage.isAvailable()) {
      final secure = SecureCookieStorage();
      // Imports any plaintext cookies from previous versions, then removes
      // them, so existing sessions survive the switch.
      await secure.migrateFromFileStorage(cookieDir);
      cookieStorage = secure;
    } else {
      // No keychain on this platform (e.g. Linux without a Secret Service
      // keyring): keep the legacy plaintext file storage rather than
      // breaking login persistence.
      cookieStorage = FileStorage(cookieDir);
    }

    final jar = PersistCookieJar(
      storage: cookieStorage,
      persistSession: true, // keep session cookies without Expires
    );
    final dio = Dio(
      BaseOptions(
        baseUrl: baseUrl,
        followRedirects: false,
        validateStatus: (s) => s != null && s >= 200 && s < 400,
        headers: {'User-Agent': _userAgent},
      ),
    );
    dio.interceptors.add(CookieManager(jar));
    return TrainlogHttpClient._(dio, jar);
  }

  // Expose authenticated requests
  Future<Response<T>> get<T>(String path, {Map<String, dynamic>? query}) =>
      dio.get(path, queryParameters: query);

  Future<Response<T>> post<T>(String path, Map<String, dynamic> data) =>
      dio.post(
        path,
        data: data,
        options: Options(contentType: Headers.formUrlEncodedContentType),
      );

  Future<Response<T>> safeGet<T>(
    String path, {
    Map<String, dynamic>? query,
    ResponseType responseType = ResponseType.json,
    bool followRedirects = true,
    int maxRedirects = 5,
    Map<String, dynamic>? headers,
    ValidateStatus? validate,
  }) {
    return safeGetWithRetry(() {
      return dio.get<T>(
        path,
        queryParameters: query,
        options: Options(
          followRedirects: followRedirects,
          maxRedirects: maxRedirects,
          responseType: responseType,
          headers: headers,
          validateStatus: validate ??
              (s) => s != null && s >= 200 && s < 400,
        ),
      );
    });
  }

  Future<Response<T>> safeGetWithRetry<T>(
    Future<Response<T>> Function() request,
  ) async {
    try {
      return await request();
    } on DioException catch (e) {
      if (e.response?.statusCode == 500) {
        debugPrint("Error - retry $e");
        await Future.delayed(const Duration(milliseconds: 300));
        return await request(); // retry once
      }
      rethrow;
    }
  }

  Future<Response<T>> safePost<T>(
    String path, {
    Map<String, dynamic>? query,
    Object? data,
    String contentType = Headers.formUrlEncodedContentType,
    Map<String, dynamic>? headers,
    bool followRedirects = false,
    int maxRedirects = 5,
    ValidateStatus? validateStatus,
  }) {
    return dio.post<T>(
      path,
      queryParameters: query,
      data: data,
      options: Options(
        contentType: contentType,
        headers: headers,
        followRedirects: followRedirects,
        maxRedirects: maxRedirects,
        validateStatus: validateStatus ?? (s) => s != null && s >= 200 && s < 500,
      ),
    );
  }
}
