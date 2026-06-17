import 'package:flutter/material.dart';
import 'package:trainlog_app/app/theme/app_colors.dart';

/// A modern "current location" marker, similar to the blue dot Google Maps
/// shows for the user's position: a solid blue dot wrapped in a white ring and
/// surrounded by a soft, blueish halo.
///
/// The marker is square; size it through the enclosing [Marker]'s width/height.
/// [color] defaults to [AppColors.blue].
class MapMarker extends StatelessWidget {
  /// Base colour of the dot and halo.
  final Color color;

  const MapMarker({super.key, this.color = AppColors.blue});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: AspectRatio(
        aspectRatio: 1,
        child: CustomPaint(
          painter: _MapMarkerPainter(color: color),
        ),
      ),
    );
  }
}

class _MapMarkerPainter extends CustomPainter {
  final Color color;

  const _MapMarkerPainter({required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.shortestSide / 2;

    // Soft blueish halo filling the marker bounds.
    final haloPaint = Paint()
      ..color = color.withValues(alpha: 0.20)
      ..style = PaintingStyle.fill;
    canvas.drawCircle(center, radius, haloPaint);

    // White ring around the dot, giving it contrast against the map.
    final dotRadius = radius * 0.42;
    final ringWidth = radius * 0.14;
    final ringPaint = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.fill;
    canvas.drawCircle(center, dotRadius + ringWidth, ringPaint);

    // Solid blue dot in the centre.
    final dotPaint = Paint()
      ..color = color
      ..style = PaintingStyle.fill;
    canvas.drawCircle(center, dotRadius, dotPaint);
  }

  @override
  bool shouldRepaint(_MapMarkerPainter oldDelegate) => oldDelegate.color != color;
}
