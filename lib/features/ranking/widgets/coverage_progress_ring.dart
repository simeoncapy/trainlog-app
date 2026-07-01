import 'dart:math' as math;

import 'package:flutter/material.dart';

import 'package:trainlog_app/app/theme/app_theme.dart';
import 'package:trainlog_app/app/theme/app_colors.dart';
import 'package:trainlog_app/utils/number_formatter.dart';

/// Circular coverage indicator used in the Countries / Regions list rows.
///
/// Always rendered as a ring: a primary-themed arc sector matching the
/// completion ratio over a faint track, with the rounded percentage centered.
/// At exactly 100% the arc is a complete green ([AppColors.early]) ring.
class CoverageProgressRing extends StatelessWidget {
  /// Coverage in the 0–100 range.
  final double percent;
  final double size;

  const CoverageProgressRing({
    super.key,
    required this.percent,
    this.size = 46,
  });

  bool get _isComplete => percent >= 100.0 - 1e-9;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final color = _isComplete ? AppColors.early : cs.primary;
    final label = NumberFormatter.decimal(
      percent.round(),
      locale: Localizations.localeOf(context),
    );

    return SizedBox(
      width: size,
      height: size,
      child: CustomPaint(
        painter: _RingPainter(
          fraction: (percent / 100).clamp(0.0, 1.0),
          color: color,
          track: cs.onSurface.withValues(alpha: 0.10),
        ),
        child: Center(
          child: Text(
            label,
            style: AppTheme.monoFont.copyWith(
              fontSize: size * 0.30,
              fontWeight: FontWeight.w800,
              color: color,
            ),
          ),
        ),
      ),
    );
  }
}

class _RingPainter extends CustomPainter {
  final double fraction;
  final Color color;
  final Color track;

  _RingPainter({
    required this.fraction,
    required this.color,
    required this.track,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = size.center(Offset.zero);
    final radius = size.width / 2;

    final strokeWidth = size.width * 0.12;
    final r = radius - strokeWidth / 2;

    final trackPaint = Paint()
      ..color = track
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth;
    canvas.drawCircle(center, r, trackPaint);

    if (fraction <= 0) return;
    final arcPaint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round;
    canvas.drawArc(
      Rect.fromCircle(center: center, radius: r),
      -math.pi / 2,
      2 * math.pi * fraction,
      false,
      arcPaint,
    );
  }

  @override
  bool shouldRepaint(_RingPainter old) =>
      old.fraction != fraction || old.color != color || old.track != track;
}
