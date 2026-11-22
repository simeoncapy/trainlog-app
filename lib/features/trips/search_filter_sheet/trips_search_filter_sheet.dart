import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:trainlog_app/core/data/models/trips.dart';
import 'package:trainlog_app/core/data/models/trips_filter.dart';
import 'package:trainlog_app/core/data/trips_repository.dart';
import 'package:trainlog_app/core/providers/trainlog_provider.dart';
import 'package:trainlog_app/features/trips/search_filter_sheet/cupertino/trips_filter_cupertino_view.dart';
import 'package:trainlog_app/features/trips/search_filter_sheet/group_picker_view.dart';
import 'package:trainlog_app/features/trips/search_filter_sheet/material/trips_filter_material_view.dart';
import 'package:trainlog_app/features/trips/search_filter_sheet/trips_filter_controller.dart';
import 'package:trainlog_app/features/trips/search_filter_sheet/trips_filter_entries.dart';
import 'package:trainlog_app/l10n/app_localizations.dart';
import 'package:trainlog_app/ui/adaptive/adaptive_sheet.dart';
import 'package:trainlog_app/ui/design.dart';

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
  if (AppDesign.of(context) == DesignLanguage.cupertino) {
    return showAppleFormSheet<TripsFilterResult>(
      context: context,
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
    backgroundColor: Theme.of(
      context,
    ).scaffoldBackgroundColor, //Theme.of(context).colorScheme.surface,
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
/// Provides a [TripsFilterController] (the filter state, shared by both
/// views), owns what only widgets can hold (the keyword field's text
/// controller, the form's scroll position, which view is shown) and swaps
/// between the main form and the country / operator pickers. The main form
/// is [TripsFilterMaterialView] or [TripsFilterCupertinoView].
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
  late final TripsFilterController _filter;
  final _keywordController = TextEditingController();
  final _mainScrollController = ScrollController();

  _SheetView _view = _SheetView.main;

  @override
  void initState() {
    super.initState();
    _filter = TripsFilterController(
      repo: widget.repo,
      countryCodes: widget.countryOptions.keys.toList(),
      typeOptions: widget.typeOptions,
      showFutureTrips: widget.showFutureTrips,
      initialFilter: widget.initialFilter,
    );
    _keywordController.text = _filter.keyword;
    _keywordController.addListener(
      () => _filter.setKeyword(_keywordController.text),
    );
    // A reset clears the keyword: mirror it in the text field.
    _filter.addListener(() {
      if (_keywordController.text != _filter.keyword) {
        _keywordController.text = _filter.keyword;
      }
    });
    _filter.load();
  }

  @override
  void dispose() {
    _filter.dispose();
    _keywordController.dispose();
    _mainScrollController.dispose();
    super.dispose();
  }

  void _show(_SheetView view) => setState(() => _view = view);

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider<TripsFilterController>.value(
      value: _filter,
      child: Builder(builder: _buildSheet),
    );
  }

  Widget _buildSheet(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final trainlog = Provider.of<TrainlogProvider>(context, listen: false);
    final filter = context.watch<TripsFilterController>();

    final Widget? picker = switch (_view) {
      _SheetView.main => null,
      _SheetView.countries => GroupPickerView(
        key: const ValueKey('countries-picker'),
        title: l10n.tripsSearchFilterCountries,
        searchPlaceholder: l10n.tripsSearchFilterSearchCountries,
        subHeadline: l10n.tripsSearchFilterAllCountriesFromTrips,
        entries: countryEntries(context, filter),
        selectedValues: filter.countries,
        onToggle: filter.setCountrySelected,
        onSelectAll: filter.selectAllCountries,
        onSelectNone: filter.clearCountries,
        onDone: () => _show(_SheetView.main),
      ),
      _SheetView.operators => GroupPickerView(
        key: const ValueKey('operators-picker'),
        title: l10n.tripsSearchFilterOperators,
        searchPlaceholder: l10n.tripsSearchFilterSearchOperators,
        subHeadline: l10n.tripsSearchFilterAllOperatorsFromTrips,
        entries: operatorEntries(context, filter, trainlog),
        selectedValues: filter.operators,
        onToggle: filter.setOperatorSelected,
        onSelectAll: filter.selectAllOperators,
        onSelectNone: filter.clearOperators,
        onDone: () => _show(_SheetView.main),
      ),
    };

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
              : PlatformView(
                  material: (_) => TripsFilterMaterialView(
                    keywordController: _keywordController,
                    scrollController: _mainScrollController,
                    picker: picker,
                    onOpenCountries: () => _show(_SheetView.countries),
                    onOpenOperators: () => _show(_SheetView.operators),
                  ),
                  cupertino: (_) => TripsFilterCupertinoView(
                    keywordController: _keywordController,
                    scrollController: _mainScrollController,
                    picker: picker,
                    onOpenCountries: () => _show(_SheetView.countries),
                    onOpenOperators: () => _show(_SheetView.operators),
                  ),
                ),
        ),
      ),
    );
  }
}
