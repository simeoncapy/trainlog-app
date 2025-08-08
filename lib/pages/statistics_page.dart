import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:trainlog_app/data/models/trips.dart';
import 'package:trainlog_app/l10n/app_localizations.dart';
import 'package:trainlog_app/providers/trips_provider.dart';
import 'package:trainlog_app/widgets/logo_bar_chart.dart';

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

  VehicleType? _selectedVehicle = VehicleType.train;
  int? _selectedYear = 0;
  GraphType? _selectedGraphType = GraphType.operator;

  late TripsProvider tripsProvider;
  late List<int> listYears;

  @override
  void initState() {
    super.initState();
    listYears = [DateTime.now().year];
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      tripsProvider = Provider.of<TripsProvider>(context, listen: false);
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
              Text(labelOf(item)),
            ],
          ),
        );
      }).toList(),
      onChanged: onChanged,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(20),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              const Icon(Icons.sort),
              Switch(
                value: _rotated,
                onChanged: (v) => setState(() => _rotated = v),
              ),
              const Icon(Icons.bar_chart),
              const SizedBox(width: 16,),
              const Icon(Icons.confirmation_num),
              Switch(
                value: _isDistance,
                onChanged: (v) => setState(() => _isDistance = v),
              ),
              const Icon(Icons.straighten),
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
                    onChanged: (v) => setState(() => _selectedVehicle = v),
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
          const SizedBox(height: 16,),
          Expanded(
            child: LogoBarChart(
              rotationQuarterTurns: !_rotated ? 1 : 0,
              images: List.generate(10, (i) => const Icon(Icons.train)),
              values: const [130, 70, 55, 45, 40, 20, 15, 10, 10, 60],
              strippedValues: const [0, 0, 10, 0, 5, 0, 0, 0, 0, 20],
              valuesTitles: const [
                'JR East','JR West','SNCF','JR Central','JR Kyushu',
                'Keisei','Keihan','Seibu','DB','Other'
              ],
              horizontalAxisTitle:  _isDistance ? "km" : "trips",
              color: Colors.lightBlue,
            ),
          ),
        ],
      ),
    );
  }
}

