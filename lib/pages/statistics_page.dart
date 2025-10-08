import 'dart:collection';
import 'dart:math' as math;
import 'package:material_symbols_icons/symbols.dart';
import 'package:country_picker/country_picker.dart';
import 'package:diacritic/diacritic.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:trainlog_app/data/models/trips.dart';
import 'package:trainlog_app/l10n/app_localizations.dart';
import 'package:trainlog_app/providers/trainlog_provider.dart';
import 'package:trainlog_app/providers/settings_provider.dart';
import 'package:trainlog_app/providers/trips_provider.dart';
import 'package:trainlog_app/services/trainlog_service.dart';
import 'package:trainlog_app/utils/map_color_palette.dart';
import 'package:trainlog_app/utils/number_formatter.dart';
import 'package:trainlog_app/utils/statistics_calculator.dart';
import 'package:trainlog_app/utils/text_utils.dart';
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
  late TrainlogProvider _trainlog;

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

      _trainlog = Provider.of<TrainlogProvider>(context, listen: false);

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

  String graphLabel(BuildContext context, GraphType type, VehicleType vehicleType) {
    final loc = AppLocalizations.of(context)!;
    switch (type) {
      case GraphType.operator: return loc.graphTypeOperator;
      case GraphType.country:  return loc.graphTypeCountry;
      case GraphType.years:    return loc.graphTypeYears;
      case GraphType.material: return loc.graphTypeMaterial;
      case GraphType.itinerary:return loc.graphTypeItinerary;
      case GraphType.stations: return loc.graphTypeStations(vehicleType.name.toLowerCase());
    }
  }

  Icon graphIcon(GraphType type) {
    switch (type) {
      case GraphType.operator: return const Icon(Icons.business);
      case GraphType.country: return const Icon(Icons.flag);
      case GraphType.years: return const Icon(Icons.calendar_today);
      case GraphType.material: return const Icon(Symbols.car_tag, fill: 1,);
      //case GraphType.material: return const Icon(Icons.train);
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
    bool enabled = true,
  }) {
    return DropdownButton<T>(
      hint: Text(hintText),
      value: selectedValue,
      isExpanded: isExpanded,
      onChanged: enabled ? onChanged : null, // disabled when null
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
    );
  }

  LinkedHashMap<String, ({double past, double future})> _orderedStats(
    Map<String, ({double past, double future})> stats, {
    required bool alpha, // true = A→Z, false = by total desc
  }) {
    final entries = stats.entries.toList();

    if (alpha) {
      // Alphabetical (case-insensitive where it matters)
      entries.sort((a, b) =>
        removeDiacritics(a.key).toLowerCase().compareTo(removeDiacritics(b.key).toLowerCase()));
    } else {
      // Numeric by total (past + future) descending; tie-break A→Z
      entries.sort((a, b) {
        final ta = a.value.past + a.value.future;
        final tb = b.value.past + b.value.future;
        final cmp = tb.compareTo(ta);
        return cmp != 0 ? cmp : removeDiacritics(a.key).toLowerCase().compareTo(removeDiacritics(b.key).toLowerCase());
      });
    }

    return LinkedHashMap.fromEntries(entries);
  }

  LinkedHashMap<String, ({double past, double future})> localizedStats(
    BuildContext context,
    Map<String, ({double past, double future})> stats,
  ) {
    final out = LinkedHashMap<String, ({double past, double future})>();
    for (final e in stats.entries) {
      final name = countryCodeToName(e.key, context);
      final cur = out[name];
      out[name] = (past: (cur?.past ?? 0) + e.value.past,
                  future: (cur?.future ?? 0) + e.value.future);
    }
    return out;
  }

  List<Widget> barChartImageBuilder(GraphType type, List<String> data)
  {
    // Normalize common edge cases
    String _normalize(String code) {
      final c = code.trim().toUpperCase();
      return (c == 'UK') ? 'GB' : c; // 'UK' is not official; use 'GB'
    }

    // Convert "JP" -> "🇯🇵"
    String _flagEmoji(String code) {
      final cc = _normalize(code);
      if (cc.length != 2) return '🏳️'; // fallback white flag
      const int base = 0x1F1E6; // Regional Indicator Symbol Letter A
      final int a = cc.codeUnitAt(0);
      final int b = cc.codeUnitAt(1);
      if (a < 65 || a > 90 || b < 65 || b > 90) return '🏳️';
      return String.fromCharCodes([base + (a - 65), base + (b - 65)]);
    }

    switch(type)
    {
      case GraphType.operator:
        //return List.generate(data.length, (_) => const Icon(Icons.train));
        return List.generate(
            data.length,
            (i) => _trainlog.getOperatorImage(data[i], maxWidth: 48, maxHeight: 48), 
          );
        case GraphType.country:
          return List.generate(
            data.length,
            (i) => Text(
              _flagEmoji(data[i]),
              style: const TextStyle(fontSize: 18), // adjust to match your bars
            ),
          );
      default:
        return List.generate(data.length, (_) => const Icon(Icons.help));
    }
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
        final loc = AppLocalizations.of(context)!;

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
                        return Center(child: Text(loc.statisticsNoDataLabel));
                      }

                      final stats = calc.currentStatsShort(9, otherLabel: loc.statisticsOtherLabel);
                      final statsAll = calc.currentStats;
                      final displayStatsTable = (calc.graph == GraphType.country)
                          ? localizedStats(context, statsAll)
                          : LinkedHashMap.of(statsAll);
                      final statsForTable = _orderedStats(displayStatsTable, alpha: _sortedAlpha);
                      final unitsTrips = {
                        UnitFactor.base:  loc.statisticsTripsUnitBase,
                        UnitFactor.thousand: loc.statisticsTripsUnitKilo,
                        UnitFactor.million:  loc.statisticsTripsUnitMega,
                        UnitFactor.billion:  loc.statisticsTripsUnitGiga,
                      };
                      final unit = calc.isDistance ? _unitsDistance[UnitFactor.base] : unitsTrips[UnitFactor.base];
                      final String Function(String)? labelBuilder =
                        (calc.graph == GraphType.country)
                            ? (String code) => countryCodeToName(code, context)
                            : null;

                      switch (_selectedStatistics) {
                        case StatisticsType.bar:
                          return LayoutBuilder(
                            builder: (context, c) {
                              const minH = 350.0;
                              final h = math.max(minH, c.maxHeight.isFinite ? c.maxHeight : minH);
                              return SizedBox(
                                height: h, // <- finite height avoids ∞ in fl_chart
                                child: LogoBarChart(
                                  stats: stats,
                                  rotationQuarterTurns: !_rotated ? 1 : 0,
                                  images: barChartImageBuilder(calc.graph, stats.keys.toList()),                                  
                                  baseUnit: unit!,
                                  unitsByFactor: calc.isDistance ? _unitsDistance : unitsTrips,
                                  color: barColor,
                                  unitHelpTooltip: calc.isDistance ? _tooltipRich(_unitsDistance) : null,
                                  labelBuilder: labelBuilder,
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
                            labelBuilder: labelBuilder,
                          );

                        case StatisticsType.table:
                          return Column(
                            mainAxisSize: MainAxisSize.min,
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text("${loc.statisticsUnitLabel} ${unit!}"),
                              const SizedBox(height: 8),
                              StatsTableChart(
                                stats: statsForTable,
                                valueFormatter: (v) => formatNumber(context, v),
                                labelHeader: graphLabel(context, calc.graph, calc.vehicle),
                                pastHeader: loc.yearPastList,
                                futureHeader: loc.yearFutureList,
                                totalHeader: loc.statisticsTotalLabel,
                                labelMaxWidth: 180,
                                labelMaxLines: 4,
                                compact: true,
                                onlyTotal: switch (calc.year) {
                                  null || 0 => false,
                                  final y when y == DateTime.now().year => false,
                                  _ => true,
                                },
                                //labelBuilder: labelBuilder, // Not used here because of statsForTable
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
    final disabledYears = calc.graph == GraphType.years;

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
                              enabled: !disabledYears,
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
                    onChanged: (g) => context.read<StatisticsCalculator>().graph = g ?? GraphType.operator,
                    labelOf: (t) => graphLabel(context, t, calc.vehicle),
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

