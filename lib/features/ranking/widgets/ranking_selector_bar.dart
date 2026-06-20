import 'package:flutter/material.dart';

import 'package:trainlog_app/features/ranking/ranking_type.dart';

/// Horizontally scrollable category selector ("pills").
///
/// Implemented categories are tappable; the rest are shown disabled (greyed
/// out, non-interactive) so users can see what is coming.
class RankingSelectorBar extends StatelessWidget {
  final RankingSelection selected;
  final ValueChanged<RankingSelection> onSelected;

  const RankingSelectorBar({
    super.key,
    required this.selected,
    required this.onSelected,
  });

  @override
  Widget build(BuildContext context) {
    final pills = buildRankingPills();

    return SizedBox(
      height: 44,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        itemCount: pills.length,
        separatorBuilder: (_, __) => const SizedBox(width: 10),
        itemBuilder: (context, i) {
          final pill = pills[i];
          return _Pill(
            selection: pill,
            selected: pill == selected,
            enabled: pill.type.isImplemented,
            onTap: () => onSelected(pill),
          );
        },
      ),
    );
  }
}

class _Pill extends StatelessWidget {
  final RankingSelection selection;
  final bool selected;
  final bool enabled;
  final VoidCallback onTap;

  const _Pill({
    required this.selection,
    required this.selected,
    required this.enabled,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    final Color bg;
    final Color fg;
    final Color accent;
    if (selected) {
      bg = cs.inverseSurface;
      fg = cs.onInverseSurface;
      accent = selection.accentColor;
    } else if (enabled) {
      bg = cs.surface;
      fg = cs.onSurface;
      accent = selection.accentColor;
    } else {
      bg = cs.surface.withValues(alpha: 0.5);
      fg = cs.onSurfaceVariant.withValues(alpha: 0.5);
      accent = cs.onSurfaceVariant.withValues(alpha: 0.4);
    }

    return Opacity(
      opacity: enabled ? 1 : 0.6,
      child: Material(
        color: bg,
        borderRadius: BorderRadius.circular(22),
        child: InkWell(
          borderRadius: BorderRadius.circular(22),
          onTap: enabled ? onTap : null,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(22),
              border: Border.all(
                color: selected
                    ? Colors.transparent
                    : cs.outline.withValues(alpha: 0.3),
                width: 1.2,
              ),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                IconTheme(
                  data: IconThemeData(size: 16, color: accent),
                  child: selection.icon,
                ),
                const SizedBox(width: 8),
                Text(
                  selection.label(context),
                  style: Theme.of(context).textTheme.labelLarge?.copyWith(
                        color: fg,
                        fontWeight: FontWeight.w700,
                      ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
