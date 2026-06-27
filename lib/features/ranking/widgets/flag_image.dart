import 'package:flutter/material.dart';
import 'package:jovial_svg/jovial_svg.dart';
import 'package:provider/provider.dart';

import 'package:trainlog_app/services/flag_cache.dart';
import 'package:trainlog_app/utils/text_utils.dart';

/// Parsed-image cache, keyed by lowercased area code. Each unique flag is parsed
/// once per app session and reused across every row that shows it.
final Map<String, ScalableImage> _siCache = {};
final Map<String, double> _ratioCache = {};

/// Renders an area flag from the [FlagCache] (memory/disk, backed by the backend
/// static SVG vector service) using [jovial_svg], which renders complex flags
/// (CSS styles, gradients, fill-rule) faithfully where flutter_svg does not.
///
/// [code] is an ISO country code (`"JP"`) or an ISO 3166-2 subdivision code
/// (`"JP-13"`). The flag is laid out at its natural aspect ratio (so wide flags
/// and near-square coats of arms both render undistorted), bounded by [size] in
/// height. While the vector loads — or if the backend has no asset for it — the
/// widget falls back to the unicode flag emoji, so a row never renders blank.
class FlagImage extends StatefulWidget {
  final String code;

  /// Bounding height for the rendered flag; the width follows the flag's ratio.
  final double size;

  const FlagImage({super.key, required this.code, this.size = 30});

  @override
  State<FlagImage> createState() => _FlagImageState();
}

class _FlagImageState extends State<FlagImage> {
  ScalableImage? _si;
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
      _resolve();
    }
  }

  String get _key => widget.code.toLowerCase();

  void _resolve() {
    final cachedSi = _siCache[_key];
    if (cachedSi != null) {
      _si = cachedSi;
      _ratio = _ratioCache[_key] ?? 1.5;
      return;
    }

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
    if (svg == null) {
      _si = null;
      return;
    }
    final key = code.toLowerCase();
    try {
      _si = _siCache[key] ??= ScalableImage.fromSvgString(svg);
      _ratio = _ratioCache[key] ??= svgAspectRatio(svg);
    } catch (_) {
      // Unparseable SVG: keep the emoji fallback.
      _si = null;
    }
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final height = widget.size * 0.72;
    final border = Border.all(
      color: cs.outline.withValues(alpha: 0.4),
      width: 0.8,
    );
    final si = _si;

    if (si == null) {
      // Emoji fallback uses a conventional flag ratio while loading.
      return Container(
        height: height,
        width: height * 1.4,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(3),
          border: border,
        ),
        clipBehavior: Clip.antiAlias,
        child: Text(
          countryCodeToEmoji(widget.code.split('-').first),
          style: TextStyle(fontSize: height * 0.95),
        ),
      );
    }

    return Container(
      height: height,
      width: height * _ratio,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(3),
        border: border,
      ),
      clipBehavior: Clip.antiAlias,
      child: ScalableImageWidget(si:si, fit: BoxFit.contain),
    );
  }
}
