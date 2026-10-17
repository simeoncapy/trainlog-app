import 'package:dio/dio.dart';
import 'package:trainlog_app/services/api/trainlog_http_client.dart';

typedef Handler = ResponseBody Function(RequestOptions options);

/// Serves each request with [handler]; a null [handler] simulates an
/// unreachable server.
class FakeAdapter implements HttpClientAdapter {
  FakeAdapter(this.handler);

  Handler? handler;

  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<List<int>>? requestStream,
    Future<void>? cancelFuture,
  ) async {
    final h = handler;
    if (h == null) {
      throw DioException.connectionTimeout(
        timeout: TrainlogHttpClient.connectTimeout,
        requestOptions: options,
      );
    }
    return h(options);
  }

  @override
  void close({bool force = false}) {}
}

ResponseBody redirectTo(String location) =>
    ResponseBody.fromString('', 302, headers: {'location': [location]});

ResponseBody jsonBody(String body) => ResponseBody.fromString(body, 200, headers: {
      Headers.contentTypeHeader: [Headers.jsonContentType],
    });

/// A Trainlog server where the session is valid while [signedIn] is true.
Handler fakeServer({required bool Function() signedIn, String password = 'secret'}) {
  return (options) {
    final path = options.path;
    if (path == '/login/') {
      return signedIn() ? redirectTo('/u/alice') : ResponseBody.fromString('<form>', 200);
    }
    if (path == '/login' && options.method == 'POST') {
      final data = options.data as Map;
      return ResponseBody.fromString('', data['password'] == password ? 200 : 401);
    }
    if (!signedIn()) return redirectTo('/login?next=$path');
    return jsonBody('{"operators": {}}');
  };
}
