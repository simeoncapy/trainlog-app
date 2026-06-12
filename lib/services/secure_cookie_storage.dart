import 'dart:io';

import 'package:cookie_jar/cookie_jar.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:path/path.dart' as p;

/// Cookie storage backed by the platform keychain/keystore
/// (flutter_secure_storage), so session cookies are encrypted at rest.
/// cookie_jar's [FileStorage] writes them in plaintext.
class SecureCookieStorage implements Storage {
  SecureCookieStorage({FlutterSecureStorage? storage})
      : _storage = storage ??
            const FlutterSecureStorage(
              aOptions: AndroidOptions(encryptedSharedPreferences: true),
            );

  /// Namespaces cookie entries so they cannot collide with any other
  /// values the app may keep in secure storage later.
  static const _keyPrefix = 'cookies.';

  final FlutterSecureStorage _storage;

  String _key(String key) => '$_keyPrefix$key';

  @override
  Future<void> init(bool persistSession, bool ignoreExpires) async {}

  @override
  Future<String?> read(String key) => _storage.read(key: _key(key));

  @override
  Future<void> write(String key, String value) =>
      _storage.write(key: _key(key), value: value);

  @override
  Future<void> delete(String key) => _storage.delete(key: _key(key));

  @override
  Future<void> deleteAll(List<String> keys) async {
    for (final key in keys) {
      await _storage.delete(key: _key(key));
    }
  }

  /// Returns true when the platform keychain/keystore actually works here.
  /// It can be missing at runtime (e.g. Linux without a Secret Service
  /// keyring), in which case the caller should fall back to file storage.
  static Future<bool> isAvailable() async {
    const probeKey = '${_keyPrefix}__probe__';
    try {
      const storage = FlutterSecureStorage(
        aOptions: AndroidOptions(encryptedSharedPreferences: true),
      );
      await storage.write(key: probeKey, value: 'ok');
      final ok = await storage.read(key: probeKey) == 'ok';
      await storage.delete(key: probeKey);
      return ok;
    } catch (e) {
      debugPrint('⚠️ Secure storage unavailable: $e');
      return false;
    }
  }

  /// One-time migration from the legacy plaintext [FileStorage] directory:
  /// imports every cookie file, then deletes the directory so no plaintext
  /// copy remains. Existing sessions survive the switch to encrypted storage.
  ///
  /// FileStorage nests the files in a config subdirectory of the path it is
  /// given (`<dir>/ie0_ps1/` for persistSession: true, ignoreExpires: false),
  /// so the walk is recursive. Within that leaf directory the filename is the
  /// storage key verbatim (cookie_jar 4.x).
  Future<void> migrateFromFileStorage(String legacyDir) async {
    final dir = Directory(legacyDir);
    if (!await dir.exists()) return;

    try {
      var migrated = 0;
      await for (final entity in dir.list(recursive: true)) {
        if (entity is! File) continue;
        final key = p.basename(entity.path);
        final value = await entity.readAsString();
        await write(key, value);
        migrated++;
      }
      await dir.delete(recursive: true);
      debugPrint('🔒 Migrated $migrated legacy cookie file(s) to secure storage');
    } catch (e) {
      debugPrint('⚠️ Cookie migration to secure storage failed: $e');
    }
  }
}
