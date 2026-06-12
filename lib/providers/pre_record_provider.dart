import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart' show TimeOfDay;
import 'package:geolocator/geolocator.dart';
import 'package:lat_lng_to_timezone/lat_lng_to_timezone.dart' as tzmap;
import 'package:trainlog_app/data/models/pre_record_model.dart';
import 'package:trainlog_app/data/models/trip_form_model.dart';
import 'package:trainlog_app/data/models/trips.dart';
import 'package:trainlog_app/providers/trainlog_provider.dart';
import 'package:trainlog_app/services/pre_record_service.dart';
import 'package:trainlog_app/utils/location_utils.dart';

/// Validation problems for the current selection. The UI maps these to
/// localized messages.
enum SelectionError {
  lessThanTwoSelected,
  moreThanTwoSelected,
  departureAfterArrival,
  typeMismatch,
}

class SelectionValidation {
  /// Exactly two records selected and all rules pass.
  final bool isValid;

  /// Nothing selected at all (not an error, but not valid either).
  final bool isEmpty;

  final List<SelectionError> errors;

  const SelectionValidation({
    required this.isValid,
    required this.isEmpty,
    required this.errors,
  });
}

/// How the vehicle type must be resolved before a trip form can be built
/// from the current selection.
enum TypeResolution { known, needsFullPicker, needsRailDisambiguation }

/// Outcome of [PreRecordProvider.recordNewLog]. The UI maps these to user
/// feedback messages.
enum RecordOutcome { success, noStationFound, cancelled, locationDisabled, failed }

typedef StationCandidate = (String? name, String? address, VehicleType type, double distance);
typedef StationChoice = (String? name, String? address, VehicleType type);

/// Asks the user to choose among several station candidates; returns null
/// when they cancel.
typedef StationPicker = Future<StationChoice?> Function(List<StationCandidate> stations);

/// State and business logic of the Smart Prerecorder: the record list, the
/// departure/arrival selection, sorting, validation and the recording flow.
/// Persistence goes through [PreRecordService]; dialogs stay in the UI and
/// are injected as callbacks.
class PreRecordProvider with ChangeNotifier {
  PreRecordProvider({PreRecordService? service})
      : _service = service ?? const PreRecordService();

  final PreRecordService _service;

  List<PreRecordModel> _records = [];
  final List<int> _selectedIds = [];
  bool _ascending = false; // default: newest first

  List<PreRecordModel> get records => List.unmodifiable(_records);
  List<int> get selectedIds => List.unmodifiable(_selectedIds);
  bool get ascending => _ascending;
  bool get hasSelection => _selectedIds.isNotEmpty;

  PreRecordModel recordById(int id) => _records.firstWhere((r) => r.id == id);

  bool isSelected(int id) => _selectedIds.contains(id);

  /// 0 = departure, 1 = arrival, -1 = not selected.
  int selectionIndexOf(int id) => _selectedIds.indexOf(id);

  Future<void> loadRecords() async {
    _records = await _service.loadAll();
    _sortRecords();
    notifyListeners();
  }

  void toggleSortOrder() {
    _ascending = !_ascending;
    _sortRecords();
    notifyListeners();
  }

  void toggleSelection(int id) {
    if (!_selectedIds.remove(id)) _selectedIds.add(id);
    notifyListeners();
  }

  void clearSelection() {
    _selectedIds.clear();
    notifyListeners();
  }

  Future<void> deleteRecords({required bool selectionOnly}) async {
    if (selectionOnly) {
      _records.removeWhere((r) => _selectedIds.contains(r.id));
    } else {
      _records.clear();
    }
    _selectedIds.clear();
    notifyListeners();
    await _service.saveAll(_records);
  }

  void _sortRecords() {
    _records.sort((a, b) => _ascending
        ? a.dateTimeUtc.compareTo(b.dateTimeUtc)
        : b.dateTimeUtc.compareTo(a.dateTimeUtc));
  }

  // ── Selection validation ─────────────────────────────────────────────────

  SelectionValidation validateSelection() {
    if (_selectedIds.isEmpty) {
      return const SelectionValidation(isValid: false, isEmpty: true, errors: []);
    }

    final errors = <SelectionError>[];
    if (_selectedIds.length < 2) {
      errors.add(SelectionError.lessThanTwoSelected);
    } else if (_selectedIds.length > 2) {
      errors.add(SelectionError.moreThanTwoSelected);
    } else {
      final a = recordById(_selectedIds[0]);
      final b = recordById(_selectedIds[1]);

      // Rule 1: departure must be before arrival
      if (a.dateTimeUtc.isAfter(b.dateTimeUtc)) {
        errors.add(SelectionError.departureAfterArrival);
      }

      // Rule 2: types must be consistent (ignore unknown)
      final bothKnown =
          a.type != VehicleType.unknown && b.type != VehicleType.unknown;
      if (bothKnown && a.type != b.type) {
        errors.add(SelectionError.typeMismatch);
      }
    }

    return SelectionValidation(
      isValid: errors.isEmpty,
      isEmpty: false,
      errors: errors,
    );
  }

  // ── Trip form building ───────────────────────────────────────────────────

