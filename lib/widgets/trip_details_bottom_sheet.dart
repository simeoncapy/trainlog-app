import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:share_plus/share_plus.dart';
import 'package:trainlog_app/data/models/trips.dart';
import 'package:trainlog_app/l10n/app_localizations.dart';
import 'package:trainlog_app/providers/polyline_provider.dart';
import 'package:trainlog_app/providers/trainlog_provider.dart';
import 'package:trainlog_app/providers/trips_provider.dart';
import 'package:trainlog_app/utils/date_utils.dart';
import 'package:trainlog_app/utils/number_formatter.dart';
import 'package:trainlog_app/utils/style_utils.dart';
import 'package:trainlog_app/widgets/trip_time_line.dart';

class TripDetailsBottomSheet extends StatelessWidget {
  final Trips trip;

  const TripDetailsBottomSheet({super.key, required this.trip});

  @override
  Widget build(BuildContext context) {
    final appLocalization = AppLocalizations.of(context)!;
    final trainlog = Provider.of<TrainlogProvider>(context, listen: false);
    final tripsProvider = Provider.of<TripsProvider>(context, listen: false);
    final polylineProvider = Provider.of<PolylineProvider>(context, listen: false);
    final scaffMsg = ScaffoldMessenger.of(context);

    String vehicle;
    if (trip.materialType?.isNotEmpty == true && trip.reg?.isNotEmpty == true) {
      vehicle = "${trip.materialType!} (${trip.reg!})";
    } else {
      vehicle = trip.materialType!.isNotEmpty
          ? trip.materialType!
          : trip.reg ?? '';
    }

    return Padding(
      padding: const EdgeInsets.all(24.0),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(appLocalization.tripsDetailTitle(trip.type.label(context).toLowerCase()), style: Theme.of(context).textTheme.headlineSmall),
          const SizedBox(height: 16),
          TripTimeline(trip: trip),
          const SizedBox(height: 16),
          if(trip.operatorName.isNotEmpty) ...[
            _dataElementBuilder(context, appLocalization.tripsDetailsTitleOperator, Uri.decodeComponent(trip.operatorName).replaceAll("&&", ", ")),
            const SizedBox(height: 4),
          ],
          if (vehicle.isNotEmpty) ...[
            _dataElementBuilder(context, appLocalization.tripsDetailsTitleVehicle, vehicle),
            const SizedBox(height: 4),
          ],
          if (trip.seat!.isNotEmpty) ...[
            _dataElementBuilder(context, appLocalization.tripsDetailsTitleSeat, trip.seat!),
            const SizedBox(height: 4),
          ],
          if (trip.price != null) ...[
            _dataElementBuilder(
              context, 
              appLocalization.tripsDetailsTitlePrice, 
              "${formatCurrency(context, trip.price!, trip.price!%1!=0)} ${trip.currency}",
              suffix: "(${appLocalization.tripsDetailPurchasedDate(formatDateTime(context, trip.purchasingDate!, hasTime: false))})"
            ),
            const SizedBox(height: 4),
          ],
          if (trip.notes!.isNotEmpty) ...[
            _dataElementBuilder(context, appLocalization.tripsDetailsTitleNotes, trip.notes!),
            const SizedBox(height: 4),
          ],
          const SizedBox(height: 4),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              ElevatedButton.icon(
                onPressed: () async {
                  final url = Uri.parse("https://trainlog.me/public/trip/${trip.uid}");
                  final params = ShareParams(uri: url);
                  await SharePlus.instance.share(params); // opens OS share sheet
                },
                label: Text(MaterialLocalizations.of(context).shareButtonLabel),
                icon: Icon(Icons.share),
                style: buttonStyleHelper(Theme.of(context).colorScheme.tertiary, Theme.of(context).colorScheme.onTertiary)
              ),
              ElevatedButton.icon(
                onPressed: null, 
                label: Text(appLocalization.tripsDetailsEditButton),
                icon: Icon(Icons.edit),
                style: buttonStyleHelper(Theme.of(context).colorScheme.primary, Theme.of(context).colorScheme.onPrimary)
              ),
              ElevatedButton.icon(
                onPressed: null, 
                label: Text(appLocalization.duplicateBtnLabel),
                //label: Text(MaterialLocalizations.of(context).copyButtonLabel),
                icon: Icon(Icons.copy),
                style: buttonStyleHelper(Theme.of(context).colorScheme.secondary, Theme.of(context).colorScheme.onSecondary)
              ),
              ElevatedButton.icon(
                onPressed: () async {
                  final confirmed = await showDialog<bool>(
                    context: context,
                    builder: (context) => AlertDialog(
                      title: Text(appLocalization.tripsDetailsDeleteDialogTitle),
                      content: Text(appLocalization.tripsDetailsDeleteDialogMessage),
                      actions: [
                        TextButton(
                          onPressed: () => Navigator.of(context).pop(false),
                          child: Text(MaterialLocalizations.of(context).cancelButtonLabel),
                        ),
                        TextButton(
                          onPressed: () => Navigator.of(context).pop(true),
                          child: Text(appLocalization.tripsDetailsDeleteDialogConfirmButton),
                        ),
                      ],
                    ),
                  );
                  if (confirmed == true) {
                    final tripId = int.tryParse(trip.uid);
                    if (tripId == null) {
                      scaffMsg.showSnackBar(
                        SnackBar(content: Text(appLocalization.tripsDetailsDeleteFailed)),
                      );
                      return;
                    }
                    final success = await trainlog.deleteTrip(tripId);
                    if (success) {
                      tripsProvider.deleteTrip(tripId);
                      polylineProvider.removePolylineByTripId(tripId);
                      Navigator.of(context).pop();
                      scaffMsg.showSnackBar(
                        SnackBar(content: Text(appLocalization.tripsDetailsDeleteSuccess)),
                      );
                    } else {
                      scaffMsg.showSnackBar(
                        SnackBar(content: Text(appLocalization.tripsDetailsDeleteFailed)),
                      );
                    }
                  }
                }, // control enabled/disabled
                icon: const Icon(Icons.delete),
                label: Text(appLocalization.tripsDetailsDeleteButton),
                style: buttonStyleHelper(Theme.of(context).colorScheme.error, Theme.of(context).colorScheme.onError)
              ),
            ],
          ),
        ],
      ),
    );
  }

  Text _dataElementBuilder(BuildContext context, String title, String data, {String? suffix}) {
    return Text.rich(
        TextSpan(
          children: [
            TextSpan(
              text: title,
              style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
            ),
            TextSpan(
              text: data,
              style: Theme.of(context).textTheme.titleMedium,
            ),
            if (suffix != null && suffix.isNotEmpty)
            TextSpan(
              text: ' $suffix',
              style: Theme.of(context).textTheme.bodySmall,
            ),
          ],
        ),
      );
  }
}
