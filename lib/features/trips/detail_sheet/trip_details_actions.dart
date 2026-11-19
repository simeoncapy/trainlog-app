import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:share_plus/share_plus.dart';
import 'package:trainlog_app/app/app_globals.dart';
import 'package:trainlog_app/data/models/trips.dart';
import 'package:trainlog_app/features/trips/detail_sheet/trip_details_common.dart';
import 'package:trainlog_app/features/trips_edit_copy/edit_copy_page.dart';
import 'package:trainlog_app/l10n/app_localizations.dart';
import 'package:trainlog_app/platform/adaptive_information_message.dart';
import 'package:trainlog_app/platform/adaptive_page_route.dart';
import 'package:trainlog_app/providers/polyline_provider.dart';
import 'package:trainlog_app/providers/trainlog_provider.dart';
import 'package:trainlog_app/providers/trips_provider.dart';
import 'package:trainlog_app/services/api/trips_api.dart';
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

    if (AppPlatform.isApple) return _buildApple(context, l10n);

    return Row(
      children: [
        Expanded(
          child: _ActionButton(
            icon: AdaptiveIcons.edit,
            label: l10n.tripsDetailsEditButton,
            background: cs.primary,
            foreground: cs.onPrimary,
            onTap: () => _openEditCopy(context, EditCopy.edit),
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
            // TODO(backend): restore `_openEditCopy(context, EditCopy.copy)`
            // once the backend PR for duplicating a trip is approved.
            onTap: () =>
                AdaptiveInformationMessage.showInfoAboveModal(
                  l10n.editTripComingSoon,
                ),
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
            label: l10n.deleteButton,
            background: cs.error.withValues(alpha: 0.12),
            foreground: cs.error,
            onTap: () => _delete(context, l10n),
          ),
        ),
      ],
    );
  }

  /// Closes the sheet and opens [EditCopyPage] on the trip, either to edit it
  /// in place or to seed a duplicate from it.
  void _openEditCopy(BuildContext context, EditCopy mode) {
    final tripId = int.tryParse(trip.uid);
    if (tripId == null) {
      debugPrint('Cannot open ${mode.name}: trip uid "${trip.uid}" is not an id');
      return;
    }

    // The sheet is dismissed first, so push on the navigator hosting it rather
    // than on this context, which is about to be unmounted.
    final navigator =
        rootNavigatorKey.currentState ?? Navigator.of(context, rootNavigator: true);
    navigator.pop();
    navigator.push(
      AdaptivePageRoute.route<void>(
        (_) => EditCopyPage(tripId: tripId, mode: mode),
      ),
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

    final confirmed = AppPlatform.isApple
        ? await _confirmDeleteApple(context, l10n)
        : await showDialog<bool>(
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
            child: Text(l10n.deleteButton),
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

  /// iOS alert with Delete in the destructive red. It keeps the theme of
  /// the sheet it is opened from (e.g. the map's), not the app's.
  Future<bool> _confirmDeleteApple(
    BuildContext context,
    AppLocalizations l10n,
  ) async {
    final theme = Theme.of(context);
    final cupertinoTheme = CupertinoTheme.of(context);
    final result = await showCupertinoDialog<bool>(
      context: context,
      useRootNavigator: true,
      builder: (dialogContext) => Theme(
        data: theme,
        child: CupertinoTheme(
          // Same blue tint as the action rows (Apple uses one tint for both).
          data: cupertinoTheme.copyWith(primaryColor: theme.colorScheme.secondary),
          child: CupertinoAlertDialog(
            title: Text(l10n.tripsDetailsDeleteDialogTitle),
            content: Text(l10n.tripsDetailsDeleteDialogMessage),
            actions: [
              CupertinoDialogAction(
                onPressed: () => Navigator.of(dialogContext).pop(false),
                child: Text(
                  CupertinoLocalizations.of(dialogContext).cancelButtonLabel,
                ),
              ),
              CupertinoDialogAction(
                isDestructiveAction: true,
                onPressed: () => Navigator.of(dialogContext).pop(true),
                child: Text(l10n.deleteButton),
              ),
            ],
          ),
        ),
      ),
    );
    return result ?? false;
  }

  /// iOS: full-width tinted rows stacked at the end of the sheet's content,
  /// like the action buttons at the bottom of an Apple Maps sheet. Delete
  /// uses the system destructive red.
  Widget _buildApple(BuildContext context, AppLocalizations l10n) {
    // The app's secondary colour (blue), like the system tint on Apple
    // Maps' action buttons; it reads well on its own wash in both modes.
    final tint = Theme.of(context).colorScheme.secondary;
    final destructive = CupertinoColors.systemRed.resolveFrom(context);

    final rows = [
      _AppleActionRow(
        icon: AdaptiveIcons.edit,
        label: l10n.tripsDetailsEditButton,
        color: tint,
        onTap: () => _openEditCopy(context, EditCopy.edit),
      ),
      _AppleActionRow(
        icon: AdaptiveIcons.copy,
        label: l10n.duplicateBtnLabel,
        color: tint,
        // TODO(backend): restore `_openEditCopy(context, EditCopy.copy)`
        // once the backend PR for duplicating a trip is approved.
        onTap: () => AdaptiveInformationMessage.showInfoAboveModal(
          l10n.editTripComingSoon,
        ),
      ),
      _AppleActionRow(
        icon: AdaptiveIcons.share,
        label: MaterialLocalizations.of(context).shareButtonLabel,
        color: tint,
        onTap: () => _share(context),
      ),
      _AppleActionRow(
        icon: AdaptiveIcons.delete,
        label: l10n.deleteButton,
        color: destructive,
        onTap: () => _delete(context, l10n),
      ),
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        for (var i = 0; i < rows.length; i++) ...[
          if (i > 0) const SizedBox(height: 10),
          rows[i],
        ],
      ],
    );
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

/// One iOS action row: a tinted capsule with the icon on the leading edge and
/// the label centred, in the row's [color] (iOS "tinted" button style).
class _AppleActionRow extends StatefulWidget {
  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;

  const _AppleActionRow({
    required this.icon,
    required this.label,
    required this.color,
    required this.onTap,
  });

  @override
  State<_AppleActionRow> createState() => _AppleActionRowState();
}

class _AppleActionRowState extends State<_AppleActionRow> {
  bool _pressed = false;

  void _setPressed(bool value) {
    if (_pressed != value) setState(() => _pressed = value);
  }

  @override
  Widget build(BuildContext context) {
    final color = widget.color;
    // A plain tap recognizer (not CupertinoButton, which keeps the pointer):
    // a vertical drag starting on a row must still scroll the sheet.
    return Semantics(
      button: true,
      label: widget.label,
      excludeSemantics: true,
      onTap: widget.onTap,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTapDown: (_) => _setPressed(true),
        onTapUp: (_) => _setPressed(false),
        onTapCancel: () => _setPressed(false),
        onTap: widget.onTap,
        child: AnimatedOpacity(
          opacity: _pressed ? 0.45 : 1,
          duration: Duration(milliseconds: _pressed ? 10 : 150),
          child: Container(
            height: 56,
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.14),
              borderRadius: BorderRadius.circular(28),
            ),
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Stack(
              alignment: Alignment.center,
              children: [
                Align(
                  alignment: AlignmentDirectional.centerStart,
                  child: Icon(widget.icon, color: color, size: 24),
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 36),
                  child: Text(
                    widget.label,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: color,
                      fontSize: 17,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
