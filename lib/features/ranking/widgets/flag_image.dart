import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:jovial_svg/jovial_svg.dart';
import 'package:provider/provider.dart';

import 'package:trainlog_app/services/flag_cache.dart';
import 'package:trainlog_app/utils/text_utils.dart';

/// Parsed-image cache, keyed by lowercased area code. Each unique flag is parsed
/// once per app session and reused across every row that shows it.
final Map<String, ScalableImage> _siCache = {};
final Map<String, double> _ratioCache = {};

/// Codes that jovial_svg cannot parse (e.g. the Georgian flag's nested
/// clip-path + use construction triggers an internal assertion). These render
/// through flutter_svg instead, so we only attempt the jovial parse once.
final Set<String> _jovialFailed = {};

/// Rasterised flags, keyed by `<code>@<pixelHeight>`. Painting a pre-rendered
/// bitmap is a cheap, constant-cost blit regardless of how complex the source
/// SVG is (some flags — e.g. US state flags with detailed seals — are very
/// expensive to paint as vectors, and we draw each flag twice for its shadow).
final Map<String, ui.Image> _rasterCache = {};
final Map<String, Future<void>> _rasterPending = {};

/// Renders an area flag from the [FlagCache] (memory/disk, backed by the backend
/// static SVG vector service).
///
/// For performance the parsed flag is rasterised to a bitmap once (off the
/// build/scroll path, via [precache]/[rasterize]) and that bitmap is painted
/// thereafter. Until the bitmap is ready it falls back to rendering the vector
/// directly: [jovial_svg] first (renders complex flags faithfully), then
/// flutter_svg for the few SVGs jovial can't handle, then the unicode flag emoji
/// so a row never renders blank.
///
/// [code] is an ISO country code (`"JP"`) or an ISO 3166-2 subdivision code
/// (`"JP-13"`). The flag is laid out at its natural aspect ratio (so wide flags
/// and near-square coats of arms both render undistorted), bounded by [size] in
/// height.
class FlagImage extends StatefulWidget {
  final String code;

  /// Bounding height for the rendered flag; the width follows the flag's ratio.
  final double size;

  const FlagImage({super.key, required this.code, this.size = 30});

  /// Fraction of [size] used as the rendered flag height (the rest leaves a
  /// little breathing room). Exposed so callers can reserve a consistent flag
  /// column without duplicating the constant.
  static const double heightFactor = 0.92;

  /// The rendered flag height for a given [size].
  static double heightForSize(double size) => size * heightFactor;

  /// Pre-parses, and (when [rasterHeight] is given) pre-rasterises, a flag's SVG
  /// off the build/scroll path. Doing this during warm-up keeps scrolling and
  /// page transitions smooth, since the row then only blits a bitmap. Cheap and
  /// idempotent.
  static Future<void> precache(
    String code,
    String svg, {
    double? rasterHeight,
    double devicePixelRatio = 1,
  }) async {
    final key = code.trim().toLowerCase();
    final si = ensureParsed(key, svg);
    if (si != null && rasterHeight != null) {
      await rasterize(code, rasterHeight, devicePixelRatio);
    }
  }

  /// Parses [svg] into the shared caches (keyed by the already-normalised [key])
  /// if not already done. Returns the parsed image, or null when jovial can't
  /// handle it (the caller renders via flutter_svg instead).
  static ScalableImage? ensureParsed(String key, String svg) {
    _ratioCache[key] ??= svgAspectRatio(svg);

    final cached = _siCache[key];
    if (cached != null) return cached;
    if (_jovialFailed.contains(key)) return null;

    try {
      return _siCache[key] = ScalableImage.fromSvgString(svg);
    } catch (e) {
      _jovialFailed.add(key);
      debugPrint('🏳️ FlagImage: jovial_svg failed to parse "$key" '
          '($e) — falling back to flutter_svg');
      return null;
    }
  }

  static String _rasterKey(String key, int pixelHeight) => '$key@$pixelHeight';

  /// The cached bitmap for [code] at the given size, or null if not rasterised
  /// yet (or not jovial-parseable).
  static ui.Image? rasterFor(String code, double logicalHeight, double dpr) {
    final pixelHeight = (logicalHeight * dpr).round();
    return _rasterCache[_rasterKey(code.trim().toLowerCase(), pixelHeight)];
  }

  /// Rasterises [code]'s parsed flag to a cached bitmap at the given size.
  /// Idempotent; concurrent calls share one rasterisation. Resolves once the
  /// bitmap is cached (or immediately when it can't be rasterised).
  static Future<void> rasterize(String code, double logicalHeight, double dpr) {
    final key = code.trim().toLowerCase();
    final si = _siCache[key];
    if (si == null) return Future.value();

    final pixelHeight = (logicalHeight * dpr).round();
    final pixelWidth =
        (logicalHeight * (_ratioCache[key] ?? 1.5) * dpr).round();
    if (pixelHeight <= 0 || pixelWidth <= 0) return Future.value();

    final rk = _rasterKey(key, pixelHeight);
    if (_rasterCache.containsKey(rk)) return Future.value();
    final pending = _rasterPending[rk];
    if (pending != null) return pending;

    final future = _rasterizeImage(si, pixelWidth, pixelHeight).then((img) {
      if (img != null) _rasterCache[rk] = img;
    });
    _rasterPending[rk] = future;
    future.whenComplete(() => _rasterPending.remove(rk));
    return future;
  }

