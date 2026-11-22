import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:trainlog_app/core/providers/trainlog_provider.dart';
import 'package:trainlog_app/features/trips/search_filter_sheet/filter_group_section.dart';
import 'package:trainlog_app/features/trips/search_filter_sheet/sheet_common.dart';
import 'package:trainlog_app/features/trips/search_filter_sheet/trips_filter_controller.dart';
import 'package:trainlog_app/features/trips/search_filter_sheet/trips_filter_entries.dart';
import 'package:trainlog_app/features/trips/search_filter_sheet/material/when_section_material.dart';
import 'package:trainlog_app/l10n/app_localizations.dart';
import 'package:trainlog_app/ui/adaptive/adaptive_search_field.dart';
import 'package:trainlog_app/ui/adaptive/adaptive_vehicle_type_filter_chips.dart';
import 'package:trainlog_app/widgets/primary_action_button.dart';

/// Trips search & filter, Material 3 view (Android): grab handle, a header
/// with a "Reset" text button, the form (search, period, countries and
/// operators as removable chips, vehicle types) and the "Show N trips"
/// button pinned at the bottom.
///
/// Reads and changes the shared [TripsFilterController]. When [picker] is
/// set (country or operator picker), it replaces the form and the footer.
class TripsFilterMaterialView extends StatelessWidget {
  const TripsFilterMaterialView({
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
        _grabHandle(context),
        Expanded(child: picker ?? _buildMainView(context, l10n)),
        if (picker == null) _actionFooter(context, l10n),
      ],
    );
  }

  Widget _grabHandle(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.only(top: 10, bottom: 4),
      child: Center(
        child: Container(
          width: 36,
          height: 5,
          decoration: BoxDecoration(
            color: cs.onSurfaceVariant.withValues(alpha: 0.4),
            borderRadius: BorderRadius.circular(99),
          ),
        ),
      ),
    );
  }

  Widget _buildMainView(BuildContext context, AppLocalizations l10n) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    final filter = context.watch<TripsFilterController>();
    final trainlog = Provider.of<TrainlogProvider>(context, listen: false);

    final selectedCountryEntries = countryEntries(
      context,
      filter,
    ).where((e) => filter.countries.contains(e.value)).toList();
    final selectedOperatorEntries = operatorEntries(
      context,
      filter,
      trainlog,
    ).where((e) => filter.operators.contains(e.value)).toList();

    return Column(
      children: [
        // ── Header ─────────────────────────────────────────────────────────
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 4, 12, 8),
          child: Row(
            children: [
              Container(
                width: 34,
                height: 34,
                decoration: BoxDecoration(
                  color: cs.primary,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(Icons.search, size: 20, color: cs.onPrimary),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  l10n.tripsSearchFilterTitle,
                  style: theme.textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              SheetMiniButton(
                label: l10n.mapFilterReset,
                emphasized: true,
                onTap: filter.reset,
              ),
            ],
          ),
        ),

        // ── Scrollable form ────────────────────────────────────────────────
        Expanded(
          child: SingleChildScrollView(
            controller: scrollController,
            padding: const EdgeInsets.fromLTRB(16, 4, 16, 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Text search — feeds the keyword query for both the card and
                // the table view.
                AdaptiveSearchField(
                  controller: keywordController,
                  placeholder: l10n.tripsSearchFilterSearchHint,
                ),
                const SizedBox(height: 20),

                // When
                MaterialWhenSection(
                  quickFilter: filter.quickFilter,
                  fromDate: filter.fromDate,
                  toDate: filter.toDate,
                  onQuickFilterSelected: filter.selectQuickFilter,
                  onFromDateChanged: filter.setFromDate,
                  onToDateChanged: filter.setToDate,
                ),
                const SizedBox(height: 20),

                // Countries
                FilterGroupSection(
                  title: l10n.tripsSearchFilterCountries,
                  addLabel: l10n.tripsSearchFilterAdd,
                  selectedEntries: selectedCountryEntries,
                  onAdd: onOpenCountries,
                  onRemove: (value) => filter.setCountrySelected(value, false),
                ),
                const SizedBox(height: 20),

                // Operators
                FilterGroupSection(
                  title: l10n.tripsSearchFilterOperators,
                  addLabel: l10n.tripsSearchFilterAdd,
                  selectedEntries: selectedOperatorEntries,
                  onAdd: onOpenOperators,
                  onRemove: (value) => filter.setOperatorSelected(value, false),
                ),
                const SizedBox(height: 20),

                // Vehicle types
                SheetSectionTitle(
                  text: l10n.typeTitle,
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      SheetMiniButton(
                        label: l10n.mapFilterVehicleTypeAllBtn,
                        emphasized: true,
                        onTap: filter.selectAllTypes,
                      ),
                      const SizedBox(width: 4),
                      SheetMiniButton(
                        label: l10n.mapFilterVehicleTypeNoneBtn,
                        onTap: filter.clearTypes,
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 10),
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
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
      child: PrimaryActionButton(
        onPressed: () => Navigator.of(context).pop(filter.result),
        icon: Icons.directions_transit_outlined,
        label: l10n.mapFilterShowTrips(filter.matchCount),
      ),
    );
  }
}
