import 'dart:collection';
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:material_symbols_icons/symbols.dart';
import 'package:provider/provider.dart';

import 'package:trainlog_app/data/models/trips.dart';
import 'package:trainlog_app/l10n/app_localizations.dart';

import 'package:trainlog_app/providers/trainlog_provider.dart';
import 'package:trainlog_app/providers/trips_provider.dart';
import 'package:trainlog_app/providers/settings_provider.dart';
import 'package:trainlog_app/providers/statistics_provider.dart';

import 'package:trainlog_app/utils/map_color_palette.dart';
import 'package:trainlog_app/utils/number_formatter.dart';
import 'package:trainlog_app/utils/text_utils.dart';
import 'package:trainlog_app/widgets/error_banner.dart';

import 'package:trainlog_app/widgets/logo_bar_chart.dart';
import 'package:trainlog_app/widgets/min_height_scrollable.dart';
import 'package:trainlog_app/widgets/statistics_type_selector.dart';
import 'package:trainlog_app/widgets/stats_pie_chart.dart';
import 'package:trainlog_app/widgets/stats_table_chart.dart';

class StatisticsPage extends StatefulWidget {
  const StatisticsPage({super.key});

  @override
  State<StatisticsPage> createState() => _StatisticsPageState();
}

class _StatisticsPageState extends State<StatisticsPage> {
  bool _rotated = false;      // bar chart orientation
  bool _sortedAlpha = false;  // table sorting mode
  bool _isParametersExpanded = true;
  StatisticsType _selectedStatistics = StatisticsType.bar;

  late List<int> _listYears;

