import 'package:flutter/material.dart';
import 'package:trainlog_app/data/models/trips.dart';

enum MapColorPalette {
  trainlogWeb,
  vibrantTones,
  colorBlind,
  red,
  blue,
  green,
  custom,
}

class MapColorPaletteHelper {
  static Map<VehicleType, Color> getPalette(MapColorPalette palette, [Map<VehicleType, Color>? custom]) {
    switch (palette) {
      case MapColorPalette.trainlogWeb:
        return {
          VehicleType.train: Color(0xFF52B0FE),
          VehicleType.plane: Color(0xFF40B91F),
          VehicleType.tram: Color(0xFFA2D7FF),
          VehicleType.metro: Color(0xFF004595),
          VehicleType.bus: Color(0xFF9F4BBB),
          VehicleType.car: Color(0xFFA68FCD),
          VehicleType.ferry: Color(0xFF1E1E7C),
          VehicleType.aerialway: Color(0xFFB1CF29),
          VehicleType.cycle: Color(0xFF692018),
          VehicleType.helicopter: Color(0xFF5771E0),
          VehicleType.walk: Color(0xFFE18B00),
          VehicleType.poi: Colors.black,
          VehicleType.unknown: Colors.grey,
        };
      case MapColorPalette.vibrantTones:
        return {
          VehicleType.train: Color(0xFF277DA1),
          VehicleType.plane: Color(0xFF90BE6D),
          VehicleType.tram: Color(0xFFF94144),
          VehicleType.metro: Color(0xFF4D908E),
          VehicleType.bus: Color(0xFFF9C74F),
          VehicleType.car: Color(0xFFF9844A),
          VehicleType.ferry: Color(0xFF577590),
          VehicleType.aerialway: Color(0xFFF8961E),
          VehicleType.cycle: Color(0xFFF3722C),
          VehicleType.helicopter: Color(0xFF43AA8B),
          VehicleType.walk: Color(0xFF220901),
          VehicleType.poi: Colors.black,
          VehicleType.unknown: Colors.grey,
        };
      case MapColorPalette.colorBlind:
        return {
          VehicleType.train: Color(0xFF9F0162),
          VehicleType.plane: Color(0xFF009F81),
          VehicleType.tram: Color(0xFFFF5AAF),
          VehicleType.metro: Color(0xFF00FCCF),
          VehicleType.bus: Color(0xFF8400CD),
          VehicleType.car: Color(0xFF008DF9),
          VehicleType.ferry: Color(0xFF00C2F9),
          VehicleType.aerialway: Color(0xFFFFB2FD),
          VehicleType.cycle: Color(0xFFA40122),
          VehicleType.helicopter: Color(0xFFE20134),
          VehicleType.walk: Color(0xFFFF6E3A),
          VehicleType.poi: Color(0xFFFFC33B),
          VehicleType.unknown: Colors.grey,
        };
      case MapColorPalette.red:
        return generateShadedPalette(Colors.red);
      case MapColorPalette.green:
        return generateShadedPalette(Colors.green);
      case MapColorPalette.blue:
        return generateShadedPalette(Colors.blue);
      case MapColorPalette.custom:
        if (custom != null) return custom;
        return {
          for (var type in VehicleType.values) type: Colors.grey,
        };
    }
  }

  static Map<VehicleType, Color> generateShadedPalette(MaterialColor baseColor) {
  final shades = [100, 200, 300, 400, 500, 600, 700, 800];
  return {
    for (int i = 0; i < VehicleType.values.length; i++)
      VehicleType.values[i]: baseColor[shades[i % shades.length]]!,
  };
}
}
