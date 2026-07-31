import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:trainlog_app/app/theme/app_theme.dart';
import 'package:trainlog_app/data/models/trip_form_model.dart';
import 'package:trainlog_app/data/models/trips.dart';
import 'package:trainlog_app/l10n/app_localizations.dart';
import 'package:trainlog_app/providers/trainlog_provider.dart';
import 'package:trainlog_app/providers/trips_provider.dart';
import 'package:trainlog_app/services/operator_suggestion_service.dart';
import 'package:trainlog_app/widgets/trip_form/operator_search_overlay.dart';
import 'package:trainlog_app/widgets/trip_form/operator_tiles.dart';
import 'package:trainlog_app/widgets/trip_form/trip_form_card.dart';

/// Step 3 of the "Add Trip" wizard: operator selection.
///
/// Shows a search field opening the app's full-screen search overlay, the
/// "Selected operators" block (with a trailing cross to remove each entry)
/// and, below it, route-relevant suggestions from the local trips database
/// ([OperatorSuggestionService]). Selecting a suggestion moves it up into
/// the selected block. Custom operators are created from inside the overlay
/// via a dashed button that appears once the user has typed something; they
/// get the app's monogram as placeholder logo.
class AddTripOperatorStep extends StatefulWidget {
  const AddTripOperatorStep({super.key});

  @override
  State<AddTripOperatorStep> createState() => _AddTripOperatorStepState();
}

class _AddTripOperatorStepState extends State<AddTripOperatorStep> {
  static const _suggestionService = OperatorSuggestionService();

  late final OperatorSearchOverlay _searchOverlay = OperatorSearchOverlay(
    onSelected: _addOperator,
    onClosed: () {
      if (mounted) setState(() {});
    },
  );

  List<OperatorSuggestion> _suggestions = [];
  String? _suggestionInputsKey;
  bool _operatorsLoaded = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();

    if (!_operatorsLoaded) {
      _operatorsLoaded = true;
      context.read<TrainlogProvider>().reloadOperatorList();
    }
    _reloadSuggestionsIfNeeded();
  }

  @override
  void dispose() {
    _searchOverlay.dispose();
    super.dispose();
  }

  // ─────────────────────────────────────────────────────────────
  // Suggestions
  // ─────────────────────────────────────────────────────────────

  /// Re-queries the suggestion service when the inputs it depends on
  /// (vehicle type and trip ends) have changed.
  void _reloadSuggestionsIfNeeded() {
    final model = context.read<TripFormModel>();
    final repository = context.read<TripsProvider>().repository;
    if (repository == null) return;

    final key = [
      model.vehicleType?.name,
      model.departureLat, model.departureLong, model.departureStationName,
      model.arrivalLat, model.arrivalLong, model.arrivalStationName,
    ].join('|');
    if (key == _suggestionInputsKey) return;
    _suggestionInputsKey = key;

    _suggestionService
        .suggest(
      repository: repository,
      vehicleType: model.vehicleType ?? VehicleType.train,
      departureLat: model.departureLat,
      departureLong: model.departureLong,
      departureName: model.departureStationName,
      arrivalLat: model.arrivalLat,
      arrivalLong: model.arrivalLong,
      arrivalName: model.arrivalStationName,
    )
        .then((results) {
      if (!mounted) return;
      setState(() => _suggestions = results);
    });
  }

  // ─────────────────────────────────────────────────────────────
  // Selection
  // ─────────────────────────────────────────────────────────────

  void _addOperator(String name) {
    final trimmed = name.trim();
    if (trimmed.isEmpty) return;

    final model = context.read<TripFormModel>();
    if (model.selectedOperators.contains(trimmed)) return;

    model.setOperators([...model.selectedOperators, trimmed]);
    model.clearOperatorError();
  }

  void _removeOperator(String name) {
    final model = context.read<TripFormModel>();
    model.setOperators(
        model.selectedOperators.where((op) => op != name).toList());
  }

  // ─────────────────────────────────────────────────────────────
  // Build
  // ─────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final model = context.watch<TripFormModel>();
    final theme = Theme.of(context);
    final loc = AppLocalizations.of(context)!;

    _reloadSuggestionsIfNeeded();

    final selected = model.selectedOperators;
    final suggestions =
        _suggestions.where((s) => !selected.contains(s.name)).toList();

    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(24, 8, 24, 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            loc.addTripOperatorTitle,
            style: AppTheme.displayFont.copyWith(
              fontSize: 26,
              fontWeight: FontWeight.w700,
              color: theme.colorScheme.onSurface,
            ),
          ),
          const SizedBox(height: 16),

          // Search field: opens the full-screen search overlay.
          TextFormField(
            readOnly: true,
            onTap: () => _searchOverlay.open(context),
            decoration: InputDecoration(
              hintText: loc.addTripOperatorHint,
              prefixIcon: const Icon(Icons.search),
              isDense: true,
              contentPadding:
                  const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
            ),
          ),
          const SizedBox(height: 20),

          // Selected operators — directly above the suggestions.
          if (selected.isNotEmpty) ...[
            TripFormSectionLabel(loc.addTripSelectedOperators),
            const SizedBox(height: 8),
            TripFormCard(
              children: [
                for (final op in selected)
                  OperatorRow(
                    name: op,
                    trailing: IconButton(
                      icon: const Icon(Icons.close, size: 20),
                      tooltip:
                          MaterialLocalizations.of(context).deleteButtonTooltip,
                      onPressed: () => _removeOperator(op),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 20),
          ],

          // Suggestions from the local trips database.
          if (suggestions.isNotEmpty) ...[
            TripFormSectionLabel(loc.addTripSuggestedOperators),
            const SizedBox(height: 8),
            TripFormCard(
              children: [
                for (final suggestion in suggestions)
                  OperatorRow(
                    name: suggestion.name,
                    subtitle:
                        loc.addTripOperatorTripCount(suggestion.tripCount),
                    trailing: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 12),
                      child: Icon(
                        Icons.radio_button_unchecked,
                        color: theme.colorScheme.outline,
                      ),
                    ),
                    onTap: () => _addOperator(suggestion.name),
                  ),
              ],
            ),
            const SizedBox(height: 8,),
            Text(
              loc.addTripSuggestedOperatorsHelper,
              softWrap: true,
              style: theme.textTheme.bodySmall,
            ),
          ],
        ],
      ),
    );
  }
}
