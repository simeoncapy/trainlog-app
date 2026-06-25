import 'package:flutter/material.dart';

import 'package:trainlog_app/l10n/app_localizations.dart';

/// The inline sorting toggles shared by the Railway Coverage list views and the
/// drill-down page: an Alphabetical/Value toggle and an Ascending/Descending
/// toggle. Styling matches the Ranking feature's compact outlined controls.
///
/// When [enabled] is false the controls are greyed out and non-interactive
/// (used on the Regions tab before a country is picked).
class CoverageSortControls extends StatelessWidget {
  final bool alphabetical;
  final bool descending;
  final bool enabled;
  final VoidCallback onToggleAlphabetical;
  final VoidCallback onToggleDirection;

  const CoverageSortControls({
    super.key,
    required this.alphabetical,
    required this.descending,
    required this.onToggleAlphabetical,
    required this.onToggleDirection,
    this.enabled = true,
  });

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context)!;

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        _IconToggle(
          active: alphabetical,
          enabled: enabled,
          icon: alphabetical ? Icons.tag : Icons.sort_by_alpha,
          tooltip: alphabetical
              ? loc.rankingSortByValue
              : loc.rankingSortAlphabetical,
          onTap: onToggleAlphabetical,
        ),
        const SizedBox(width: 8),
        _IconToggle(
          active: false,
          enabled: enabled,
          icon: descending ? Icons.arrow_upward : Icons.arrow_downward,
          tooltip: descending
              ? loc.rankingOrderAscending
              : loc.rankingOrderDescending,
          onTap: onToggleDirection,
        ),
      ],
    );
  }
}

class _IconToggle extends StatelessWidget {
  final bool active;
  final bool enabled;
  final IconData icon;
  final String tooltip;
  final VoidCallback onTap;

  const _IconToggle({
    required this.active,
    required this.enabled,
    required this.icon,
    required this.tooltip,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final cardColor = isDark ? cs.surface : Colors.white;

    return Opacity(
      opacity: enabled ? 1 : 0.4,
      child: Tooltip(
        message: tooltip,
        child: GestureDetector(
          onTap: enabled ? onTap : null,
          child: Container(
            padding: const EdgeInsets.all(9),
            decoration: BoxDecoration(
              color: active ? cs.primary.withValues(alpha: 0.15) : cardColor,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(
                color: active
                    ? cs.primary.withValues(alpha: 0.6)
                    : cs.outlineVariant.withValues(alpha: 0.4),
                width: 1.2,
              ),
            ),
            child: Icon(icon, size: 18, color: cs.primary),
          ),
        ),
      ),
    );
  }
}
