import 'dart:async';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:liquid_glass_widgets/liquid_glass_widgets.dart'
    show GlassSheetDetent, GlassSheetState;
import 'package:provider/provider.dart';
import 'package:trainlog_app/core/data/models/trips.dart';
import 'package:trainlog_app/core/data/models/trips_filter.dart';
import 'package:trainlog_app/core/data/trips_repository.dart';
import 'package:trainlog_app/features/trips/search_filter_sheet/filter_group_section.dart';
import 'package:trainlog_app/features/trips/search_filter_sheet/group_picker_view.dart';
import 'package:trainlog_app/features/trips/search_filter_sheet/sheet_common.dart';
import 'package:trainlog_app/features/trips/search_filter_sheet/when_section.dart';
import 'package:trainlog_app/l10n/app_localizations.dart';
import 'package:trainlog_app/platform/adaptive_sheet.dart';
import 'package:trainlog_app/platform/adaptive_vehicle_type_filter_chips.dart';
import 'package:trainlog_app/platform/glass_filter_parts.dart';
import 'package:trainlog_app/core/providers/trainlog_provider.dart';
import 'package:trainlog_app/utils/platform_utils.dart';
import 'package:trainlog_app/utils/style_utils.dart';
import 'package:trainlog_app/utils/text_utils.dart';
import 'package:trainlog_app/widgets/primary_action_button.dart';

/// Opens the trips search & filter interface as a bottom sheet, using the
/// same native presentation hooks as `showAdaptiveTripBottomSheet` (the trip
/// details sheet): a Material modal bottom sheet on Android, a Liquid Glass
/// sheet on Apple platforms.
///
/// Resolves with the new [TripsFilterResult] when the user confirms via the
/// "Show N trips" action, or null when the sheet is dismissed.
Future<TripsFilterResult?> showTripsSearchFilterSheet(
  BuildContext context, {
  required TripsRepository repo,
  required Map<String, String> countryOptions,
  required List<VehicleType> typeOptions,
  required bool showFutureTrips,
  TripsFilterResult? initialFilter,
}) {
  if (AppPlatform.isApple) {
    // A large-detent Liquid Glass sheet: opaque at rest like iOS 26 form
    // sheets, glass while it is dragged away.
    return showAppleDetentSheet<TripsFilterResult>(
      context: context,
      detents: const {GlassSheetDetent.large},
      initialState: GlassSheetState.full,
      // ✕ / title / ↺ level with the grab handle, as in iOS 26 sheets.
      topInset: kAppleSheetHeaderInset,
      // Page colour behind the grouped cells, as on the Settings page.
      expandedColor: CupertinoDynamicColor.resolve(
          CupertinoTheme.of(context).scaffoldBackgroundColor, context),
      builder: (ctx) => TripsSearchFilterSheet(
        repo: repo,
        countryOptions: countryOptions,
        typeOptions: typeOptions,
        showFutureTrips: showFutureTrips,
        initialFilter: initialFilter,
      ),
    );
  }

  return showModalBottomSheet<TripsFilterResult>(
    context: context,
    useSafeArea: true,
    isScrollControlled: true,
    backgroundColor: Theme.of(context).scaffoldBackgroundColor,//Theme.of(context).colorScheme.surface,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
    ),
    builder: (_) => FractionallySizedBox(
      heightFactor: 0.92,
      child: TripsSearchFilterSheet(
        repo: repo,
        countryOptions: countryOptions,
        typeOptions: typeOptions,
        showFutureTrips: showFutureTrips,
        initialFilter: initialFilter,
      ),
    ),
  );
}

enum _SheetView { main, countries, operators }

/// Body of the trips search & filter bottom sheet.
///
/// Owns the working copy of the filter, keeps the "Show N trips" preview
/// count up to date against the repository, and swaps between the main form
/// and the country/operator picker views.
class TripsSearchFilterSheet extends StatefulWidget {
  const TripsSearchFilterSheet({
    super.key,
    required this.repo,
    required this.countryOptions,
    required this.typeOptions,
    required this.showFutureTrips,
    this.initialFilter,
  });

  final TripsRepository repo;

  /// ISO code → localized country name, for every country present in the
  /// user's trips.
  final Map<String, String> countryOptions;
  final List<VehicleType> typeOptions;

