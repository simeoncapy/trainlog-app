import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:trainlog_app/core/data/models/pre_record_model.dart';
import 'package:trainlog_app/core/providers/pre_record_provider.dart';
import 'package:trainlog_app/features/spr/widgets/pre_record_tile.dart';
import 'package:trainlog_app/l10n/app_localizations.dart';
import 'package:trainlog_app/navigation/nav_models.dart';

/// What the Smart Prerecorder views can ask the page for, and what they
/// show of the current selection.
class SprPageActions {
  const SprPageActions({
    required this.onPrimaryActionsReady,
    required this.explanation,
    required this.errorBanner,
    required this.isValidSelection,
    required this.createTrip,
    required this.record,
    required this.delete,
    required this.openNote,
    required this.sortIcon,
    required this.sortTooltip,
    required this.deleteLabel,
  });

  /// Hands the shell the actions of its bar.
  final SetPrimaryActions onPrimaryActionsReady;

  /// The "How it works" expansion tile.
  final Widget explanation;

  /// Why the selection cannot become a trip, with the spacing under it.
  final List<Widget> errorBanner;

  /// The selection is a departure / arrival pair that can become a trip.
  final bool isValidSelection;

  /// Null while the current selection cannot produce a trip.
  final VoidCallback? createTrip;
  final VoidCallback record;

  /// Deletes the selection, or every record (after confirmation).
  final VoidCallback delete;
  final ValueChanged<PreRecordModel> openNote;
  final IconData sortIcon;
  final String sortTooltip;
  final String Function({bool short}) deleteLabel;
}

/// The page under the shell, the same on both designs: the explanation,
/// optional [topControls], then the records; [bottomBar] stays fixed under
/// them.
class SprPageLayout extends StatelessWidget {
  const SprPageLayout({
    super.key,
    required this.actions,
    required this.bottomSpacing,
    this.topControls,
    this.bottomBar,
    this.onSelectionTap,
  });

  final SprPageActions actions;

  /// Space under the last record.
  final double bottomSpacing;
  final Widget? topControls;
  final Widget? bottomBar;

  /// Called when a record is tapped, before it is (de)selected.
  final VoidCallback? onSelectionTap;

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final prerecords = context.watch<PreRecordProvider>();
    final records = prerecords.records;

    return Padding(
      padding: const EdgeInsets.all(8.0),
      child: Column(
        children: [
          Expanded(
            child: CustomScrollView(
              slivers: [
                SliverToBoxAdapter(child: actions.explanation),
                const SliverToBoxAdapter(child: SizedBox(height: 16)),
                if (topControls != null) ...[
                  SliverToBoxAdapter(child: topControls),
                  const SliverToBoxAdapter(child: SizedBox(height: 8)),
                ],
                if (records.isEmpty)
                  SliverFillRemaining(
                    hasScrollBody: false,
                    child: Center(
                      child: Text(
                        loc.prerecorderNoData,
                        style: theme.textTheme.bodyLarge,
                      ),
                    ),
                  )
                else
                  SliverList(
                    delegate: SliverChildBuilderDelegate((context, index) {
                      final record = records[index];
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 8),
                        child: PreRecordTile(
                          record: record,
                          selected: prerecords.isSelected(record.id),
                          selectionIndex: prerecords.selectionIndexOf(
                            record.id,
                          ),
                          onTap: () {
                            onSelectionTap?.call();
                            prerecords.toggleSelection(record.id);
                          },
                          onNote: () => actions.openNote(record),
                        ),
                      );
                    }, childCount: records.length),
                  ),
                SliverToBoxAdapter(child: SizedBox(height: bottomSpacing)),
              ],
            ),
          ),
          if (bottomBar != null) bottomBar!,
        ],
      ),
    );
  }
}
