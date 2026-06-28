import 'dart:async';
import 'dart:io';

import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:trainlog_app/utils/cached_data_utils.dart';

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

  bool _warmStarted = false;

  /// One-shot background warm-up, safe to call repeatedly: resolves the set of
  /// area codes via [codesLoader] (e.g. the rail-coverage leaderboard) and
  /// preloads every flag, so the Ranking page opens with flags already cached.
  /// Only the first call does any work.
  Future<void> warmUp(Future<List<String>> Function() codesLoader) async {
    if (_warmStarted) return;
    _warmStarted = true;
    try {
      final codes = await codesLoader();
      await preload(codes);
    } catch (_) {
      // Best-effort; flags still load lazily when the page is opened.
      _warmStarted = false;
    }
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

  // ── Force refresh ──────────────────────────────────────────────────────────

  /// Forces a single flag [code] to be re-downloaded from the backend, bypassing
  /// the in-memory and on-disk caches, and overwrites both with the fresh copy.
  ///
  /// If the backend is unavailable the existing cached copy is kept (a transient
  /// failure never wipes a flag). Returns the refreshed SVG, or the previous one
  /// on failure.
  Future<String?> forceReload(String code) {
    final key = _key(code);
    // Share with a concurrent force-refresh of the same code, but always go to
    // the network (unlike [load], which may resolve from disk).
    final pending = _pending[key];
    if (pending != null) return pending;

    final future = _refetch(key);
    _pending[key] = future;
    future.whenComplete(() => _pending.remove(key));
    return future;
  }

  /// Forces every known flag (everything currently in memory or persisted on
  /// disk) to be re-downloaded from the backend and overwritten, with bounded
  /// concurrency. Flags that fail to re-download keep their existing copy.
  Future<void> forceReloadAll({int concurrency = 4}) async {
    final codes = (await _knownCodes()).toList();
    if (codes.isEmpty) return;

    var index = 0;
    Future<void> worker() async {
      while (index < codes.length) {
        await forceReload(codes[index++]);
      }
    }

    final workers = concurrency.clamp(1, 8);
    await Future.wait([for (var i = 0; i < workers; i++) worker()]);
  }

  /// Re-downloads [key] from the backend and overwrites the caches. Keeps the
  /// existing copy when the fetch yields nothing.
  Future<String?> _refetch(String key) async {
    final raw = await _fetch(key);
    if (raw == null) return _memory[key];

    final clean = sanitizeSvg(raw);
    _memory[key] = clean;
    await _persist(key, clean);
    return clean;
  }

  /// The set of flag codes known to the cache: the union of in-memory entries
  /// and persisted `<code>.svg` files.
  Future<Set<String>> _knownCodes() async {
    final codes = <String>{..._memory.keys};
    try {
      final dir = await _ensureDir();
      if (await dir.exists()) {
        await for (final entity in dir.list()) {
          if (entity is File && entity.path.toLowerCase().endsWith('.svg')) {
            codes.add(p.basenameWithoutExtension(entity.path));
          }
        }
      }
    } catch (_) {
      // Disk unavailable — fall back to whatever is in memory.
    }
    return codes;
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
      final dir = Directory(AppCacheFilePath.flagFolder);
      if (!await dir.exists()) await dir.create(recursive: true);
      return dir;
    }();
  }

  static void clearCache() {
    final dir = Directory(AppCacheFilePath.flagFolder);
    if (!dir.existsSync()) return;

    dir.delete(recursive: true);
  }
}

/// Strips editor-only elements (Inkscape `<script>`, `<metadata>` and
/// `<sodipodi:namedview>` blocks) that add noise without affecting the visual
/// flag. Kept so cached SVGs stay lean across renderers.
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

/// Computes the natural width/height aspect ratio of an SVG so flags can be laid
/// out at their real proportions (a wide national flag vs. a near-square coat of
/// arms) instead of being forced into a fixed rectangle.
///
/// Prefers the `viewBox`, falling back to the root `width`/`height` attributes,
/// then to [fallback]. The result is clamped to a sane range.
double svgAspectRatio(String svg, {double fallback = 1.5}) {
  final viewBox = RegExp(
    r'viewBox\s*=\s*"([\d.eE+\-\s,]+)"',
    caseSensitive: false,
  ).firstMatch(svg);
  if (viewBox != null) {
    final parts = viewBox.group(1)!.trim().split(RegExp(r'[\s,]+'));
    if (parts.length == 4) {
      final w = double.tryParse(parts[2]);
      final h = double.tryParse(parts[3]);
      if (w != null && h != null && w > 0 && h > 0) {
        return (w / h).clamp(0.25, 4.0).toDouble();
      }
    }
  }

  final w = _svgRootDimension(svg, 'width');
  final h = _svgRootDimension(svg, 'height');
  if (w != null && h != null && h > 0) {
    return (w / h).clamp(0.25, 4.0).toDouble();
  }

  return fallback;
}

/// Reads a numeric root `<svg>` dimension attribute ([name]), ignoring any unit
/// suffix (`px`, `pt`, …). Returns null when absent or percentage-based.
double? _svgRootDimension(String svg, String name) {
  final match = RegExp(
    '<svg[^>]*?\\b$name\\s*=\\s*"([\\d.eE+\\-]+)',
    caseSensitive: false,
  ).firstMatch(svg);
  if (match == null) return null;
  return double.tryParse(match.group(1)!);
}
