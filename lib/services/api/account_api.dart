import 'dart:ffi';

import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:trainlog_app/services/api/trainlog_http_client.dart';

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
