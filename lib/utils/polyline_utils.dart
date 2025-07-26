import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:google_polyline_algorithm/google_polyline_algorithm.dart';
import 'package:trainlog_app/data/models/trips.dart';
import 'package:geodesy/geodesy.dart';

List<LatLng> decodePath(String path) {
  return decodePolyline(path)
      .map((p) => LatLng(p[0].toDouble(), p[1].toDouble()))
      .toList();
}

List<Polyline> decodePolylinesBatch(Map<String, dynamic> args) {
  final List<Map<String, dynamic>> entries = List<Map<String, dynamic>>.from(args['entries']);
  final Map<VehicleType, Color> colorPalette = Map<VehicleType, Color>.from(args['colors']);      

  return entries.map((e) {
    try {
      final path = (e['path'] as String).trim();
      final type = e['type'] as VehicleType;
      List<LatLng> points = decodePolyline(path)
          .map((p) => LatLng(p[0].toDouble(), p[1].toDouble()))
          .toList();
      if (type == VehicleType.plane) print("${e['uid']}: ${points.length}");
      if (type == VehicleType.plane && points.length == 2) {
        points = generateGeodesicPoints(points[0], points[1], 40);
      }
      return Polyline(points: points, color: colorPalette[type] ?? Colors.black, strokeWidth: 4.0);
    } catch (_) {
      return null; // skip
    }
  }).whereType<Polyline>().toList();
}

List<LatLng> generateGeodesicPoints(LatLng start, LatLng end, int numPoints) {
  //const earthRadius = 6371000; // meters
  double toRadians(double deg) => deg * pi / 180;
  double toDegrees(double rad) => rad * 180 / pi;

  final lat1 = toRadians(start.latitude);
  final lon1 = toRadians(start.longitude);
  final lat2 = toRadians(end.latitude);
  final lon2 = toRadians(end.longitude);

  final d = 2 * asin(sqrt(
    pow(sin((lat2 - lat1) / 2), 2) +
    cos(lat1) * cos(lat2) * pow(sin((lon2 - lon1) / 2), 2),
  ));

  List<LatLng> result = [];

  for (int i = 0; i <= numPoints; i++) {
    final f = i / numPoints;
    final A = sin((1 - f) * d) / sin(d);
    final B = sin(f * d) / sin(d);

    final x = A * cos(lat1) * cos(lon1) + B * cos(lat2) * cos(lon2);
    final y = A * cos(lat1) * sin(lon1) + B * cos(lat2) * sin(lon2);
    final z = A * sin(lat1) + B * sin(lat2);

    final lat = atan2(z, sqrt(x * x + y * y));
    final lon = atan2(y, x);

    result.add(LatLng(toDegrees(lat), toDegrees(lon)));
  }

  return result;
}