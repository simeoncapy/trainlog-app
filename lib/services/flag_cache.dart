import 'dart:async';
import 'dart:io';

import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

/// In-memory + on-disk cache for flag SVGs.
///
/// Flags are fetched once (through [_fetch]), sanitised to drop editor cruft
/// that the SVG renderer warns about, then kept in memory and persisted to disk
/// so they survive restarts and never re-hit the network while scrolling.
///
/// [preload] warms the cache in the background for a batch of codes (e.g. every
/// country/subdivision in a leaderboard) so rows render instantly from memory.
class FlagCache {
  /// Downloads the raw SVG markup for a code, or null when unavailable.
  final Future<String?> Function(String code) _fetch;

  FlagCache(this._fetch);

  final Map<String, String> _memory = {};
  final Map<String, Future<String?>> _pending = {};
  Future<Directory>? _dirFuture;

  String _key(String code) => code.trim().toLowerCase();

  /// The cached, sanitised SVG for [code] if already in memory, else null.
  String? cached(String code) => _memory[_key(code)];

  /// Loads [code] from memory, then disk, then the network — caching the result
  /// at every level. Concurrent calls for the same code share one fetch.
  Future<String?> load(String code) {
    final key = _key(code);
    final mem = _memory[key];
    if (mem != null) return Future.value(mem);

    final pending = _pending[key];
    if (pending != null) return pending;

    final future = _loadUncached(key);
    _pending[key] = future;
    future.whenComplete(() => _pending.remove(key));
    return future;
  }

  /// Warms the cache for [codes] in the background with bounded concurrency.
  Future<void> preload(Iterable<String> codes, {int concurrency = 4}) async {
    final queue = <String>{
      for (final c in codes)
        if (!_memory.containsKey(_key(c))) _key(c),
    }.toList();
    if (queue.isEmpty) return;

    var index = 0;
    Future<void> worker() async {
      while (index < queue.length) {
        final code = queue[index++];
        await load(code);
      }
    }

    final workers = concurrency.clamp(1, 8);
    await Future.wait([for (var i = 0; i < workers; i++) worker()]);
  }

  Future<String?> _loadUncached(String key) async {
    // Disk first — survives restarts without a network round-trip.
    try {
      final dir = await _ensureDir();
      final file = File(p.join(dir.path, '$key.svg'));
      if (await file.exists()) {
        final disk = await file.readAsString();
        if (disk.trim().isNotEmpty) {
          _memory[key] = disk;
          return disk;
        }
      }
    } catch (_) {
      // Disk unavailable — fall through to the network.
    }

    final raw = await _fetch(key);
    if (raw == null) return null;

    final clean = sanitizeSvg(raw);
    _memory[key] = clean;
    unawaited(_persist(key, clean));
    return clean;
  }

  Future<void> _persist(String key, String svg) async {
    try {
      final dir = await _ensureDir();
      await File(p.join(dir.path, '$key.svg')).writeAsString(svg);
    } catch (_) {
      // Persistence is best-effort; the in-memory copy still serves this run.
    }
  }

  Future<Directory> _ensureDir() {
    return _dirFuture ??= () async {
      final base = await getApplicationSupportDirectory();
      final dir = Directory(p.join(base.path, 'flag_cache'));
      if (!await dir.exists()) await dir.create(recursive: true);
      return dir;
    }();
  }
}

/// Strips editor-only elements that the SVG renderer cannot handle and warns
/// about on every parse (Inkscape `<script>`, `<metadata>` and
/// `<sodipodi:namedview>` blocks). The visual flag is unaffected.
String sanitizeSvg(String svg) {
  var s = svg;
  // Paired blocks first, then any self-closing variants the renderer reports
  // (e.g. "<script/>", "<metadata/>", "<sodipodi:namedview/>").
  for (final tag in const ['script', 'metadata', 'sodipodi:namedview']) {
    s = s.replaceAll(
      RegExp('<$tag[\\s\\S]*?</$tag>', caseSensitive: false),
      '',
    );
    s = s.replaceAll(
      RegExp('<$tag\\b[^>]*/>', caseSensitive: false),
      '',
    );
  }
  return s;
}
