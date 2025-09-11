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

// Treat strings without offset as *UTC*, not device-local,
// to avoid accidental device-TZ contamination.
DateTime? _parseUtcLoose(String? s) {
  if (s == null) return null;
  final text = s.trim();
  if (text.isEmpty) return null;
  final hasOffset = RegExp(r'(Z|[+\-]\d{2}:\d{2})$').hasMatch(text);
  final iso = hasOffset ? text : '${text}Z';
  final dt = DateTime.parse(iso);
  return dt.toUtc();
}

List<PolylineEntry> decodePolylinesBatch(Map<String, dynamic> args) {
  final List<Map<String, dynamic>> entries = List<Map<String, dynamic>>.from(args['entries']);
  final Map<VehicleType, Color> colorPalette = Map<VehicleType, Color>.from(args['colors']);

  final nowUtc = DateTime.now().toUtc();

  return entries.map((e) {
    try {
      final path = (e['path'] as String).trim();
      final type = e['type'] as VehicleType;

      // Local times (kept for UI/year filters)
      final startLocalStr = e['start_datetime']?.toString();
      final startLocal = startLocalStr != null ? DateTime.tryParse(startLocalStr) : null;

      // UTC times (truth for past/future + flip)
      final startUtc = _parseUtcLoose(e['utc_start_datetime']?.toString());
      final endUtc   = _parseUtcLoose(e['utc_end_datetime']?.toString());

      final createdStr = e['created']?.toString();
      final createdDate = createdStr != null ? DateTime.tryParse(createdStr) : null;

      // Decide future strictly from UTC
      final isFuture = (startUtc != null) ? startUtc.isAfter(nowUtc) : false;

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
        startDate: startLocal,
        creationDate: createdDate,
        utcStartDate: startUtc,
        utcEndDate: endUtc,
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
  final DateTime? startDate;     // local start (kept for UI)
  final DateTime? creationDate;
  final DateTime? utcStartDate;  // source of truth for past/future
  final DateTime? utcEndDate;
  final bool isFuture;

  PolylineEntry({
    required this.polyline,
    required this.type,
    required this.startDate,
    required this.creationDate,
    required this.utcStartDate,
    required this.utcEndDate,
    this.isFuture = false,
  });

  Map<String, dynamic> toJson() => {
        'type': type.name,
        'startDate': startDate?.toIso8601String(),
        'creationDate': creationDate?.toIso8601String(),
        'utcStartDate': utcStartDate?.toIso8601String(),
        'utcEndDate': utcEndDate?.toIso8601String(),
        'isFuture': isFuture,
        'polyline': {
          'points': polyline.points.map((e) => {'lat': e.latitude, 'lng': e.longitude}).toList(),
          'color': polyline.color.value,
          'strokeWidth': polyline.strokeWidth,
          'isDashed': (polyline.pattern).segments?.length != null &&
              (polyline.pattern).segments!.length > 1,
        },
      };

  factory PolylineEntry.fromJson(Map<String, dynamic> json) {
    // Keep local start as-is
    final startLocal =
        json['startDate'] != null ? DateTime.parse(json['startDate'] as String) : null;

    // Parse UTC robustly (treat naive as UTC)
    DateTime? parseUtcLoose(dynamic v) =>
        _parseUtcLoose(v is String ? v : v?.toString());

    return PolylineEntry(
      type: VehicleType.values.firstWhere((e) => e.name == json['type']),
      startDate: startLocal,
      creationDate:
          json['creationDate'] != null ? DateTime.parse(json['creationDate'] as String) : null,
      utcStartDate: parseUtcLoose(json['utcStartDate']),
      utcEndDate: parseUtcLoose(json['utcEndDate']),
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
}