  static Future<ui.Image?> _rasterizeImage(
    ScalableImage si,
    int width,
    int height,
  ) async {
    try {
      await si.prepareImages(); // decode any embedded raster (no-op for vectors)
      final vp = si.viewport;
      if (vp.width <= 0 || vp.height <= 0) return null;

      final recorder = ui.PictureRecorder();
      final canvas = ui.Canvas(recorder);
      canvas.scale(width / vp.width, height / vp.height);
      canvas.translate(-vp.left, -vp.top);
      si.paint(canvas);
      final picture = recorder.endRecording();
      final image = await picture.toImage(width, height);
      picture.dispose();
      return image;
    } catch (e) {
      debugPrint('🏳️ FlagImage: rasterize failed ($e)');
      return null;
    }
  }

  @override
  State<FlagImage> createState() => _FlagImageState();
}

class _FlagImageState extends State<FlagImage> {
  ScalableImage? _si;

  /// Raw SVG used by the flutter_svg fallback when jovial can't parse it.
  String? _fallbackSvg;

  /// Pre-rendered bitmap; once available it replaces the vector renderers.
  ui.Image? _raster;

  double _ratio = 1.5;
  double _dpr = 1;
  bool _depsReady = false;

  @override
  void initState() {
    super.initState();
    _resolve();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _dpr = MediaQuery.devicePixelRatioOf(context);
    _depsReady = true;
    _refreshRaster();
  }

  @override
  void didUpdateWidget(FlagImage oldWidget) {
    super.didUpdateWidget(oldWidget);
    // ListView recycles row Elements: when the code changes, reload so a scrolled
    // row never shows the previous area's flag.
    if (oldWidget.code != widget.code) {
      _si = null;
      _fallbackSvg = null;
      _raster = null;
      _resolve();
    }
  }

  void _resolve() {
    final cache = context.read<FlagCache>();
    final cachedSvg = cache.cached(widget.code);
    if (cachedSvg != null) {
      _apply(widget.code, cachedSvg);
      return;
    }

    final code = widget.code;
    cache.load(code).then((svg) {
      if (!mounted || code != widget.code) return;
      setState(() => _apply(code, svg));
    });
  }

  void _apply(String code, String? svg) {
    _si = null;
    _fallbackSvg = null;
    _raster = null;

    if (svg == null) {
      debugPrint('🏳️ FlagImage: no SVG available for "$code" (emoji fallback)');
      return;
    }

    final key = code.toLowerCase();
    final si = FlagImage.ensureParsed(key, svg);
    _ratio = _ratioCache[key] ?? 1.5;
    if (si != null) {
      _si = si;
      _refreshRaster();
    } else {
      _fallbackSvg = svg; // jovial can't handle it — render via flutter_svg.
    }
  }

  /// Uses the cached bitmap if present, otherwise rasterises it in the
  /// background and swaps it in when ready. Only runs once dependencies (the
  /// device pixel ratio) are known, so the bitmap is rendered at the right size.
  void _refreshRaster() {
    if (!_depsReady || _si == null) return;
    final height = FlagImage.heightForSize(widget.size);

    final existing = FlagImage.rasterFor(widget.code, height, _dpr);
    if (existing != null) {
      _raster = existing;
      return;
    }

    final code = widget.code;
    FlagImage.rasterize(code, height, _dpr).then((_) {
      if (!mounted || code != widget.code) return;
      final img = FlagImage.rasterFor(code, height, _dpr);
      if (img != null) setState(() => _raster = img);
    });
  }

  @override
  Widget build(BuildContext context) {
    // Bounding height; flags are a touch taller than their nominal width-ish size
    // so coats of arms and detailed flags stay legible.
    final height = FlagImage.heightForSize(widget.size);

    final raster = _raster;
    final si = _si;
    final fallbackSvg = _fallbackSvg;

    if (raster == null && si == null && fallbackSvg == null) {
      // Emoji fallback uses a conventional flag ratio while loading / when no
      // renderer can handle the SVG.
      return SizedBox(
        height: height,
        width: height * 1.4,
        child: Center(
          child: Text(
            countryCodeToEmoji(widget.code.split('-').first),
            style: TextStyle(
              fontSize: height * 0.95,
              shadows: const [
                Shadow(color: Colors.black38, blurRadius: 1.5, offset: Offset(0, 1)),
              ],
            ),
          ),
        ),
      );
    }

    // A fresh flag widget each call (a Widget can't be shared between the shadow
    // and foreground layers in the same Stack). Prefers the cached bitmap, which
    // is far cheaper to paint than the source vector.
    SizedBox flag() {
      final Widget content = raster != null
          ? RawImage(image: raster, fit: BoxFit.contain)
          : si != null
              ? ScalableImageWidget(si: si, fit: BoxFit.contain)
              : SvgPicture.string(fallbackSvg!, fit: BoxFit.contain);
      return SizedBox(
        height: height,
        width: height * _ratio,
        child: content,
      );
    }

    // Drop shadow that follows the painted silhouette rather than the bounding
    // rectangle: the flag is recoloured to a black silhouette, blurred, offset
    // and faded, then the real flag is drawn on top. A coat of arms therefore
    // casts a shield-shaped shadow.
    return Stack(
      clipBehavior: Clip.none,
      children: [
        Opacity(
          opacity: 0.45,
          child: Transform.translate(
            offset: const Offset(0, 1.2),
            child: ImageFiltered(
              imageFilter: ui.ImageFilter.blur(sigmaX: 1.4, sigmaY: 1.4),
              // srcATop with opaque black recolours the painted pixels to a
              // solid silhouette while preserving their alpha shape.
              child: ColorFiltered(
                colorFilter: const ColorFilter.mode(
                  Colors.black,
                  BlendMode.srcATop,
                ),
                child: flag(),
              ),
            ),
          ),
        ),
        flag(),
      ],
    );
  }
}
