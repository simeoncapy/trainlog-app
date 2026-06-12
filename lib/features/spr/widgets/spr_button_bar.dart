import 'package:flutter/material.dart';
import 'package:trainlog_app/l10n/app_localizations.dart';
import 'package:trainlog_app/platform/adaptive_button.dart';
import 'package:trainlog_app/platform/widget/adaptive_app_bar_square_button.dart';
import 'package:trainlog_app/utils/platform_utils.dart';

/// Bottom action bar of the Smart Prerecorder.
///
/// On Apple platforms: create-trip + record buttons (delete/sort live in the
/// app bar). On other platforms: delete + sort (create/record live in the
/// FAB). The validation banner, when present, is shown above either row.
class SprButtonBar extends StatelessWidget {
  final List<Widget> errorBanner;

  /// Null while the current selection cannot produce a trip.
  final VoidCallback? onCreateTrip;
  final VoidCallback onRecord;
  final VoidCallback onDelete;
  final VoidCallback onToggleSort;
  final IconData sortIcon;
  final String sortTooltip;
  final String deleteLabel;

  const SprButtonBar({
    super.key,
    required this.errorBanner,
    required this.onCreateTrip,
    required this.onRecord,
    required this.onDelete,
    required this.onToggleSort,
    required this.sortIcon,
    required this.sortTooltip,
    required this.deleteLabel,
  });

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context)!;

    if (AppPlatform.isApple) {
      return Column(
        children: [
          ...errorBanner,
          Row(
            children: [
              Expanded(
                child: AdaptiveButton.build(
                  context: context,
                  label: Text(
                    loc.prerecorderCreateTripButton,
                    overflow: TextOverflow.ellipsis,
                    maxLines: 1,
                    softWrap: false,
                  ),
                  icon: AdaptiveIcons.add,
                  onPressed: onCreateTrip,
                  size: AdaptiveButton.large,
                  type: AdaptiveButtonType.secondary,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: AdaptiveButton.build(
                  context: context,
                  label: Text(loc.prerecorderRecordButton),
                  icon: AdaptiveIcons.edit,
                  onPressed: onRecord,
                  size: AdaptiveButton.large,
                  type: AdaptiveButtonType.primary,
                ),
              ),
            ],
          ),
        ],
      );
    }

    return Column(
      children: [
        ...errorBanner,
        Row(
          children: [
            IntrinsicWidth(
              child: AdaptiveButton.build(
                context: context,
                label: Text(deleteLabel),
                icon: AdaptiveIcons.delete,
                type: AdaptiveButtonType.destructive,
                size: AdaptiveButton.small,
                onPressed: onDelete,
              ),
            ),
            const Spacer(),
            AdaptiveAppBarSquareButton(
              icon: sortIcon,
              onPressed: onToggleSort,
              tooltip: sortTooltip,
              size: 48,
              iconSize: 24,
            ),
          ],
        ),
      ],
    );
  }
}
