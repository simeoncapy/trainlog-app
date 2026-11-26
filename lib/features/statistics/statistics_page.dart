import 'package:flutter/widgets.dart';
import 'package:provider/provider.dart';

import 'package:trainlog_app/core/providers/statistics_provider.dart';
import 'package:trainlog_app/core/providers/trainlog_provider.dart';
import 'package:trainlog_app/core/providers/trips_provider.dart';
import 'package:trainlog_app/features/statistics/cupertino/statistics_cupertino_view.dart';
import 'package:trainlog_app/features/statistics/material/statistics_material_view.dart';
import 'package:trainlog_app/features/statistics/statistics_controller.dart';
import 'package:trainlog_app/ui/design.dart';


/// The Statistics page: [StatisticsProvider] loads the data for the chosen
/// dimension, vehicle, unit and year, [StatisticsController] holds the view
/// and the sort; each design draws its own view.
class StatisticsPage extends StatefulWidget {
  const StatisticsPage({super.key, this.initialView = StatisticsView.bar});

  final StatisticsView initialView;

  @override
  State<StatisticsPage> createState() => _StatisticsPageState();
}

class _StatisticsPageState extends State<StatisticsPage> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      final tripsProvider = Provider.of<TripsProvider>(context, listen: false);
      if (tripsProvider.repository == null) {
        await tripsProvider.loadNecessaryTripsData(hardRefresh: true);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(
          create: (ctx) => StatisticsProvider(
            ctx.read<TrainlogProvider>(),
            allVehicles: ctx.read<TripsProvider>().vehicleTypesWithoutPoi,
          )..load(),
        ),
        ChangeNotifierProvider(
          create: (_) => StatisticsController(view: widget.initialView),
        ),
      ],
      builder: (context, _) {
        context.watch<TrainlogProvider>();
        final statsProv = context.read<StatisticsProvider>();
        // Trip types may arrive after the provider was created.
        statsProv.updateAllVehicles(
          context.watch<TripsProvider>().vehicleTypesWithoutPoi,
        );
        return PlatformView(
          material: (_) => const StatisticsMaterialView(),
          cupertino: (_) => const StatisticsCupertinoView(),
        );
      },
    );
  }
}
