import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart' show Theme;
import 'package:provider/provider.dart';

import 'package:trainlog_app/core/data/models/trips.dart';
import 'package:trainlog_app/core/providers/settings_provider.dart';
import 'package:trainlog_app/core/providers/statistics_provider.dart';
import 'package:trainlog_app/core/providers/trips_provider.dart';
import 'package:trainlog_app/features/statistics/statistics_chart.dart';
import 'package:trainlog_app/features/statistics/statistics_controller.dart';
import 'package:trainlog_app/features/statistics/statistics_graph_images.dart';
import 'package:trainlog_app/l10n/app_localizations.dart';
import 'package:trainlog_app/ui/adaptive/adaptive_dialog.dart';
import 'package:trainlog_app/ui/adaptive/app_steps_tab_bar.dart';
import 'package:trainlog_app/ui/cupertino/glass_menu_parts.dart';
import 'package:trainlog_app/ui/tokens/app_theme.dart';
import 'package:trainlog_app/utils/map_color_palette.dart';
import 'package:trainlog_app/utils/number_formatter.dart';

/// The Statistics page on iOS: a large title, the dimension menu beside the
/// view's segmented control, the year, vehicle and unit menus, the total as a captioned figure, then the
/// chart on a rounded card.
class StatisticsCupertinoView extends StatelessWidget {
  const StatisticsCupertinoView({super.key});

  @override
  Widget build(BuildContext context) {
    final media = MediaQuery.of(context);
    return ListView(
      padding: EdgeInsets.only(bottom: media.padding.bottom + 24),
      children: const [
        _TitleBar(),
        _DimensionAndViewRow(),
        SizedBox(height: 10),
        _FiltersRow(),
        SizedBox(height: 18),
        _TotalFigure(),
        SizedBox(height: 12),
        _ChartCard(),
      ],
    );
  }
}

/// "Statistics" in the large-title style, with the round sort menu trailing
/// (not on the pie, which keeps its own order).
class _TitleBar extends StatelessWidget {
  const _TitleBar();

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context)!;
    final controller = context.watch<StatisticsController>();
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 6, 16, 10),
      child: SizedBox(
        height: 48,
        child: Row(
          children: [
            Expanded(
              child: Text(
                loc.statisticsTitle,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: CupertinoTheme.of(context).textTheme.navLargeTitleTextStyle,
              ),
            ),
            if (controller.canSort)
              GlassMenuIconButton(
                icon: CupertinoIcons.arrow_up_arrow_down,
                semanticLabel: loc.rankingSortAlphabetical,
                sections: [
                  AppMenuSection(
                    entries: [
                      AppMenuEntry(
                        label: loc.rankingSortByValue,
                        checked: !controller.sortedAlpha,
                        onTap: () => controller.sortedAlpha = false,
                      ),
                      AppMenuEntry(
                        label: loc.rankingSortAlphabetical,
                        checked: controller.sortedAlpha,
                        onTap: () => controller.sortedAlpha = true,
                      ),
                    ],
                  ),
                ],
              ),
          ],
        ),
      ),
    );
  }
}

