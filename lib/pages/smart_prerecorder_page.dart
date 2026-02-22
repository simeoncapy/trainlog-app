import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:trainlog_app/data/models/pre_record_model.dart';
import 'package:trainlog_app/data/models/trip_form_model.dart';
import 'package:trainlog_app/data/models/trips.dart';
import 'dart:convert';
import 'dart:io';
import 'package:trainlog_app/l10n/app_localizations.dart';
import 'package:trainlog_app/navigation/nav_models.dart';
import 'package:trainlog_app/pages/add_trip_page.dart';
import 'package:trainlog_app/platform/adaptive_button.dart';
import 'package:trainlog_app/platform/adaptive_dialog.dart';
import 'package:trainlog_app/platform/adaptive_expansion_title.dart';
import 'package:trainlog_app/platform/adaptive_information_message.dart';
import 'package:trainlog_app/platform/adaptive_list_container.dart';
import 'package:trainlog_app/platform/adaptive_record_tile.dart';
import 'package:trainlog_app/providers/settings_provider.dart';
import 'package:trainlog_app/providers/trainlog_provider.dart';
import 'package:trainlog_app/utils/date_utils.dart';
import 'package:trainlog_app/utils/location_utils.dart';
import 'package:trainlog_app/utils/map_color_palette.dart';
import 'package:trainlog_app/utils/number_formatter.dart';
import 'package:trainlog_app/utils/platform_utils.dart';
import 'package:trainlog_app/utils/style_utils.dart';
import 'package:trainlog_app/utils/cached_data_utils.dart';
import 'package:geolocator/geolocator.dart';
import 'package:trainlog_app/widgets/error_banner.dart';
import 'package:trainlog_app/widgets/shimmer_box.dart';

class SmartPrerecorderPage extends StatefulWidget {
  final SetPrimaryActions onPrimaryActionsReady;
  const SmartPrerecorderPage({super.key, required this.onPrimaryActionsReady});

  @override
  State<SmartPrerecorderPage> createState() => _SmartPrerecorderPageState();
}

class _SmartPrerecorderPageState extends State<SmartPrerecorderPage> {
  List<PreRecordModel> _records = [];
  final List<int> _selectedIds = [];
  bool _ascending = false; // default: newest first
  IconData get sortIcon => _ascending ? AdaptiveIcons.sortAscending : AdaptiveIcons.sortDescending;
  String sortTooltip(AppLocalizations loc) => _ascending ? loc.ascendingOrder : loc.descendingOrder;
  String deleteButtonLabel(AppLocalizations loc, {bool short = false}) {
    if (_selectedIds.isNotEmpty) {
      return short ? loc.deleteSelectionShort : loc.deleteSelection;
    }
    else {
      return short ? loc.deleteAllShort : loc.deleteAll;
    }    
  }

  @override
  void initState() {
    super.initState();
    _loadPreRecords();
  }

  Future<void> _loadPreRecords() async {
    final file = File(AppCacheFilePath.preRecord);

    // Create file if missing
    if (!await file.exists()) {
      await file.create(recursive: true);
      await file.writeAsString(jsonEncode([]));
    }

    final content = await file.readAsString();
    if (content.trim().isEmpty) {
      setState(() => _records = []);
      return;
    }

    final List decoded = jsonDecode(content);
    setState(() {
      _records = decoded
          .map((e) => PreRecordModel.fromJson(e))
          .toList();
      _records.removeWhere( // remove incomplete records
        (r) => r.loaded == false,
      );
      _sortRecords();
    });
  }

  void _sortRecords() {
    _records.sort((a, b) =>
        _ascending
            ? a.dateTimeUtc.compareTo(b.dateTimeUtc)
            : b.dateTimeUtc.compareTo(a.dateTimeUtc));
  }

