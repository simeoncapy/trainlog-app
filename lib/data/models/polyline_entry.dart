import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:google_polyline_algorithm/google_polyline_algorithm.dart';
import 'package:latlong2/latlong.dart';

import 'package:trainlog_app/data/models/trips.dart';

List<LatLng> decodePath(String path) =>
    decodePolyline(path).map((p) => LatLng(p[0].toDouble(), p[1].toDouble())).toList();

DateTime? parseUtcLoose(String? s) {
  if (s == null) return null;
  final text = s.trim();
  if (text.isEmpty) return null;
  final hasOffset = RegExp(r'(Z|[+\-]\d{2}:\d{2})$').hasMatch(text);
  final iso = hasOffset ? text : '${text}Z';
  return DateTime.parse(iso).toUtc();
}

bool hasClockPart(String? s) {
  if (s == null) return false;
  return RegExp(r'\d{2}:\d{2}').hasMatch(s);
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

/// For `compute()` isolate: only send primitives/Lists/Maps.
/// args['entries']: List<Map> with 'type' as String (VehicleType.name)
/// args['colors'] : Map<String,int> color values (ARGB)
List<PolylineEntry> decodePolylinesBatchIsolateFriendly(Map<String, dynamic> args) {
  final entries = List<Map<String, dynamic>>.from(args['entries'] as List);
  final colorMap = Map<String, int>.from(args['colors'] as Map);

  return entries.map((e) {
    try {
      final path = (e['path'] as String).trim();

      final typeName = (e['type'] as String).trim();
      final type = VehicleType.values.firstWhere((t) => t.name == typeName);

      final uidRaw = e['uid'];
      final id = (uidRaw is int) ? uidRaw : int.parse(uidRaw.toString());

      final startLocalStr = e['start_datetime']?.toString();
      final startLocal = startLocalStr != null ? DateTime.tryParse(startLocalStr) : null;

      final startStrUtc = e['utc_start_datetime']?.toString();
      final endStrUtc = e['utc_end_datetime']?.toString();
      final utcStart = parseUtcLoose(startStrUtc);
      final utcEnd = parseUtcLoose(endStrUtc);
      final hasTimeRange = hasClockPart(startStrUtc) && hasClockPart(endStrUtc);

      final createdStr = e['created']?.toString();
      final created = createdStr != null ? DateTime.tryParse(createdStr) : null;

      List<LatLng> points = decodePath(path);
      if (type == VehicleType.plane && points.length == 2) {
        points = generateGeodesicPoints(points[0], points[1], 40);
      }

      final colorInt = colorMap[type.name] ?? Colors.black.value;

      final base = Polyline(
        points: points,
        color: Color(colorInt),
        strokeWidth: 4.0,
        borderColor: Colors.black,
        borderStrokeWidth: 1.0,
        pattern: const StrokePattern.solid(),
      );

      final isFutureHint = utcStart != null && utcStart.isAfter(DateTime.now().toUtc());

      return PolylineEntry(
        polyline: base,
        type: type,
        startDate: startLocal,
        creationDate: created,
        utcStartDate: utcStart,
        utcEndDate: utcEnd,
        hasTimeRange: hasTimeRange,
        isFuture: isFutureHint,
        tripId: id,
      );
    } catch (_) {
      return null;
    }
  }).whereType<PolylineEntry>().toList();
}

class PolylineEntry {
  final Polyline polyline;
  final VehicleType type;
  final DateTime? startDate;
  final DateTime? creationDate;
  final DateTime? utcStartDate;
  final DateTime? utcEndDate;
  final bool hasTimeRange;
  final bool isFuture;
  final int tripId;

  PolylineEntry({
    required this.polyline,
    required this.type,
    required this.startDate,
    required this.creationDate,
    required this.utcStartDate,
    required this.utcEndDate,
    required this.hasTimeRange,
    this.isFuture = false,
    required this.tripId,
  });

  @override
  String toString() => toJson().toString();

  Map<String, dynamic> toJson() => {
        'uid': tripId,
        'type': type.name,
        'startDate': startDate?.toIso8601String(),
        'creationDate': creationDate?.toIso8601String(),
        'utcStartDate': utcStartDate?.toIso8601String(),
        'utcEndDate': utcEndDate?.toIso8601String(),
        'hasTimeRange': hasTimeRange,
        'isFuture': isFuture,
        'polyline': {
          'points': polyline.points.map((e) => {'lat': e.latitude, 'lng': e.longitude}).toList(),
          'color': polyline.color.toARGB32(),
          'strokeWidth': polyline.strokeWidth,
          'borderColor': polyline.borderColor.toARGB32(),
          'borderStrokeWidth': polyline.borderStrokeWidth,
        },
      };

  factory PolylineEntry.fromJson(Map<String, dynamic> json) {
    DateTime? parseUtc(dynamic v) => (v == null) ? null : DateTime.parse(v as String).toUtc();

    final base = Polyline(
      points: (json['polyline']['points'] as List)
          .map((p) => LatLng((p['lat'] as num).toDouble(), (p['lng'] as num).toDouble()))
          .toList(),
      color: Color(json['polyline']['color']),
      strokeWidth: (json['polyline']['strokeWidth'] as num).toDouble(),
      borderColor: Color(json['polyline']['borderColor']),
      borderStrokeWidth: (json['polyline']['borderStrokeWidth'] as num?)?.toDouble() ?? 1.0,
      pattern: const StrokePattern.solid(),
    );

    return PolylineEntry(
      polyline: base,
      type: VehicleType.values.firstWhere((e) => e.name == json['type']),
      startDate: json['startDate'] != null ? DateTime.parse(json['startDate']) : null,
      creationDate: json['creationDate'] != null ? DateTime.parse(json['creationDate']) : null,
      utcStartDate: parseUtc(json['utcStartDate']),
      utcEndDate: parseUtc(json['utcEndDate']),
      hasTimeRange: json['hasTimeRange'] == true,
      isFuture: json['isFuture'] == true,
      tripId: (json['uid'] is int) ? json['uid'] : int.parse(json['uid'].toString()),
    );
  }
}
