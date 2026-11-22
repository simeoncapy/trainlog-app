import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:trainlog_app/core/providers/pre_record_provider.dart';
import 'package:trainlog_app/features/spr/widgets/spr_page_actions.dart';
import 'package:trainlog_app/l10n/app_localizations.dart';
import 'package:trainlog_app/navigation/nav_models.dart';
import 'package:trainlog_app/ui/adaptive/adaptive_button.dart';
import 'package:trainlog_app/utils/platform_utils.dart';

/// Smart Prerecorder, iOS: sort and delete in the navigation bar, and a
/// fixed bottom bar with "Create trip" and "Record". Selecting a record
/// gives a selection haptic.
class SprCupertinoView extends StatelessWidget {
  const SprCupertinoView({super.key, required this.actions});

  final SprPageActions actions;

  @override
  Widget build(BuildContext context) {
    final prerecords = context.watch<PreRecordProvider>();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!context.mounted) return;
      actions.onPrimaryActionsReady([
        AppPrimaryAction(
          onPressed: prerecords.toggleSortOrder,
          icon: actions.sortIcon,
          tooltip: actions.sortTooltip,
        ),
        AppPrimaryAction(
          onPressed: actions.delete,
          icon: AdaptiveIcons.delete,
          label: actions.deleteLabel(short: true),
          isDestructive: true,
        ),
      ]);
    });

    return SprPageLayout(
      actions: actions,
      // Small visual spacing above the fixed bar.
      bottomSpacing: 8,
      onSelectionTap: HapticFeedback.selectionClick,
      bottomBar: Padding(
        padding: const EdgeInsets.only(top: 8),
        child: CupertinoSprButtonBar(actions: actions),
      ),
    );
  }
}

/// Create-trip + record buttons (delete / sort live in the navigation bar),
/// under the validation banner when there is one.
class CupertinoSprButtonBar extends StatelessWidget {
  const CupertinoSprButtonBar({super.key, required this.actions});

  final SprPageActions actions;

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context)!;
    final errorBanner = actions.errorBanner;
    final onCreateTrip = actions.createTrip;
    final onRecord = actions.record;
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
}
