import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:trainlog_app/providers/trips_provider.dart';
import 'package:fluttertoast/fluttertoast.dart';

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

        return Stack(
          children: [
            // MyApp always stays mounted
            Positioned.fill(child: _child!),  

            // Loader is only an overlay
            // if (showLoader)
            //   Positioned.fill(
            //     child: Container(
            //       color: Colors.black.withValues(alpha: 0.1),
            //       child: const Center(
            //         child: CircularProgressIndicator(),
            //       ),
            //     ),
            //   ),
          ],
        );
      },
    );
  }
}