  /// Page-level Past/Future scope, used for the preview count when the filter
  /// itself carries no date constraint.
  final bool showFutureTrips;
  final TripsFilterResult? initialFilter;

  @override
  State<TripsSearchFilterSheet> createState() => _TripsSearchFilterSheetState();
}

class _TripsSearchFilterSheetState extends State<TripsSearchFilterSheet> {
  final _keywordController = TextEditingController();
  final _mainScrollController = ScrollController();

  TripsQuickDateFilter? _quickFilter = TripsQuickDateFilter.allTime;
  DateTime? _fromDate;
  DateTime? _toDate;
  late Set<String> _countries;
  late Set<String> _operators;
  late Set<VehicleType> _types;

  _SheetView _view = _SheetView.main;

  /// value → number of trips, ordered by count (descending).
  Map<String, int> _countryTripCounts = const {};
  Map<String, int> _operatorTripCounts = const {};

  int _matchCount = 0;
  Timer? _countDebounce;

  @override
  void initState() {
    super.initState();
    final f = widget.initialFilter;
    if (f != null) {
      _keywordController.text = f.keyword;
      _quickFilter = f.quickDateFilter;
      _fromDate = f.customStartDate;
      _toDate = f.customEndDate;
      _countries = Set.of(f.countries);
      _operators = Set.of(f.operators);
      _types = f.types.isEmpty ? Set.of(widget.typeOptions) : Set.of(f.types);
    } else {
      _countries = {};
      _operators = {};
      _types = Set.of(widget.typeOptions);
    }

    _keywordController.addListener(_scheduleCountRefresh);
    _loadGroupCounts();
    _refreshCount();
  }

  @override
  void dispose() {
    _countDebounce?.cancel();
    _keywordController.dispose();
    _mainScrollController.dispose();
    super.dispose();
  }

  // ── Data ───────────────────────────────────────────────────────────────────

  Future<void> _loadGroupCounts() async {
    final operatorCounts = await widget.repo.fetchOperatorsByTripPF();
    final countryCounts = await widget.repo.fetchCountriesByTripPF();
    if (!mounted) return;
    setState(() {
      _operatorTripCounts = {
        for (final e in operatorCounts.entries) e.key: e.value.past + e.value.future,
      };
      _countryTripCounts = {
        for (final e in countryCounts.entries) e.key: e.value.past + e.value.future,
      };
    });
  }

  TripsFilterResult _buildResult() {
    // A selection covering every available type is no restriction at all.
    final restrictsTypes = _types.length < widget.typeOptions.length ||
        !_types.containsAll(widget.typeOptions);
    return TripsFilterResult(
      keyword: _keywordController.text.trim(),
      quickDateFilter: _quickFilter,
      customStartDate: _fromDate,
      customEndDate: _toDate,
      countries: Set.of(_countries),
      operators: Set.of(_operators),
      types: restrictsTypes
          ? widget.typeOptions.where(_types.contains).toList()
          : const [],
    );
  }

  void _scheduleCountRefresh() {
    _countDebounce?.cancel();
    _countDebounce = Timer(const Duration(milliseconds: 250), _refreshCount);
  }

  Future<void> _refreshCount() async {
    final count = await widget.repo.countFilteredTrips(
      showFutureTrips: widget.showFutureTrips,
      filter: _buildResult(),
    );
    if (mounted) setState(() => _matchCount = count);
  }

  void _reset() {
    setState(() {
      _keywordController.clear();
      _quickFilter = TripsQuickDateFilter.allTime;
      _fromDate = null;
      _toDate = null;
      _countries.clear();
      _operators.clear();
      _types = Set.of(widget.typeOptions);
    });
    _scheduleCountRefresh();
  }

  // ── Group entries ──────────────────────────────────────────────────────────

