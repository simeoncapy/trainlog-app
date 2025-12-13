import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:trainlog_app/data/models/trip_form_model.dart';
import 'package:trainlog_app/l10n/app_localizations.dart';
import 'package:trainlog_app/widgets/mini_map_box.dart';


class TripFormPath extends StatefulWidget {
  const TripFormPath({super.key});

  @override
  State<TripFormPath> createState() => _TripFormPathState();
}

class _TripFormPathState extends State<TripFormPath> {
  bool _isNewRouter = false;

  @override
  void initState() {
    super.initState();

    final model = context.read<TripFormModel>();
  }

  void _showHelpDialog(BuildContext context) {
  final loc = AppLocalizations.of(context)!;

  showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text(loc.helpTitle),
          content: SingleChildScrollView(
            child: Text(
              "Bla bla bla",
              style: Theme.of(context).textTheme.bodyMedium,
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: Text(MaterialLocalizations.of(context).closeButtonLabel),
            ),
          ],
        );
      },
    );
  }

  void _showHelpBottomSheet(BuildContext context) {
    final loc = AppLocalizations.of(context)!;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (context) {
        return Padding(
          padding: const EdgeInsets.all(16),
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(loc.helpTitle,
                    style: Theme.of(context).textTheme.titleLarge),
                const SizedBox(height: 12),
                Text("Bla bla bla"),
                const SizedBox(height: 24),
              ],
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context)!;
    final model = context.watch<TripFormModel>();

    return Column(
      children: [
        Row(
          children: [
            Checkbox(
            value: _isNewRouter,
            onChanged: (value) {
              setState(() {
                _isNewRouter = value!;
              });
            },
            ),
            Expanded(child: Text(loc.addTripPathUseNewRouter)),
            IconButton(
              onPressed: () {
                _showHelpDialog(context);
                //_showHelpBottomSheet(context); TODO Choose the best option
              },
              icon: const Icon(Icons.help_outline),
              style: IconButton.styleFrom(
                backgroundColor: Theme.of(context).colorScheme.secondaryContainer,
                foregroundColor: Theme.of(context).colorScheme.onSecondaryContainer,
                shape: const CircleBorder(),
              ),
            ),
            SizedBox(width: 8,),
          ],
        ),
        SizedBox(height: 8,),
        Expanded(
          child: MiniMapBox(
            lat: model.departureLat,
            long: model.departureLong,
            emptyMessage: "", // always display a map here
            markerColor: Colors.green,
            isCoordinateMovable: model.departureGeoMode,
            onCoordinateChanged: (lat, long) {
              WidgetsBinding.instance.addPostFrameCallback((_) {
                model.updateDepartureCoords(lat, long);
              });
            },
          ),
        ),
      ],
    );
  }
}
