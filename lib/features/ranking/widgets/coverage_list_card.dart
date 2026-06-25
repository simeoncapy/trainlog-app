import 'package:flutter/material.dart';

/// Unified rounded card background used by the Railway Coverage list views and
/// the drill-down page, matching the Ranking list card (border + soft shadow,
/// theme-aware surface). Rows are laid out by the caller with hairline dividers.
class CoverageListCard extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry margin;

  const CoverageListCard({
    super.key,
    required this.child,
    this.margin = const EdgeInsets.fromLTRB(16, 0, 16, 12),
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      margin: margin,
      decoration: BoxDecoration(
        color: isDark ? cs.surface : Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: isDark
              ? Colors.transparent
              : cs.outline.withValues(alpha: 0.18),
          width: 1.2,
        ),
        boxShadow: [
          BoxShadow(
            color: cs.shadow.withValues(alpha: isDark ? 0.25 : 0.06),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(18),
        child: child,
      ),
    );
  }
}