  Future<Position> _getCurrentPosition(AppLocalizations loc) async {
    bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      throw Exception(loc.locationServicesDisabled);
    }

    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
    }

    if (permission == LocationPermission.denied ||
        permission == LocationPermission.deniedForever) {
      throw Exception(loc.locationPermissionDenied);
    }

    return Geolocator.getCurrentPosition(
      locationSettings: platformLocationSettings()
    );
  }

  Future<void> _saveAll() async {
    final file = File(AppCacheFilePath.preRecord);
    await file.writeAsString(
      jsonEncode(_records.map((e) => e.toJson()).toList()),
      flush: true,
    );
  }

  Widget? _selectionTrailing(
    int recordId,
    AppLocalizations loc,
    ThemeData theme,
  ) {
    final index = _selectedIds.indexOf(recordId);
    if (index == -1) return null;

    if (index == 0) {
      return Text(
        loc.departureSingleCharacter,
        style: TextStyle(
          fontSize: 28,
          fontWeight: FontWeight.bold,
          color: Colors.green,
        ),
      );
    }

    if (index == 1) {
      return Text(
        loc.arrivalSingleCharacter,
        style: TextStyle(
          fontSize: 28,
          fontWeight: FontWeight.bold,
          color: Colors.red,
        ),
      );
    }

    return null;
  }

  Future<void> _deleteRecords({
    required bool deleteSelection,
  }) async {
    final file = File(AppCacheFilePath.preRecord);

    if (deleteSelection) {
      _records.removeWhere(
        (r) => _selectedIds.contains(r.id),
      );
    } else {
      _records.clear();
    }

    _selectedIds.clear();

    await file.writeAsString(
      jsonEncode(_records.map((e) => e.toJson()).toList()),
      flush: true,
    );
  }

  TripFormModel _createTripFormModel()
  {
    final model = TripFormModel();
    final departurePrerecord = _records.where(
      (r) => r.id == _selectedIds[0]
    ).first;
    final arrivalPrerecord = _records.where(
      (r) => r.id == _selectedIds[1]
    ).first;

    VehicleType? firstKnown(VehicleType a, VehicleType b) {
      if (a != VehicleType.unknown) return a;
      if (b != VehicleType.unknown) return b;
      return null;
    }

    model.vehicleType = firstKnown(departurePrerecord.type, arrivalPrerecord.type);
    // Departure
    model.departureDate = departurePrerecord.dateTime; 
    model.departureLat = departurePrerecord.lat;
    model.departureLong = departurePrerecord.long;  
    if (departurePrerecord.stationName?.trim().isEmpty ?? true) {  // geo mode
      model.departureGeoMode = true;
    }
    else { // name mode
      model.departureStationName = departurePrerecord.stationName;
      model.departureAddress = departurePrerecord.address;
      model.departureGeoMode = false;
    }

    // Arrival
    model.arrivalDate = arrivalPrerecord.dateTime;
    model.arrivalLat = arrivalPrerecord.lat;
    model.arrivalLong = arrivalPrerecord.long;
    if (arrivalPrerecord.stationName?.trim().isEmpty ?? true) {  // geo mode
      model.arrivalGeoMode = true;
    }
    else { // name mode
      model.arrivalStationName = arrivalPrerecord.stationName;
      model.arrivalAddress = arrivalPrerecord.address;
      model.arrivalGeoMode = false;
    }

    return model;
  }

  Future<(String?, String?, VehicleType)?> _showStationSelectionDialog(
    BuildContext context,
    List<(String?, String?, VehicleType, double)> stations,
  ) async {
    final loc = AppLocalizations.of(context)!;
    final settings = context.read<SettingsProvider>();
    final palette = MapColorPaletteHelper.getPalette(settings.mapColorPalette);

    return AdaptiveDialog.showCustom<(String?, String?, VehicleType)>(
      context: context,
      maxWidth: 500,
      maxHeightFactor: 0.6,
      barrierDismissible: true, // tap outside => null
      builder: (ctx) {
        final theme = Theme.of(ctx); // ok even in Cupertino pages

        return Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Padding(
              padding: const EdgeInsets.all(16),
              child: Text(
                loc.prerecorderSelectStation,
                style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
                textAlign: TextAlign.center,
              ),
            ),
            Padding(
              padding: const EdgeInsets.only(left: 8, right: 8, bottom: 4),
              child: Text(loc.prerecorderStationsFound(stations.length)),
            ),

            Expanded(
              child: ListView.builder(
                itemCount: stations.length,
                itemBuilder: (ctx, index) {
                  final (name, address, type, distance) = stations[index];

                  return AdaptiveRecordTile(
                    materialUseCard: false,        // IMPORTANT: remove Card separation on Material
                    cupertinoUseBackground: false, // IMPORTANT: remove per-row rounded blocks on iOS
                    leading: IconTheme(
                      data: IconThemeData(
                        color: palette[type],
                        size: 32,
                      ),
                      child: type.icon(),
                    ),
                    title: Text(
                          name ?? "",
                          style: theme.textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.w600,
                          )
                    ),
                    subtitle: Text(
                      loc.prerecorderAway(formatNumber(ctx, distance)),
                      style: theme.textTheme.bodySmall,
                    ),
                    onTap: () => AdaptiveDialog.pop(ctx, (name, address, type)),
                  );
                },
              ),
            ),

            Padding(
              padding: const EdgeInsets.all(16),
              child: SizedBox(
                width: double.infinity,
                child: AdaptiveButton.build(
                  context: ctx,
                  type: AdaptiveButtonType.primary,
                  onPressed: () => AdaptiveDialog.pop(
                    ctx,
                    (null, null, VehicleType.unknown),
                  ),
                  label: Text(loc.prerecorderUnknownStation),
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  // UI
  @override
Widget build(BuildContext context) {
  final loc = AppLocalizations.of(context)!;
  final theme = Theme.of(context);

  WidgetsBinding.instance.addPostFrameCallback((_) {
    if (!mounted) return;
    widget.onPrimaryActionsReady(_buildPrimaryAction(context));
  });

  return Padding(
    padding: const EdgeInsets.all(8.0),
    child: Column(
      children: [
        // Scrollable area (explanation + list + optional top controls)
        Expanded(
          child: CustomScrollView(
            slivers: [
              SliverToBoxAdapter(
                child: _explanationTile(loc, theme),
              ),
              const SliverToBoxAdapter(
                child: SizedBox(height: 16),
              ),

              // Android controls (if you still want them in-page)
              if (!AppPlatform.isApple) ...[
                SliverToBoxAdapter(
                  child: _buttonBar(_selectedIds, loc, theme),
                ),
                const SliverToBoxAdapter(
                  child: SizedBox(height: 8),
                ),
              ],

              // Records
              if (_records.isEmpty)
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
                      final record = _records[index];
                      final selected = _selectedIds.contains(record.id);

                      return Padding(
                        padding: const EdgeInsets.only(bottom: 8),
                        child: _preRecordTile(record, selected, loc, theme),
                      );
                    },
                    childCount: _records.length,
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
            child: _buttonBar(_selectedIds, loc, theme),
          ),
      ],
    ),
  );
}

  Widget _explanationTile(AppLocalizations loc, ThemeData theme) {
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

  Column _buttonBar(List<int> selectedIds, AppLocalizations loc, ThemeData theme) {
    final errors = <String>[];
    bool noSelection = false;

    if (selectedIds.isEmpty) {
      noSelection = true; // No error message for no selection, but still not valid
    }
    else if (selectedIds.length < 2) {
      errors.add(loc.prerecorderErrorLessThanTwoSelected);
    } 
    else if (selectedIds.length > 2) {
      errors.add(loc.prerecorderErrorMoreThanTwoSelected);
    } else {
      final a = _records.firstWhere((r) => r.id == selectedIds[0]);
      final b = _records.firstWhere((r) => r.id == selectedIds[1]);

      // Rule 1: departure must be before arrival
      if (a.dateTimeUtc.isAfter(b.dateTimeUtc)) {
        errors.add(loc.prerecorderErrorDepartureAfterArrival);
      }

      // Rule 2: types must be consistent (ignore unknown)
      final bothKnown = a.type != VehicleType.unknown && b.type != VehicleType.unknown;
      if (bothKnown && a.type != b.type) {
        errors.add(loc.prerecorderErrorTypeSameForDepartureArrival);
      }
    }

    final isValidSelection = errors.isEmpty && !noSelection;
    final String? errorMessage = errors.isEmpty ? null : errors.join('\n');
    final isWarning = (errorMessage == loc.prerecorderErrorLessThanTwoSelected);

    final errorBanner = errorMessage != null ? [
          ErrorBanner(
            message: errorMessage,
            compact: true,
            severity: isWarning ? ErrorSeverity.warning : ErrorSeverity.error,
          ),
          SizedBox(height: 8,),
        ]: [];

    final createTripCaller = !isValidSelection ? null : () {
              Navigator.of(context).push(PageRouteBuilder(
                pageBuilder: (_, __, ___) => ChangeNotifierProvider(
                  create: (_) => _createTripFormModel(),
                  child: AddTripPage(preRecorderIdsToDelete: _selectedIds,),
                ),
                transitionDuration: Duration.zero,
                reverseTransitionDuration: Duration.zero,
              ));
            };

    if(AppPlatform.isApple) {
      return Column(
        children: [
          ...errorBanner,
          Row(
            children: [
              Expanded(
                child: AdaptiveButton.build(
                  context: context,
                  label: Text(loc.prerecorderCreateTripButton,), 
                  icon: AdaptiveIcons.add,
                  onPressed: createTripCaller,
                  size: AdaptiveButton.large,
                  type: AdaptiveButtonType.secondary
                ),
              ),
              const SizedBox(width: 8,),
              Expanded(
                child: AdaptiveButton.build(
                  context: context,
                  label: Text(loc.prerecorderRecordButton,), 
                  icon: AdaptiveIcons.edit,
                  onPressed: _recordNewLog,
                  size: AdaptiveButton.large,
                  type: AdaptiveButtonType.primary
                ),
              ),
            ],
          )
        ],
      );
    }

    return Column(
      children: [
        SizedBox(
          width: double.infinity,
          child: ElevatedButton.icon(
            onPressed: createTripCaller,
            label: Text(
              loc.prerecorderCreateTripButton,
              style: TextStyle(
                fontSize: theme.textTheme.titleMedium?.fontSize,
                fontWeight: FontWeight.w600,
              ),
            ),
            icon: const Icon(Icons.add, size: 24),
            style: buttonStyleHelper(theme.colorScheme.primary, theme.colorScheme.onPrimary).copyWith(
              padding: WidgetStateProperty.all(
                const EdgeInsets.symmetric(vertical: 16),
              ),
            ),
          ),
        ),
        SizedBox(height: 8,),
        ...errorBanner,
        if(!AppPlatform.isApple)
        Row(
          children: [
            IntrinsicWidth(
              child: AdaptiveButton.build(
                context: context,
                label: Text(deleteButtonLabel(loc)), 
                icon: AdaptiveIcons.delete,
                type: AdaptiveButtonType.destructive,
                size: AdaptiveButton.small,
                onPressed: () async {
                    _askForDelete(loc);
                  }
              ),
            ),
            const Spacer(),
            Material(
              elevation: 4,
              shape: const CircleBorder(),
              color: theme.colorScheme.secondaryContainer,
              child: IconButton(
                onPressed: _changeSortOder,
                icon: Icon(sortIcon),
                color: theme.colorScheme.onSecondaryContainer,
                tooltip: sortTooltip(loc),
              ),
            ),
          ],
        ),
      ],
    );
  }

  void _changeSortOder() {
    setState(() {
      _ascending = !_ascending;
      _sortRecords();
    });
  }

  Future<void> _askForDelete(AppLocalizations loc) async {
    final deleteSelection = _selectedIds.isNotEmpty;

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

    setState(() {
      _deleteRecords(deleteSelection: deleteSelection);
    });
  }

  Widget _preRecordTile(
    PreRecordModel record,
    bool selected,
    AppLocalizations loc, 
    ThemeData theme,
  ) {
    final hasCoordinates = record.lat != null && record.long != null;
    final hasStation = record.stationName != null &&
        record.stationName!.trim().isNotEmpty;
    final hasAddress = record.address != null &&
        record.address!.trim().isNotEmpty;
    final settings = context.read<SettingsProvider>();
    final palette = MapColorPaletteHelper.getPalette(settings.mapColorPalette);
    final unknownLocationIcon = Icon( Icons.not_listed_location, color: theme.colorScheme.primary, size: 32, );

    return AdaptiveRecordTile(
      selected: selected,
      leading: record.loaded
          ? (hasStation ? IconTheme(
              data: IconThemeData(
                color: palette[record.type],
                size: 32,
              ),
              child: record.type.icon(),
            ) : unknownLocationIcon)
          : (AppPlatform.isApple
              ? const CupertinoActivityIndicator()
              : const SizedBox(
                  width: 32,
                  height: 32,
                  child: CircularProgressIndicator(strokeWidth: 3),
                )),
      title: record.loaded
          ? Text(
              record.stationName ?? loc.prerecorderUnknownStation,
              style: AppPlatform.isApple
                  ? null
                  : theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
            )
          : const ShimmerBox(width: 180, height: 18),
      subtitle: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(formatDateTime(context, record.dateTime)),
          hasCoordinates
              ? Text(
                  hasAddress
                      ? record.address!
                      : '${record.lat!.toStringAsFixed(6)}, ${record.long!.toStringAsFixed(6)}',
                )
              : const ShimmerBox(width: 180, height: 18),
        ],
      ),
      trailing: _selectionTrailing(record.id, loc, theme),
      onTap: () {
        // iOS feels nicer if tap gives a little haptic:
        if (AppPlatform.isApple) HapticFeedback.selectionClick();
        setState(() {
          if (selected) {
            _selectedIds.remove(record.id);
          } else {
            _selectedIds.add(record.id);
          }
        });
      },
    );
  }

  Future<void> _recordNewLog() async {
    final trainlog = Provider.of<TrainlogProvider>(context, listen: false);
    final loc = AppLocalizations.of(context)!;
    final settings = context.read<SettingsProvider>();

    try {
      final id = DateTime.now().millisecondsSinceEpoch;

      // Create record immediately
      final pendingRecord = PreRecordModel(
        id: id,
        dateTime: DateTime.now(),
        loaded: false, // tells that the coordinates, station name and address have to be fetched
      );

      setState(() {
        _records.add(pendingRecord);
        _sortRecords();
      });

      await _saveAll(); // save pending state

      final position = await _getCurrentPosition(loc);
      final index = _records.indexWhere((r) => r.id == id);

      setState(() {
        _records[index] = _records[index].copyWith(
            lat: position.latitude,
            long: position.longitude,
          );
        });
        await _saveAll();

      // Resolve stations asynchronously
      final stations = await trainlog.findStationsFromCoordinate(
        position.latitude,
        position.longitude,
        distanceLimitMeters: settings.sprRadius,
      );

      // Handle empty results (no station found)
      if (stations.isEmpty) {
        if (index == -1) return;

        // Remove the pending record
        // setState(() {
        //   _records.removeWhere((r) => r.id == id);
        // });
        // Unknown station (manual input)
        setState(() {
        _records[index] = _records[index].copyWith(
            stationName: null,
            address: null,
            type: VehicleType.unknown,
            loaded: true,
          );
        });
        await _saveAll();
        
        // scaffMsg.showSnackBar(
        //   SnackBar(content: Text(loc.prerecorderNoStationReachable))
        // );
        if(!mounted) return;
        AdaptiveInformationMessage.show(context, loc.prerecorderNoStationReachable);
        return;
      }

      // If only one station, use it directly
      String? name;
      String? address;
      VehicleType? type;

      if (stations.length == 1) {
        (name, address, type, _) = stations[0];
      } else {
        if (!mounted) return;
        // Multiple stations - show selection dialog
        final result = await _showStationSelectionDialog(context, stations);
        
        if (result == null) {
          // User cancelled - remove pending record
          setState(() {
            _records.removeWhere((r) => r.id == id);
          });
          await _saveAll();
          return;
        }
        
        (name, address, type) = result;
      }

      // Update same record
      if (index == -1) return;

      setState(() {
        _records[index] = _records[index].copyWith(
          stationName: name,
          address: address,
          type: type,
          loaded: true,
        );
      });

      await _saveAll(); // persist resolved data
    } catch (e) {          
      setState(() {
        _records.removeWhere((r) => r.loaded == false);
      });
      await _saveAll();
      if(!mounted) return;
      debugPrint(e.toString());
      AdaptiveInformationMessage.show(context, loc.prerecorderErrorFetchingStation);
      return;
    }
  }

  List<AppPrimaryAction> _buildPrimaryAction(BuildContext context) {
    final loc = AppLocalizations.of(context)!;

    if(AppPlatform.isApple) {
      return [
        AppPrimaryAction(
          onPressed: _changeSortOder,
          icon: sortIcon,
          tooltip: sortTooltip(loc),
        ),
        AppPrimaryAction(
          onPressed: () => _askForDelete(loc),
          icon: AdaptiveIcons.delete,
          label: deleteButtonLabel(loc, short: true),
          isDestructive: true,
        ),
      ];
    }

    return [AppPrimaryAction(
      onPressed: _recordNewLog,
      icon: AdaptiveIcons.edit,
      label: loc.prerecorderRecordButton
    )];
  }
}
