import 'package:flutter/material.dart';

/// Categorical palette for ranked charts: 10 distinct hues, assigned by rank,
/// plus a neutral grey reserved for the "Other" bucket.
///
/// Each theme has its own steps of the same hues. Adjacent slots were
/// validated for colour-vision deficiency (protan/deutan ΔE ≥ 8) and normal
/// vision (ΔE ≥ 15) against the light card (#FFFFFF) and dark surface
/// (#161C27). Non-adjacent pairs (e.g. orange/yellow) can be close, so keep a
/// secondary cue (rank number, legend order) next to the colour.
abstract final class ChartPalette {
  static const List<Color> _light = [
    Color(0xFF2A78D6), // blue
    Color(0xFFEB6834), // orange
    Color(0xFF1BAF7A), // aqua
    Color(0xFFEDA100), // yellow
    Color(0xFFE87BA4), // pink
    Color(0xFF008300), // green
    Color(0xFF6250D6), // violet
    Color(0xFFE34948), // red
    Color(0xFF0F9FB5), // cyan
    Color(0xFF8A9A00), // olive
  ];

  static const List<Color> _dark = [
    Color(0xFF3987E5), // blue
    Color(0xFFD95926), // orange
    Color(0xFF199E70), // aqua
    Color(0xFFC98500), // yellow
    Color(0xFFD55181), // pink
    Color(0xFF008300), // green
    Color(0xFF9085E9), // violet
    Color(0xFFE66767), // red
    Color(0xFF1597AA), // cyan
    Color(0xFF8F9E1A), // olive
  ];

  static const Color _otherLight = Color(0xFF9A9A96);
  static const Color _otherDark = Color(0xFF6F7480);

  /// Number of distinct hues before colours would repeat.
  static int get length => _light.length;

  /// Colour of the item at [rank] (0-based); wraps past [length].
  static Color colorAt(int rank, Brightness brightness) {
    final colors = brightness == Brightness.dark ? _dark : _light;
    return colors[rank % colors.length];
  }

  /// Neutral colour of the "Other" bucket.
  static Color other(Brightness brightness) =>
      brightness == Brightness.dark ? _otherDark : _otherLight;
}
