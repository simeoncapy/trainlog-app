import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:trainlog_app/providers/polyline_provider.dart';
import 'package:trainlog_app/providers/trips_provider.dart';
import 'package:trainlog_app/widgets/data_loading_screen.dart';

class TripsLoader extends StatefulWidget {
  final Widget Function(BuildContext) builder;

  const TripsLoader({
    super.key,
    required this.builder,
  });

  @override
  State<TripsLoader> createState() => _TripsLoaderState();
}

class _TripsLoaderState extends State<TripsLoader> {
  Widget? _child;

  @override
  Widget build(BuildContext context) {
    return Consumer<TripsProvider>(
      builder: (context, trips, _) {
        // Build MyApp only once
        _child ??= widget.builder(context);

        final showLoader =
            trips.isLoading || trips.repository == null;

        if (!trips.isLoading && trips.repository != null) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (!mounted) return;
            context.read<PolylineProvider>().ensureLoaded();
          });
        }

        return Stack(
          children: [
            // MyApp always stays mounted
            Positioned.fill(child: _child!),  

            //Loader is only an overlay
            if (showLoader)
              const Positioned.fill(child: DataLoadingScreen()),
          ],
        );
      },
    );
  }
}