  @override
  void initState() {
    super.initState();
    _listYears = [DateTime.now().year];

    WidgetsBinding.instance.addPostFrameCallback((_) async {
      // Ensure Trips repo (for year list) is loaded
      final tripsProvider = Provider.of<TripsProvider>(context, listen: false);
      if (tripsProvider.repository == null) {
        await tripsProvider.loadTrips();
      }
      final years = await tripsProvider.repository?.fetchListOfYears()
        ?..sort((a, b) => b.compareTo(a));

      if (!mounted) return;
      setState(() => _listYears = years ?? [DateTime.now().year]);
    });
  }

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context)!;

    return ChangeNotifierProvider(
      // Inject StatisticsProvider with TrainlogProvider, then load once
      create: (ctx) => StatisticsProvider(ctx.read<TrainlogProvider>())..load(),
      builder: (context, _) {
        context.watch<TrainlogProvider>();  // forces rebuild when logos load
        final statsProv  = context.watch<StatisticsProvider>();
        final settings   = context.watch<SettingsProvider>();
        final palette    = MapColorPaletteHelper.getPalette(settings.mapColorPalette);
        final barColor   = palette[statsProv.vehicle] ?? Colors.blue;
        final hasData    = statsProv.currentStats.isNotEmpty && !statsProv.isLoading;

        return Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            children: [
              // Top right: chart type switcher (bar/pie/table)
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  StatisticsTypeSelector(
                    initialValue: _selectedStatistics,
                    onChanged: (newType) => setState(() {
                      _selectedStatistics = newType;
                    }),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              if(_selectedStatistics == StatisticsType.pie)
              ErrorBanner(
                  severity: ErrorSeverity.info,
                  compact: true,
                  message: loc.statisticsPieWip,
                ),
              const SizedBox(height: 8),
              _filtersPanel(context, statsProv),
              const SizedBox(height: 16),

              Expanded(
                child: MinHeightScrollable(
                  minHeight: 350,
                  child: Builder(
                    builder: (_) {
                      if (statsProv.isLoading) {
                        return const Center(child: CircularProgressIndicator());
                      }
                      if (statsProv.error != null) {
                        return Center(child: Text('Error: ${statsProv.error}'));
                      }
                      if (!hasData) {
                        return Center(child: Text(loc.statisticsNoDataLabel));
                      }

                      // Data + helpers
                      final stats = statsProv.currentStats;
                      final unitMap = statsProv.unitsByFactor(context);
                      final baseUnit = statsProv.baseUnitLabel(context);
                      final labelBuilder = statsProv.labelBuilder(context);
                      //final images = statsProv.graphImages(context);
                      final statsShort = statsProv.currentStatsShort(
                        10, // top 10
                        otherLabel: AppLocalizations.of(context)!.statisticsOtherLabel,
                      );
                      final images = statsProv.graphImagesForKeys(
                        context,
                        statsShort.keys.toList(),
                      );
                      // For duration tooltips: parallel raw-seconds lists in same order
                      List<double>? rawPastSecs;
                      List<double>? rawFutureSecs;
                      String Function(BuildContext, double)? rawFormatter;

                      if (statsProv.unit == GraphUnit.duration) {
                        final rawShort = statsProv.currentDurationRawSecondsShort(
                          10,
                          otherLabel: AppLocalizations.of(context)!.statisticsOtherLabel,
                        );

                        rawPastSecs = [
                          for (final k in statsShort.keys) (rawShort[k]?.past ?? 0),
                        ];
                        rawFutureSecs = [
                          for (final k in statsShort.keys) (rawShort[k]?.future ?? 0),
                        ];
                        rawFormatter = (ctx, v) => statsProv.humanizeSeconds(ctx, v);
                      }
                      final isDurationOrTrips =
                          statsProv.unit == GraphUnit.duration || statsProv.unit == GraphUnit.trip;


                      switch (_selectedStatistics) {
                        case StatisticsType.bar:
                          return LayoutBuilder(
                            builder: (context, c) {
                              const minH = 350.0;
                              final h = math.max(
                                minH, c.maxHeight.isFinite ? c.maxHeight : minH);
                              return SizedBox(
                                height: h,
                                child: LogoBarChart(
                                  stats: statsShort,
                                  rotationQuarterTurns: !_rotated ? 1 : 0,
                                  images: images,
                                  baseUnit: baseUnit,
                                  unitsByFactor: unitMap, // null for duration
                                  color: barColor,
                                  // Only show tooltip for scalable units (distance/trips/CO2)
                                  unitHelpTooltip: (isDurationOrTrips)
                                      ? null
                                      : _tooltipRich(context, unitMap!),
                                  labelBuilder: labelBuilder,
                                  // (optional) for pretty duration tooltips:
                                  tooltipRawPast: rawPastSecs,
                                  tooltipRawFuture: rawFutureSecs,
                                  tooltipValueFormatter: rawFormatter,
                                ),
                              );
                            },
                          );

                        case StatisticsType.pie:
                          return StatsPieChart(
                            stats: statsShort,
                            interactive: false,
                            seedColor: barColor,
                            valueFormatter: (v) =>
                                formatNumber(context, v, noDecimal: false),
                            showLegend: true,
                            sectionsSpace: 2,
                            centerSpaceRadius: 36,
                            labelBuilder: labelBuilder,
                          );

                        case StatisticsType.table:
                          // Localize countries in labels for table (same as your old page)
                          final fullStats = statsProv.currentStats;
                          final tableStats = (statsProv.graph == GraphType.country)
                              ? _orderedStats(_localizedStatsForTable(context, fullStats), alpha: _sortedAlpha)
                              : _orderedStats(fullStats, alpha: _sortedAlpha);
                          final isDuration = statsProv.unit == GraphUnit.duration;

                          // 2) For duration: build a FULL raw-seconds map (keys must match table keys)
                          Map<String, ({double past, double future})>? rawForTable;
                          if (isDuration) {
                            final rawSeconds = statsProv.currentDurationRawSeconds(); // full, keyed by original labels
                            rawForTable = (statsProv.graph == GraphType.country)
                                ? _localizedRawSecondsForTable(context, rawSeconds)
                                : LinkedHashMap.of(rawSeconds);
                          }

                          return Column(
                            mainAxisSize: MainAxisSize.min,
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              if(!isDuration) Text("${loc.statisticsUnitLabel} $baseUnit"),
                              const SizedBox(height: 8),
                              StatsTableChart(
                                stats: tableStats,
                                isDuration: isDuration,
                                rawValues: rawForTable,
                                rawValueFormatter: statsProv.humanizeSeconds,
                                valueFormatter: (v) => formatNumber(context, v),
                                //labelBuilder: statsProv.labelBuilder(context),
                                labelHeader: statsProv.graph.label(context, statsProv.vehicle),
                                pastHeader: loc.yearPastList,
                                futureHeader: loc.yearFutureList,
                                totalHeader: loc.statisticsTotalLabel,
                                labelMaxWidth: 180,
                                labelMaxLines: 4,
                                compact: true,
                                onlyTotal: switch (statsProv.year) {
                                  null => false,
                                  final y when y == 0 => false,
                                  final y when y == DateTime.now().year => false,
                                  _ => true,
                                },
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

  // ------------------------ FILTERS PANEL -----------------------------

  ExpansionPanelList _filtersPanel(BuildContext context, StatisticsProvider p) {
    final loc = AppLocalizations.of(context)!;
    final tripsProv = context.watch<TripsProvider>();
    final disabledYears = p.graph == GraphType.years;

    return ExpansionPanelList(
      expansionCallback: (i, isExpanded) =>
          setState(() => _isParametersExpanded = isExpanded),
      children: [
        ExpansionPanel(
          canTapOnHeader: true,
          isExpanded: _isParametersExpanded,
          headerBuilder: (context, isExpanded) {
            return ListTile(
              title: isExpanded
                  ? Text(loc.statisticsHideFilters)
                  : Row(
                      children: [
                        p.vehicle.icon(),
                        const Text("・"),
                        p.graph.icon(),
                        const Text("・"),
                        p.unit.icon(),
                        const Text("・"),
                        Expanded(
                          child: Text(
                            p.year == null || p.year == 0
                                ? loc.tripsFilterAllYears
                                : p.year.toString(),
                            overflow: TextOverflow.ellipsis,
                            maxLines: 1,
                          ),
                        ),
                      ],
                    ),
            );
          },
          body: Column(
            children: [ 
              // Vehicle + Year
              Row(
                children: [
                  Expanded(
                    child: buildDropdown<VehicleType>(
                      items: tripsProv.vehicleTypes,
                      selectedValue: p.vehicle,
                      onChanged: (v) => p.vehicle = v ?? VehicleType.train,
                      labelOf: (v) => VehicleType.labelOf(v, context),
                      iconOf: (v) => VehicleType.iconOf(v),
                      hintText: 'Select vehicle',
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: buildDropdown<int>(
                      items: [0, ...tripsProv.years], // 0 = All
                      selectedValue: p.year ?? 0,
                      onChanged: disabledYears ? null : (y) => p.year = y,
                      labelOf: (y) => y == 0
                          ? AppLocalizations.of(context)!.tripsFilterAllYears
                          : y.toString(),
                      hintText: 'Select Year',
                      enabled: !disabledYears,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),

              // Graph type
              buildDropdown<GraphType>(
                items: GraphType.values,
                selectedValue: p.graph,
                onChanged: (g) => p.graph = g ?? GraphType.operator,
                labelOf: (t) => t.label(context, p.vehicle),
                iconOf: (t) => t.icon(),
                hintText: 'Select a graph',
              ),
             
              const SizedBox(height: 16),

              // right-side switches for rotation / alpha sort
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  // Dropdown takes all available space
                  Expanded(
                    child: buildDropdown<GraphUnit>(
                      items: GraphUnit.values,
                      selectedValue: p.unit,
                      onChanged: (u) => p.unit = u ?? GraphUnit.trip,
                      labelOf: (u) => u.label(context),
                      iconOf: (u) => u.icon(),
                      hintText: 'Select a unit',
                    ),
                  ),

                  // Small spacing between dropdown and switches
                  const SizedBox(width: 8),

                  // Switches only take as much width as needed
                  if (_selectedStatistics == StatisticsType.bar)
                    _iconSwitch(
                      iconBefore: Icons.sort,
                      iconAfter: Icons.bar_chart,
                      value: _rotated,
                      onChanged: (v) => setState(() => _rotated = v),
                    ),
                  if (_selectedStatistics == StatisticsType.table)
                    _iconSwitch(
                      iconBefore: Icons.arrow_downward,
                      iconAfter: Icons.sort_by_alpha,
                      value: _sortedAlpha,
                      onChanged: (v) => setState(() => _sortedAlpha = v),
                    ),
                ],
              ),              
            ],
          ),
        )
      ],
    );
  }

  // ------------------------ SMALL HELPERS -----------------------------

  Widget _iconSwitch({
    required IconData iconBefore,
    required IconData iconAfter,
    required bool value,
    required ValueChanged<bool> onChanged,
    bool disabled = false,
  }) {
    return Row(
      children: [
        Icon(iconBefore),
        Switch(value: value, onChanged: disabled ? null : onChanged),
        Icon(iconAfter),
      ],
    );
  }

  // Dropdown helper (same UX as your original)
  Widget buildDropdown<T>({
    required List<T> items,
    required T? selectedValue,
    required ValueChanged<T?>? onChanged,
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
      onChanged: enabled ? onChanged : null,
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

  // Keep your stable ordering logic (alpha vs by-total)
  LinkedHashMap<String, ({double past, double future})> _orderedStats(
    Map<String, ({double past, double future})> stats, {
    required bool alpha,
  }) {
    final entries = stats.entries.toList();
    if (alpha) {
      entries.sort((a, b) => a.key.toLowerCase().compareTo(b.key.toLowerCase()));
    } else {
      entries.sort((a, b) {
        final ta = a.value.past + a.value.future;
        final tb = b.value.past + b.value.future;
        final cmp = tb.compareTo(ta);
        return cmp != 0 ? cmp : a.key.toLowerCase().compareTo(b.key.toLowerCase());
      });
    }
    return LinkedHashMap.fromEntries(entries);
  }

  // For the table: localize country names (same behavior as your old page)
  LinkedHashMap<String, ({double past, double future})> _localizedStatsForTable(
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
    // Keep ordering preference
    return _orderedStats(out, alpha: _sortedAlpha);
  }

  // Localize + aggregate a raw-seconds map keyed by country code,
// so keys match the table’s localized labels.
  LinkedHashMap<String, ({double past, double future})> _localizedRawSecondsForTable(
    BuildContext context,
    Map<String, ({double past, double future})> rawSecondsByCode,
  ) {
    final out = LinkedHashMap<String, ({double past, double future})>();
    for (final e in rawSecondsByCode.entries) {
      final name = countryCodeToName(e.key, context);
      final cur = out[name];
      out[name] = (
        past: (cur?.past ?? 0) + e.value.past,
        future: (cur?.future ?? 0) + e.value.future
      );
    }
    return out;
  }

  InlineSpan _tooltipRich(BuildContext context, Map<UnitFactor, String> units) {
    final base = Theme.of(context).textTheme.bodyMedium!;
    final baseUnit = units[UnitFactor.base]!;
    return WidgetSpan(
      child: DefaultTextStyle(
        style: base.copyWith(
          color: Theme.of(context).colorScheme.onPrimaryContainer,
        ),
        child: IntrinsicWidth(
          child: Table(
            defaultColumnWidth: const IntrinsicColumnWidth(),
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
                  Text(baseUnit),
                ]),
            ],
          ),
        ),
      ),
    );
  }
}
