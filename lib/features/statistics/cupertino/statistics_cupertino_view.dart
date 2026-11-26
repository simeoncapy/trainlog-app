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
import 'package:trainlog_app/ui/cupertino/liquid_glass.dart';
import 'package:trainlog_app/ui/tokens/app_colors.dart';
import 'package:trainlog_app/ui/tokens/app_theme.dart';
import 'package:trainlog_app/utils/map_color_palette.dart';
import 'package:trainlog_app/utils/number_formatter.dart';

/// The Statistics page on iOS: a large title with the filter and sort
/// menus, the view's segmented control (icons only) at full width, the
/// dimension as the chart's heading menu, the total with the active filters
/// under it, then the chart on a rounded card.
class StatisticsCupertinoView extends StatelessWidget {
  const StatisticsCupertinoView({super.key});

  @override
  Widget build(BuildContext context) {
    final media = MediaQuery.of(context);
    return ListView(
      padding: EdgeInsets.only(bottom: media.padding.bottom + 24),
      children: const [
        _TitleBar(),
        _ViewSegments(),
        SizedBox(height: 18),
        _DimensionHeading(),
        SizedBox(height: 6),
        _TotalFigure(),
        SizedBox(height: 12),
        _ChartCard(),
      ],
    );
  }
}

/// "Statistics" in the large-title style, with the filter menu (year, mode,
/// unit) and the sort menu grouped in a glass capsule. The pie keeps its own
/// order, so it has no sort.
class _TitleBar extends StatelessWidget {
  const _TitleBar();

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context)!;
    final controller = context.watch<StatisticsController>();
    final filters = _filterSections(context);
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
              GlassButtonGroup(
                children: [
                  GlassMenuGroupItem(
                    icon: CupertinoIcons.line_horizontal_3_decrease,
                    semanticLabel: loc.filterButton,
                    sections: filters,
                  ),
                  GlassMenuGroupItem(
                    icon: CupertinoIcons.arrow_up_arrow_down,
                    semanticLabel: loc.rankingSortMenu,
                    sections: _sortSections(loc, controller),
                  ),
                ],
              )
            else
              GlassMenuIconButton(
                icon: CupertinoIcons.line_horizontal_3_decrease,
                semanticLabel: loc.filterButton,
                sections: filters,
              ),
          ],
        ),
      ),
    );
  }

  List<AppMenuSection> _sortSections(
    AppLocalizations loc,
    StatisticsController controller,
  ) => [
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
  ];

  /// Year, mode and unit, each a submenu showing its current choice. The
  /// "Years" dimension spans every year, so it has no year filter.
  List<AppMenuSection> _filterSections(BuildContext context) {
    final loc = AppLocalizations.of(context)!;
    final statsProv = context.watch<StatisticsProvider>();
    final years = context.watch<TripsProvider>().years;
    final vehicles = context.watch<TripsProvider>().vehicleTypesWithoutPoi;
    final palette = MapColorPaletteHelper.getPalette(
      context.watch<SettingsProvider>().mapColorPalette,
    );
    final label = CupertinoColors.label.resolveFrom(context);
    final year = statsProv.year ?? 0;
    final vehicle = statsProv.vehicle;
    Color vehicleColor(VehicleType? v) => v == null ? label : palette[v] ?? label;
    Widget icon(IconData? data, [Color? color]) =>
        Icon(data, size: 18, color: color ?? label);

    return [
      AppMenuSection(
        entries: [
          if (statsProv.graph != GraphType.years)
            AppMenuEntry.submenu(
              label: loc.statisticsFilterYear,
              subtitle: _yearLabel(loc, year),
              leading: icon(CupertinoIcons.calendar),
              submenu: [
                AppMenuSection(
                  entries: [
                    for (final y in [0, ...years])
                      AppMenuEntry(
                        label: _yearLabel(loc, y),
                        checked: y == year,
                        onTap: () => statsProv.year = y,
                      ),
                  ],
                ),
              ],
            ),
          AppMenuEntry.submenu(
            label: loc.statisticsFilterMode,
            subtitle: _vehicleLabel(context, vehicle),
            leading: icon(statisticsVehicleIcon(vehicle).icon, vehicleColor(vehicle)),
            submenu: [
              AppMenuSection(
                entries: [
                  for (final v in <VehicleType?>[null, ...vehicles])
                    AppMenuEntry(
                      label: _vehicleLabel(context, v),
                      checked: v == vehicle,
                      leading: icon(statisticsVehicleIcon(v).icon, vehicleColor(v)),
                      onTap: () => statsProv.vehicle = v,
                    ),
                ],
              ),
            ],
          ),
          AppMenuEntry.submenu(
            label: loc.statisticsFilterUnit,
            subtitle: statsProv.unit.label(context),
            leading: icon(statsProv.unit.icon().icon),
            submenu: [
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
        ],
      ),
    ];
  }
}

String _yearLabel(AppLocalizations loc, int year) =>
    year == 0 ? loc.tripsFilterAllYears : year.toString();

String _vehicleLabel(BuildContext context, VehicleType? v) => v == null
    ? AppLocalizations.of(context)!.statisticsAllVehicles
    : VehicleType.labelOf(v, context);

/// Bars, pie or table: an icon-only segmented control at full width.
class _ViewSegments extends StatelessWidget {
  const _ViewSegments();

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context)!;
    final controller = context.watch<StatisticsController>();
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: AppStepsTabBar(
        fullWidth: true,
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
    );
  }
}

