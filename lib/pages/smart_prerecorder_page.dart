import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:trainlog_app/data/models/pre_record_model.dart';
import 'package:trainlog_app/data/models/trip_form_model.dart';
import 'package:trainlog_app/data/models/trips.dart';
import 'dart:convert';
import 'dart:io';
import 'package:trainlog_app/l10n/app_localizations.dart';
import 'package:trainlog_app/pages/add_trip_page.dart';
import 'package:trainlog_app/providers/settings_provider.dart';
import 'package:trainlog_app/providers/trainlog_provider.dart';
import 'package:trainlog_app/utils/date_utils.dart';
import 'package:trainlog_app/utils/location_utils.dart';
import 'package:trainlog_app/utils/map_color_palette.dart';
import 'package:trainlog_app/utils/number_formatter.dart';
import 'package:trainlog_app/utils/style_utils.dart';
import 'package:trainlog_app/utils/cached_data_utils.dart';
import 'package:geolocator/geolocator.dart';
import 'package:trainlog_app/widgets/shimmer_box.dart';

class SmartPrerecorderPage extends StatefulWidget {
  final void Function(FloatingActionButton? fab) onFabReady;
  const SmartPrerecorderPage({super.key, required this.onFabReady});

  @override
  State<SmartPrerecorderPage> createState() => _SmartPrerecorderPageState();
}

class _SmartPrerecorderPageState extends State<SmartPrerecorderPage> {
  List<PreRecordModel> _records = [];
  final List<int> _selectedIds = [];
  bool _ascending = false; // default: newest first


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