/// The year menu; disabled for the "Years" dimension, which spans every
/// year.
class _YearCapsule extends StatelessWidget {
  const _YearCapsule();

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context)!;
    final statsProv = context.watch<StatisticsProvider>();
    final years = context.watch<TripsProvider>().years;
    final selected = statsProv.year ?? 0;
    final enabled = statsProv.graph != GraphType.years;
    String labelOf(int y) => y == 0 ? loc.tripsFilterAllYears : y.toString();

    return IgnorePointer(
      ignoring: !enabled,
      child: Opacity(
        opacity: enabled ? 1 : 0.4,
        child: GlassMenuCapsule(
          label: labelOf(selected),
          selected: false,
          leading: CupertinoIcons.calendar,
          semanticLabel: loc.tripsFilterAllYears,
          menuWidth: 220,
          sections: [
            AppMenuSection(
              entries: [
                for (final y in [0, ...years])
                  AppMenuEntry(
                    label: labelOf(y),
                    checked: y == selected,
                    onTap: () => statsProv.year = y,
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

/// The dimension menu (Operator, Country…) and the bar / pie / table
/// segmented control (icons only) on one line.
class _DimensionAndViewRow extends StatelessWidget {
  const _DimensionAndViewRow();

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context)!;
    final statsProv = context.watch<StatisticsProvider>();
    final controller = context.watch<StatisticsController>();

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        children: [
          Flexible(
            child: GlassMenuCapsule(
              label: statsProv.graph.label(context, statsProv.vehicle),
              selected: false,
              leading: statsProv.graph.icon().icon,
              semanticLabel: statsProv.graph.label(context, statsProv.vehicle),
              sections: [
                AppMenuSection(
                  entries: [
                    for (final g in GraphType.values)
                      AppMenuEntry(
                        label: g.label(context, statsProv.vehicle),
                        checked: g == statsProv.graph,
                        onTap: () => statsProv.graph = g,
                      ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          AppStepsTabBar(
            selectedIndex: controller.view.index,
            onTabChanged: (i) => controller.view = StatisticsView.values[i],
            tabs: [
              AppStepsTab(
                label: loc.statisticsViewBar,
                iconOnly: true,
                leadingIcon: const Icon(CupertinoIcons.chart_bar_alt_fill),
              ),
              AppStepsTab(
                label: loc.statisticsViewPie,
                iconOnly: true,
                leadingIcon: const Icon(CupertinoIcons.chart_pie_fill),
              ),
              AppStepsTab(
                label: loc.statisticsViewTable,
                iconOnly: true,
                leadingIcon: const Icon(CupertinoIcons.table),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

/// The year, vehicle and unit menus, scrolling sideways when they do not
/// fit.
class _FiltersRow extends StatelessWidget {
  const _FiltersRow();

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context)!;
    final statsProv = context.watch<StatisticsProvider>();
    final vehicles = context.watch<TripsProvider>().vehicleTypesWithoutPoi;
    final palette = MapColorPaletteHelper.getPalette(
      context.watch<SettingsProvider>().mapColorPalette,
    );
    final label = CupertinoColors.label.resolveFrom(context);
    final vehicle = statsProv.vehicle;
    String vehicleLabel(VehicleType? v) =>
        v == null ? loc.statisticsAllVehicles : VehicleType.labelOf(v, context);
    Color vehicleColor(VehicleType? v) => v == null ? label : palette[v] ?? label;

    final capsules = [
      const _YearCapsule(),
      GlassMenuCapsule(
        label: vehicleLabel(vehicle),
        selected: false,
        leading: statisticsVehicleIcon(vehicle).icon,
        leadingColor: vehicleColor(vehicle),
        semanticLabel: vehicleLabel(vehicle),
        sections: [
          AppMenuSection(
            entries: [
              for (final v in <VehicleType?>[null, ...vehicles])
                AppMenuEntry(
                  label: vehicleLabel(v),
                  checked: v == vehicle,
                  leading: Icon(
                    statisticsVehicleIcon(v).icon,
                    size: 18,
                    color: vehicleColor(v),
                  ),
                  onTap: () => statsProv.vehicle = v,
                ),
            ],
          ),
        ],
      ),
      GlassMenuCapsule(
        label: statsProv.unit.label(context),
        selected: false,
        leading: statsProv.unit.icon().icon,
        semanticLabel: statsProv.unit.label(context),
        menuWidth: 200,
        sections: [
          AppMenuSection(
            entries: [
              for (final u in GraphUnit.values)
                AppMenuEntry(
                  label: u.label(context),
                  checked: u == statsProv.unit,
                  onTap: () => statsProv.unit = u,
                ),
            ],
          ),
        ],
      ),
    ];

    return SizedBox(
      height: 44,
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        child: Row(spacing: 8, children: capsules),
      ),
    );
  }
}

/// The total as a captioned figure, with the unit scale behind an info
/// button for the units shortened to k/M/G (distance, CO2).
class _TotalFigure extends StatelessWidget {
  const _TotalFigure();

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context)!;
    final statsProv = context.watch<StatisticsProvider>();
    final secondary = CupertinoColors.secondaryLabel.resolveFrom(context);
    final text = Theme.of(context).textTheme;
    final units = statsProv.unitsByFactor(context);
    final showUnits =
        statsProv.unit != GraphUnit.trip && statsProv.unit != GraphUnit.duration && units != null;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(
                loc.statisticsTotalLabel,
                style: text.bodySmall?.copyWith(color: secondary, letterSpacing: 0),
              ),
              if (showUnits)
                CupertinoButton(
                  padding: const EdgeInsets.only(left: 4),
                  minimumSize: const Size(28, 20),
                  onPressed: () => _showUnits(context, units),
                  child: Icon(
                    CupertinoIcons.info_circle,
                    size: 15,
                    color: CupertinoTheme.of(context).primaryColor,
                  ),
                ),
            ],
          ),
          Text(
            statsProv.isLoading ? '–' : statsProv.totalFormatted(context),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: AppTheme.monoFont.copyWith(
              fontSize: text.headlineSmall?.fontSize,
              fontWeight: FontWeight.w700,
              color: CupertinoColors.label.resolveFrom(context),
            ),
          ),
        ],
      ),
    );
  }

  void _showUnits(BuildContext context, Map<UnitFactor, String> units) {
    final loc = AppLocalizations.of(context)!;
    final base = units[UnitFactor.base]!;
    final lines = [
      for (final f in UnitFactor.values.where((f) => f != UnitFactor.base))
        '1 ${units[f]} = ${formatNumber(context, f.multiplier, noDecimal: true)} $base',
    ];
    AdaptiveDialog.show(
      context: context,
      title: loc.statisticsUnitLabel.replaceAll(RegExp(r'\s*:\s*$'), ''),
      message: lines.join('\n'),
    );
  }
}

/// The chart on a rounded surface card, without border or shadow.
class _ChartCard extends StatelessWidget {
  const _ChartCard();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: DecoratedBox(
        decoration: ShapeDecoration(
          color: Theme.of(context).colorScheme.surface,
          shape: const RoundedSuperellipseBorder(
            borderRadius: BorderRadius.all(Radius.circular(26)),
          ),
        ),
        child: const Padding(
          padding: EdgeInsets.fromLTRB(12, 16, 12, 12),
          child: StatisticsChart(),
        ),
      ),
    );
  }
}
