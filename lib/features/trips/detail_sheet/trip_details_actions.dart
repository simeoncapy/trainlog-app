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
import 'package:trainlog_app/utils/platform_utils.dart';

/// The action button row (Edit, Duplicate, Share, Delete). Buttons use the
/// adaptive button tokens so they match light/dark styling on both platforms.
class TripDetailsActions extends StatelessWidget {
  final Trips trip;

  const TripDetailsActions({super.key, required this.trip});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final isApple = AppPlatform.isApple;

    final buttons = <Widget>[
      AdaptiveButton.build(
        context: context,
        label: isApple ? null : Text(l10n.tripsDetailsEditButton),
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
        label: isApple ? null : Text(MaterialLocalizations.of(context).shareButtonLabel),
        icon: AdaptiveIcons.share,
        type: AdaptiveButtonType.secondary,
        onPressed: () => _share(context),
      ),
      AdaptiveButton.build(
        context: context,
        label: isApple ? null : Text(l10n.tripsDetailsDeleteButton),
        icon: AdaptiveIcons.delete,
        type: AdaptiveButtonType.destructive,
        onPressed: () => _delete(context, l10n),
      ),
    ];

    return Wrap(
      spacing: 8,
      runSpacing: 8,
      alignment: isApple ? WrapAlignment.center : WrapAlignment.start,
      children: buttons,
    );
  }

  Future<void> _share(BuildContext context) async {
    final trainlog = Provider.of<TrainlogProvider>(context, listen: false);
    final url = Uri.parse('${trainlog.instanceUrl}/public/trip/${trip.uid}');
    await SharePlus.instance.share(ShareParams(uri: url));
  }

  Future<void> _delete(BuildContext context, AppLocalizations l10n) async {
    final trainlog = Provider.of<TrainlogProvider>(context, listen: false);
    final tripsProvider = Provider.of<TripsProvider>(context, listen: false);
    final polylineProvider = Provider.of<PolylineProvider>(context, listen: false);

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
      debugPrint('Trip $tripId deleted successfully');
      tripsProvider.deleteTrip(tripId);
      polylineProvider.removePolylineByTripId(tripId);
      AppNavigator.pop();
      AdaptiveInformationMessage.showInfo(l10n.tripsDetailsDeleteSuccess);
    } else {
      AdaptiveInformationMessage.showInfo(l10n.tripsDetailsDeleteFailed);
    }
  }
}
