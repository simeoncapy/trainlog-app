import 'package:flutter/material.dart';
import 'package:trainlog_app/data/models/trips.dart';
import 'package:trainlog_app/l10n/app_localizations.dart';
import 'package:trainlog_app/utils/date_utils.dart';
import 'package:trainlog_app/utils/number_formatter.dart';
import 'package:trainlog_app/widgets/trip_time_line.dart';

class TripDetailsBottomSheet extends StatelessWidget {
  final Trips trip;

  const TripDetailsBottomSheet({super.key, required this.trip});

  @override
  Widget build(BuildContext context) {
    final appLocalization = AppLocalizations.of(context)!;
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
          _dataElementBuilder(context, appLocalization.tripsDetailsTitleOperator, Uri.decodeComponent(trip.operatorName)),
          const SizedBox(height: 4),
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
