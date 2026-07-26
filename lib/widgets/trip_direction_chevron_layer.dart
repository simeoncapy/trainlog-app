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
/// Chevrons respect the stacking order of the trips: the layer walks the
/// rendered polylines in their paint order and re-strokes each line over the
/// chevrons already drawn for the trips below it, so where two trips overlap
/// the chevrons of the lower one are hidden by the upper line, exactly like
/// the line itself.
///
/// Must be placed inside [FlutterMap.children], directly above the polyline
/// layer.
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

  /// A polyline whose on-screen bounding box is smaller than this gets no
  /// chevrons, so zoomed-out short trips are not covered by a lone chevron.
  static const double _minOnScreenSize = _spacing * 0.75;

  /// Points closer than this (squared, in screen pixels) to the previously
  /// kept point are dropped while walking a path: a cheap stand-in for the
  /// polyline layer's simplification when re-stroking lines every frame. Kept
  /// at ~1 px so the re-stroked line stays visually on top of the original.
  static const double _decimationSq = 1.0;

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

    // Until the first chevron is on the canvas there is nothing to cover, so
    // the polylines themselves do not need to be re-stroked yet.
    var anyChevronDrawn = false;

    var i = 0;
    while (i < polylines.length) {
      final polyline = polylines[i];

      // Only solid lines carry chevrons; a dashed/dotted line at this position
      // has no preceding base (never produced by the render pipeline) and is
      // skipped defensively.
      final pattern = polyline.pattern;
      if (pattern.segments != null || pattern.spacingFactor != null) {
        i++;
        continue;
      }

      // The white dashed overlay of a future trip immediately follows its
      // base polyline and shares its points list.
      Polyline<int>? overlay;
      if (i + 1 < polylines.length &&
          identical(polylines[i + 1].points, polyline.points) &&
          polylines[i + 1].pattern.segments != null) {
        overlay = polylines[i + 1];
      }
      i += overlay == null ? 1 : 2;

      final projected = _project(polyline);
      if (projected == null) continue;

      for (final shift in worldShifts) {
        final drewChevrons = _drawPolylineWorld(
          canvas,
          polyline,
          overlay,
          projected,
          shift: shift,
          zoomScale: zoomScale,
          origin: origin,
          cullRect: cullRect,
          redrawLine: anyChevronDrawn,
        );
        anyChevronDrawn = anyChevronDrawn || drewChevrons;
      }
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

  /// Draws one world copy of a trip: optionally its line (border, core and
  /// dashed overlay, mirroring the polyline layer below to cover chevrons of
  /// earlier trips), then its own chevrons.
  ///
  /// Returns whether at least one chevron was drawn.
  bool _drawPolylineWorld(
    Canvas canvas,
    Polyline<int> polyline,
    Polyline<int>? overlay,
    _ProjectedPath projected, {
    required double shift,
    required double zoomScale,
    required Offset origin,
    required Rect cullRect,
    required bool redrawLine,
  }) {
    final crs = camera.crs;

    // Cheap whole-polyline culling: transform only the two bounding-box
    // corners to screen space before touching the individual points.
    final b = projected.bounds;
    final (l, t) = crs.transform(b.left + shift, b.top, zoomScale);
    final (r, bo) = crs.transform(b.right + shift, b.bottom, zoomScale);
    final screenBounds = Rect.fromPoints(Offset(l, t) - origin, Offset(r, bo) - origin);
    if (!screenBounds.overlaps(cullRect)) return false;

    final wantChevrons = screenBounds.longestSide >= _minOnScreenSize;
    if (!wantChevrons && !redrawLine) return false;

    final linePath = redrawLine ? Path() : null;
    final dashPath = redrawLine && overlay != null ? Path() : null;
    final chevronPath = wantChevrons ? Path() : null;

    final dashSegments = overlay?.pattern.segments;
    final dashLen = dashSegments != null ? dashSegments[0] : 0.0;
    final gapLen = dashSegments != null ? dashSegments[1] : 0.0;
    var dashOn = true;
    var dashRemaining = dashLen;

    // Phase the first chevron half a spacing in, so short-but-visible paths
    // still get one near their middle.
    var untilChevron = _spacing * 0.5;
    var drewChevrons = false;

    final offsets = projected.offsets;
    var (prevX, prevY) =
        crs.transform(offsets.first.dx + shift, offsets.first.dy, zoomScale);
    prevX -= origin.dx;
    prevY -= origin.dy;
    linePath?.moveTo(prevX, prevY);
    dashPath?.moveTo(prevX, prevY);

    for (var i = 1; i < offsets.length; i++) {
      var (x, y) =
          crs.transform(offsets[i].dx + shift, offsets[i].dy, zoomScale);
      x -= origin.dx;
      y -= origin.dy;

      final dx = x - prevX;
      final dy = y - prevY;
      final segSq = dx * dx + dy * dy;

      // Drop nearly-coincident points (except the final one, so the path
      // always reaches the arrival).
      if (segSq < _decimationSq && i < offsets.length - 1) continue;
      if (segSq == 0) continue;

      final segLen = math.sqrt(segSq);
      final dirX = dx / segLen;
      final dirY = dy / segLen;

      linePath?.lineTo(x, y);

      if (chevronPath != null) {
        var travelled = 0.0;
        while (segLen - travelled >= untilChevron) {
          travelled += untilChevron;
          untilChevron = _spacing;

          final posX = prevX + dirX * travelled;
          final posY = prevY + dirY * travelled;
          if (cullRect.contains(Offset(posX, posY))) {
            _addChevron(chevronPath, posX, posY, dirX, dirY);
            drewChevrons = true;
          }
        }
        untilChevron -= segLen - travelled;
      }

      if (dashPath != null) {
        var travelled = 0.0;
        while (segLen - travelled >= dashRemaining) {
          travelled += dashRemaining;
          final posX = prevX + dirX * travelled;
          final posY = prevY + dirY * travelled;
          if (dashOn) {
            dashPath.lineTo(posX, posY);
          } else {
            dashPath.moveTo(posX, posY);
          }
          dashOn = !dashOn;
          dashRemaining = dashOn ? dashLen : gapLen;
        }
        dashRemaining -= segLen - travelled;
        if (dashOn) dashPath.lineTo(x, y);
      }

      prevX = x;
      prevY = y;
    }

    final paint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;

    if (linePath != null) {
      // Mirror the polyline layer's stacking: border underneath, then the
      // coloured core, then the white dashed overlay of future trips.
      if (polyline.borderStrokeWidth > 0) {
        canvas.drawPath(
          linePath,
          paint
            ..color = polyline.borderColor
            ..strokeWidth = polyline.strokeWidth + polyline.borderStrokeWidth,
        );
      }
      canvas.drawPath(
        linePath,
        paint
          ..color = polyline.color
          ..strokeWidth = polyline.strokeWidth,
      );
      if (dashPath != null && overlay != null) {
        canvas.drawPath(
          dashPath,
          paint
            ..color = overlay.color
            ..strokeWidth = overlay.strokeWidth,
        );
      }
    }

    if (chevronPath != null && drewChevrons) {
      final useBlack = polyline.color.computeLuminance() > _luminancePivot;
      canvas.drawPath(
        chevronPath,
        paint
          ..color = useBlack ? Colors.black : Colors.white
          ..strokeWidth = math.max(polyline.strokeWidth * 0.5, 1.8),
      );
    }

    return drewChevrons;
  }

  /// Appends one chevron (two strokes meeting at a tip pointing along the
  /// travel direction) to [path].
  void _addChevron(Path path, double posX, double posY, double dirX, double dirY) {
    const halfLength = 2.5; // Along the travel direction. Spread: 3.0
    const halfSpan = 2.0; // Across the line. Spread: 4.5

    final tipX = posX + dirX * halfLength;
    final tipY = posY + dirY * halfLength;
    final backX = posX - dirX * halfLength;
    final backY = posY - dirY * halfLength;
    // Perpendicular of (dirX, dirY) is (-dirY, dirX).
    path
      ..moveTo(backX - dirY * halfSpan, backY + dirX * halfSpan)
      ..lineTo(tipX, tipY)
      ..lineTo(backX + dirY * halfSpan, backY - dirX * halfSpan);
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
