import 'package:flutter/widgets.dart';
import 'package:provider/provider.dart';
import 'package:trainlog_app/core/data/models/polyline_filter_state.dart';
import 'package:trainlog_app/core/providers/polyline_provider.dart';
import 'package:trainlog_app/l10n/app_localizations.dart';
import 'package:trainlog_app/ui/adaptive/app_steps_tab_bar.dart';

/// The map filter's time range control (All, Past, Future, Years), shared by
/// both views: [AppStepsTabBar] draws the Material track on Android and the
/// Liquid Glass segmented control (text only) on iOS.
class MapFilterTimeRange extends StatelessWidget {
  const MapFilterTimeRange({super.key, this.onYearsChosen});

  /// Called when the user switches to "Years", so the view can show the
  /// first page of its year grid.
  final VoidCallback? onYearsChosen;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final poly = context.watch<PolylineProvider>();
    return AppStepsTabBar(
      fullWidth: true,
      selectedIndex: poly.yearFilterChoice.index,
      tabs: [
        AppStepsTab(label: l10n.yearAllList),
        AppStepsTab(label: l10n.yearPastList),
        AppStepsTab(label: l10n.yearFutureList),
        AppStepsTab(label: l10n.yearTitle),
      ],
      onTabChanged: (index) {
        final choice = PolylineYearFilter.values[index];
        context.read<PolylineProvider>().setYearFilter(choice);
        if (choice == PolylineYearFilter.years) onYearsChosen?.call();
      },
    );
  }
}
