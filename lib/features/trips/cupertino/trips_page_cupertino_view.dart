import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart' show Theme;
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:trainlog_app/core/providers/trips_provider.dart';
import 'package:trainlog_app/features/trips/cupertino/trips_list_cupertino.dart';
import 'package:trainlog_app/features/trips/trips_page.dart';
import 'package:trainlog_app/features/trips/trips_page_controller.dart';
import 'package:trainlog_app/features/trips/widgets/trips_page_body.dart';
import 'package:trainlog_app/l10n/app_localizations.dart';
import 'package:trainlog_app/navigation/nav_models.dart';
import 'package:trainlog_app/ui/tokens/app_theme.dart';
import 'package:trainlog_app/utils/platform_utils.dart';

/// Trips page, iOS: the filter, the view toggle and "clear filter" are
/// grouped glass buttons in the navigation bar, instead of a header row in
/// the page (the title is in the navigation bar too, with the trip count
/// as its subtitle). The cards are an inset grouped list by month
/// ([TripsListCupertino]).
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

    final repo = context.select((TripsProvider p) => p.repository)!;
    return TripsPageBody(
      actions: actions,
      // Above the floating tab bar and the home indicator.
      tableFooterHeight: (bottomInset) => bottomInset + 50,
      header: _TripCountSubtitle(
        count: controller.summaryCount,
        future: controller.showsFutureTrips,
        filtered: controller.activeFilter != null,
      ),
      showSummary: false,
      cardView: (key, filter, moment, revision) => TripsListCupertino(
        key: key,
        repo: repo,
        filter: filter,
        timeMoment: moment,
        revision: revision,
      ),
    );
  }
}

/// The trip count under the large title, as a navigation bar subtitle:
/// "1,234 past trips", "· filtered" while a search or filter is active.
class _TripCountSubtitle extends StatelessWidget {
  const _TripCountSubtitle({
    required this.count,
    required this.future,
    required this.filtered,
  });

  final int count;
  final bool future;
  final bool filtered;

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context)!;
    final theme = CupertinoTheme.of(context);
    final style = Theme.of(context).textTheme.bodyMedium?.copyWith(
      color: CupertinoColors.secondaryLabel.resolveFrom(context),
    );
    final number = NumberFormat.decimalPattern(
      Localizations.localeOf(context).toString(),
    ).format(count);
    final label = future
        ? loc.tripsCountFutureLabel(count)
        : loc.tripsCountPastLabel(count);

    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 0, 16, 12),
      child: Align(
        alignment: Alignment.centerLeft,
        child: Text.rich(
          TextSpan(
            children: [
              TextSpan(
                text: number,
                style: AppTheme.monoFont.copyWith(
                  fontWeight: FontWeight.w700,
                  color: theme.primaryColor,
                ),
              ),
              TextSpan(text: ' $label'),
              if (filtered) TextSpan(text: ' · ${loc.tripsCountFiltered}'),
            ],
          ),
          style: style,
        ),
      ),
    );
  }
}