  List<GroupEntry> _countryEntries() {
    final entries = <GroupEntry>[];
    final seen = <String>{};

    GroupEntry build(String code, int count) => GroupEntry(
          value: code,
          // Context-aware rendering: translates codes CountryLocalizations
          // doesn't know (e.g. "UN" → international waters).
          label: countryCodeToName(code, context),
          leading: Text(
            countryCodeToEmoji(code),
            style: const TextStyle(fontSize: 18),
          ),
          tripCount: count,
        );

    // Ordered by trip count first…
    for (final e in _countryTripCounts.entries) {
      entries.add(build(e.key, e.value));
      seen.add(e.key);
    }
    // …then any remaining known country without a computed count yet.
    for (final code in widget.countryOptions.keys) {
      if (seen.add(code)) entries.add(build(code, 0));
    }
    return entries;
  }

  List<GroupEntry> _operatorEntries(TrainlogProvider trainlog) {
    return [
      for (final e in _operatorTripCounts.entries)
        GroupEntry(
          value: e.key,
          label: e.key,
          leading: withOperatorLogoBg(
            context,
            trainlog.getOperatorImage(e.key, maxWidth: 32, maxHeight: 32),
          ),
          tripCount: e.value,
        ),
    ];
  }

  // ── Build ──────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final trainlog = Provider.of<TrainlogProvider>(context, listen: false);

    final Widget body;
    switch (_view) {
      case _SheetView.main:
        body = AppPlatform.isApple
            ? _buildMainViewApple(context, l10n, trainlog)
            : _buildMainView(context, l10n, trainlog);
      case _SheetView.countries:
        body = GroupPickerView(
          key: const ValueKey('countries-picker'),
          title: l10n.tripsSearchFilterCountries,
          searchPlaceholder: l10n.tripsSearchFilterSearchCountries,
          subHeadline: l10n.tripsSearchFilterAllCountriesFromTrips,
          entries: _countryEntries(),
          selectedValues: _countries,
          onToggle: (value, selected) {
            setState(() => selected ? _countries.add(value) : _countries.remove(value));
            _scheduleCountRefresh();
          },
          onSelectAll: () {
            setState(() => _countries
              ..clear()
              ..addAll(_countryEntries().map((e) => e.value)));
            _scheduleCountRefresh();
          },
          onSelectNone: () {
            setState(() => _countries.clear());
            _scheduleCountRefresh();
          },
          onDone: () => setState(() => _view = _SheetView.main),
        );
      case _SheetView.operators:
        body = GroupPickerView(
          key: const ValueKey('operators-picker'),
          title: l10n.tripsSearchFilterOperators,
          searchPlaceholder: l10n.tripsSearchFilterSearchOperators,
          subHeadline: l10n.tripsSearchFilterAllOperatorsFromTrips,
          entries: _operatorEntries(trainlog),
          selectedValues: _operators,
          onToggle: (value, selected) {
            setState(() => selected ? _operators.add(value) : _operators.remove(value));
            _scheduleCountRefresh();
          },
          onSelectAll: () {
            setState(() => _operators
              ..clear()
              ..addAll(_operatorTripCounts.keys));
            _scheduleCountRefresh();
          },
          onSelectNone: () {
            setState(() => _operators.clear());
            _scheduleCountRefresh();
          },
          onDone: () => setState(() => _view = _SheetView.main),
        );
    }

    // Keep the sheet (notably its text fields and footer) above the keyboard.
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;

