import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:share_plus/share_plus.dart';
import 'package:trainlog_app/app/app_globals.dart';
import 'package:trainlog_app/data/models/trips.dart';
import 'package:trainlog_app/features/trips/detail_sheet/trip_details_common.dart';
import 'package:trainlog_app/l10n/app_localizations.dart';
import 'package:trainlog_app/platform/adaptive_information_message.dart';
import 'package:trainlog_app/providers/polyline_provider.dart';
import 'package:trainlog_app/providers/trainlog_provider.dart';
import 'package:trainlog_app/providers/trips_provider.dart';
import 'package:trainlog_app/utils/platform_utils.dart';

/// The action button row (Edit, Duplicate, Share, Delete). Buttons are equal
/// width, stack an icon above the label, and are meant to be pinned at the
/// bottom of the sheet (outside the scroll view). Colours come from adaptive
/// tokens so they match light/dark on both platforms.
class TripDetailsActions extends StatelessWidget {
  final Trips trip;

  const TripDetailsActions({super.key, required this.trip});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final cs = Theme.of(context).colorScheme;

    return Row(
      children: [
        Expanded(
          child: _ActionButton(
            icon: AdaptiveIcons.edit,
            label: l10n.tripsDetailsEditButton,
            background: cs.primary,
            foreground: cs.onPrimary,
            onTap: null,
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: _ActionButton(
            icon: AdaptiveIcons.copy,
            label: l10n.duplicateBtnLabel,
            background: detailSurfaceColor(context),
            foreground: cs.onSurface,
            border: detailBorderColor(context),
            onTap: null,
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: _ActionButton(
            icon: AdaptiveIcons.share,
            label: MaterialLocalizations.of(context).shareButtonLabel,
            background: detailSurfaceColor(context),
            foreground: cs.onSurface,
            border: detailBorderColor(context),
            onTap: () => _share(context),
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: _ActionButton(
            icon: AdaptiveIcons.delete,
            label: l10n.tripsDetailsDeleteButton,
            background: cs.error.withValues(alpha: 0.12),
            foreground: cs.error,
            onTap: () => _delete(context, l10n),
          ),
        ),
      ],
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

class _ActionButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color background;
  final Color foreground;
  final Color? border;
  final VoidCallback? onTap;

  const _ActionButton({
    required this.icon,
    required this.label,
    required this.background,
    required this.foreground,
    this.border,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: background,
      borderRadius: BorderRadius.circular(14),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(14),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 4),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(14),
            border: border != null ? Border.all(color: border!) : null,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, size: 22, color: foreground),
              const SizedBox(height: 4),
              Text(
                label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: foreground,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
