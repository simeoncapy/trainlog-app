import 'package:flutter/material.dart';
import 'package:trainlog_app/features/trips/detail_sheet/trip_details_actions.dart';
import 'package:trainlog_app/features/trips/detail_sheet/trip_details_common.dart';
import 'package:trainlog_app/l10n/app_localizations.dart';
import 'package:trainlog_app/utils/platform_utils.dart';

/// Trip actions, Material view (Android): a row of equal-width buttons, icon
/// above label, pinned at the bottom of the sheet (outside the scroll view).
class TripActionsMaterialView extends StatelessWidget {
  const TripActionsMaterialView({super.key, required this.callbacks});

  final TripActionCallbacks callbacks;

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
            onTap: callbacks.onEdit,
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
            onTap: callbacks.onDuplicate,
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
            onTap: callbacks.onShare,
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: _ActionButton(
            icon: AdaptiveIcons.delete,
            label: l10n.deleteButton,
            background: cs.error.withValues(alpha: 0.12),
            foreground: cs.error,
            onTap: () =>
                callbacks.onDelete(() => _confirmDelete(context, l10n)),
          ),
        ),
      ],
    );
  }

  Future<bool> _confirmDelete(
    BuildContext context,
    AppLocalizations l10n,
  ) async {
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
            child: Text(l10n.deleteButton),
          ),
        ],
      ),
    );
    return confirmed == true;
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