/// The dimension (Operator, Country…) as the chart's heading, opening a
/// menu of the other dimensions.
class _DimensionHeading extends StatelessWidget {
  const _DimensionHeading();

  @override
  Widget build(BuildContext context) {
    final statsProv = context.watch<StatisticsProvider>();
    final label = statsProv.graph.label(context, statsProv.vehicle);
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Align(
        alignment: Alignment.centerLeft,
        child: GlassMenuHeading(
          label: label,
          semanticLabel: label,
          style: AppTheme.displayFont.copyWith(
            fontSize: Theme.of(context).textTheme.titleLarge?.fontSize,
            color: AppColors.amber,
          ),
          sections: [
            AppMenuSection(
              entries: [
                for (final g in GraphType.values)
                  AppMenuEntry(
                    label: g.label(context, statsProv.vehicle),
                    checked: g == statsProv.graph,
                    leading: Icon(
                      g.icon().icon,
                      size: 18,
                      color: CupertinoColors.label.resolveFrom(context),
                    ),
                    onTap: () => statsProv.graph = g,
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

/// The total as a large figure, with the unit scale behind an info button
/// for the units shortened to k/M/G (distance, CO2), and the active filters
/// in a grey line under it.
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
              Flexible(
                child: Text(
                  statsProv.isLoading ? '–' : statsProv.totalFormatted(context),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: AppTheme.monoFont.copyWith(
                    fontSize: text.headlineSmall?.fontSize,
                    fontWeight: FontWeight.w700,
                    color: CupertinoColors.label.resolveFrom(context),
                  ),
                ),
              ),
              if (showUnits)
                CupertinoButton(
                  padding: const EdgeInsets.only(left: 6),
                  minimumSize: const Size(28, 28),
                  onPressed: () => _showUnits(context, units),
                  child: Icon(
                    CupertinoIcons.info_circle,
                    size: 18,
                    color: CupertinoTheme.of(context).primaryColor,
                  ),
                ),
            ],
          ),
          const SizedBox(height: 2),
          Text(
            [
              if (statsProv.graph != GraphType.years)
                _yearLabel(loc, statsProv.year ?? 0),
              _vehicleLabel(context, statsProv.vehicle),
              statsProv.unit.label(context),
            ].join(' · '),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: text.bodyMedium?.copyWith(color: secondary, letterSpacing: 0),
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
