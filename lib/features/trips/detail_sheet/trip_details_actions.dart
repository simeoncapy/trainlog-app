import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:share_plus/share_plus.dart';
import 'package:trainlog_app/app/app_globals.dart';
import 'package:trainlog_app/core/data/models/trips.dart';
import 'package:trainlog_app/core/providers/polyline_provider.dart';
import 'package:trainlog_app/core/providers/trainlog_provider.dart';
import 'package:trainlog_app/core/providers/trips_provider.dart';
import 'package:trainlog_app/core/services/api/trips_api.dart';
import 'package:trainlog_app/features/trips/detail_sheet/cupertino/trip_actions_cupertino_view.dart';
import 'package:trainlog_app/features/trips/detail_sheet/material/trip_actions_material_view.dart';
import 'package:trainlog_app/features/trips/detail_sheet/trip_actions_controller.dart';
import 'package:trainlog_app/features/trips_edit_copy/edit_copy_page.dart';
import 'package:trainlog_app/l10n/app_localizations.dart';
import 'package:trainlog_app/ui/adaptive/adaptive_information_message.dart';
import 'package:trainlog_app/ui/adaptive/adaptive_page_route.dart';
import 'package:trainlog_app/ui/design.dart';

/// What the trip actions do, handed to both views.
class TripActionCallbacks {
  const TripActionCallbacks({
    required this.onEdit,
    required this.onDuplicate,
    required this.onShare,
    required this.onDelete,
  });

  final VoidCallback onEdit;
  final VoidCallback onDuplicate;
  final VoidCallback onShare;

  /// Deletes the trip once [confirm] (the view's own confirmation) agrees.
  final Future<void> Function(Future<bool> Function() confirm) onDelete;
}

/// The trip's actions (Edit, Duplicate, Share, Delete) at the end of its
/// details sheet: a row of buttons on Android, tinted rows on iOS.
///
/// The work is done by [TripActionsController]; this entry wires it to the
/// navigation and messages both views share, and picks the view.
class TripDetailsActions extends StatelessWidget {
  final Trips trip;

  const TripDetailsActions({super.key, required this.trip});

  @override
  Widget build(BuildContext context) {
    final actions = TripActionsController(
      trip: trip,
      trainlog: Provider.of<TrainlogProvider>(context, listen: false),
      trips: Provider.of<TripsProvider>(context, listen: false),
      polylines: Provider.of<PolylineProvider>(context, listen: false),
    );
    final l10n = AppLocalizations.of(context)!;

    final callbacks = TripActionCallbacks(
      onEdit: () => _openEditCopy(context, actions, EditCopy.edit),
      // TODO(backend): restore `_openEditCopy(context, actions,
      // EditCopy.copy)` once the backend PR for duplicating a trip is
      // approved.
      onDuplicate: () => AdaptiveInformationMessage.showInfoAboveModal(
        l10n.editTripComingSoon,
      ),
      onShare: () =>
          SharePlus.instance.share(ShareParams(uri: actions.shareUrl)),
      onDelete: (confirm) => _delete(actions, l10n, confirm),
    );

    return PlatformView(
      material: (_) => TripActionsMaterialView(callbacks: callbacks),
      cupertino: (_) => TripActionsCupertinoView(callbacks: callbacks),
    );
  }

  /// Closes the sheet and opens [EditCopyPage] on the trip, either to edit it
  /// in place or to seed a duplicate from it.
  void _openEditCopy(
    BuildContext context,
    TripActionsController actions,
    EditCopy mode,
  ) {
    final tripId = actions.tripId;
    if (tripId == null) {
      debugPrint(
        'Cannot open ${mode.name}: trip uid "${trip.uid}" is not an id',
      );
      return;
    }

    // The sheet is dismissed first, so push on the navigator hosting it rather
    // than on this context, which is about to be unmounted.
    final navigator =
        rootNavigatorKey.currentState ??
        Navigator.of(context, rootNavigator: true);
    navigator.pop();
    navigator.push(
      AdaptivePageRoute.route<void>(
        (_) => EditCopyPage(tripId: tripId, mode: mode),
      ),
    );
  }

  Future<void> _delete(
    TripActionsController actions,
    AppLocalizations l10n,
    Future<bool> Function() confirm,
  ) async {
    if (!await confirm()) return;

    switch (await actions.delete()) {
      case TripDeleteOutcome.deleted:
        AppNavigator.pop();
        AdaptiveInformationMessage.showInfo(l10n.tripsDetailsDeleteSuccess);
      case TripDeleteOutcome.invalidId:
      case TripDeleteOutcome.failed:
        AdaptiveInformationMessage.showInfo(l10n.tripsDetailsDeleteFailed);
    }
  }
}
