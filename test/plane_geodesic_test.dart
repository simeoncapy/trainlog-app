import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:trainlog_app/data/models/polyline_entry.dart';
import 'package:trainlog_app/data/models/trips.dart';
import 'package:trainlog_app/utils/polyline_styling.dart';

/// Haneda to San Francisco, stored the way the routing page saves a geodesic
/// flight: its two endpoints only.
Trips _trip(String type) => Trips.fromJson(
      {
        'uid': '9',
        'type': type,
        'start_datetime': '2026-10-24 10:00:00',
        'end_datetime': '2026-10-24 19:00:00',
        'path': [
          [35.55, 139.78],
          [37.62, -122.38],
        ],
      },
      pathAsGooglePolyline: false,
    );

void main() {
  const palette = <VehicleType, Color>{};

  // A trip added or changed (created, edited, synced) is drawn through
  // PolylineStyling, not the batch decoder: it used to draw a plane as a
  // straight line on the map.
  test('a plane added to the map is drawn as a great circle', () {
    final points =
        PolylineStyling.createPolyline(null, _trip('plane'), palette).points;

    expect(points, hasLength(41));
    expect(points.first.latitude, closeTo(35.55, 1e-9));
    expect(points.last.longitude, closeTo(-122.38, 1e-9));
    // The great circle between them passes far north of both ends, near the
    // Aleutians, instead of along the straight line between them.
    final northmost =
        points.map((p) => p.latitude).reduce((a, b) => a > b ? a : b);
    expect(northmost, greaterThan(47));
  });

  test('the batch decoder draws the same great circle', () {
    final entries = PolylineTools.decodePolylinesBatchIsolateFriendly({
      'entries': [
        {
          'uid': 9,
          'type': 'plane',
          'path': _trip('plane').path,
        },
      ],
      'colors': <String, int>{},
    });

    final styled =
        PolylineStyling.createPolyline(null, _trip('plane'), palette).points;
    expect(entries.single.polyline.points, styled);
  });

  test('a two-point train path stays a straight line', () {
    final points =
        PolylineStyling.createPolyline(null, _trip('train'), palette).points;
    expect(points, hasLength(2));
  });
}
