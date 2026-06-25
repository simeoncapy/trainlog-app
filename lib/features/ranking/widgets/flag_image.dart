import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:provider/provider.dart';

import 'package:trainlog_app/services/flag_cache.dart';
import 'package:trainlog_app/utils/text_utils.dart';

/// Renders an area flag from the [FlagCache] (memory/disk, backed by the backend
/// static SVG vector service).
///
/// [code] is an ISO country code (`"JP"`) or an ISO 3166-2 subdivision code
/// (`"JP-13"`). While the vector loads — or if the backend has no asset for it —
/// the widget falls back to the unicode flag emoji derived from the parent
/// country code, so a row never renders blank. Cached SVGs render instantly and
/// without re-fetching, which keeps fast scrolling smooth.
class FlagImage extends StatefulWidget {
  final String code;
  final double size;

  const FlagImage({super.key, required this.code, this.size = 30});

  @override
  State<FlagImage> createState() => _FlagImageState();
}

class _FlagImageState extends State<FlagImage> {
  String? _svg;

  @override
  void initState() {
    super.initState();
    _resolve();
  }

  @override
  void didUpdateWidget(FlagImage oldWidget) {
    super.didUpdateWidget(oldWidget);
    // ListView recycles row Elements: when the code changes, reload so a scrolled
    // row never shows the previous country's flag.
    if (oldWidget.code != widget.code) {
      _svg = null;
      _resolve();
    }
  }

  void _resolve() {
    final cache = context.read<FlagCache>();
    final cached = cache.cached(widget.code);
    if (cached != null) {
      _svg = cached;
      return;
    }
    final code = widget.code;
    cache.load(code).then((svg) {
      if (!mounted || code != widget.code) return;
      setState(() => _svg = svg);
    });
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final svg = _svg;

    final Widget child = svg != null
        ? SvgPicture.string(svg, fit: BoxFit.cover)
        : Center(
            child: Text(
              countryCodeToEmoji(widget.code.split('-').first),
              style: TextStyle(fontSize: widget.size * 0.82),
            ),
          );

    return Container(
      width: widget.size,
      height: widget.size * 0.72,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(4),
        border: Border.all(
          color: cs.outline.withValues(alpha: 0.4),
          width: 0.8,
        ),
      ),
      clipBehavior: Clip.antiAlias,
      child: child,
    );
  }
}
