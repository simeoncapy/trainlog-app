import 'dart:ui' show ImageFilter;

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

/// Renders an area flag from the [FlagCache] (memory/disk, backed by the backend
/// static SVG vector service).
///
/// Rendering uses a fallback chain: [jovial_svg] first (renders complex flags —
/// CSS, gradients, fill-rule — faithfully where flutter_svg does not), then
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

  @override
  State<FlagImage> createState() => _FlagImageState();
}

class _FlagImageState extends State<FlagImage> {
  ScalableImage? _si;

  /// Raw SVG used by the flutter_svg fallback when jovial can't parse it.
  String? _fallbackSvg;
  double _ratio = 1.5;

  @override
  void initState() {
    super.initState();
    _resolve();
  }

  @override
  void didUpdateWidget(FlagImage oldWidget) {
    super.didUpdateWidget(oldWidget);
    // ListView recycles row Elements: when the code changes, reload so a scrolled
    // row never shows the previous area's flag.
    if (oldWidget.code != widget.code) {
      _si = null;
      _fallbackSvg = null;
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

    if (svg == null) {
      debugPrint('🏳️ FlagImage: no SVG available for "$code" (emoji fallback)');
      return;
    }

    final key = code.toLowerCase();
    _ratio = _ratioCache[key] ??= svgAspectRatio(svg);

    final cachedSi = _siCache[key];
    if (cachedSi != null) {
      _si = cachedSi;
      return;
    }

    if (!_jovialFailed.contains(key)) {
      try {
        _si = _siCache[key] = ScalableImage.fromSvgString(svg);
        return;
      } catch (e) {
        // jovial can't render this one — remember it and fall back to
        // flutter_svg (a different engine that may handle it).
        _jovialFailed.add(key);
        debugPrint('🏳️ FlagImage: jovial_svg failed to parse "$code" '
            '($e) — falling back to flutter_svg');
      }
    }

    _fallbackSvg = svg;
  }

  @override
  Widget build(BuildContext context) {
    // Bounding height; flags are a touch taller than their nominal width-ish size
    // so coats of arms and detailed flags stay legible.
    final height = FlagImage.heightForSize(widget.size);

    final si = _si;
    final fallbackSvg = _fallbackSvg;

    if (si == null && fallbackSvg == null) {
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
    // and foreground layers in the same Stack).
    SizedBox flag() => SizedBox(
          height: height,
          width: height * _ratio,
          child: si != null
              ? ScalableImageWidget(si: si, fit: BoxFit.contain)
              : SvgPicture.string(fallbackSvg!, fit: BoxFit.contain),
        );

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
              imageFilter: ImageFilter.blur(sigmaX: 1.4, sigmaY: 1.4),
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
