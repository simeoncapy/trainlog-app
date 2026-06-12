import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:trainlog_app/data/models/trips.dart';
import 'package:trainlog_app/features/spr/widgets/pre_record_tile.dart';
import 'package:trainlog_app/features/spr/widgets/spr_button_bar.dart';
import 'package:trainlog_app/features/spr/widgets/spr_dialogs.dart';
import 'package:trainlog_app/features/trips/add_trip_page.dart';
import 'package:trainlog_app/l10n/app_localizations.dart';
import 'package:trainlog_app/navigation/nav_models.dart';
import 'package:trainlog_app/platform/adaptive_dialog.dart';
import 'package:trainlog_app/platform/adaptive_expansion_title.dart';
import 'package:trainlog_app/platform/adaptive_information_message.dart';
import 'package:trainlog_app/providers/pre_record_provider.dart';
import 'package:trainlog_app/providers/settings_provider.dart';
import 'package:trainlog_app/providers/trainlog_provider.dart';
import 'package:trainlog_app/services/geo_permission_service.dart';
import 'package:trainlog_app/utils/platform_utils.dart';
import 'package:trainlog_app/widgets/error_banner.dart';

/// Smart Prerecorder: record timestamped locations on the go, then turn a
/// departure/arrival pair into a trip.
///
/// State and business logic live in [PreRecordProvider] (scoped to this
/// page); persistence in PreRecordService. This widget only orchestrates
/// the UI: list, action bar, dialogs and user feedback.
class SmartPrerecorderPage extends StatelessWidget {
  final SetPrimaryActions onPrimaryActionsReady;
  const SmartPrerecorderPage({super.key, required this.onPrimaryActionsReady});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => PreRecordProvider()..loadRecords(),
      child: _SmartPrerecorderView(onPrimaryActionsReady: onPrimaryActionsReady),
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
    final theme = Theme.of(context);
    final prerecords = context.watch<PreRecordProvider>();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      widget.onPrimaryActionsReady(_buildPrimaryAction(context));
    });

    final records = prerecords.records;

    return Padding(
      padding: const EdgeInsets.all(8.0),
      child: Column(
        children: [
          // Scrollable area (explanation + list + optional top controls)
          Expanded(
            child: CustomScrollView(
              slivers: [
                SliverToBoxAdapter(
                  child: _explanationTile(loc),
                ),
                const SliverToBoxAdapter(
                  child: SizedBox(height: 16),
                ),

                // Android controls (iOS gets the fixed bottom bar instead)
                if (!AppPlatform.isApple) ...[
                  SliverToBoxAdapter(
                    child: _buttonBar(prerecords, loc),
                  ),
                  const SliverToBoxAdapter(
                    child: SizedBox(height: 8),
                  ),
                ],

                // Records
                if (records.isEmpty)
                  SliverFillRemaining(
                    hasScrollBody: false,
                    child: Center(
                      child: Text(
                        loc.prerecorderNoData,
                        style: theme.textTheme.bodyLarge,
                      ),
                    ),
                  )
                else
                  SliverList(
                    delegate: SliverChildBuilderDelegate(
                      (context, index) {
                        final record = records[index];

                        return Padding(
                          padding: const EdgeInsets.only(bottom: 8),
                          child: PreRecordTile(
                            record: record,
                            selected: prerecords.isSelected(record.id),
                            selectionIndex:
                                prerecords.selectionIndexOf(record.id),
                            onTap: () {
                              if (AppPlatform.isApple) {
                                HapticFeedback.selectionClick();
                              }
                              prerecords.toggleSelection(record.id);
                            },
                          ),
                        );
                      },
                      childCount: records.length,
                    ),
                  ),

                // Bottom padding:
                // - Android: keep room for FAB overlay
                // - iOS: small visual spacing above fixed bar
                SliverToBoxAdapter(
                  child: SizedBox(height: AppPlatform.isApple ? 8 : 88),
                ),
              ],
            ),
          ),

          // iOS fixed bottom action bar (always visible)
          if (AppPlatform.isApple)
            Padding(
              padding: const EdgeInsets.only(top: 8),
              child: _buttonBar(prerecords, loc),
            ),
        ],
      ),
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

  Widget _buttonBar(PreRecordProvider prerecords, AppLocalizations loc) {
    final tripSelectionUi = _buildTripSelectionUiState(prerecords, loc);

    return SprButtonBar(
      errorBanner: tripSelectionUi.errorBanner,
      onCreateTrip: tripSelectionUi.createTripCaller,
      onRecord: _recordNewLog,
      onDelete: () => _askForDelete(loc),
      onToggleSort: prerecords.toggleSortOrder,
      sortIcon: _sortIcon(prerecords),
      sortTooltip: _sortTooltip(prerecords, loc),
      deleteLabel: _deleteButtonLabel(prerecords, loc),
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
    final isWarning = validation.errors.length == 1 &&
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

    final tripModel = prerecords.buildTripForm(resolvedType);
    final selectedIds = List<int>.of(prerecords.selectedIds);
    if (!mounted) return;

    final result = await Navigator.of(context).push(
      PageRouteBuilder(
        pageBuilder: (_, __, ___) => ChangeNotifierProvider(
          create: (_) => tripModel,
          child: AddTripPage(
            preRecorderIdsToDelete: selectedIds,
          ),
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
        AdaptiveInformationMessage.show(context, loc.prerecorderNoStationReachable);
      case RecordOutcome.locationDisabled:
        AdaptiveInformationMessage.show(context, loc.locationServicesDisabled);
      case RecordOutcome.failed:
        AdaptiveInformationMessage.show(context, loc.prerecorderErrorFetchingStation);
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

  List<AppPrimaryAction> _buildPrimaryAction(BuildContext context) {
    final loc = AppLocalizations.of(context)!;
    final prerecords = _prerecords;

    if (AppPlatform.isApple) {
      return [
        AppPrimaryAction(
          onPressed: prerecords.toggleSortOrder,
          icon: _sortIcon(prerecords),
          tooltip: _sortTooltip(prerecords, loc),
        ),
        AppPrimaryAction(
          onPressed: () => _askForDelete(loc),
          icon: AdaptiveIcons.delete,
          label: _deleteButtonLabel(prerecords, loc, short: true),
          isDestructive: true,
        ),
      ];
    }

    final tripSelectionUi = _buildTripSelectionUiState(prerecords, loc);
    return [
      AppPrimaryAction(
        onPressed: tripSelectionUi.isValidSelection
            ? tripSelectionUi.createTripCaller!
            : _recordNewLog,
        icon: tripSelectionUi.isValidSelection
            ? AdaptiveIcons.add
            : AdaptiveIcons.edit,
        label: tripSelectionUi.isValidSelection
            ? loc.prerecorderCreateTripButton
            : loc.prerecorderRecordButton,
      ),
    ];
  }
}
