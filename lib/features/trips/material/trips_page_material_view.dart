import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:trainlog_app/features/trips/trips_page.dart';
import 'package:trainlog_app/features/trips/trips_page_controller.dart';
import 'package:trainlog_app/features/trips/widgets/trips_page_body.dart';
import 'package:trainlog_app/l10n/app_localizations.dart';
import 'package:trainlog_app/ui/adaptive/adaptive_widget.dart';
import 'package:trainlog_app/utils/platform_utils.dart';

/// Trips page, Material 3 (Android): "New trip" in the shell, and a header
/// row in the page with the title, the view toggle and the filter.
class TripsPageMaterialView extends StatelessWidget {
  const TripsPageMaterialView({super.key, required this.actions});

  final TripsPageActions actions;

  @override
  Widget build(BuildContext context) {
    final controller = context.watch<TripsPageController>();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (context.mounted) {
        actions.onPrimaryActionsReady([actions.addTripAction()]);
      }
    });

    return TripsPageBody(
      actions: actions,
      tableFooterHeight: (_) => 180.0,
      header: _PageHeader(
        isCardView: controller.isCardView,
        filterActive: controller.activeFilter != null,
        onToggleView: controller.toggleView,
        onFilterTap: actions.openFilter,
        onClearFilter: controller.clearFilter,
      ),
    );
  }
}

class _PageHeader extends StatelessWidget {
  const _PageHeader({
    required this.isCardView,
    required this.filterActive,
    required this.onToggleView,
    required this.onFilterTap,
    required this.onClearFilter,
  });

  final bool isCardView;
  final bool filterActive;
  final VoidCallback onToggleView;
  final VoidCallback onFilterTap;
  final VoidCallback onClearFilter;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 12, 8),
      child: Row(
        children: [
          Expanded(
            child: Text(
              AppLocalizations.of(context)!.menuTripsTitle,
              style: Theme.of(
                context,
              ).textTheme.headlineMedium?.copyWith(fontWeight: FontWeight.w700),
            ),
          ),

          // View toggle
          AdaptiveAppBarSquareButton(
            icon: isCardView
                ? Icons.table_chart_outlined
                : Icons.view_agenda_outlined,
            onPressed: onToggleView,
            tooltip: isCardView
                ? AppLocalizations.of(context)!.tripsTableViewTooltip
                : AppLocalizations.of(context)!.tripsCardViewTooltip,
            size: 36,
            iconSize: 18,
          ),

          // Clear filter (when active)
          if (filterActive) ...[
            const SizedBox(width: 8),
            AdaptiveAppBarSquareButton(
              icon: Icons.search_off,
              onPressed: onClearFilter,
              tooltip: AppLocalizations.of(context)!.filterClearButton,
              size: 36,
              iconSize: 18,
              circle: true,
            ),
          ],

          const SizedBox(width: 8),

          // Filter button
          AdaptiveAppBarSquareButton(
            icon: AdaptiveIcons.search,
            onPressed: onFilterTap,
            tooltip: AppLocalizations.of(context)!.filterButton,
            size: 36,
            iconSize: 18,
          ),
        ],
      ),
    );
  }
}
