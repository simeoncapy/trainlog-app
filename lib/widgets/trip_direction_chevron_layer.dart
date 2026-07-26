import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:provider/provider.dart';

import 'package:trainlog_app/providers/polyline_provider.dart';

/// Map layer drawing small chevrons along the rendered trip polylines to show
/// the direction of travel (departure → arrival).
///
/// Chevrons are spaced at a constant *screen* distance, so their density stays
/// the same at every zoom level: zooming out naturally shows fewer chevrons
/// per trip, and trips too short on screen get none at all. Each chevron is
/// black or white, whichever contrasts best with the trip's line colour.
///
/// Must be placed inside [FlutterMap.children], above the polyline layer.
class TripDirectionChevronLayer extends StatelessWidget {
  const TripDirectionChevronLayer({super.key});

  @override
  Widget build(BuildContext context) {
    final camera = MapCamera.of(context);
    final poly = context.watch<PolylineProvider>();

    return IgnorePointer(
      child: MobileLayerTransformer(
        child: CustomPaint(
          painter: _TripDirectionChevronPainter(
            camera: camera,
            polylines: poly.renderedPolylines,
          ),
          size: camera.size,
        ),
      ),
    );
  }
}

class _TripDirectionChevronPainter extends CustomPainter {
  final MapCamera camera;
  final List<Polyline<int>> polylines;

  _TripDirectionChevronPainter({
    required this.camera,
    required this.polylines,
  });

  /// On-screen distance between two consecutive chevrons, in logical pixels.
  static const double _spacing = 72.0;

  /// A polyline whose on-screen bounding box is smaller than this is skipped
  /// entirely, so zoomed-out short trips are not covered by a lone chevron.
  static const double _minOnScreenSize = _spacing * 0.75;

  /// WCAG relative-luminance pivot: above it black offers the better contrast,
  /// below it white does (sqrt(1.05 * 0.05) - 0.05).
  static const double _luminancePivot = 0.179;

  /// Caches the zoom-independent planar projection of each polyline, keyed by
  /// its (stable) points list, so panning/zooming only rescales cheap offsets
  /// instead of re-projecting every LatLng on each frame.
  static final Expando<_ProjectedPath> _projectionCache = Expando();

  @override
  void paint(Canvas canvas, Size size) {
    // Cull to the canvas plus a margin, so a chevron whose anchor sits just
    // outside the edge does not visibly pop in while panning.
    final cullRect = (Offset.zero & size).inflate(24);

    final crs = camera.crs;
    final zoomScale = crs.scale(camera.zoom);
    final origin = camera.pixelOrigin;

    final worldWidth =
        crs.replicatesWorldLongitude ? crs.projection.getWorldWidth() : 0.0;
    final worldShifts = worldWidth == 0.0
        ? const [0.0]
        : [0.0, -worldWidth, worldWidth];

    final blackPath = Path();
    final whitePath = Path();
    var hasBlack = false;
    var hasWhite = false;

    for (final polyline in polylines) {
      // Future trips are rendered as two stacked polylines: the coloured base
      // and a white dashed overlay. Only draw chevrons once per trip — on the
      // solid coloured line — and pick their colour to contrast with it.
      final pattern = polyline.pattern;
      if (pattern.segments != null || pattern.spacingFactor != null) continue;

      final projected = _project(polyline);
      if (projected == null) continue;

      final useBlack = polyline.color.computeLuminance() > _luminancePivot;
      final target = useBlack ? blackPath : whitePath;

      for (final shift in worldShifts) {
        final added = _addChevronsForWorld(
          target,
          projected,
          shift: shift,
          zoomScale: zoomScale,
          origin: origin,
          cullRect: cullRect,
        );
        if (added) {
          if (useBlack) {
            hasBlack = true;
          } else {
            hasWhite = true;
          }
        }
      }
    }

    final strokeWidth = polylines.isEmpty ? 4.0 : polylines.first.strokeWidth;
    final paint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = math.max(strokeWidth * 0.5, 1.8)
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;

    // White first, black on top: where two trips overlap the upper chevrons
    // stay readable.
    if (hasWhite) {
      canvas.drawPath(whitePath, paint..color = Colors.white);
    }
    if (hasBlack) {
      canvas.drawPath(blackPath, paint..color = Colors.black);
    }
  }

