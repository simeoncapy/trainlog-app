import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:trainlog_app/core/providers/trainlog_provider.dart';
import 'package:trainlog_app/features/trips/search_filter_sheet/filter_group_section.dart';
import 'package:trainlog_app/features/trips/search_filter_sheet/sheet_common.dart';
import 'package:trainlog_app/features/trips/search_filter_sheet/trips_filter_controller.dart';
import 'package:trainlog_app/features/trips/search_filter_sheet/trips_filter_entries.dart';
import 'package:trainlog_app/features/trips/search_filter_sheet/when_section.dart';
import 'package:trainlog_app/l10n/app_localizations.dart';
import 'package:trainlog_app/ui/adaptive/adaptive_vehicle_type_filter_chips.dart';
import 'package:trainlog_app/ui/cupertino/glass_filter_parts.dart';

/// Trips search & filter, iOS 26 view: glass ✕ / title / ↺ bar, search
/// field, a grouped list (period menu with optional From / To dates,
/// countries and operators as summary rows opening the pickers), the
/// vehicle capsules and the solid amber "Show N trips" button. The Liquid
/// Glass sheet draws its own grab handle.
///
/// Reads and changes the shared [TripsFilterController]. When [picker] is
/// set (country or operator picker), it replaces the form and the footer.
class TripsFilterCupertinoView extends StatelessWidget {
  const TripsFilterCupertinoView({
    super.key,
    required this.keywordController,
    required this.scrollController,
    required this.picker,
    required this.onOpenCountries,
    required this.onOpenOperators,
  });

  final TextEditingController keywordController;
  final ScrollController scrollController;
  final Widget? picker;
  final VoidCallback onOpenCountries;
  final VoidCallback onOpenOperators;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Column(
      children: [
        Expanded(child: picker ?? _buildMainView(context, l10n)),
        if (picker == null) _actionFooter(context, l10n),
      ],
    );
  }

  Widget _buildMainView(BuildContext context, AppLocalizations l10n) {
    final filter = context.watch<TripsFilterController>();
    final trainlog = Provider.of<TrainlogProvider>(context, listen: false);

    String summary(List<GroupEntry> selected, int total) {
      // None selected = no restriction; all selected reads the same.
      if (selected.isEmpty || selected.length == total) {
        return l10n.tripsSearchFilterAny;
      }
      final shown = selected.take(2).map((e) => e.label).join(', ');
      return selected.length > 2 ? '$shown +${selected.length - 2}' : shown;
    }

    final countries = countryEntries(context, filter);
    final operators = operatorEntries(context, filter, trainlog);
    final selectedCountryEntries = countries
        .where((e) => filter.countries.contains(e.value))
        .toList();
    final selectedOperatorEntries = operators
        .where((e) => filter.operators.contains(e.value))
        .toList();
    final allTypesSelected = filter.allTypesSelected;

    return Column(
      children: [
        GlassSheetHeader(
          title: l10n.tripsSearchFilterTitle,
          closeTooltip: MaterialLocalizations.of(context).closeButtonTooltip,
          resetTooltip: l10n.mapFilterReset,
          onClose: () => Navigator.of(context, rootNavigator: true).pop(),
          onReset: filter.reset,
        ),
        Expanded(
          child: SingleChildScrollView(
            controller: scrollController,
            padding: const EdgeInsets.fromLTRB(16, 4, 16, 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                SheetSearchField(
                  controller: keywordController,
                  placeholder: l10n.tripsSearchFilterSearchHint,
                ),
                const SizedBox(height: 18),
                WhenSection(
                  quickFilter: filter.quickFilter,
                  fromDate: filter.fromDate,
                  toDate: filter.toDate,
                  onQuickFilterSelected: filter.selectQuickFilter,
                  onCustomSelected: filter.selectCustomRange,
                  onFromDateChanged: filter.setFromDate,
                  onToDateChanged: filter.setToDate,
                ),
                const SizedBox(height: 18),
                GlassFormGroup(
                  children: [
                    GlassFormRow(
                      title: l10n.tripsSearchFilterCountries,
                      trailing: GlassDisclosure(
                        value: summary(
                          selectedCountryEntries,
                          countries.length,
                        ),
                      ),
                      onTap: onOpenCountries,
                    ),
                    GlassFormRow(
                      title: l10n.tripsSearchFilterOperators,
                      trailing: GlassDisclosure(
                        value: summary(
                          selectedOperatorEntries,
                          operators.length,
                        ),
                      ),
                      onTap: onOpenOperators,
                    ),
                  ],
                ),
                const SizedBox(height: 22),
                GlassFilterSectionHeader(
                  title: l10n.typeTitle,
                  actionLabel: allTypesSelected
                      ? l10n.filterDeselectAll
                      : l10n.filterSelectAll,
                  onAction: allTypesSelected
                      ? filter.clearTypes
                      : filter.selectAllTypes,
                ),
                const SizedBox(height: 6),
                AdaptiveVehicleTypeFilterChips(
                  availableTypes: filter.typeOptions,
                  selectedTypes: filter.types,
                  onTypeToggle: filter.setTypeSelected,
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _actionFooter(BuildContext context, AppLocalizations l10n) {
    final filter = context.watch<TripsFilterController>();
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
      child: GlassPrimaryButton(
        icon: Icons.directions_transit_outlined,
        label: l10n.mapFilterShowTrips(filter.matchCount),
        onPressed: () =>
            Navigator.of(context, rootNavigator: true).pop(filter.result),
      ),
    );
  }
}
