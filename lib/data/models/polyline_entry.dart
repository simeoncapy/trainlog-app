import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:google_polyline_algorithm/google_polyline_algorithm.dart';
import 'package:latlong2/latlong.dart';

import 'package:trainlog_app/data/models/trips.dart';

// PolylineEntry (lower in this file) and PolylineTools provide encoding/decoding and helper methods.

class PolylineTools {

  static List<LatLng> decodePath(String path) =>
      decodePolyline(path).map((p) => LatLng(p[0].toDouble(), p[1].toDouble())).toList();

  static String encodePath(dynamic points) {
    final latLngList = toLatLngList(points);

    // google_polyline_algorithm expects List<List<num>>
    final encodedInput = latLngList
        .map<List<num>>((p) => <num>[p.latitude, p.longitude])
        .toList();

    return encodePolyline(encodedInput);
  }

  static List<LatLng> toLatLngList(dynamic points) {
    if (points is List<LatLng>) {
      return points;
    }

    if (points is List) {
      // Expect: [{ "lat": 35.7, "lng": 139.8 }, ...]
      return points.map<LatLng>((e) {
        final m = e as Map<String, dynamic>;
        final lat = (m['lat'] as num).toDouble();
        final lng = (m['lng'] as num).toDouble();
        return LatLng(lat, lng);
      }).toList();
    }

    throw ArgumentError('Unsupported points type: ${points.runtimeType}');
  }

  static Polyline createPolyline(List<LatLng> points, Color? color) {
    return Polyline(
      points: points,
      color: color ?? Colors.black,
      strokeWidth: 4.0,
      borderColor: Colors.black,
      borderStrokeWidth: 1.0,
      pattern: const StrokePattern.solid(),
    );
  }

  static DateTime? parseUtcLoose(String? s) {
    if (s == null) return null;
    final text = s.trim();
    if (text.isEmpty) return null;
    final hasOffset = RegExp(r'(Z|[+\-]\d{2}:\d{2})$').hasMatch(text);
    final iso = hasOffset ? text : '${text}Z';
    return DateTime.parse(iso).toUtc();
  }

  static bool hasClockPart(String? s) {
    if (s == null) return false;
    return RegExp(r'\d{2}:\d{2}').hasMatch(s);
  }

  static List<LatLng> generateGeodesicPoints(LatLng start, LatLng end, int numPoints) {
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
  static List<PolylineEntry> decodePolylinesBatchIsolateFriendly(Map<String, dynamic> args) {
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

        final base = createPolyline(points, Color(colorInt));

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
}

// ------------------------------------------------------------------------
// PolylineEntry

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

  PolylineEntry copyWith({
    Polyline? polyline,
    VehicleType? type,
    DateTime? startDate,
    DateTime? creationDate,
    DateTime? utcStartDate,
    DateTime? utcEndDate,
    bool? hasTimeRange,
    bool? isFuture,
    int? tripId,
  }) {
    return PolylineEntry(
      polyline: polyline ?? this.polyline,
      type: type ?? this.type,
      startDate: startDate ?? this.startDate,
      creationDate: creationDate ?? this.creationDate,
      utcStartDate: utcStartDate ?? this.utcStartDate,
      utcEndDate: utcEndDate ?? this.utcEndDate,
      hasTimeRange: hasTimeRange ?? this.hasTimeRange,
      isFuture: isFuture ?? this.isFuture,
      tripId: tripId ?? this.tripId,
    );
  }

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
