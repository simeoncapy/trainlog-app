import 'package:flutter/material.dart';

import 'package:trainlog_app/l10n/app_localizations.dart';
import 'package:trainlog_app/widgets/icon_toggle_button.dart';

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
