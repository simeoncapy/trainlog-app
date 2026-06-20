import 'package:flutter/material.dart';

import 'package:trainlog_app/features/ranking/ranking_type.dart';
import 'package:trainlog_app/l10n/app_localizations.dart';
import 'package:trainlog_app/platform/widget/adaptive_popup.dart';
import 'package:trainlog_app/providers/ranking_provider.dart';

/// Filter row beneath the user-position block: unit dropdown (Distance / Trips),
/// an alphabetical toggle and an order-direction toggle. Styling matches the
/// Statistics feature's compact outlined controls.
class RankingFilterControls extends StatelessWidget {
  final RankingProvider provider;

  const RankingFilterControls({super.key, required this.provider});

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context)!;

    return Row(
      children: [
        // Sorting unit — hidden for world-squares (percentage only).
        if (provider.showsUnitDropdown)
          Expanded(
            child: _UnitDropdown(
              selected: provider.sortUnit,
              onChanged: (u) => provider.sortUnit = u,
            ),
          )
        else
          const Spacer(),
        const SizedBox(width: 10),
        // Icon + tooltip show the action the tap will perform, not the
        // current state.
        _IconToggle(
          active: provider.alphabetical,
          icon: provider.alphabetical ? Icons.tag : Icons.sort_by_alpha,
          tooltip: provider.alphabetical
              ? loc.rankingSortByValue
              : loc.rankingSortAlphabetical,
          onTap: provider.toggleAlphabetical,
        ),
        const SizedBox(width: 8),
        _IconToggle(
          active: false,
          icon: provider.descending
              ? Icons.arrow_upward
              : Icons.arrow_downward,
          tooltip: provider.descending
              ? loc.rankingOrderAscending
              : loc.rankingOrderDescending,
          onTap: provider.toggleDirection,
        ),
      ],
    );
  }
}

class _UnitDropdown extends StatelessWidget {
  final RankingSortUnit selected;
  final ValueChanged<RankingSortUnit> onChanged;

  const _UnitDropdown({required this.selected, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return AdaptivePopup<RankingSortUnit>(
      initialValue: selected,
      onSelected: onChanged,
      items: RankingSortUnit.values
          .map(
            (u) => AdaptivePopupItem(
              value: u,
              label: u.label(context),
              leading: IconTheme(
                data: IconThemeData(size: 18, color: cs.primary),
                child: u.icon,
              ),
            ),
          )
          .toList(),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: cs.outline.withValues(alpha: 0.4),
            width: 1.2,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            IconTheme(
              data: IconThemeData(size: 18, color: cs.primary),
              child: selected.icon,
            ),
            const SizedBox(width: 6),
            Flexible(
              child: Text(
                selected.label(context),
                style: Theme.of(context).textTheme.labelLarge?.copyWith(
                      color: cs.onSurface,
                      fontWeight: FontWeight.w500,
                    ),
                overflow: TextOverflow.ellipsis,
                maxLines: 1,
              ),
            ),
            const SizedBox(width: 3),
            Icon(Icons.keyboard_arrow_down,
                size: 18, color: cs.onSurfaceVariant),
          ],
        ),
      ),
    );
  }
}

class _IconToggle extends StatelessWidget {
  final bool active;
  final IconData icon;
  final String tooltip;
  final VoidCallback onTap;

  const _IconToggle({
    required this.active,
    required this.icon,
    required this.tooltip,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Tooltip(
      message: tooltip,
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.all(9),
          decoration: BoxDecoration(
            color: active ? cs.primary.withValues(alpha: 0.15) : null,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(
              color: active
                  ? cs.primary.withValues(alpha: 0.6)
                  : cs.outline.withValues(alpha: 0.4),
              width: 1.2,
            ),
          ),
          child: Icon(icon, size: 18, color: cs.primary),
        ),
      ),
    );
  }
}
