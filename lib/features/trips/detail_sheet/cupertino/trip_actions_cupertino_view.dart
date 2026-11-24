import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:trainlog_app/features/trips/detail_sheet/trip_details_actions.dart';
import 'package:trainlog_app/l10n/app_localizations.dart';
import 'package:trainlog_app/ui/adaptive/adaptive_dialog.dart';
import 'package:trainlog_app/utils/platform_utils.dart';

/// Trip actions, iOS view: a row of four equal tiles, icon above label, like
/// the action row of an Apple Maps place. Edit is filled with the accent,
/// Duplicate and Share are tinted with it, Delete is tinted with the system
/// destructive red and confirms with an action sheet.
class TripActionsCupertinoView extends StatelessWidget {
  const TripActionsCupertinoView({super.key, required this.callbacks});

  final TripActionCallbacks callbacks;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final cs = Theme.of(context).colorScheme;
    final accent = cs.primary;
    final destructive = CupertinoColors.systemRed.resolveFrom(context);

    final tiles = [
      _AppleActionTile(
        icon: AdaptiveIcons.edit,
        label: l10n.tripsDetailsEditButton,
        background: accent,
        foreground: cs.onPrimary,
        onTap: callbacks.onEdit,
      ),
      _AppleActionTile(
        icon: AdaptiveIcons.copy,
        label: l10n.duplicateBtnLabel,
        background: accent.withValues(alpha: 0.16),
        foreground: accent,
        onTap: callbacks.onDuplicate,
      ),
      _AppleActionTile(
        icon: AdaptiveIcons.share,
        label: MaterialLocalizations.of(context).shareButtonLabel,
        background: accent.withValues(alpha: 0.16),
        foreground: accent,
        onTap: callbacks.onShare,
      ),
      _AppleActionTile(
        icon: AdaptiveIcons.delete,
        label: l10n.deleteButton,
        background: destructive.withValues(alpha: 0.16),
        foreground: destructive,
        onTap: () => callbacks.onDelete(() => _confirmDelete(context, l10n)),
      ),
    ];

    return Row(
      children: [
        for (var i = 0; i < tiles.length; i++) ...[
          if (i > 0) const SizedBox(width: 8),
          Expanded(child: tiles[i]),
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

/// One iOS action tile: a rounded rectangle (continuous corners) with the
/// icon above the label, in the tile's colours.
class _AppleActionTile extends StatefulWidget {
  final IconData icon;
  final String label;
  final Color background;
  final Color foreground;
  final VoidCallback onTap;

  const _AppleActionTile({
    required this.icon,
    required this.label,
    required this.background,
    required this.foreground,
    required this.onTap,
  });

  @override
  State<_AppleActionTile> createState() => _AppleActionTileState();
}

class _AppleActionTileState extends State<_AppleActionTile> {
  bool _pressed = false;

  void _setPressed(bool value) {
    if (_pressed != value) setState(() => _pressed = value);
  }

  @override
  Widget build(BuildContext context) {
    final fg = widget.foreground;
    // A plain tap recognizer (not CupertinoButton, which keeps the pointer):
    // a vertical drag starting on a tile must still move the sheet.
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
          child: DecoratedBox(
            decoration: ShapeDecoration(
              color: widget.background,
              shape: const RoundedSuperellipseBorder(
                borderRadius: BorderRadius.all(Radius.circular(16)),
              ),
            ),
            child: SizedBox(
              height: 64,
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 4),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(widget.icon, color: fg, size: 22),
                    const SizedBox(height: 4),
                    Text(
                      widget.label,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: Theme.of(context).textTheme.labelLarge?.copyWith(
                        color: fg,
                        fontWeight: FontWeight.w600,
                        letterSpacing: 0,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
