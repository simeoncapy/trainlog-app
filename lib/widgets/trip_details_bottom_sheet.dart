// trip_details_bottom_sheet.dart
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:share_plus/share_plus.dart';
import 'package:trainlog_app/app/app_globals.dart';
import 'package:trainlog_app/data/models/trips.dart';
import 'package:trainlog_app/l10n/app_localizations.dart';
import 'package:trainlog_app/platform/adaptive_button.dart';
import 'package:trainlog_app/platform/adaptive_information_message.dart';
import 'package:trainlog_app/providers/polyline_provider.dart';
import 'package:trainlog_app/providers/trainlog_provider.dart';
import 'package:trainlog_app/providers/trips_provider.dart';
import 'package:trainlog_app/services/trainlog_service.dart';
import 'package:trainlog_app/utils/date_utils.dart';
import 'package:trainlog_app/utils/number_formatter.dart';
import 'package:trainlog_app/utils/platform_utils.dart';
import 'package:trainlog_app/utils/style_utils.dart';
import 'package:trainlog_app/widgets/trip_time_line.dart';

class TripDetailsBottomSheet extends StatefulWidget {
  final Trips trip;

  const TripDetailsBottomSheet({super.key, required this.trip});

  @override
  State<TripDetailsBottomSheet> createState() => _TripDetailsBottomSheetState();
}

class _TripDetailsBottomSheetState extends State<TripDetailsBottomSheet> {
  // Only used on iOS, but safe to keep always.
  final ScrollController _iosScrollController = ScrollController();

  @override
  void dispose() {
    _iosScrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final trip = widget.trip;

    final l10n = AppLocalizations.of(context)!;
    final trainlog = Provider.of<TrainlogProvider>(context, listen: false);
    final tripsProvider = Provider.of<TripsProvider>(context, listen: false);
    final polylineProvider = Provider.of<PolylineProvider>(context, listen: false);
    final scaffMsg = ScaffoldMessenger.of(context);

    final String vehicle = _buildVehicleLabel(trip);

    final title = Text(
      l10n.tripsDetailTitle(trip.type.label(context).toLowerCase()),
      style: Theme.of(context).textTheme.headlineSmall,
    );

    final content = _TripDetailsContent(
      trip: trip,
      vehicle: vehicle,
      trainlog: trainlog,
      tripsProvider: tripsProvider,
      polylineProvider: polylineProvider,
      scaffMsg: scaffMsg,
    );

    // iOS: shown inside your Cupertino "card" with a fixed height -> scroll inside + explicit controller.
    if (AppPlatform.isApple) {
      return Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            title,
            const SizedBox(height: 8),
            content,
          ],
        ),
      );
    }

    // Android/Material: keep minimal height. Scroll only when content is taller than available.
    return SingleChildScrollView(
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            title,
            const SizedBox(height: 16),
            content,
          ],
        ),
      ),
    );
  }

  static String _buildVehicleLabel(Trips trip) {
    final material = trip.materialType ?? '';
    final reg = trip.reg ?? '';

    if (material.isNotEmpty && reg.isNotEmpty) {
      return "$material ($reg)";
    }
    if (material.isNotEmpty) return material;
    return reg;
  }
}

class _TripDetailsContent extends StatelessWidget {
  final Trips trip;
  final String vehicle;
  final TrainlogProvider trainlog;
  final TripsProvider tripsProvider;
  final PolylineProvider polylineProvider;
  final ScaffoldMessengerState scaffMsg;

