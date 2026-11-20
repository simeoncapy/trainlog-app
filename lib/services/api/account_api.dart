import 'dart:ffi';

import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:trainlog_app/services/api/session_expiry.dart';
import 'package:trainlog_app/services/api/trainlog_http_client.dart';

/// Outcome of [AccountApi.deleteAccount].
enum DeleteAccountResult {
  /// The account and all its data are gone on the server.
  deleted,

  /// The password did not match: nothing was deleted.
  wrongPassword,

  /// The typed username did not match the account: nothing was deleted.
  confirmMismatch,

  /// The server could not be reached, or answered something unexpected.
  /// Nothing can be assumed deleted.
  failed,
}

/// Account settings domain: reading/writing the user's app settings and the
/// list of available currencies.
class AccountApi {
  final TrainlogHttpClient _client;

  AccountApi(this._client);

  Future<Map<String, String>> fetchAccountSettings(String username) async {
    final path = '/u/$username/settings_app';

    try {
      final res = await _client.safeGet<Map<String, dynamic>>(path);
      final data = res.data;
      if (data == null) return {};

      final out = <String, String>{};
      data.forEach((k, v) {
        final key = k.toString().trim();
        final val = v?.toString().trim();
        if (key.isNotEmpty && val != null && val.isNotEmpty) {
          out[key] = val;
        }
      });
      return out;
    } catch (e) {
      debugPrint('🛑 fetchAccountSettings failed: $e');
      return {};
    }
  }

  Future<void> updateAccountSettings(String username, Map<String, dynamic> settings) async {
    final path = '/u/$username/settings_app';

    debugPrint("Updating account settings for $username: $settings");

    final r = await _client.safePost(
      path,
      data: settings,
      contentType: Headers.jsonContentType,
      headers: {'Accept': 'application/json'},
      followRedirects: false,
      validateStatus: (s) => s != null && s < 500,
    );
    debugPrint(r.statusMessage);
  }

  /// Permanently deletes the account on the server, with every piece of data
  /// it owns. The server only goes ahead when [password] is the account's
  /// password and [confirmUsername] is the username typed back exactly.
  ///
  /// Uses the `?raw=1` JSON mode of `/u/<username>/delete_account`. The
  /// session check is skipped: a 403 for a wrong password is an answer, not
  /// an expired session.
  Future<DeleteAccountResult> deleteAccount(
    String username, {
    required String password,
    required String confirmUsername,
  }) async {
    final path = '/u/$username/delete_account';

    try {
      final res = await _client.dio.post(
        path,
        queryParameters: const {'raw': '1'},
        data: {
          'delete_confirm_secret': password,
          'delete_confirm_phrase': confirmUsername,
        },
        options: Options(
          contentType: Headers.formUrlEncodedContentType,
          headers: {'Accept': 'application/json'},
          followRedirects: false,
          responseType: ResponseType.json,
          validateStatus: (s) => s != null && s < 500,
          extra: const {skipSessionCheckExtraKey: true},
        ),
      );

      final data = res.data;
      if (res.statusCode == 200 && data is Map && data['deleted'] == true) {
        return DeleteAccountResult.deleted;
      }
      final error = data is Map ? data['error'] : null;
      switch (error) {
        case 'wrong_password':
          return DeleteAccountResult.wrongPassword;
        case 'confirm_mismatch':
          return DeleteAccountResult.confirmMismatch;
      }
      debugPrint('🛑 deleteAccount unexpected answer: ${res.statusCode} $data');
      return DeleteAccountResult.failed;
    } catch (e) {
      debugPrint('🛑 deleteAccount failed: $e');
      return DeleteAccountResult.failed;
    }
  }

  Future<List<String>> fetchAvailableCurrencies(String username) async {
    final path = '/u/$username/settings_app';

    try {
      final res = await _client.safeGet<Map<String, dynamic>>(path);
      final data = res.data;
      if (data == null) return const [];

      final raw = data['currencyOptions'];
      if (raw is! List) return const [];

      final out = <String>[];
      final seen = <String>{};

      for (final item in raw) {
        if (item is Map) {
          final currency = item['currency']?.toString().trim();
          if (currency != null && currency.isNotEmpty && seen.add(currency)) {
            out.add(currency);
          }
        }
      }

      return out;
    } catch (e) {
      debugPrint('🛑 fetchAvailableCurrencies failed: $e');
      return const [];
    }
  }

  Future<double?> convertCurrency(double amount, String fromCurrency, DateTime date, String toCurrency) async {
    Map<String, dynamic> querry = {
      "amount": amount,
      "base_currency": fromCurrency,
      "target_currency": toCurrency,
      "date": date.toIso8601String().split('T').first,
    };

    final path = '/convert_currency';
    final r = await _client.safePost(
      path,
      data: querry,
      contentType: Headers.jsonContentType,
      headers: {'Accept': 'application/json'},
      followRedirects: false,
      validateStatus: (s) => s != null && s < 500,
    );

    final data = r.data;
    if (data == null) return null;

    final raw = data['converted_amount'];
    return raw is num ? raw.toDouble() : double.tryParse(raw.toString());
  }
}
