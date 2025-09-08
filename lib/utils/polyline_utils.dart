import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:google_polyline_algorithm/google_polyline_algorithm.dart';
import 'package:latlong2/latlong.dart';
import 'package:trainlog_app/data/models/trips.dart';

List<LatLng> decodePath(String path) {
  return decodePolyline(path)
      .map((p) => LatLng(p[0].toDouble(), p[1].toDouble()))
      .toList();
}

List<PolylineEntry> decodePolylinesBatch(Map<String, dynamic> args) {
  final List<Map<String, dynamic>> entries = List<Map<String, dynamic>>.from(args['entries']);
  final Map<VehicleType, Color> colorPalette = Map<VehicleType, Color>.from(args['colors']);

  return entries.map((e) {
    try {
      final path = (e['path'] as String).trim();
      final type = e['type'] as VehicleType;

      final startDateStr = e['start_datetime']?.toString();
      final startDate = startDateStr != null ? DateTime.tryParse(startDateStr) : null;
      final createdStr = e['created']?.toString();
      final createdDate = createdStr != null ? DateTime.tryParse(createdStr) : null;

      final isFuture = (startDate != null) && startDate.isAfter(DateTime.now());

      List<LatLng> points =
          decodePolyline(path).map((p) => LatLng(p[0].toDouble(), p[1].toDouble())).toList();

      if (type == VehicleType.plane && points.length == 2) {
        points = generateGeodesicPoints(points[0], points[1], 40);
      }

      return PolylineEntry(
        polyline: Polyline(
          points: points,
          color: colorPalette[type] ?? Colors.black,
          pattern: isFuture ? StrokePattern.dashed(segments: const [20, 20]) : const StrokePattern.solid(),
          strokeWidth: 4.0,
        ),
        type: type,
        startDate: startDate,
        creationDate: createdDate,
        isFuture: isFuture,
      );
    } catch (_) {
      return null;
    }
  }).whereType<PolylineEntry>().toList();
}

List<LatLng> generateGeodesicPoints(LatLng start, LatLng end, int numPoints) {
  double toRadians(double deg) => deg * math.pi / 180;
  double toDegrees(double rad) => rad * 180 / math.pi;

  final lat1 = toRadians(start.latitude);
  final lon1 = toRadians(start.longitude);
  final lat2 = toRadians(end.latitude);
  final lon2 = toRadians(end.longitude);

  final d = 2 *
      math.asin(math.sqrt(
        math.pow(math.sin((lat2 - lat1) / 2), 2) +
            math.cos(lat1) * math.cos(lat2) * math.pow(math.sin((lon2 - lon1) / 2), 2),
      ));

  final result = <LatLng>[];

  for (int i = 0; i <= numPoints; i++) {
    final f = i / numPoints;
    final A = math.sin((1 - f) * d) / math.sin(d);
    final B = math.sin(f * d) / math.sin(d);

    final x = A * math.cos(lat1) * math.cos(lon1) + B * math.cos(lat2) * math.cos(lon2);
    final y = A * math.cos(lat1) * math.sin(lon1) + B * math.cos(lat2) * math.sin(lon2);
    final z = A * math.sin(lat1) + B * math.sin(lat2);

    final lat = math.atan2(z, math.sqrt(x * x + y * y));
    final lon = math.atan2(y, x);

    result.add(LatLng(toDegrees(lat), toDegrees(lon)));
  }

  return result;
}

class PolylineEntry {
  final Polyline polyline;
  final VehicleType type;
  final DateTime? startDate;
  final DateTime? creationDate;
  final bool isFuture;

  PolylineEntry({
    required this.polyline,
    required this.type,
    required this.startDate,
    required this.creationDate,
    this.isFuture = false,
  });

  Map<String, dynamic> toJson() => {
        'type': type.name,
        'startDate': startDate?.toIso8601String(),
        'creationDate': creationDate?.toIso8601String(),
        'isFuture': isFuture,
        'polyline': {
          'points': polyline.points.map((e) => {'lat': e.latitude, 'lng': e.longitude}).toList(),
          'color': polyline.color.value,
          'strokeWidth': polyline.strokeWidth,
          'isDashed': (polyline.pattern).segments?.length != null &&
              (polyline.pattern).segments!.length > 1,
        },
      };

  factory PolylineEntry.fromJson(Map<String, dynamic> json) => PolylineEntry(
        type: VehicleType.values.firstWhere((e) => e.name == json['type']),
        startDate: json['startDate'] != null ? DateTime.parse(json['startDate']) : null,
        creationDate: json['creationDate'] != null ? DateTime.parse(json['creationDate']) : null,
        isFuture: json['isFuture'] == true,
        polyline: Polyline(
          points: (json['polyline']['points'] as List)
              .map((p) => LatLng((p['lat'] as num).toDouble(), (p['lng'] as num).toDouble()))
              .toList(),
          color: Color(json['polyline']['color']),
          pattern: (json['polyline']['isDashed'] == true)
              ? StrokePattern.dashed(segments: const [20, 20])
              : const StrokePattern.solid(),
          strokeWidth: (json['polyline']['strokeWidth'] as num).toDouble(),
        ),
      );
}