  const _TripDetailsContent({
    required this.trip,
    required this.vehicle,
    required this.trainlog,
    required this.tripsProvider,
    required this.polylineProvider,
    required this.scaffMsg,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if(AppPlatform.isApple) ... [          
          Center(
            child: Wrap(
              spacing: 8,
              runSpacing: 8,
              children: _buttonHelper(context, l10n),
            ),
          ),
          const SizedBox(height: 8),
        ],

        TripTimeline(trip: trip),
        const SizedBox(height: 16),

        if (trip.operatorName.isNotEmpty) ...[
          _dataElement(
            context,
            l10n.tripsDetailsTitleOperator,
            Uri.decodeComponent(trip.operatorName).replaceAll("&&", ", "),
          ),
          const SizedBox(height: 4),
        ],

        if (vehicle.isNotEmpty) ...[
          _dataElement(context, l10n.tripsDetailsTitleVehicle, vehicle),
          const SizedBox(height: 4),
        ],

        if ((trip.seat ?? '').isNotEmpty) ...[
          _dataElement(context, l10n.tripsDetailsTitleSeat, trip.seat!),
          const SizedBox(height: 4),
        ],

        if (trip.price != null) ...[
          _dataElement(
            context,
            l10n.tripsDetailsTitlePrice,
            "${formatCurrency(context, trip.price!, trip.price! % 1 != 0)} ${trip.currency}",
            suffix:
                "(${l10n.tripsDetailPurchasedDate(formatDateTime(context, trip.purchasingDate!, hasTime: false))})",
          ),
          const SizedBox(height: 4),
        ],

        if ((trip.notes ?? '').isNotEmpty) ...[
          _dataElement(context, l10n.tripsDetailsTitleNotes, trip.notes!),
          const SizedBox(height: 4),
        ],        

        if(AppPlatform.isMaterial) ... [
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: _buttonHelper(context, l10n),
          ),
        ]
      ],
    );
  }

  List<Widget> _buttonHelper(BuildContext context, AppLocalizations l10n) {
    final isA = AppPlatform.isApple;
    return [
          AdaptiveButton.build(
            context: context, 
            label: isA ? null : Text(MaterialLocalizations.of(context).shareButtonLabel),
            icon: AdaptiveIcons.share,
            //type: AdaptiveButtonType.tertiary,
            onPressed: () async {
              final url = Uri.parse("${TrainlogService.baseUrl}/public/trip/${trip.uid}");
              final params = ShareParams(uri: url);
              await SharePlus.instance.share(params);
            },
          ),
          AdaptiveButton.build(
            context: context, 
            label: isA ? null : Text(l10n.tripsDetailsEditButton),
            icon: AdaptiveIcons.edit,
            type: AdaptiveButtonType.primary,
            onPressed: null,
          ),
          AdaptiveButton.build(
            context: context, 
            label: Text(l10n.duplicateBtnLabel),
            icon: AdaptiveIcons.copy,
            type: AdaptiveButtonType.secondary,
            onPressed: null,
          ),
          AdaptiveButton.build(
            context: context, 
            label: isA ? null : Text(l10n.tripsDetailsDeleteButton),
            icon: AdaptiveIcons.delete,
            type: AdaptiveButtonType.destructive,
            onPressed: () async {
              final confirmed = await showDialog<bool>(
                context: context,
                builder: (context) => AlertDialog(
                  title: Text(l10n.tripsDetailsDeleteDialogTitle),
                  content: Text(l10n.tripsDetailsDeleteDialogMessage),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.of(context).pop(false),
                      child: Text(MaterialLocalizations.of(context).cancelButtonLabel),
                    ),
                    TextButton(
                      onPressed: () => Navigator.of(context).pop(true),
                      child: Text(l10n.tripsDetailsDeleteDialogConfirmButton),
                    ),
                  ],
                ),
              );

              if (confirmed != true) return;

              final tripId = int.tryParse(trip.uid);
              if (tripId == null) {
                AdaptiveInformationMessage.showInfo(l10n.tripsDetailsDeleteFailed);
                return;
              }

              final success = await trainlog.deleteTrip(tripId);
              if (success) {
                tripsProvider.deleteTrip(tripId);
                polylineProvider.removePolylineByTripId(tripId);
                AppNavigator.pop();
                AdaptiveInformationMessage.showInfo(l10n.tripsDetailsDeleteSuccess);
              } else {
                AdaptiveInformationMessage.showInfo(l10n.tripsDetailsDeleteFailed);
              }
            },
          ),
        ];
  }

  Text _dataElement(
    BuildContext context,
    String title,
    String data, {
    String? suffix,
  }) {
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