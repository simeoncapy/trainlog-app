import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:trainlog_app/features/trips/detail_sheet/trip_details_actions.dart';
import 'package:trainlog_app/l10n/app_localizations.dart';
import 'package:trainlog_app/ui/adaptive/adaptive_dialog.dart';
import 'package:trainlog_app/utils/platform_utils.dart';

/// Trip actions, iOS view: full-width tinted rows stacked at the end of the
/// sheet's content, like the action buttons at the bottom of an Apple Maps
/// sheet. Delete uses the system destructive red and confirms with an
/// action sheet.
class TripActionsCupertinoView extends StatelessWidget {
  const TripActionsCupertinoView({super.key, required this.callbacks});

  final TripActionCallbacks callbacks;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    // The app's secondary colour (blue), like the system tint on Apple
    // Maps' action buttons; it reads well on its own wash in both modes.
    final tint = Theme.of(context).colorScheme.secondary;
    final destructive = CupertinoColors.systemRed.resolveFrom(context);

    final rows = [
      _AppleActionRow(
        icon: AdaptiveIcons.edit,
        label: l10n.tripsDetailsEditButton,
        color: tint,
        onTap: callbacks.onEdit,
      ),
      _AppleActionRow(
        icon: AdaptiveIcons.copy,
        label: l10n.duplicateBtnLabel,
        color: tint,
        onTap: callbacks.onDuplicate,
      ),
      _AppleActionRow(
        icon: AdaptiveIcons.share,
        label: MaterialLocalizations.of(context).shareButtonLabel,
        color: tint,
        onTap: callbacks.onShare,
      ),
      _AppleActionRow(
        icon: AdaptiveIcons.delete,
        label: l10n.deleteButton,
        color: destructive,
        onTap: () => callbacks.onDelete(() => _confirmDelete(context, l10n)),
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

  /// iOS action sheet with Delete in the destructive red and a separate
  /// Cancel, as Photos and Mail confirm a deletion. Unlike an alert, a tap
  /// outside cancels it. It keeps the theme of the sheet it is opened from
  /// (e.g. the map's), not the app's.
  Future<bool> _confirmDelete(
    BuildContext context,
    AppLocalizations l10n,
  ) async {
    final result = await AdaptiveDialog.show(
      context: context,
      title: l10n.tripsDetailsDeleteDialogTitle,
      message: l10n.tripsDetailsDeleteDialogMessage,
      useActionSheetOnIOS: true,
      barrierDismissible: true,
      // Opened from the trip sheet, which sits on the root navigator.
      skipWhenRootCanPop: false,
      actions: [
        AdaptiveDialogAction(
          label: l10n.deleteButton,
          result: AdaptiveDialogResult.primary,
          isDestructive: true,
        ),
        AdaptiveDialogAction(
          label: CupertinoLocalizations.of(context).cancelButtonLabel,
          result: AdaptiveDialogResult.cancelled,
          isDefault: true,
        ),
      ],
    );
    return result == AdaptiveDialogResult.primary;
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
