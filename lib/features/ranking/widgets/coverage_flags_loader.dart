import 'package:flutter/widgets.dart';
import 'package:provider/provider.dart';

import 'package:trainlog_app/core/data/models/ranking_model.dart';
import 'package:trainlog_app/core/services/flag_cache.dart';
import 'package:trainlog_app/features/ranking/widgets/flag_image.dart';

/// Loads and pre-rasterises the flags of a railway coverage list, and gives
/// the width of its flag column. Shared by the Material and iOS lists.
mixin CoverageFlagsLoader<T extends StatefulWidget> on State<T> {
  /// The rows whose flags are shown.
  List<RailPercentageEntry> get coverageEntries;

  /// The flag code of a row (country or subdivision).
  String coverageFlagOf(RailPercentageEntry entry);

  /// Nominal flag size passed to [FlagImage] (its height is derived from this).
  static const double flagSize = 34;

  /// Device pixel ratio, read in [didChangeDependencies] (reading MediaQuery in
  /// initState is illegal) and used to rasterise flags at the right resolution.
  double _dpr = 1;
  bool _flagsRequested = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _dpr = MediaQuery.devicePixelRatioOf(context);
    if (!_flagsRequested) {
      _flagsRequested = true;
      _ensureFlagsLoaded();
    }
  }

  @override
  void didUpdateWidget(covariant T oldWidget) {
    super.didUpdateWidget(oldWidget);
    // The entry set changes on tab / sort / country switches.
    _ensureFlagsLoaded();
  }

  /// Loads any not-yet-cached flags for the current entries, then pre-parses and
  /// pre-rasterises them, then rebuilds so the reserved flag-column width
  /// reflects every flag (not just the ones first rendered). The set is fixed
  /// per entry list, so the width stays stable while scrolling.
  ///
  /// Pre-rasterising here is what keeps scrolling and page transitions smooth:
  /// some flags (e.g. US state flags with detailed seals) are very expensive to
  /// paint as vectors, and we'd otherwise re-render each one — twice, for its
  /// shadow — every time its row first appears. Rendering each to a bitmap once,
  /// off the scroll path (yielding between flags so a frame isn't blocked), turns
  /// every subsequent paint into a cheap blit.
  Future<void> _ensureFlagsLoaded() async {
    final cache = context.read<FlagCache>();
    final dpr = _dpr;
    final rasterHeight = FlagImage.heightForSize(flagSize);
    final codes = <String>{for (final e in coverageEntries) coverageFlagOf(e)};

    // Fetch (disk/network) in parallel.
    await Future.wait(codes.map((c) async {
      if (cache.cached(c) == null) await cache.load(c);
    }));
    if (!mounted) return;

    // Pre-parse + pre-rasterise off the scroll path, yielding between flags so a
    // long list of complex SVGs doesn't block a single frame.
    for (final code in codes) {
      final svg = cache.cached(code);
      if (svg != null) {
        await FlagImage.precache(
          code,
          svg,
          rasterHeight: rasterHeight,
          devicePixelRatio: dpr,
        );
      }
      await Future<void>.delayed(Duration.zero);
      if (!mounted) return;
    }

    if (mounted) setState(() {});
  }

  /// Width reserved for the flag column: the widest flag across *all* entries
  /// (the largest aspect ratio × the flag height), so names stay aligned and the
  /// column never shifts as different flags scroll into view.
  double flagColumnWidth(FlagCache cache) {
    final height = FlagImage.heightForSize(flagSize);
    var maxRatio = 0.0;
    for (final e in coverageEntries) {
      // svgAspectRatio('') returns the default ratio for not-yet-loaded flags.
      final ratio = svgAspectRatio(cache.cached(coverageFlagOf(e)) ?? '');
      if (ratio > maxRatio) maxRatio = ratio;
    }
    return height * maxRatio;
  }
}
