import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:trainlog_app/core/data/models/time_moment.dart';
import 'package:trainlog_app/core/data/models/trips_filter.dart';
import 'package:trainlog_app/core/providers/trainlog_provider.dart';
import 'package:trainlog_app/core/providers/trips_provider.dart';
import 'package:trainlog_app/features/menu/menu_summary_card.dart';
import 'package:trainlog_app/features/trips/trips_page.dart';
import 'package:trainlog_app/features/trips/trips_page_controller.dart';
import 'package:trainlog_app/features/trips/widgets/trip_card_view.dart';
import 'package:trainlog_app/features/trips/widgets/trip_table_view.dart';
import 'package:trainlog_app/l10n/app_localizations.dart';
import 'package:trainlog_app/ui/adaptive/app_steps_tab_bar.dart';

/// The trips page under its header, the same on both designs: pull to
/// refresh, the trip count (card view), Past / Future, then the cards or
/// the table. A view can draw the count elsewhere ([showSummary]) and give
/// its own list in place of the cards ([cardView]).
class TripsPageBody extends StatelessWidget {
  const TripsPageBody({
    super.key,
    required this.actions,
    required this.header,
    required this.tableFooterHeight,
    this.showSummary = true,
    this.cardView,
  });

  final TripsPageActions actions;

  /// What sits above the trip count.
  final Widget header;

  /// See [TripTableView.footerHeight].
  final double Function(double bottomInset) tableFooterHeight;

  /// Shows the trip count block above Past / Future (card view only).
  final bool showSummary;

  /// Builds the list shown in card view; defaults to [TripCardView]. [key]
  /// changes with the filter and Past / Future.
  final Widget Function(
    Key key,
    TripsFilterResult? filter,
    TimeMoment timeMoment,
    int revision,
  )?
  cardView;

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context)!;
    final controller = context.watch<TripsPageController>();
    final repo = context.select((TripsProvider p) => p.repository)!;
    final revision = context.select((TripsProvider p) => p.revision);
    final trainlog = context.read<TrainlogProvider>();
    final filter = controller.activeFilter;
    final moment = controller.timeMoment;

    return SafeArea(
      top: false,
      bottom: false,
      child: RefreshIndicator(
        key: actions.refreshKey,
        onRefresh: actions.onRefresh,
        child: Column(
          children: [
            header,

            // ── Summary block (card view only) ──────────────────────────
            if (controller.isCardView && showSummary)
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
                child: _SummaryBlock(count: controller.summaryCount),
              ),

            // ── Past / Future tab selector ───────────────────────────────
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
              child: AppStepsTabBar(
                fullWidth: true,
                tabs: [
                  AppStepsTab(
                    label: loc.yearPastList,
                    leadingIcon: const Icon(Icons.restore),
                  ),
                  AppStepsTab(
                    label: loc.yearFutureList,
                    leadingIcon: const Icon(Icons.next_plan_outlined),
                  ),
                ],
                selectedIndex: moment == TimeMoment.past ? 0 : 1,
                onTabChanged: (i) => controller.setTimeMoment(
                  i == 0 ? TimeMoment.past : TimeMoment.future,
                ),
              ),
            ),

            // ── Content view ─────────────────────────────────────────────
            Expanded(
              child: controller.isCardView && cardView != null
                  ? cardView!(
                      ValueKey('card-$moment-${filter.hashCode}'),
                      filter,
                      moment,
                      revision,
                    )
                  : controller.isCardView
                  ? TripCardView(
                      key: ValueKey('card-$moment-${filter.hashCode}'),
                      repo: repo,
                      trainlog: trainlog,
                      filter: filter,
                      timeMoment: moment,
                      revision: revision,
                    )
                  : TripTableView(
                      key: ValueKey('table-$moment-${filter.hashCode}'),
                      repo: repo,
                      trainlog: trainlog,
                      filter: filter,
                      timeMoment: moment,
                      revision: revision,
                      footerHeight: tableFooterHeight,
                    ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SummaryBlock extends StatelessWidget {
  const _SummaryBlock({required this.count});
  final int count;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      decoration: BoxDecoration(
        color: cs.inverseSurface,
        borderRadius: BorderRadius.circular(12),
      ),
      child: TripCountLine(count: count),
    );
  }
}