  /// How the vehicle type must be resolved for the current (valid) selection.
  /// The type is non-null only for [TypeResolution.known].
  (TypeResolution, VehicleType?) typeResolutionForSelection() {
    const railGroup = {VehicleType.train, VehicleType.metro, VehicleType.rail};

    final depType = recordById(_selectedIds[0]).type;
    final arrType = recordById(_selectedIds[1]).type;
    final depKnown = depType != VehicleType.unknown;
    final arrKnown = arrType != VehicleType.unknown;

    if (!depKnown && !arrKnown) {
      // Both unknown → the user must pick from the full list
      return (TypeResolution.needsFullPicker, null);
    }

    // At least one is known — pick the known one (or either if both known & equal)
    final knownType = depKnown ? depType : arrType;
    if (railGroup.contains(knownType)) {
      // Rail family → let the user disambiguate
      return (TypeResolution.needsRailDisambiguation, null);
    }
    return (TypeResolution.known, knownType);
  }

  /// Builds the trip form for the current selection once [type] has been
  /// resolved (see [typeResolutionForSelection]).
  TripFormModel buildTripForm(VehicleType type) {
    final model = TripFormModel();
    model.vehicleType = type;

    _applyEndpoint(model, recordById(_selectedIds[0]), isDeparture: true);
    _applyEndpoint(model, recordById(_selectedIds[1]), isDeparture: false);

    model.initState(); // Toggle hasBeenModified
    return model;
  }

  void _applyEndpoint(
    TripFormModel model,
    PreRecordModel record, {
    required bool isDeparture,
  }) {
    final timezone = tzmap.latLngToTimezoneString(record.lat!, record.long!);
    final dateOnly = DateTime(
      record.dateTime.year,
      record.dateTime.month,
      record.dateTime.day,
    );
    final timeOnly = TimeOfDay.fromDateTime(record.dateTime);
    final geoMode = record.stationName?.trim().isEmpty ?? true;

    if (isDeparture) {
      model.setDepartureDateTime(dateOnly, timeOnly, timezone);
      model.departureLat = record.lat;
      model.departureLong = record.long;
      model.departureGeoMode = geoMode;
      if (!geoMode) {
        model.departureStationName = record.stationName;
        model.departureAddress = record.address;
      }
    } else {
      model.setArrivalDateTime(dateOnly, timeOnly, timezone);
      model.arrivalLat = record.lat;
      model.arrivalLong = record.long;
      model.arrivalGeoMode = geoMode;
      if (!geoMode) {
        model.arrivalStationName = record.stationName;
        model.arrivalAddress = record.address;
      }
    }
  }

  // ── Recording ────────────────────────────────────────────────────────────

  /// Records a new log at the current position: shows a pending record
  /// immediately, then resolves coordinates and the nearby station.
  /// [pickStation] is called only when several candidates are found.
  ///
  /// Location permission must already have been granted by the caller.
  Future<RecordOutcome> recordNewLog({
    required TrainlogProvider trainlog,
    required int radiusMeters,
    required StationPicker pickStation,
  }) async {
    final id = DateTime.now().millisecondsSinceEpoch;

    try {
      // Show the pending tile immediately.
      _records.add(PreRecordModel(
        id: id,
        dateTime: DateTime.now(),
        loaded: false, // coordinates, station name and address still pending
      ));
      _sortRecords();
      notifyListeners();
      await _service.saveAll(_records);

      if (!await Geolocator.isLocationServiceEnabled()) {
        await _discardRecord(id);
        return RecordOutcome.locationDisabled;
      }

      final position = await Geolocator.getCurrentPosition(
        locationSettings: platformLocationSettings(),
      );

      _updateRecord(
        id,
        (r) => r.copyWith(lat: position.latitude, long: position.longitude),
      );
      await _service.saveAll(_records);

      final stations = await trainlog.findStationsFromCoordinate(
        position.latitude,
        position.longitude,
        distanceLimitMeters: radiusMeters,
      );

      if (stations.isEmpty) {
        // Unknown station (manual input later)
        _updateRecord(
          id,
          (r) => r.copyWith(type: VehicleType.unknown, loaded: true),
        );
        await _service.saveAll(_records);
        return RecordOutcome.noStationFound;
      }

      StationChoice choice;
      if (stations.length == 1) {
        final (name, address, type, _) = stations[0];
        choice = (name, address, type);
      } else {
        final picked = await pickStation(stations);
        if (picked == null) {
          // User cancelled — remove the pending record
          await _discardRecord(id);
          return RecordOutcome.cancelled;
        }
        choice = picked;
      }

      final (name, address, type) = choice;
      _updateRecord(
        id,
        (r) => r.copyWith(
          stationName: name,
          address: address,
          type: type,
          loaded: true,
        ),
      );
      await _service.saveAll(_records);
      return RecordOutcome.success;
    } catch (e) {
      debugPrint('🛑 recordNewLog failed: $e');
      _records.removeWhere((r) => !r.loaded);
      notifyListeners();
      await _service.saveAll(_records);
      return RecordOutcome.failed;
    }
  }

  void _updateRecord(int id, PreRecordModel Function(PreRecordModel) update) {
    final index = _records.indexWhere((r) => r.id == id);
    if (index == -1) return;
    _records[index] = update(_records[index]);
    notifyListeners();
  }

  Future<void> _discardRecord(int id) async {
    _records.removeWhere((r) => r.id == id);
    notifyListeners();
    await _service.saveAll(_records);
  }
}