  /// Projects (and caches) the polyline into zoom-independent planar space.
  _ProjectedPath? _project(Polyline<int> polyline) {
    final points = polyline.points;
    if (points.length < 2) return null;

    final cached = _projectionCache[points];
    if (cached != null) return cached;

    final projection = camera.crs.projection;
    final offsets = List<Offset>.generate(
      points.length,
      (i) => projection.project(points[i]),
      growable: false,
    );

    var minX = offsets.first.dx, maxX = offsets.first.dx;
    var minY = offsets.first.dy, maxY = offsets.first.dy;
    for (final o in offsets) {
      if (o.dx < minX) minX = o.dx;
      if (o.dx > maxX) maxX = o.dx;
      if (o.dy < minY) minY = o.dy;
      if (o.dy > maxY) maxY = o.dy;
    }

    final projected = _ProjectedPath(
      offsets: offsets,
      bounds: Rect.fromLTRB(minX, minY, maxX, maxY),
    );
    _projectionCache[points] = projected;
    return projected;
  }

  /// Walks one world copy of [projected] in screen space and appends a chevron
  /// to [target] every [_spacing] pixels along the way.
  ///
  /// Returns whether at least one chevron was added.
  bool _addChevronsForWorld(
    Path target,
    _ProjectedPath projected, {
    required double shift,
    required double zoomScale,
    required Offset origin,
    required Rect cullRect,
  }) {
    final crs = camera.crs;

    // Cheap whole-polyline culling: transform only the two bounding-box
    // corners to screen space before touching the individual points.
    final b = projected.bounds;
    final (left, top) = crs.transform(b.left + shift, b.top, zoomScale);
    final (right, bottom) = crs.transform(b.right + shift, b.bottom, zoomScale);
    final screenBounds = Rect.fromPoints(
      Offset(left, top) - origin,
      Offset(right, bottom) - origin,
    );
    if (!screenBounds.overlaps(cullRect)) return false;
    if (screenBounds.longestSide < _minOnScreenSize) return false;

    final offsets = projected.offsets;
    var (prevX, prevY) =
        crs.transform(offsets.first.dx + shift, offsets.first.dy, zoomScale);
    prevX -= origin.dx;
    prevY -= origin.dy;

    // Phase the first chevron half a spacing in, so short-but-visible paths
    // still get one near their middle.
    var untilNext = _spacing * 0.5;
    var addedAny = false;

    for (var i = 1; i < offsets.length; i++) {
      var (x, y) =
          crs.transform(offsets[i].dx + shift, offsets[i].dy, zoomScale);
      x -= origin.dx;
      y -= origin.dy;

      final dx = x - prevX;
      final dy = y - prevY;
      final segLen = math.sqrt(dx * dx + dy * dy);

      if (segLen > 0) {
        final dirX = dx / segLen;
        final dirY = dy / segLen;
        var travelled = 0.0;

        while (segLen - travelled >= untilNext) {
          travelled += untilNext;
          untilNext = _spacing;

          final pos = Offset(prevX + dirX * travelled, prevY + dirY * travelled);
          if (cullRect.contains(pos)) {
            _addChevron(target, pos, dirX, dirY);
            addedAny = true;
          }
        }
        untilNext -= segLen - travelled;
      }

      prevX = x;
      prevY = y;
    }

    return addedAny;
  }

  /// Appends one chevron (two strokes meeting at a tip pointing along the
  /// travel direction) to [path].
  void _addChevron(Path path, Offset pos, double dirX, double dirY) {
    const halfLength = 3.0; // Along the travel direction.
    const halfSpan = 4.5; // Across the line.

    final tip = Offset(pos.dx + dirX * halfLength, pos.dy + dirY * halfLength);
    final backX = pos.dx - dirX * halfLength;
    final backY = pos.dy - dirY * halfLength;
    // Perpendicular of (dirX, dirY) is (-dirY, dirX).
    final wing1 = Offset(backX - dirY * halfSpan, backY + dirX * halfSpan);
    final wing2 = Offset(backX + dirY * halfSpan, backY - dirX * halfSpan);

    path
      ..moveTo(wing1.dx, wing1.dy)
      ..lineTo(tip.dx, tip.dy)
      ..lineTo(wing2.dx, wing2.dy);
  }

  @override
  bool shouldRepaint(covariant _TripDirectionChevronPainter oldDelegate) =>
      oldDelegate.camera != camera ||
      !identical(oldDelegate.polylines, polylines);
}

/// A polyline projected into zoom-independent planar (CRS) space, with its
/// planar bounding box for fast culling.
class _ProjectedPath {
  final List<Offset> offsets;
  final Rect bounds;

  const _ProjectedPath({required this.offsets, required this.bounds});
}