    // The SafeArea keeps the footer above the system navigation bar — the
    // Material host only avoids the status bar. On Apple it keeps the footer
    // above the home indicator.
    return SafeArea(
      top: false,
      child: AnimatedPadding(
        duration: const Duration(milliseconds: 150),
        padding: EdgeInsets.only(bottom: bottomInset),
        // While the sheet closes with the keyboard still animating away, the
        // space left here can drop to almost nothing: skip the layout then.
        child: LayoutBuilder(
          builder: (context, constraints) => constraints.maxHeight < 120
              ? const SizedBox.shrink()
              : Column(
                  children: [
                    // The Apple glass sheet draws its own grab handle.
                    if (!AppPlatform.isApple) _grabHandle(context),
                    Expanded(child: body),
                    if (_view == _SheetView.main)
                      AppPlatform.isApple
                          ? _actionFooterApple(context, l10n)
                          : _actionFooter(context, l10n),
                  ],
                ),
        ),
      ),
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

  Widget _buildMainView(
    BuildContext context,
    AppLocalizations l10n,
    TrainlogProvider trainlog,
  ) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;

    final selectedCountryEntries = _countryEntries()
        .where((e) => _countries.contains(e.value))
        .toList();
    final selectedOperatorEntries = _operatorEntries(trainlog)
        .where((e) => _operators.contains(e.value))
        .toList();

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
                child: Icon(
                  AppPlatform.isApple ? CupertinoIcons.search : Icons.search,
                  size: 20,
                  color: cs.onPrimary,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  l10n.tripsSearchFilterTitle,
                  style: theme.textTheme.titleLarge
                      ?.copyWith(fontWeight: FontWeight.w700),
                ),
              ),
              SheetMiniButton(
                label: l10n.mapFilterReset,
                emphasized: true,
                onTap: _reset,
              ),
            ],
          ),
        ),

        // ── Scrollable form ────────────────────────────────────────────────
        Expanded(
          child: SingleChildScrollView(
            controller: _mainScrollController,
            padding: const EdgeInsets.fromLTRB(16, 4, 16, 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Text search — feeds the keyword query for both the card and
                // the table view.
                SheetSearchField(
                  controller: _keywordController,
                  placeholder: l10n.tripsSearchFilterSearchHint,
                ),
                const SizedBox(height: 20),

                // When
                WhenSection(
                  quickFilter: _quickFilter,
                  fromDate: _fromDate,
                  toDate: _toDate,
                  onQuickFilterSelected: (value) {
                    setState(() {
                      // Selecting a quick chip clears any custom dates.
                      _quickFilter = value;
                      _fromDate = null;
                      _toDate = null;
                    });
                    _scheduleCountRefresh();
                  },
                  onFromDateChanged: (date) {
                    setState(() {
                      _fromDate = date;
                      // Touching the custom range deselects the quick chip.
                      _quickFilter = null;
                    });
                    _scheduleCountRefresh();
                  },
                  onToDateChanged: (date) {
                    setState(() {
                      _toDate = date;
                      _quickFilter = null;
                    });
                    _scheduleCountRefresh();
                  },
                ),
                const SizedBox(height: 20),

                // Countries
                FilterGroupSection(
                  title: l10n.tripsSearchFilterCountries,
                  addLabel: l10n.tripsSearchFilterAdd,
                  selectedEntries: selectedCountryEntries,
                  onAdd: () => setState(() => _view = _SheetView.countries),
                  onRemove: (value) {
                    setState(() => _countries.remove(value));
                    _scheduleCountRefresh();
                  },
                ),
                const SizedBox(height: 20),

                // Operators
                FilterGroupSection(
                  title: l10n.tripsSearchFilterOperators,
                  addLabel: l10n.tripsSearchFilterAdd,
                  selectedEntries: selectedOperatorEntries,
                  onAdd: () => setState(() => _view = _SheetView.operators),
                  onRemove: (value) {
                    setState(() => _operators.remove(value));
                    _scheduleCountRefresh();
                  },
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
                        onTap: () {
                          setState(() => _types = Set.of(widget.typeOptions));
                          _scheduleCountRefresh();
                        },
                      ),
                      const SizedBox(width: 4),
                      SheetMiniButton(
                        label: l10n.mapFilterVehicleTypeNoneBtn,
                        onTap: () {
                          setState(() => _types.clear());
                          _scheduleCountRefresh();
                        },
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 10),
                AdaptiveVehicleTypeFilterChips(
                  availableTypes: widget.typeOptions,
                  selectedTypes: _types,
                  onTypeToggle: (type, selected) {
                    setState(() {
                      selected ? _types.add(type) : _types.remove(type);
                    });
                    _scheduleCountRefresh();
                  },
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  // ── Apple (iOS 26) ───────────────────────────────────────────────────────

  /// iOS 26 form: glass ✕ / title / ↺ bar, search field, a grouped list
  /// (period menu with optional From / To dates, countries and operators as
  /// summary rows opening the pickers) and the vehicle capsules.
  Widget _buildMainViewApple(
    BuildContext context,
    AppLocalizations l10n,
    TrainlogProvider trainlog,
  ) {
    String summary(List<GroupEntry> selected, int total) {
      // None selected = no restriction; all selected reads the same.
      if (selected.isEmpty || selected.length == total) {
        return l10n.tripsSearchFilterAny;
      }
      final shown = selected.take(2).map((e) => e.label).join(', ');
      return selected.length > 2 ? '$shown +${selected.length - 2}' : shown;
    }

    final selectedCountryEntries = _countryEntries()
        .where((e) => _countries.contains(e.value))
        .toList();
    final selectedOperatorEntries = _operatorEntries(trainlog)
        .where((e) => _operators.contains(e.value))
        .toList();
    final allTypesSelected = widget.typeOptions.isNotEmpty &&
        widget.typeOptions.every(_types.contains);

    return Column(
      children: [
        GlassSheetHeader(
          title: l10n.tripsSearchFilterTitle,
          closeTooltip: MaterialLocalizations.of(context).closeButtonTooltip,
          resetTooltip: l10n.mapFilterReset,
          onClose: () => Navigator.of(context, rootNavigator: true).pop(),
          onReset: _reset,
        ),
        Expanded(
          child: SingleChildScrollView(
            controller: _mainScrollController,
            padding: const EdgeInsets.fromLTRB(16, 4, 16, 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                SheetSearchField(
                  controller: _keywordController,
                  placeholder: l10n.tripsSearchFilterSearchHint,
                ),
                const SizedBox(height: 18),
                WhenSection(
                  quickFilter: _quickFilter,
                  fromDate: _fromDate,
                  toDate: _toDate,
                  onQuickFilterSelected: (value) {
                    setState(() {
                      _quickFilter = value;
                      _fromDate = null;
                      _toDate = null;
                    });
                    _scheduleCountRefresh();
                  },
                  onCustomSelected: () {
                    setState(() => _quickFilter = null);
                    _scheduleCountRefresh();
                  },
                  onFromDateChanged: (date) {
                    setState(() {
                      _fromDate = date;
                      _quickFilter = null;
                    });
                    _scheduleCountRefresh();
                  },
                  onToDateChanged: (date) {
                    setState(() {
                      _toDate = date;
                      _quickFilter = null;
                    });
                    _scheduleCountRefresh();
                  },
                ),
                const SizedBox(height: 18),
                GlassFormGroup(children: [
                  GlassFormRow(
                    title: l10n.tripsSearchFilterCountries,
                    trailing: GlassDisclosure(
                        value: summary(selectedCountryEntries,
                            _countryEntries().length)),
                    onTap: () => setState(() => _view = _SheetView.countries),
                  ),
                  GlassFormRow(
                    title: l10n.tripsSearchFilterOperators,
                    trailing: GlassDisclosure(
                        value: summary(selectedOperatorEntries,
                            _operatorEntries(trainlog).length)),
                    onTap: () => setState(() => _view = _SheetView.operators),
                  ),
                ]),
                const SizedBox(height: 22),
                GlassFilterSectionHeader(
                  title: l10n.typeTitle,
                  actionLabel: allTypesSelected
                      ? l10n.filterDeselectAll
                      : l10n.filterSelectAll,
                  onAction: () {
                    setState(() {
                      if (allTypesSelected) {
                        _types.clear();
                      } else {
                        _types = Set.of(widget.typeOptions);
                      }
                    });
                    _scheduleCountRefresh();
                  },
                ),
                const SizedBox(height: 6),
                AdaptiveVehicleTypeFilterChips(
                  availableTypes: widget.typeOptions,
                  selectedTypes: _types,
                  onTypeToggle: (type, selected) {
                    setState(() {
                      selected ? _types.add(type) : _types.remove(type);
                    });
                    _scheduleCountRefresh();
                  },
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _actionFooterApple(BuildContext context, AppLocalizations l10n) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
      child: GlassPrimaryButton(
        icon: Icons.directions_transit_outlined,
        label: l10n.mapFilterShowTrips(_matchCount),
        onPressed: () =>
            Navigator.of(context, rootNavigator: true).pop(_buildResult()),
      ),
    );
  }

  Widget _actionFooter(BuildContext context, AppLocalizations l10n) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
      child: PrimaryActionButton(
        onPressed: () => Navigator.of(
          context,
          rootNavigator: AppPlatform.isApple,
        ).pop(_buildResult()),
        icon: Icons.directions_transit_outlined,
        label: l10n.mapFilterShowTrips(_matchCount),
      ),
    );
  }
}
