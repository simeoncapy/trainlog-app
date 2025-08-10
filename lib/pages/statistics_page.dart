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
import 'package:trainlog_app/widgets/logo_bar_chart.dart';
import 'package:trainlog_app/widgets/min_height_scrollable.dart';
import 'package:trainlog_app/widgets/statistics_type_selector.dart';
import 'package:trainlog_app/widgets/trips_filter_dialog.dart';

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
  bool _isDistance = false;
  bool _isParametersExpanded = true;

  StatisticsType _selectedStatistics = StatisticsType.bar;
  VehicleType? _selectedVehicle = VehicleType.train;
  Color _selectedVehicleColor = Colors.blue;
  int? _selectedYear = 0;
  GraphType? _selectedGraphType = GraphType.operator;

  late List<int> listYears;

  late Map<VehicleType, Color> _palette;

  // TODO: Create a statistics class that do and store them all
  late LinkedHashMap<String, ({double past, double future})> _statsOperatorDistance = LinkedHashMap<String, ({double past, double future})>();
  late LinkedHashMap<String, ({double past, double future})> _statsOperatorTrip = LinkedHashMap<String, ({double past, double future})>();

  LinkedHashMap<String, ({double past, double future})> get _currentStats =>
    _isDistance ? _statsOperatorDistance : _statsOperatorTrip;

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
    _loadStats(); // fire & forget
  }

  Future<void> _loadStats() async {
    final repo = context.read<TripsProvider>().repository;
    if (repo == null) return;

    final rawDist = await repo.fetchOperatorsByDistancePF(filter: TripsFilterResult(keyword: "", types: [_selectedVehicle!]));
    final rawTrip = await repo.fetchOperatorsByTripPF(filter: TripsFilterResult(keyword: "", types: [_selectedVehicle!]));

    final dist = await getTop9WithOtherPF(original: rawDist, factor: 1_000);
    final trip = await getTop9WithOtherPF(original: rawTrip, factor: 1.0);

    if (!mounted) return;
    setState(() {
      _statsOperatorDistance = dist;
      _statsOperatorTrip = trip;
    });
  }

  Future<LinkedHashMap<String, double>> getTop9WithOther({
    required Map<String, double> original,
    double factor = 1_000, // divide by this
  }) async {
    // Sort descending by value
    final sortedEntries = original.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    // Keep top 9
    final top9 = sortedEntries.take(9).toList();
    final rest = sortedEntries.skip(9);

    // Sum the rest
    final otherValue = rest.fold<double>(0, (sum, e) => sum + e.value);

    // Create LinkedHashMap to preserve order
    final result = LinkedHashMap<String, double>();

    // Add scaled top 9
    for (final e in top9) {
      result[e.key] = e.value / factor;
    }

    // Add "Other" if there was anything to sum
    if (otherValue > 0) {
      result["Other"] = otherValue / factor;
    }

    return result;
  }

  Future<LinkedHashMap<String, ({double past, double future})>> getTop9WithOtherPF({
    required Map<String, ({num past, num future})> original,
    double factor = 1_000, // divide by this; use 1.0 for counts
    String otherLabel = 'Other',
  }) async {
    // Sort by (past + future) descending
    final sortedEntries = original.entries.toList()
      ..sort((a, b) =>
          (b.value.past + b.value.future).compareTo(a.value.past + a.value.future));

    // Take top 9 and the rest
    final top9 = sortedEntries.take(9).toList();
    final rest = sortedEntries.skip(9);

    // Sum the rest into "Other"
    double otherPast = 0;
    double otherFuture = 0;
    for (final e in rest) {
      otherPast  += e.value.past.toDouble();
      otherFuture+= e.value.future.toDouble();
    }

    // Build result (preserve order) and apply scaling
    final result = LinkedHashMap<String, ({double past, double future})>();

    for (final e in top9) {
      result[e.key] = (
        past:   e.value.past.toDouble()   / factor,
        future: e.value.future.toDouble() / factor,
      );
    }

    if (otherPast > 0 || otherFuture > 0) {
      result[otherLabel] = (
        past:   otherPast   / factor,
        future: otherFuture / factor,
      );
    }

    return result;
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
    final loc = AppLocalizations.of(context)!;
    final settings = context.read<SettingsProvider>();
    _palette = MapColorPaletteHelper.getPalette(settings.mapColorPalette);
    _selectedVehicleColor = _palette[_selectedVehicle] ?? Colors.blue;
    final hasData = _currentStats.isNotEmpty;
    const double kMinPanelHeight = 350;
    final _unitsTrips = {
      UnitFactor.base:  loc.statisticsTripsUnitBase,
      UnitFactor.thousand: loc.statisticsTripsUnitKilo,
      UnitFactor.million:  loc.statisticsTripsUnitMega,
      UnitFactor.billion:  loc.statisticsTripsUnitGiga,
    };

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
          const SizedBox(height: 16,),
          Expanded(
            child: MinHeightScrollable(
              minHeight: kMinPanelHeight,
              child: switch (_selectedStatistics) {
                StatisticsType.table => const Center(child: Text("Table")),
                StatisticsType.pie   => const Center(child: Text("Pie")),
                StatisticsType.bar   => hasData
                    ? LogoBarChart(
                        rotationQuarterTurns: !_rotated ? 1 : 0,
                        images: List.generate(_currentStats.length, (_) => const Icon(Icons.train)),
                        values: _currentStats.values.map((v) => v.past).toList(),
                        strippedValues: _currentStats.values.map((v) => v.future).toList(),
                        valuesTitles: _currentStats.keys.toList(),
                        baseUnit: _isDistance ? "km" : loc.statisticsTripsUnitBase,
                        unitsByFactor: _isDistance ? _unitsDistance : _unitsTrips,
                        color: _selectedVehicleColor,
                        unitHelpTooltip: _isDistance ? _tooltipRich(_unitsDistance) : null,
                      )
                    : const Center(child: CircularProgressIndicator()),
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTable() {
    // TODO: Create table
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Text("TODO")/* your DataTable */,
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
                              _selectedVehicle!.icon(),
                              Text("・"),
                              graphIcon(_selectedGraphType!),
                              Text("・"),
                              Expanded(
                                child: Text(_selectedYear == 0 
                                      ? AppLocalizations.of(context)!.tripsFilterAllYears 
                                      : _selectedYear.toString(),
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
                      _buildIconSwitch(
                        iconBefore: Icons.sort,
                        iconAfter: Icons.bar_chart,
                        value: _rotated,
                        onChanged: (v) => setState(() => _rotated = v),
                        disabled: _selectedStatistics != StatisticsType.bar
                      ),
                      const Spacer(),
                      _buildIconSwitch(
                        iconBefore: Icons.confirmation_num,
                        iconAfter: Icons.straighten,
                        value: _isDistance,
                        onChanged: (v) => setState(() => _isDistance = v),
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
                            selectedValue: _selectedVehicle,
                            onChanged: (v) => setState(() {
                              _selectedVehicle = v;
                              _selectedVehicleColor = _palette[_selectedVehicle] ?? Colors.blue;
                              _loadStats();
                            }),
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
                              selectedValue: _selectedYear,
                              onChanged: (y) => setState(() => _selectedYear = y),
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
                    selectedValue: _selectedGraphType,
                    onChanged: (v) => setState(() => _selectedGraphType = v),
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

