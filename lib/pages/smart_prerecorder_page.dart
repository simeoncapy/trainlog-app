import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:trainlog_app/data/models/pre_record_model.dart';
import 'package:trainlog_app/data/models/trip_form_model.dart';
import 'dart:convert';
import 'dart:io';
import 'package:trainlog_app/l10n/app_localizations.dart';
import 'package:trainlog_app/pages/add_trip_page.dart';
import 'package:trainlog_app/providers/settings_provider.dart';
import 'package:trainlog_app/providers/trainlog_provider.dart';
import 'package:trainlog_app/utils/date_utils.dart';
import 'package:trainlog_app/utils/location_utils.dart';
import 'package:trainlog_app/utils/map_color_palette.dart';
import 'package:trainlog_app/utils/style_utils.dart';
import 'package:trainlog_app/utils/cached_data_utils.dart';
import 'package:geolocator/geolocator.dart';

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
      _sortRecords();
    });
  }

  void _sortRecords() {
    _records.sort((a, b) =>
        _ascending
            ? a.dateTime.compareTo(b.dateTime)
            : b.dateTime.compareTo(a.dateTime));
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
    return ExpansionTile(
          initiallyExpanded: true,
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

    return Card(
      color: selected
          ? theme.colorScheme.primaryContainer
          : null,
      child: ListTile(
        titleAlignment: ListTileTitleAlignment.center,
        leading: hasStation ? IconTheme(
              data: IconThemeData(
                color: palette[record.type],
                size: 32
              ),
              child: record.type.icon(),
            ) 
          : Icon(
          Icons.not_listed_location,
          color: theme.colorScheme.primary,
          size: 32,
        ),
        title: Text(
          hasStation ? record.stationName! : loc.prerecorderUnknownStation,
          style: theme.textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.bold,
          ),
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
    return FloatingActionButton.extended(
      onPressed: () async {
        try {
          final position = await _getCurrentPosition(loc);

          final record = await trainlog.findStationFromCoordinate(position.latitude, position.longitude);
          await _savePreRecord(record);

          setState(() {
            _records.add(record);
            _sortRecords();
          });

        } catch (e) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(e.toString())),
          );
        }
      },
      icon: const Icon(Icons.edit),
      label: Text(loc.prerecorderRecordButton)
    );
  }
}
