import 'package:flutter/material.dart';

import 'package:trainlog_app/app/theme/app_colors.dart';

/// Linear coverage bar shown beneath a username on the drill-down ranking page.
///
/// Uses the same colour rule as [CoverageProgressRing]: a solid green
/// ([AppColors.early]) fill at 100%, otherwise a primary-themed fill matching
/// the completion ratio over a faint track.
class CoverageProgressBar extends StatelessWidget {
  /// Coverage in the 0–100 range.
  final double percent;
  final double height;

  const CoverageProgressBar({
    super.key,
    required this.percent,
    this.height = 6,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final isComplete = percent >= 100.0 - 1e-9;
    final color = isComplete ? AppColors.early : cs.primary;
    final fraction = (percent / 100).clamp(0.0, 1.0);

    return ClipRRect(
      borderRadius: BorderRadius.circular(height),
      child: Stack(
        children: [
          Container(
            height: height,
            color: cs.onSurface.withValues(alpha: 0.10),
          ),
          FractionallySizedBox(
            widthFactor: fraction,
            child: Container(height: height, color: color),
          ),
        ],
      ),
    );
  }
}
