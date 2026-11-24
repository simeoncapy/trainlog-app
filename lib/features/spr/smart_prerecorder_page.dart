import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:trainlog_app/core/data/models/trips.dart';
import 'package:trainlog_app/core/data/models/pre_record_model.dart';
import 'package:trainlog_app/features/spr/geolog_note_page.dart';
import 'package:trainlog_app/features/spr/cupertino/spr_cupertino_view.dart';
import 'package:trainlog_app/features/spr/material/spr_material_view.dart';
import 'package:trainlog_app/features/spr/widgets/spr_page_actions.dart';
import 'package:trainlog_app/features/spr/widgets/spr_dialogs.dart';
import 'package:trainlog_app/features/trips_add/add_trip_wizard_page.dart';
import 'package:trainlog_app/l10n/app_localizations.dart';
import 'package:trainlog_app/navigation/nav_models.dart';
import 'package:trainlog_app/ui/adaptive/adaptive_dialog.dart';
import 'package:trainlog_app/ui/adaptive/adaptive_page_route.dart';
import 'package:trainlog_app/ui/adaptive/adaptive_expansion_title.dart';
import 'package:trainlog_app/ui/adaptive/adaptive_information_message.dart';
import 'package:trainlog_app/core/providers/pre_record_provider.dart';
import 'package:trainlog_app/core/providers/settings_provider.dart';
import 'package:trainlog_app/core/providers/trainlog_provider.dart';
import 'package:trainlog_app/core/services/geo_permission_service.dart';
import 'package:trainlog_app/core/services/geolog_note_merger.dart';
import 'package:trainlog_app/ui/design.dart';
import 'package:trainlog_app/utils/platform_utils.dart';
import 'package:trainlog_app/widgets/error_banner.dart';

/// Smart Prerecorder: record timestamped locations on the go, then turn a
/// departure/arrival pair into a trip.
///
/// State and business logic live in [PreRecordProvider] (scoped to this
/// page); persistence in PreRecordService. This entry orchestrates the
/// dialogs and user feedback ([SprPageActions]) and picks the Material or
/// iOS view.
class SmartPrerecorderPage extends StatelessWidget {
  final SetPrimaryActions onPrimaryActionsReady;
  const SmartPrerecorderPage({super.key, required this.onPrimaryActionsReady});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => PreRecordProvider()..loadRecords(),
      child: _SmartPrerecorderView(
        onPrimaryActionsReady: onPrimaryActionsReady,
      ),
    );
  }
}

class _TripSelectionUiState {
  final bool isValidSelection;
  final List<Widget> errorBanner;
  final VoidCallback? createTripCaller;

  const _TripSelectionUiState({
    required this.isValidSelection,
    required this.errorBanner,
    required this.createTripCaller,
  });
}

class _SmartPrerecorderView extends StatefulWidget {
  final SetPrimaryActions onPrimaryActionsReady;
  const _SmartPrerecorderView({required this.onPrimaryActionsReady});

  @override
  State<_SmartPrerecorderView> createState() => _SmartPrerecorderViewState();
}

class _SmartPrerecorderViewState extends State<_SmartPrerecorderView> {
  final GeoPermissionService _geo = const GeoPermissionService();

  PreRecordProvider get _prerecords => context.read<PreRecordProvider>();

  IconData _sortIcon(PreRecordProvider prerecords) => prerecords.ascending
      ? AdaptiveIcons.sortAscending
      : AdaptiveIcons.sortDescending;

  String _sortTooltip(PreRecordProvider prerecords, AppLocalizations loc) =>
      prerecords.ascending ? loc.ascendingOrder : loc.descendingOrder;

