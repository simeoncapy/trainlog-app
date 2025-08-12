import 'dart:collection';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:trainlog_app/data/models/trips.dart';
import 'package:trainlog_app/l10n/app_localizations.dart';
import 'package:trainlog_app/providers/settings_provider.dart';
import 'package:trainlog_app/providers/trips_provider.dart';
import 'package:trainlog_app/utils/map_color_palette.dart';
import 'package:trainlog_app/utils/number_formatter.dart';
import 'package:trainlog_app/utils/statistics_calculator.dart';
import 'package:trainlog_app/widgets/logo_bar_chart.dart';
import 'package:trainlog_app/widgets/min_height_scrollable.dart';
import 'package:trainlog_app/widgets/statistics_type_selector.dart';
import 'package:trainlog_app/widgets/stats_pie_chart.dart';
import 'package:trainlog_app/widgets/stats_table_chart.dart';

enum GraphType {
  operator,
  country,
  years,
  material,
  itinerary,
  stations,
}

class StatisticsPage extends StatefulWidget {
  const StatisticsPage({super.key});

  @override
  State<StatisticsPage> createState() => _StatisticsPageState();
}

class _StatisticsPageState extends State<StatisticsPage> {
  bool _rotated = false;
  bool _sortedAlpha = false; // for the table
  bool _isParametersExpanded = true;
  StatisticsType _selectedStatistics = StatisticsType.bar;

  late List<int> listYears;  

  final _unitsDistance = {
    UnitFactor.base:  "km",
    UnitFactor.thousand: "Mm",
    UnitFactor.million:  "Gm",
    UnitFactor.billion:  "Tm",
  };