  Future<void> _savePreRecord(PreRecordModel record) async {
    final file = File(AppCacheFilePath.preRecord);

    final content = await file.readAsString();
    final List data =
        content.trim().isEmpty ? [] : jsonDecode(content);

    data.add(record.toJson());

    await file.writeAsString(
      jsonEncode(data),
      flush: true,
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

  Future<bool> _confirmDelete({
    required BuildContext context,
    required AppLocalizations loc,
    required bool deleteSelection,
  }) async {
    return await showDialog<bool>(
          context: context,
          builder: (context) {
            return AlertDialog(
              title: Text(
                deleteSelection
                    ? loc.deleteSelection
                    : loc.deleteAll,
              ),
              content: Text(
                deleteSelection
                    ? loc.prerecorderDeleteSelectionConfirm
                    : loc.prerecorderDeleteAllConfirm,
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(context).pop(false),
                  child: Text(MaterialLocalizations.of(context).cancelButtonLabel),
                ),
                ElevatedButton(
                  style: buttonStyleHelper(
                    Theme.of(context).colorScheme.error,
                    Theme.of(context).colorScheme.onError,
                  ),
                  onPressed: () => Navigator.of(context).pop(true),
                  child: Text(MaterialLocalizations.of(context).deleteButtonTooltip),
                ),
              ],
            );
          },
        ) ??
        false;
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
    final theme = Theme.of(context);
    final settings = context.read<SettingsProvider>();
    final palette = MapColorPaletteHelper.getPalette(settings.mapColorPalette);

    return await showDialog<(String?, String?, VehicleType)?>(
      context: context,
      builder: (context) {
        return Dialog(
          child: Container(
            constraints: BoxConstraints(
              maxHeight: MediaQuery.of(context).size.height * 0.6,
              maxWidth: 500,
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Text(
                    loc.prerecorderSelectStation,
                    style: theme.textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.only(left: 8.0, right: 8.0, bottom: 4.0),
                  child: Text(
                    loc.prerecorderStationsFound(stations.length),                    
                  ),
                ),
                Expanded(
                  child: ListView.builder(
                    shrinkWrap: true,
                    itemCount: stations.length,
                    itemBuilder: (context, index) {
                      final (name, address, type, distance) = stations[index];
                      return ListTile(
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
                          ),
                        ),
                        subtitle: Text(
                          loc.prerecorderAway(formatNumber(context, distance)),
                          style: theme.textTheme.bodySmall,
                        ),
                        onTap: () {
                          Navigator.of(context).pop((name, address, type));
                        },
                      );
                    },
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      // onPressed: () {
                      //   final (name, address, type, _) = stations[0];
                      //   Navigator.of(context).pop((name, address, type));
                      // },
                      onPressed: () {
                        Navigator.of(context).pop((null, null, VehicleType.unknown));
                      },
                      style: buttonStyleHelper(
                        theme.colorScheme.primary,
                        theme.colorScheme.onPrimary,
                      ),
                      //child: Text(loc.prerecorderSelectClosest),
                      child: Text(loc.prerecorderUnknownStation),
                    ),
                  ),
                ),
              ],
            ),
          ),
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
        if (mounted) widget.onFabReady(buildFloatingActionButton(context)!);
      });

    return Padding(
      padding: const EdgeInsets.all(8.0),
      child: Column(
        children: [
          _explanationTile(loc, theme),
          SizedBox(height: 16,),
          _buttonBar(_selectedIds, loc, theme),
          SizedBox(height: 8,),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.only(bottom: 80), // Avoid the last item to be hidden by the FAB
              child: _records.isEmpty
                ? Center(
                    child: Text(
                      loc.prerecorderNoData,
                      style: theme.textTheme.bodyLarge,
                    ),
                  )
                : ListView.builder(
                    //padding: const EdgeInsets.only(bottom: 80), // Avoid the last item to be hidden by the FAB
                    itemCount: _records.length,
                    itemBuilder: (context, index) {
                      final record = _records[index];
                      final selected = _selectedIds.contains(record.id);

                      return _preRecordTile(record, selected, loc, theme);
                    },
                  ),
            ),
          )
        ],
      ),
    );
  }

  ExpansionTile _explanationTile(AppLocalizations loc, ThemeData theme) {
    final settings = context.read<SettingsProvider>();
    return ExpansionTile(
          initiallyExpanded: settings.isSmartPrerecorderExplanationExpanded,
          onExpansionChanged: (p) => settings.setIsSmartPrerecorderExplanationExpanded(p),
          tilePadding: const EdgeInsets.symmetric(horizontal: 16),
          childrenPadding: const EdgeInsets.only(bottom: 8),
          leading: Icon(Icons.info),
          title: Text(
            loc.prerecorderExplanationTitle,
            textAlign: TextAlign.left,
            style: theme.textTheme.titleLarge,
          ),
          expandedCrossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(loc.prerecorderExplanation),
            Text(loc.prerecorderExplanationStation),
            Text(loc.prerecorderExplanationDelete),            
            SizedBox(height: 8,),
            Text(loc.prerecorderExplanationPrivacy)
          ],
        );
  }

  Column _buttonBar(List<int> selectedIds, AppLocalizations loc, ThemeData theme) {
    return Column(
      children: [
        SizedBox(
          width: double.infinity,
          child: ElevatedButton.icon(
            onPressed: selectedIds.length != 2 ? null : () {
              Navigator.of(context).push(PageRouteBuilder(
                pageBuilder: (_, __, ___) => ChangeNotifierProvider(
                  create: (_) => _createTripFormModel(),
                  child: AddTripPage(preRecorderIdsToDelete: _selectedIds,),
                ),
                transitionDuration: Duration.zero,
                reverseTransitionDuration: Duration.zero,
              ));
            } ,
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
        Row(
          children: [
            IntrinsicWidth(
              child: ElevatedButton.icon(
                onPressed: () async {
                  final deleteSelection = selectedIds.isNotEmpty;

                  final confirmed = await _confirmDelete(
                    context: context,
                    loc: loc,
                    deleteSelection: deleteSelection,
                  );

                  if (!confirmed) return;

                  setState(() {
                    _deleteRecords(deleteSelection: deleteSelection);
                  });
                },
                label: Text(selectedIds.isNotEmpty ? loc.deleteSelection : loc.deleteAll),
                icon: Icon(Icons.delete),
                style: buttonStyleHelper(theme.colorScheme.error, theme.colorScheme.onError)
              ),
            ),
            const Spacer(),
            Material(
              elevation: 4,
              shape: const CircleBorder(),
              color: theme.colorScheme.secondaryContainer,
              child: IconButton(
                onPressed: () {
                  setState(() {
                    _ascending = !_ascending;
                    _sortRecords();
                  });
                },
                icon: Icon(
                  _ascending ? Icons.arrow_upward : Icons.arrow_downward,
                ),
                color: theme.colorScheme.onSecondaryContainer,
                tooltip: _ascending
                    ? loc.ascendingOrder
                    : loc.descendingOrder,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _preRecordTile(
    PreRecordModel record,
    bool selected,
    AppLocalizations loc, 
    ThemeData theme,
  ) {
    final hasStation = record.stationName != null &&
        record.stationName!.trim().isNotEmpty;
    final hasAddress = record.address != null &&
        record.address!.trim().isNotEmpty;
    final settings = context.read<SettingsProvider>();
    final palette = MapColorPaletteHelper.getPalette(settings.mapColorPalette);
    final unknownLocationIcon = Icon( Icons.not_listed_location, color: theme.colorScheme.primary, size: 32, );

    return Card(
      color: selected
          ? theme.colorScheme.primaryContainer
          : null,
      child: ListTile(
        titleAlignment: ListTileTitleAlignment.center,
        leading: record.loaded
          ?  (hasStation ? IconTheme(
              data: IconThemeData(
                color: palette[record.type],
                size: 32,
              ),
              child: record.type.icon(),
            ) : unknownLocationIcon)
          : const SizedBox(
              width: 32,
              height: 32,
              child: CircularProgressIndicator(strokeWidth: 3),
            ),
        title: record.loaded
          ? Text(
              record.stationName ?? loc.prerecorderUnknownStation,
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            )
          : const ShimmerBox(
              width: 180,
              height: 18,
            ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              formatDateTime(context, record.dateTime),
            ),
            Text(
              hasAddress ? record.address! : '${record.lat.toStringAsFixed(6)}, ${record.long.toStringAsFixed(6)}',
            ),
          ],
        ),
        isThreeLine: true,
        selected: selected,
        trailing: _selectionTrailing(record.id, loc, theme),
        onTap: () {
          setState(() {
            if (selected) {
              _selectedIds.remove(record.id);
            } else {
              _selectedIds.add(record.id);
            }
          });
        },
      ),
    );
  }

  FloatingActionButton? buildFloatingActionButton(BuildContext context) {
    final trainlog = Provider.of<TrainlogProvider>(context, listen: false);
    final loc = AppLocalizations.of(context)!;
    final scaffMsg = ScaffoldMessenger.of(context);
    final settings = context.read<SettingsProvider>();

    return FloatingActionButton.extended(
      onPressed: () async {
        try {
          final position = await _getCurrentPosition(loc);

          final id = DateTime.now().millisecondsSinceEpoch;

          // Create record immediately
          final pendingRecord = PreRecordModel(
            id: id,
            lat: position.latitude,
            long: position.longitude,
            dateTime: DateTime.now(),
            loaded: false, // tells that the station name and address have to be fetched
          );

          setState(() {
            _records.add(pendingRecord);
            _sortRecords();
          });

          await _saveAll(); // save pending state

          // Resolve stations asynchronously
          final stations = await trainlog.findStationsFromCoordinate(
            position.latitude,
            position.longitude,
            distanceLimitMeters: settings.sprRadius,
          );

          // Handle empty results (no station found)
          if (stations.isEmpty) {
            final index = _records.indexWhere((r) => r.id == id);
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
            
            scaffMsg.showSnackBar(
              SnackBar(content: Text(loc.prerecorderNoStationReachable))
            );
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
          final index = _records.indexWhere((r) => r.id == id);
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
          scaffMsg.showSnackBar(SnackBar(content: Text(e.toString())));
        }
      },
      icon: const Icon(Icons.edit),
      label: Text(loc.prerecorderRecordButton)
    );
  }
}
