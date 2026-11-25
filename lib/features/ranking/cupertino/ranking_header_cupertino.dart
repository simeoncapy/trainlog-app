import 'package:flutter/cupertino.dart';
import 'package:provider/provider.dart';

import 'package:trainlog_app/core/data/models/trips.dart';
import 'package:trainlog_app/core/providers/ranking_provider.dart';
import 'package:trainlog_app/core/providers/settings_provider.dart';
import 'package:trainlog_app/features/ranking/ranking_type.dart';
import 'package:trainlog_app/l10n/app_localizations.dart';
import 'package:trainlog_app/ui/cupertino/glass_filter_parts.dart';
import 'package:trainlog_app/ui/cupertino/glass_menu_parts.dart';
import 'package:trainlog_app/utils/map_color_palette.dart';

/// The sort menu of the ranking pages: by value or alphabetically, then the
/// order.
List<AppMenuSection> rankingSortSections(
  AppLocalizations loc, {
  required bool alphabetical,
  required bool descending,
  required VoidCallback toggleAlphabetical,
  required VoidCallback toggleDirection,
}) {
  return [
    AppMenuSection(
      entries: [
        AppMenuEntry(
          label: loc.rankingSortByValue,
          checked: !alphabetical,
          onTap: () {
            if (alphabetical) toggleAlphabetical();
          },
        ),
        AppMenuEntry(
          label: loc.rankingSortAlphabetical,
          checked: alphabetical,
          onTap: () {
            if (!alphabetical) toggleAlphabetical();
          },
        ),
      ],
    ),
    AppMenuSection(
      entries: [
        AppMenuEntry(
          label: loc.rankingOrderDescending,
          checked: descending,
          onTap: () {
            if (!descending) toggleDirection();
          },
        ),
        AppMenuEntry(
          label: loc.rankingOrderAscending,
          checked: !descending,
          onTap: () {
            if (descending) toggleDirection();
          },
        ),
      ],
    ),
  ];
}

/// The page title in the iOS large-title style (as the shell draws it for
/// the other tabs), with the page's glass buttons on the trailing side.
class RankingTitleBar extends StatelessWidget {
  const RankingTitleBar({
    super.key,
    required this.title,
    this.actions,
    this.leading,
  });

  final String title;
  final Widget? actions;

  /// Before the title, e.g. an area's flag.
  final Widget? leading;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 6, 16, 10),
      child: SizedBox(
        height: 48,
        child: Row(
          children: [
            if (leading != null) ...[leading!, const SizedBox(width: 10)],
            Expanded(
              child: Text(
                title,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: CupertinoTheme.of(
                  context,
                ).textTheme.navLargeTitleTextStyle,
              ),
            ),
            if (actions != null) actions!,
          ],
        ),
      ),
    );
  }
}

/// The leaderboard categories as capsules scrolling sideways, the selected
/// one filled with its colour. The vehicles share one capsule opening a
/// Liquid Glass menu; it shows the chosen vehicle once one is picked.
class RankingCategoryCapsules extends StatelessWidget {
  const RankingCategoryCapsules({super.key});

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context)!;
    final provider = context.watch<RankingProvider>();
    final selected = provider.selection;
    final palette = MapColorPaletteHelper.getPalette(
      context.watch<SettingsProvider>().mapColorPalette,
    );
    final pills = buildRankingPills();
    final vehicles = pills.where((p) => p.isVehicle).toList();

    final children = <Widget>[];
    var vehiclesAdded = false;
    for (final pill in pills) {
      if (pill.isVehicle) {
        if (vehiclesAdded) continue;
        vehiclesAdded = true;
        children.add(
          GlassMenuCapsule(
            label: selected.isVehicle
                ? selected.label(context)
                : loc.rankingTypeVehicles,
            selected: selected.isVehicle,
            selectedColor: selected.isVehicle
                ? selected.accentColor(palette)
                : null,
            semanticLabel: loc.rankingTypeVehicles,
            sections: [
              AppMenuSection(
                entries: [
                  for (final v in vehicles)
                    AppMenuEntry(
                      label: v.label(context),
                      checked: v == selected,
                      trailing: Icon(
                        VehicleType.iconOf(v.vehicle!).icon,
                        size: 18,
                        color: v.accentColor(palette),
                      ),
                      onTap: () => provider.select(v),
                    ),
                ],
              ),
            ],
          ),
        );
        continue;
      }
      children.add(
        FilterCapsule(
          label: pill.label(context),
          selected: pill == selected,
          selectedColor: pill.accentColor(palette),
          onTap: () => provider.select(pill),
        ),
      );
    }

    return SizedBox(
      height: FilterCapsule.height,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        clipBehavior: Clip.none,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        itemCount: children.length,
        separatorBuilder: (_, _) => const SizedBox(width: 8),
        itemBuilder: (_, i) => Center(child: children[i]),
      ),
    );
  }
}
