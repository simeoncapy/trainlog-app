import 'dart:math' as math;
import 'dart:typed_data';

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
/// That re-stroke is the layer's main cost, so it is kept off the hot path in
/// two ways:
///
///  * each polyline's simplified geometry is cached per zoom level, mirroring
///    what the polyline layer below already does, so panning only rescales a
///    thinned point list instead of walking every stored point;
///  * the screen area actually covered by chevrons is tracked as the layer
///    paints, and only the trips passing over that area are re-stroked.
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

  /// Points closer than this (in screen pixels) to the previously kept point
  /// are dropped: a cheap stand-in for the polyline layer's simplification
  /// when re-stroking lines. Kept at ~1 px so the re-stroked line stays
  /// visually on top of the original.
  static const double _decimationPx = 1.0;

  /// How far from its anchor a chevron's geometry reaches, before its stroke
  /// is taken into account. Half-diagonal of the shape drawn by [_addChevron].
  static const double _chevronReach = 3.2;

  /// WCAG relative-luminance pivot: above it black offers the better contrast,
  /// below it white does (sqrt(1.05 * 0.05) - 0.05).
  static const double _luminancePivot = 0.179;

  /// Caches the zoom-independent planar projection of each polyline, keyed by
  /// its (stable) points list, so panning/zooming only rescales cheap offsets
  /// instead of re-projecting every LatLng on each frame. Each entry also
  /// carries the simplified point list for the last zoom level it was asked
  /// for.
  static final Expando<_ProjectedPath> _projectionCache = Expando();

  @override
  void paint(Canvas canvas, Size size) {
    // Cull to the canvas plus a margin, so a chevron whose anchor sits just
    // outside the edge does not visibly pop in while panning.
    final cullRect = (Offset.zero & size).inflate(24);

    final crs = camera.crs;
    final zoomScale = crs.scale(camera.zoom);
    final origin = camera.pixelOrigin;

    // Simplification happens in planar space so its result can be reused for
    // every pan at this zoom. The tolerance is derived at the *next* whole
    // zoom, which keeps it at or below one screen pixel for every fractional
    // zoom sharing the key: a cached list is then never coarser than the
    // per-frame decimation it replaces.
    final zoomKey = camera.zoom.ceil();
    final planarToleranceSq = _planarToleranceSq(zoomKey);

    final worldWidth =
        crs.replicatesWorldLongitude ? crs.projection.getWorldWidth() : 0.0;
    final worldShifts = worldWidth == 0.0
        ? const [0.0]
        : [0.0, -worldWidth, worldWidth];

    // Screen area covered by the chevrons drawn so far. A trip only needs to
    // be re-stroked where it can actually paint over one of them, so trips
    // clear of this area keep the cheap early exit.
    final chevronRegion = _ChevronRegion.forArea(cullRect);

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
      final offsets = projected.simplified(zoomKey, planarToleranceSq);

      List<Rect>? drawnChevrons;
      for (final shift in worldShifts) {
        final drawn = _drawPolylineWorld(
          canvas,
          polyline,
          overlay,
          projected,
          offsets,
          shift: shift,
          zoomScale: zoomScale,
          origin: origin,
          cullRect: cullRect,
          chevronRegion: chevronRegion,
        );
        if (drawn != null) (drawnChevrons ??= []).add(drawn);
      }

      // Registered only once every world copy is drawn, so a trip is never
      // re-stroked over chevrons it drew itself — those belong on top of it.
      if (drawnChevrons != null) {
        for (final rect in drawnChevrons) {
          chevronRegion.add(rect);
        }
      }
    }
  }

  /// Squared simplification tolerance in planar units, equivalent to
  /// [_decimationPx] screen pixels at zoom [zoomKey].
  double _planarToleranceSq(int zoomKey) {
    final crs = camera.crs;
    final scale = crs.scale(zoomKey.toDouble());
    final (x0, _) = crs.transform(0.0, 0.0, scale);
    final (x1, _) = crs.transform(1.0, 0.0, scale);
    final pixelsPerPlanarUnit = (x1 - x0).abs();
    if (pixelsPerPlanarUnit <= 0) return 0.0;
    final tolerance = _decimationPx / pixelsPerPlanarUnit;
    return tolerance * tolerance;
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
  /// [offsets] is the simplified planar geometry to walk; [projected] is only
  /// consulted for the (unsimplified) bounding box used to cull.
  ///
  /// Returns the screen area covered by the chevrons it drew, or null if it
  /// drew none.
  Rect? _drawPolylineWorld(
    Canvas canvas,
    Polyline<int> polyline,
    Polyline<int>? overlay,
    _ProjectedPath projected,
    List<Offset> offsets, {
    required double shift,
    required double zoomScale,
    required Offset origin,
    required Rect cullRect,
    required _ChevronRegion chevronRegion,
  }) {
    final crs = camera.crs;

    // Cheap whole-polyline culling: transform only the two bounding-box
    // corners to screen space before touching the individual points.
    final b = projected.bounds;
    final (l, t) = crs.transform(b.left + shift, b.top, zoomScale);
    final (r, bo) = crs.transform(b.right + shift, b.bottom, zoomScale);
    final screenBounds = Rect.fromPoints(Offset(l, t) - origin, Offset(r, bo) - origin);
    if (!screenBounds.overlaps(cullRect)) return null;

    final wantChevrons = screenBounds.longestSide >= _minOnScreenSize;

    // The bounding box tracks the centre line, so widen it by the stroke to
    // cover everything this trip can actually paint over.
    final halfStroke = (polyline.strokeWidth + polyline.borderStrokeWidth) * 0.5;
    final redrawLine = chevronRegion.overlaps(screenBounds.inflate(halfStroke));

    if (!wantChevrons && !redrawLine) return null;

    final linePath = redrawLine ? Path() : null;
    final dashPath = redrawLine && overlay != null ? Path() : null;
    final chevronPath = wantChevrons ? Path() : null;

    final chevronStroke = math.max(polyline.strokeWidth * 0.5, 1.8);
    final chevronRadius = _chevronReach + chevronStroke * 0.5;

    final dashSegments = overlay?.pattern.segments;
    final dashLen = dashSegments != null ? dashSegments[0] : 0.0;
    final gapLen = dashSegments != null ? dashSegments[1] : 0.0;
    var dashOn = true;
    var dashRemaining = dashLen;

    // Phase the first chevron half a spacing in, so short-but-visible paths
    // still get one near their middle.
    var untilChevron = _spacing * 0.5;
    Rect? chevronBounds;

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
            final drawn = Rect.fromCircle(
              center: Offset(posX, posY),
              radius: chevronRadius,
            );
            chevronBounds = chevronBounds?.expandToInclude(drawn) ?? drawn;
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

    if (chevronPath != null && chevronBounds != null) {
      final useBlack = polyline.color.computeLuminance() > _luminancePivot;
      canvas.drawPath(
        chevronPath,
        paint
          ..color = useBlack ? Colors.black : Colors.white
          ..strokeWidth = chevronStroke,
      );
    }

    return chevronBounds;
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
///
/// Also memoises the simplified point list for the zoom level it was last
/// asked about. One entry is enough: the map sits at a single zoom between
/// gestures, which is when panning repaints matter most.
class _ProjectedPath {
  final List<Offset> offsets;
  final Rect bounds;

  int? _simplifiedZoomKey;
  List<Offset>? _simplifiedOffsets;

  _ProjectedPath({required this.offsets, required this.bounds});

  /// The point list thinned to [toleranceSq] (squared planar units), cached
  /// against [zoomKey].
  List<Offset> simplified(int zoomKey, double toleranceSq) {
    final cached = _simplifiedOffsets;
    if (cached != null && _simplifiedZoomKey == zoomKey) return cached;

    final result = _thin(offsets, toleranceSq);
    _simplifiedZoomKey = zoomKey;
    _simplifiedOffsets = result;
    return result;
  }

  /// Drops points closer than [toleranceSq] to the previously kept one. The
  /// first and last points are always kept, so the path still spans departure
  /// to arrival.
  static List<Offset> _thin(List<Offset> points, double toleranceSq) {
    if (toleranceSq <= 0 || points.length < 3) return points;

    final kept = <Offset>[points.first];
    var prev = points.first;
    for (var i = 1; i < points.length - 1; i++) {
      final p = points[i];
      final dx = p.dx - prev.dx;
      final dy = p.dy - prev.dy;
      if (dx * dx + dy * dy < toleranceSq) continue;
      kept.add(p);
      prev = p;
    }
    kept.add(points.last);

    // Nothing dropped: keep sharing the original list rather than a copy.
    return kept.length == points.length ? points : kept;
  }
}

/// Coarse record of where chevrons have been drawn on screen, used to decide
/// which trips have to be re-stroked over them.
///
/// A single union rectangle would swell to the whole viewport as soon as two
/// trips sit in opposite corners, so occupancy is kept per cell instead.
/// Cells are marked outward, making the test conservative: it may ask for a
/// re-stroke that was not needed, never skip one that was.
class _ChevronRegion {
  static const double _cellSize = 32.0;

  final Rect _area;
  final int _columns;
  final int _rows;
  final Uint8List _cells;

  /// Union of everything added so far, letting the common "nowhere near a
  /// chevron" case be rejected without touching [_cells]. Null while empty.
  Rect? _markedBounds;

  _ChevronRegion._(this._area, this._columns, this._rows, this._cells);

  factory _ChevronRegion.forArea(Rect area) {
    final columns = math.max(1, (area.width / _cellSize).ceil());
    final rows = math.max(1, (area.height / _cellSize).ceil());
    return _ChevronRegion._(
      Rect.fromLTWH(
        area.left,
        area.top,
        columns * _cellSize,
        rows * _cellSize,
      ),
      columns,
      rows,
      Uint8List(columns * rows),
    );
  }

  void add(Rect rect) {
    if (!rect.overlaps(_area)) return;

    final (c0, r0, c1, r1) = _cellRange(rect);
    for (var row = r0; row <= r1; row++) {
      final rowStart = row * _columns;
      for (var column = c0; column <= c1; column++) {
        _cells[rowStart + column] = 1;
      }
    }

    final marked = _markedBounds;
    _markedBounds = marked == null ? rect : marked.expandToInclude(rect);
  }

  bool overlaps(Rect rect) {
    final marked = _markedBounds;
    if (marked == null || !rect.overlaps(marked)) return false;

    final (c0, r0, c1, r1) = _cellRange(rect);
    for (var row = r0; row <= r1; row++) {
      final rowStart = row * _columns;
      for (var column = c0; column <= c1; column++) {
        if (_cells[rowStart + column] != 0) return true;
      }
    }
    return false;
  }

  /// Inclusive (column, row) bounds of the cells [rect] touches, clamped to
  /// the grid. Only call for a rect known to overlap [_area].
  (int, int, int, int) _cellRange(Rect rect) {
    int column(double x) =>
        ((x - _area.left) / _cellSize).floor().clamp(0, _columns - 1);
    int row(double y) =>
        ((y - _area.top) / _cellSize).floor().clamp(0, _rows - 1);

    return (
      column(rect.left),
      row(rect.top),
      column(rect.right),
      row(rect.bottom),
    );
  }
}
