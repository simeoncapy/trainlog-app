import 'package:flutter/material.dart';

import 'package:trainlog_app/features/ranking/ranking_type.dart';
import 'package:trainlog_app/l10n/app_localizations.dart';
import 'package:trainlog_app/platform/widget/adaptive_popup.dart';
import 'package:trainlog_app/providers/ranking_provider.dart';
import 'package:trainlog_app/widgets/icon_toggle_button.dart';

/// Filter row beneath the user-position block: unit dropdown (Distance / Trips),
/// an alphabetical toggle and an order-direction toggle. Styling matches the
/// Statistics feature's compact outlined controls.
class RankingFilterControls extends StatelessWidget {
  final RankingProvider provider;

  const RankingFilterControls({super.key, required this.provider});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        // Sorting unit — hidden for world-squares (percentage only).
        if (provider.showsUnitDropdown)
          Expanded(
            child: _UnitDropdown(
              items: provider.availableUnits,
              selected: provider.sortUnit,
              onChanged: (u) => provider.sortUnit = u,
            ),
          )
        else
          const Spacer(),
        const SizedBox(width: 10),
        RankingSortButtons(
          alphabetical: provider.alphabetical,
          descending: provider.descending,
          onToggleAlphabetical: provider.toggleAlphabetical,
          onToggleDirection: provider.toggleDirection,
        ),
      ],
    );
  }
}

/// The two compact sorting toggles shared across the ranking screens:
/// an Alphabetical/Value toggle and an Ascending/Descending toggle. The icon and
/// tooltip show the action the tap will perform, not the current state.
///
/// When [enabled] is false both toggles are dimmed and non-interactive (e.g. on
/// the railway-coverage Regions tab before a country is picked).
class RankingSortButtons extends StatelessWidget {
  final bool alphabetical;
  final bool descending;
  final bool enabled;
  final VoidCallback onToggleAlphabetical;
  final VoidCallback onToggleDirection;

  const RankingSortButtons({
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
        IconToggleButton(
          active: alphabetical,
          enabled: enabled,
          icon: alphabetical ? Icons.tag : Icons.sort_by_alpha,
          tooltip: alphabetical
              ? loc.rankingSortByValue
              : loc.rankingSortAlphabetical,
          onTap: onToggleAlphabetical,
        ),
        const SizedBox(width: 8),
        IconToggleButton(
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

class _UnitDropdown extends StatelessWidget {
  final List<RankingSortUnit> items;
  final RankingSortUnit selected;
  final ValueChanged<RankingSortUnit> onChanged;

  const _UnitDropdown({
    required this.items,
    required this.selected,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return AdaptivePopup<RankingSortUnit>(
      initialValue: selected,
      onSelected: onChanged,
      items: items
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
          color: isDark ? cs.surface : Colors.white,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: cs.outlineVariant.withValues(alpha: 0.4),
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