  String _deleteButtonLabel(
    PreRecordProvider prerecords,
    AppLocalizations loc, {
    bool short = false,
  }) {
    if (prerecords.hasSelection) {
      return short ? loc.deleteSelectionShort : loc.deleteSelection;
    }
    return short ? loc.deleteAllShort : loc.deleteAll;
  }

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context)!;
    final prerecords = context.watch<PreRecordProvider>();
    final selection = _buildTripSelectionUiState(prerecords, loc);
    final actions = SprPageActions(
      onPrimaryActionsReady: widget.onPrimaryActionsReady,
      explanation: _explanationTile(loc),
      errorBanner: selection.errorBanner,
      isValidSelection: selection.isValidSelection,
      createTrip: selection.createTripCaller,
      record: _recordNewLog,
      delete: () => _askForDelete(loc),
      openNote: _openNote,
      sortIcon: _sortIcon(prerecords),
      sortTooltip: _sortTooltip(prerecords, loc),
      deleteLabel: ({bool short = false}) =>
          _deleteButtonLabel(prerecords, loc, short: short),
    );
    return PlatformView(
      material: (_) => SprMaterialView(actions: actions),
      cupertino: (_) => SprCupertinoView(actions: actions),
    );
  }

  Widget _explanationTile(AppLocalizations loc) {
    final settings = context.read<SettingsProvider>();

    return AdaptiveExpansionTile(
      initiallyExpanded: settings.isSmartPrerecorderExplanationExpanded,
      onExpansionChanged: settings.setIsSmartPrerecorderExplanationExpanded,
      leading: Icon(AdaptiveIcons.info),
      title: Text(
        loc.prerecorderExplanationTitle,
        textAlign: TextAlign.left,
        style: AdaptiveTextStyle.title(context),
      ),
      children: [
        Text(loc.prerecorderExplanation),
        Text(loc.prerecorderExplanationStation),
        Text(loc.prerecorderExplanationDelete),
        const SizedBox(height: 8),
        Text(loc.prerecorderExplanationPrivacy),
      ],
    );
  }

  String _errorText(SelectionError error, AppLocalizations loc) {
    switch (error) {
      case SelectionError.lessThanTwoSelected:
        return loc.prerecorderErrorLessThanTwoSelected;
      case SelectionError.moreThanTwoSelected:
        return loc.prerecorderErrorMoreThanTwoSelected;
      case SelectionError.departureAfterArrival:
        return loc.prerecorderErrorDepartureAfterArrival;
      case SelectionError.typeMismatch:
        return loc.prerecorderErrorTypeSameForDepartureArrival;
    }
  }

  _TripSelectionUiState _buildTripSelectionUiState(
    PreRecordProvider prerecords,
    AppLocalizations loc,
  ) {
    final validation = prerecords.validateSelection();

    final errorMessage = validation.errors.isEmpty
        ? null
        : validation.errors.map((e) => _errorText(e, loc)).join('\n');
    final isWarning =
        validation.errors.length == 1 &&
        validation.errors.single == SelectionError.lessThanTwoSelected;

    final errorBanner = errorMessage != null
        ? <Widget>[
            ErrorBanner(
              message: errorMessage,
              compact: true,
              severity: isWarning ? ErrorSeverity.warning : ErrorSeverity.error,
            ),
            const SizedBox(height: 8),
          ]
        : <Widget>[];

    return _TripSelectionUiState(
      isValidSelection: validation.isValid,
      errorBanner: errorBanner,
      createTripCaller: validation.isValid ? _createTrip : null,
    );
  }

  /// Resolves the vehicle type (asking the user when needed), builds the
  /// trip form from the selected pair, and opens the add-trip page.
  Future<void> _createTrip() async {
    final prerecords = _prerecords;

    final (resolution, knownType) = prerecords.typeResolutionForSelection();
    VehicleType? resolvedType = knownType;
    if (resolution == TypeResolution.needsFullPicker) {
      resolvedType = await showVehicleTypePickerDialog(context);
    } else if (resolution == TypeResolution.needsRailDisambiguation) {
      resolvedType = await showRailDisambiguationDialog(context);
    }
    if (resolvedType == null) return; // user dismissed a dialog

    // Fields both notes fill in differently: the user picks a side for each.
    final choices = <GeologNoteConflict, GeologNoteSide>{};
    final conflicts = prerecords.noteConflictsForSelection();
    if (conflicts.isNotEmpty) {
      final departure = prerecords.recordById(prerecords.selectedIds[0]).note!;
      final arrival = prerecords.recordById(prerecords.selectedIds[1]).note!;
      for (final conflict in conflicts) {
        if (!mounted) return;
        final side = await showNoteConflictDialog(
          context,
          conflict: conflict,
          departure: departure,
          arrival: arrival,
        );
        if (side == null) return; // user cancelled
        choices[conflict] = side;
      }
    }

    final tripModel = prerecords.buildTripForm(resolvedType, choices: choices);
    final selectedIds = List<int>.of(prerecords.selectedIds);
    if (!mounted) return;

    final result = await Navigator.of(context).push(
      PageRouteBuilder(
        pageBuilder: (_, __, ___) => ChangeNotifierProvider(
          create: (_) => tripModel,
          child: AddTripWizardPage(preRecorderIdsToDelete: selectedIds),
        ),
        transitionDuration: Duration.zero,
        reverseTransitionDuration: Duration.zero,
      ),
    );

    if (!mounted) return;
    if (result == true) {
      debugPrint(
        "Trip creation successful, deleting prerecords with ids: $selectedIds",
      );
      prerecords.clearSelection();
      await prerecords.loadRecords();
    }
  }

  /// Opens the note page of [record] and saves what it hands back.
  Future<void> _openNote(PreRecordModel record) async {
    final prerecords = _prerecords;
    final result = await Navigator.of(context).push<GeologNoteResult>(
      AdaptivePageRoute.route<GeologNoteResult>(
        (_) => GeologNotePage(record: record),
      ),
    );
    if (result == null || !mounted) return;
    await prerecords.saveNote(
      record.id,
      note: result.note,
      station: result.station,
    );
  }

  Future<void> _recordNewLog() async {
    final loc = AppLocalizations.of(context)!;
    final settings = context.read<SettingsProvider>();
    final trainlog = context.read<TrainlogProvider>();
    final prerecords = _prerecords;

    // Make sure location access is granted (prompting the user if needed)
    // before recording anything.
    final granted = await _geo.requestPermission(settings);
    if (!granted) {
      if (!mounted) return;
      AdaptiveInformationMessage.show(context, loc.locationPermissionDenied);
      return;
    }

    final outcome = await prerecords.recordNewLog(
      trainlog: trainlog,
      radiusMeters: settings.sprRadius,
      pickStation: (stations) async {
        if (!mounted) return null;
        return showStationSelectionDialog(context, stations);
      },
    );

    if (!mounted) return;
    switch (outcome) {
      case RecordOutcome.noStationFound:
        AdaptiveInformationMessage.show(
          context,
          loc.prerecorderNoStationReachable,
        );
      case RecordOutcome.locationDisabled:
        AdaptiveInformationMessage.show(context, loc.locationServicesDisabled);
      case RecordOutcome.failed:
        AdaptiveInformationMessage.show(
          context,
          loc.prerecorderErrorFetchingStation,
        );
      case RecordOutcome.success:
      case RecordOutcome.cancelled:
        break;
    }
  }

  Future<void> _askForDelete(AppLocalizations loc) async {
    final prerecords = _prerecords;
    final deleteSelection = prerecords.hasSelection;

    final confirmed = await AdaptiveDialog.confirm(
      context: context,
      title: deleteSelection ? loc.deleteSelection : loc.deleteAll,
      message: deleteSelection
          ? loc.prerecorderDeleteSelectionConfirm
          : loc.prerecorderDeleteAllConfirm,
      confirmLabel: MaterialLocalizations.of(context).deleteButtonTooltip,
      destructive: true,
    );

    if (!confirmed) return;

    await prerecords.deleteRecords(selectionOnly: deleteSelection);
  }
}
