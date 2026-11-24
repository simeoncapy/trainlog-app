import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:trainlog_app/core/providers/pre_record_provider.dart';
import 'package:trainlog_app/features/spr/widgets/spr_page_actions.dart';
import 'package:trainlog_app/l10n/app_localizations.dart';
import 'package:trainlog_app/navigation/nav_models.dart';
import 'package:trainlog_app/ui/adaptive/adaptive_button.dart';
import 'package:trainlog_app/ui/adaptive/widget/adaptive_app_bar_square_button.dart';
import 'package:trainlog_app/utils/platform_utils.dart';

/// Smart Prerecorder, Material: delete and sort above the records, and the
/// FAB records a Geolog, or creates the trip once a valid pair is selected.
class SprMaterialView extends StatelessWidget {
  const SprMaterialView({super.key, required this.actions});

  final SprPageActions actions;

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context)!;
    context.watch<PreRecordProvider>();
    final valid = actions.isValidSelection;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!context.mounted) return;
      actions.onPrimaryActionsReady([
        AppPrimaryAction(
          onPressed: valid ? actions.createTrip! : actions.record,
          icon: valid ? AdaptiveIcons.add : AdaptiveIcons.edit,
          label: valid
              ? loc.prerecorderCreateTripButton
              : loc.prerecorderRecordButton,
        ),
      ]);
    });

    return SprPageLayout(
      actions: actions,
      // Room for the FAB over the list.
      bottomSpacing: 88,
      topControls: MaterialSprButtonBar(actions: actions),
    );
  }
}

/// Delete + sort row (create / record live in the FAB), under the
/// validation banner when there is one.
class MaterialSprButtonBar extends StatelessWidget {
  const MaterialSprButtonBar({super.key, required this.actions});

  final SprPageActions actions;

  @override
  Widget build(BuildContext context) {
    final errorBanner = actions.errorBanner;
    final deleteLabel = actions.deleteLabel();
    final onDelete = actions.delete;
    final sortIcon = actions.sortIcon;
    final onToggleSort = context.read<PreRecordProvider>().toggleSortOrder;
    final sortTooltip = actions.sortTooltip;
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
