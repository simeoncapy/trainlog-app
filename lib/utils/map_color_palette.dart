import 'package:flutter/material.dart';
import 'package:trainlog_app/data/models/trips.dart';

enum MapColorPalette {
  trainlogWeb,
  trainlogVariation,
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
          VehicleType.unknown: Colors.grey,
        };
      case MapColorPalette.trainlogVariation:
        return {
          VehicleType.train: Colors.blue,
          VehicleType.plane: Colors.green,
          VehicleType.tram: Colors.lightBlue,
          VehicleType.metro: Colors.deepOrange,
          VehicleType.bus: Colors.deepPurple,
          VehicleType.car: Colors.purple,
          VehicleType.ferry: Colors.teal,
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
