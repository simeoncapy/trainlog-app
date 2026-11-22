import 'package:flutter/cupertino.dart';
import 'package:provider/provider.dart';
import 'package:trainlog_app/features/trips/trips_page.dart';
import 'package:trainlog_app/features/trips/trips_page_controller.dart';
import 'package:trainlog_app/features/trips/widgets/trips_page_body.dart';
import 'package:trainlog_app/l10n/app_localizations.dart';
import 'package:trainlog_app/navigation/nav_models.dart';
import 'package:trainlog_app/utils/platform_utils.dart';

/// Trips page, iOS: the filter, the view toggle and "clear filter" are
/// grouped glass buttons in the navigation bar next to "New trip", instead
/// of a header row in the page (the title is in the navigation bar too).
class TripsPageCupertinoView extends StatelessWidget {
  const TripsPageCupertinoView({super.key, required this.actions});

  final TripsPageActions actions;

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context)!;
    final controller = context.watch<TripsPageController>();
    final isCardView = controller.isCardView;
    final barActions = [
      actions.addTripAction(),
      AppPrimaryAction(
        icon: AdaptiveIcons.search,
        tooltip: loc.filterButton,
        onPressed: actions.openFilter,
      ),
      AppPrimaryAction(
        icon: isCardView
            ? CupertinoIcons.table
            : CupertinoIcons.rectangle_grid_1x2,
        tooltip: isCardView
            ? loc.tripsTableViewTooltip
            : loc.tripsCardViewTooltip,
        onPressed: controller.toggleView,
      ),
      if (controller.activeFilter != null)
        AppPrimaryAction(
          icon: CupertinoIcons.clear,
          tooltip: loc.filterClearButton,
          onPressed: controller.clearFilter,
        ),
    ];
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (context.mounted) actions.onPrimaryActionsReady(barActions);
    });

    return TripsPageBody(
      actions: actions,
      // Above the floating tab bar and the home indicator.
      tableFooterHeight: (bottomInset) => bottomInset + 50,
      header: const SizedBox(height: 4),
    );
  }
}
