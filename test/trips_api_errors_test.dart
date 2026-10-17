import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:trainlog_app/services/api/session_expiry.dart';
import 'package:trainlog_app/services/api/trainlog_http_client.dart';
import 'package:trainlog_app/services/api/trips_api.dart';

import 'fake_trainlog_server.dart';

TripsApi _api(Handler? handler) {
  final client = TrainlogHttpClient()..dio.httpClientAdapter = FakeAdapter(handler);
  return TripsApi(client);
}

Matcher get _throwsUnreachable =>
    throwsA(isA<DioException>().having(isServerUnreachable, 'unreachable', isTrue));

Matcher get _throwsExpired =>
    throwsA(isA<DioException>().having((e) => e.error, 'error', isA<SessionExpiredException>()));

void main() {
  final since = DateTime.utc(2026, 1, 1);

  group('a failed sync is an error, never an empty result', () {
    test('incremental sync, server unreachable', () {
      expect(_api(null).fetchLastUpdatedTripsData('alice', since), _throwsUnreachable);
    });

    test('incremental sync, session expired', () {
      final api = _api((o) => redirectTo('/login?next=${o.path}'));
      expect(api.fetchLastUpdatedTripsData('alice', since), _throwsExpired);
    });

    test('full export, server unreachable', () {
      expect(_api(null).fetchAllTripsData('alice'), _throwsUnreachable);
    });

    test('full export, session expired', () {
      final api = _api((o) => redirectTo('/login?next=${o.path}'));
      expect(api.fetchAllTripsData('alice'), _throwsExpired);
    });
  });

  test('a missing new endpoint still falls back to the legacy one', () async {
    final api = _api((o) => o.path.contains('getUpdatedTrips')
        ? ResponseBody.fromString('', 404)
        : jsonBody('{"trips": [], "idList": [1, 2]}'));
    final result = await api.fetchLastUpdatedTripsData('alice', since);
    expect(result.serverTripIds, [1, 2]);
  });

  test('isServerUnreachable', () {
    final options = RequestOptions(path: '/');
    expect(isServerUnreachable(DioException.connectionError(requestOptions: options, reason: 'x')), isTrue);
    expect(isServerUnreachable(DioException.receiveTimeout(timeout: Duration.zero, requestOptions: options)), isTrue);
    expect(
      isServerUnreachable(DioException.badResponse(
        statusCode: 500,
        requestOptions: options,
        response: Response(requestOptions: options, statusCode: 500),
      )),
      isFalse,
    );
    expect(isServerUnreachable(Exception('x')), isFalse);
  });
}