  @override
  void initState() {
    super.initState();
    listYears = [DateTime.now().year];
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      final tripsProvider = Provider.of<TripsProvider>(context, listen: false);
      if (tripsProvider.repository == null) {
        await tripsProvider.loadTrips();
      }
      final years = await tripsProvider.repository?.fetchListOfYears()?..sort((a, b) => b.compareTo(a));

      if (!mounted) return;
      setState(() {
        listYears = years ?? [DateTime.now().year];
      });
    });
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
  }

  String graphLabel(BuildContext context, GraphType type) {
    final loc = AppLocalizations.of(context)!;
    switch (type) {
      case GraphType.operator: return loc.graphTypeOperator;
      case GraphType.country:  return loc.graphTypeCountry;
      case GraphType.years:    return loc.graphTypeYears;
      case GraphType.material: return loc.graphTypeMaterial;
      case GraphType.itinerary:return loc.graphTypeItinerary;
      case GraphType.stations: return loc.graphTypeStations;
    }
  }

  Icon graphIcon(GraphType type) {
    switch (type) {
      case GraphType.operator: return const Icon(Icons.business);
      case GraphType.country: return const Icon(Icons.flag);
      case GraphType.years: return const Icon(Icons.calendar_today);
      case GraphType.material: return const Icon(Icons.train);
      case GraphType.itinerary: return const Icon(Icons.route);
      case GraphType.stations: return const Icon(Icons.villa);
    }
  }

  // Generic dropdown helper
  Widget buildDropdown<T>({
    required List<T> items,
    required T? selectedValue,
    required ValueChanged<T?> onChanged,
    required String Function(T item) labelOf,
    Icon? Function(T item)? iconOf,
    String hintText = 'Select an option',
    bool isExpanded = true,
  }) {
    return DropdownButton<T>(
      hint: Text(hintText),
      value: selectedValue,
      isExpanded: isExpanded,
      items: items.map((item) {
        return DropdownMenuItem<T>(
          value: item,
          child: Row(
            children: [
              if (iconOf != null) ...[
                iconOf(item) ?? const SizedBox.shrink(),
                const SizedBox(width: 8),
              ],
              Expanded(
                child: Text(
                  labelOf(item),
                  overflow: TextOverflow.ellipsis,
                  maxLines: 1,
                ),
              ),
            ],
          ),
        );
      }).toList(),
      onChanged: onChanged,
    );
  }

  @override
  Widget build(BuildContext context) {
    final tripsProv = context.watch<TripsProvider>();
    final repo = tripsProv.repository;
    if (repo == null) {
      return const Center(child: CircularProgressIndicator());
    }

    return ChangeNotifierProvider(
      // created once when inserted in the tree; .load() kicks off the async fetch
      create: (_) => StatisticsCalculator(repo, VehicleType.train, GraphType.operator, initialYear: 0)..load(),
      builder: (context, _) {
        final calc = context.watch<StatisticsCalculator>();
        final settings = context.watch<SettingsProvider>();
        final palette = MapColorPaletteHelper.getPalette(settings.mapColorPalette);
        final hasData = calc.currentStats.isNotEmpty && !calc.isLoading;
        final barColor = palette[calc.vehicle] ?? Colors.blue;

        return Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  StatisticsTypeSelector(
                    initialValue: StatisticsType.bar,
                    onChanged: (newType) {
                      setState(() {
                        _selectedStatistics = newType;
                      });
                    },
                  ),
                ],
              ),
              const SizedBox(height: 16,),
              _graphFilterExpansionBuilder(context),
              const SizedBox(height: 16),
              Expanded(
                child: MinHeightScrollable(
                  minHeight: 350,
                  child: Builder(
                    builder: (_) {
                      if (calc.isLoading) {
                        return const Center(child: CircularProgressIndicator());
                      }
                      if (calc.error != null) {
                        return Center(child: Text('Error: ${calc.error}'));
                      }
                      if (!hasData) {
                        return const Center(child: Text('No data'));
                      }

                      final stats = calc.currentStats;
                      final unitsTrips = {
                        UnitFactor.base:  AppLocalizations.of(context)!.statisticsTripsUnitBase,
                        UnitFactor.thousand: AppLocalizations.of(context)!.statisticsTripsUnitKilo,
                        UnitFactor.million:  AppLocalizations.of(context)!.statisticsTripsUnitMega,
                        UnitFactor.billion:  AppLocalizations.of(context)!.statisticsTripsUnitGiga,
                      };
                      final unit = calc.isDistance ? _unitsDistance[UnitFactor.base] : unitsTrips[UnitFactor.base];

                      switch (_selectedStatistics) {
                        case StatisticsType.bar:
                          return LayoutBuilder(
                            builder: (context, c) {
                              const minH = 350.0;
                              final h = math.max(minH, c.maxHeight.isFinite ? c.maxHeight : minH);
                              return SizedBox(
                                height: h, // <- finite height avoids ∞ in fl_chart
                                child: LogoBarChart(
                                  rotationQuarterTurns: !_rotated ? 1 : 0,
                                  images: List.generate(stats.length, (_) => const Icon(Icons.train)),
                                  values: stats.values.map((v) => v.past).toList(),
                                  strippedValues: stats.values.map((v) => v.future).toList(),
                                  valuesTitles: stats.keys.toList(),
                                  baseUnit: unit!,
                                  unitsByFactor: calc.isDistance ? _unitsDistance : unitsTrips,
                                  color: barColor,
                                  unitHelpTooltip: calc.isDistance ? _tooltipRich(_unitsDistance) : null,
                                ),
                              );
                            },
                          );

                        case StatisticsType.pie:
                          return StatsPieChart(
                            stats: stats,
                            interactive: false,
                            seedColor: barColor, // ties palette vibe to the chart
                            valueFormatter: (v) => formatNumber(context, v, noDecimal: false),
                            showLegend: true,
                            sectionsSpace: 2,
                            centerSpaceRadius: 36,
                          );

                        case StatisticsType.table:
                          return Column(
                            mainAxisSize: MainAxisSize.min,
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text("Unit: ${unit!}"),
                              const SizedBox(height: 8),

                              // ⬇️ the table
                              StatsTableChart(
                                stats: stats,
                                valueFormatter: (v) => formatNumber(context, v),
                                labelHeader: 'Operator',
                                pastHeader: AppLocalizations.of(context)!.yearPastList,
                                futureHeader: AppLocalizations.of(context)!.yearFutureList,
                                totalHeader: 'Total',
                                labelMaxWidth: 150,
                                labelMaxLines: 3,
                                compact: true,
                              ),
                            ],
                          );

                      }
                    },
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildTable( // TODO move to a separate widget?
    BuildContext context,
    LinkedHashMap<String, ({double past, double future})> stats,
  ) {
    final rows = stats.entries.toList();
    if (rows.isEmpty) return const Center(child: Text('No data'));

    String fmt(num v) => formatNumber(context, v, noDecimal: false);
    const double labelMaxWidth = 220;

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: DataTable(
        columns: const [
          DataColumn(label: Text('Label')),
          DataColumn(label: Text('Past')),
          DataColumn(label: Text('Future')),
          DataColumn(label: Text('Total')),
        ],
        rows: [
          for (final e in rows)
            DataRow(cells: [
              DataCell(Text(e.key, softWrap: true,)),
              DataCell(Text(fmt(e.value.past))),
              DataCell(Text(fmt(e.value.future))),
              DataCell(Text(fmt(e.value.past + e.value.future))),
            ]),
        ],
      ),
    );
  }

  Widget _buildIconSwitch({
    required IconData iconBefore,
    required IconData iconAfter,
    required bool value,
    required ValueChanged<bool> onChanged,
    bool disabled = false,
  }) {
    return Row(
      children: [
        Icon(iconBefore),
        Switch(
          value: value,
          onChanged: disabled ? null : onChanged,
        ),
        Icon(iconAfter),
      ],
    );
  }

  InlineSpan _tooltipRich(Map<UnitFactor, String> units) {
    final base = Theme.of(context).textTheme.bodyMedium!;
    final baseUnit = units[UnitFactor.base]!;
    return WidgetSpan(
      child: DefaultTextStyle(
        style: base.copyWith(
          color: Theme.of(context).colorScheme.onPrimaryContainer,
          fontFeatures: const [FontFeature.tabularFigures()], // equal-width digits
        ),
        child: IntrinsicWidth( // <- remove huge right gap
          child: Table(
            // keep everything tight to content
            defaultColumnWidth: const IntrinsicColumnWidth(),
            columnWidths: const {
              0: IntrinsicColumnWidth(), // label (km/Mm/…)
              1: IntrinsicColumnWidth(), // number (right-aligned)
              2: IntrinsicColumnWidth(), // baseUnit
            },
            children: [
              for (final f in UnitFactor.values.where((f) => f != UnitFactor.base))
                TableRow(children: [
                  Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: Text(units[f]!),
                  ),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 8),
                    child: Align(
                      alignment: Alignment.centerRight,
                      child: Text(
                        formatNumber(context, f.multiplier, noDecimal: true),
                      ),
                    ),
                  ),
                  const SizedBox(width: 4),
                  Text(baseUnit),
                ]),
            ],
          ),
        ),
      ),
    );
  }


  ExpansionPanelList _graphFilterExpansionBuilder(BuildContext context) {
    final loc = AppLocalizations.of(context)!;
    final calc = context.watch<StatisticsCalculator>();

    return ExpansionPanelList(
          expansionCallback: (panelIndex, isExpanded) {
            setState(() {
              _isParametersExpanded = isExpanded;
            });
          },
          children: [
            ExpansionPanel(
              canTapOnHeader: true,
              headerBuilder: (context, isExpanded) {
                return ListTile(
                  title: isExpanded 
                          ? Text(loc.statisticsHideFilters)
                          : Row(
                            children: [
                              calc.vehicle.icon(),
                              Text("・"),
                              graphIcon(calc.graph),
                              Text("・"),
                              Expanded(
                                child: Text(calc.year == 0 
                                      ? AppLocalizations.of(context)!.tripsFilterAllYears 
                                      : calc.year.toString(),
                                      overflow: TextOverflow.ellipsis,
                                      maxLines: 1,
                                    ),
                              )
                            ],
                          ),
                );
              },
              isExpanded: _isParametersExpanded,
              body: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      switch(_selectedStatistics)
                      {
                        StatisticsType.bar =>
                          _buildIconSwitch(
                            iconBefore: Icons.sort,
                            iconAfter: Icons.bar_chart,
                            value: _rotated,
                            onChanged: (v) => setState(() => _rotated = v),
                            disabled: _selectedStatistics != StatisticsType.bar
                          ),
                        StatisticsType.table =>
                          _buildIconSwitch(
                            iconBefore: Icons.arrow_downward,
                            iconAfter: Icons.sort_by_alpha,
                            value: _sortedAlpha,
                            onChanged: (v) => setState(() => _sortedAlpha = v),
                            disabled: _selectedStatistics != StatisticsType.table
                          ),
                        _ => const SizedBox.shrink(),
                      },
                      const Spacer(),
                      _buildIconSwitch(
                        iconBefore: Icons.confirmation_num,
                        iconAfter: Icons.straighten,
                        value: calc.isDistance,
                        //onChanged: (v) => setState(() => _isDistance = v),
                        onChanged: (v) => context.read<StatisticsCalculator>().isDistance = v,
                      ),
                    ],
                  ),
                  const SizedBox(height: 16,),
                  Row(
                    children: [
                      Expanded(
                        child: Consumer<TripsProvider>(
                          builder: (_, p, __) => buildDropdown<VehicleType>(
                            items: p.vehicleTypes,
                            selectedValue: calc.vehicle,
                            onChanged: (v) => context.read<StatisticsCalculator>().vehicle = v ?? VehicleType.train,
                            labelOf: (v) => VehicleType.labelOf(v, context),
                            iconOf: (v) => VehicleType.iconOf(v),
                            hintText: 'Select vehicle',
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Consumer<TripsProvider>(
                          builder: (_, p, __) {
                            final yearsWithAll = [0, ...p.years]; // 0 is the "All" value
                            return buildDropdown<int>(
                              items: yearsWithAll,
                              selectedValue: calc.year,
                              //onChanged: (y) => setState(() => _selectedYear = y),
                              onChanged: (y) => context.read<StatisticsCalculator>().year = y,
                              labelOf: (y) => y == 0 ? AppLocalizations.of(context)!.tripsFilterAllYears : y.toString(),
                              hintText: 'Select Year',
                            );
                          },
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16,),
                  buildDropdown<GraphType>(
                    items: GraphType.values,
                    selectedValue: calc.graph,
                    //onChanged: (g) => setState(() => _selectedGraphType = g ?? GraphType.operator),
                    onChanged: (g) => context.read<StatisticsCalculator>().graph = g ?? GraphType.operator,
                    labelOf: (t) => graphLabel(context, t),
                    iconOf: (t) => graphIcon(t),
                    hintText: 'Select a graph',
                  ),
                ],
              ),
            )
          ],
        );
  }
}

