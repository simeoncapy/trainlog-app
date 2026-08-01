import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:latlong2/latlong.dart';
import 'package:trainlog_app/data/models/polyline_entry.dart';
import 'package:trainlog_app/data/models/trips.dart';
import 'package:trainlog_app/utils/date_utils.dart';
import 'package:timezone/timezone.dart' as tz;
import 'package:trainlog_app/widgets/trip_visibility_selector.dart';
import 'package:trainlog_app/widgets/vehicle_energy_selector.dart';

class TripFormModel extends ChangeNotifier {
  TripFormModel();

  /// Seeds a form with an existing trip, for the edit/duplicate page.
  ///
  /// Only what the form edits is copied. Endpoint coordinates are recovered
  /// from the trip path — a trip carries station names, not their position —
  /// so the date pickers can resolve the endpoint timezones.
  factory TripFormModel.fromTrip(Trips trip) {
    final model = TripFormModel();

    model.vehicleType = trip.type;

    final (departure, arrival) = _endpointsOf(trip);
    model.departureStationName = trip.originStation;
    model.departureStationBaseName = trip.originStation;
    model.departureLat = departure?.latitude;
    model.departureLong = departure?.longitude;

    model.arrivalStationName = trip.destinationStation;
    model.arrivalStationBaseName = trip.destinationStation;
    model.arrivalLat = arrival?.latitude;
    model.arrivalLong = arrival?.longitude;

    model.selectedOperators = trip.operatorName
        .split(',')
        .map((op) => op.trim())
        .where((op) => op.isNotEmpty)
        .toList();

    // --- when ---
    final manualDuration = trip.manualTripDuration?.round();
    final durationParts = manualDuration == null
        ? null
        : (manualDuration ~/ 3600, (manualDuration % 3600) ~/ 60);

    if (trip.isUnknownPastFuture) {
      model.dateType = DateType.unknown;
      model.isPast = trip.startDatetime == unknownPast;
      if (durationParts != null) {
        model.duration[DateType.unknown] = durationParts;
      }
    } else if (trip.isDateOnly) {
      model.dateType = DateType.date;
      model.departureDayDateOnly = trip.startDatetime;
      if (durationParts != null) {
        model.duration[DateType.date] = durationParts;
      }
    } else {
      model.dateType = DateType.precise;
      model.departureDate = trip.utcStartDatetime ?? trip.startDatetime;
      model.departureDateLocal = trip.startDatetime;
      model.hasDepartureDateTime = (depDate: true, depTime: true);
      model.arrivalDate = trip.utcEndDatetime ?? trip.endDatetime;
      model.arrivalDateLocal = trip.endDatetime;
      model.hasArrivalDateTime = (arrDate: true, arrTime: true);
    }

    model.delayDepartureMinute = trip.departureDelayInMinutes;
    model.delayDepartureTime = trip.departureDelayDate;
    model.delayArrivalMinute = trip.arrivalDelayInMinutes;
    model.delayArrivalTime = trip.arrivalDelayDate;

    // --- details & ticket ---
    model.line = _orNull(trip.lineName);
    model.material = _orNull(trip.materialType);
    model.registration = _orNull(trip.reg);
    model.seat = _orNull(trip.seat);
    model.notes = _orNull(trip.notes);

    model.energyType = trip.powerType;
    model.price = trip.price;
    model.currencyCode = _orNull(trip.currency);
    model.purchaseDate = trip.purchasingDate;
    model.tripVisibility = trip.visibility;

    // Seeding is not a user edit.
    model.initState();
    return model;
  }

  /// First and last point of the trip path, i.e. where the trip departs from
  /// and arrives at. Both are null when the trip carries no usable path.
  static (LatLng?, LatLng?) _endpointsOf(Trips trip) {
    var points = trip.pathPoints;
    if (points == null && trip.path.isNotEmpty) {
      try {
        points = PolylineTools.decodePath(trip.path);
      } catch (e) {
        debugPrint('TripFormModel: could not decode the path of ${trip.uid}: $e');
      }
    }
    if (points == null || points.isEmpty) return (null, null);
    return (points.first, points.last);
  }

  static String? _orNull(String? value) =>
      (value == null || value.isEmpty) ? null : value;

  bool _hasBeenChanged = false;
  // STEP 1 — Basic info
  bool highlightBasicsErrors = false;
  bool basicsHasError = false;
  VehicleType? vehicleType = VehicleType.train;

  String? departureStationName;
  String? departureStationBaseName;
  double? departureLat;
  double? departureLong;
  String? departureAddress;
  bool departureGeoMode = false;
  bool highlightDepartureErrors = false;

  String? arrivalStationName;
  String? arrivalStationBaseName;
  double? arrivalLat;
  double? arrivalLong;
  String? arrivalAddress;
  bool arrivalGeoMode = false;
  bool highlightArrivalErrors = false;

  List<String> selectedOperators = [];
  bool highlightOperatorsErrors = false;

  // STEP 2 — Dates
  bool dateHasError = false;
  DateType dateType = DateType.precise;
  DateTime? departureDate;
  DateTime? departureDateLocal;
  ({bool depDate, bool depTime}) hasDepartureDateTime = (
    depDate: false,
    depTime: false,
  );
  DateTime? arrivalDate;
  DateTime? arrivalDateLocal;
  ({bool arrDate, bool arrTime}) hasArrivalDateTime = (
    arrDate: false,
    arrTime: false,
  );
  bool isPast = true;
  Map <DateType, (int?, int?)> duration = {
    DateType.precise: (null, null),
    DateType.unknown: (null, null),
    DateType.date: (null, null)
  };
  DateTime? departureDayDateOnly;

  bool delayDepartureMinuteMode = false;
  DateTime? delayDepartureTime;
  int? delayDepartureMinute;

  bool delayArrivalMinuteMode = false;
  DateTime? delayArrivalTime;
  int? delayArrivalMinute;

  // STEP 3 — Details
  String? line;
  String? material;
  String? registration;
  String? seat;
  String? notes;

  double? price;
  DateTime? purchaseDate;
  String? currencyCode;

  EnergyType energyType = EnergyType.auto;
  TripVisibility? tripVisibility;// = TripVisibility.private;

  String get visibilityName => tripVisibility?.name ?? TripVisibility.private.name;
  TripVisibility get visibility => tripVisibility ?? TripVisibility.private;

  // -----------------------------
  // Helpers
  // -----------------------------
  String _isoDate(DateTime? dt) =>
    dt == null ? '' : dt.toIso8601String().split('T').first;

  String _isoTime(DateTime? dt) {
    if (dt == null) return '';
    final hh = dt.hour.toString().padLeft(2, '0');
    final mm = dt.minute.toString().padLeft(2, '0');
    return '$hh:$mm';
  }

  String _isoDateUtc(DateTime? dt) =>
    dt == null ? '' : dt.toUtc().toIso8601String().split('T').first;

  String _isoTimeUtc(DateTime? dt) =>
      dt == null ? '' : dt.toUtc().toIso8601String().split('T')[1];

  String _when(bool cond, String Function() f) => cond ? f() : '';

  String _s(String? v) => v ?? '';

  String _pastFutureString(bool isPast) => isPast ? 'past' : 'future';

  String _duration(DateType type, {required bool isHour}) {
    final rec = duration[type] ?? (null, null); // (hour, minute)
    final v = isHour ? rec.$1 : rec.$2;         // int?
    return (v ?? 0).toString();//.toStringAsFixed(1);         // "0.0" / "2.0"
  }

  String _toSeconds(DateType type) {
    final (h, m) = duration[type] ?? (0, 0); // (hour, minute)
    final s = (h??0) * 3600 + (m??0) * 60;
    return s.toString();
  }

  // -----------------------------
  // Getters
  // -----------------------------
  bool get hasBeenChanged => _hasBeenChanged;

  bool get departureHasError =>
    (departureStationName?.isEmpty ?? true) ||
    departureLat == null ||
    departureLong == null;

  bool get arrivalHasError =>
    (arrivalStationName?.isEmpty ?? true) ||
    arrivalLat == null ||
    arrivalLong == null;

  (int?, int?) get currentDuration => duration[dateType] ?? (null, null);

  bool validateOperators() => selectedOperators.isNotEmpty;
  bool get operatorHasError => !validateOperators();

  bool arrivalIsAfterDeparture() {
    if (departureDate == null || arrivalDate == null) return false;
    return !arrivalDate!.isBefore(departureDate!);
  }

  bool hasDepartureAndArrivalDates() {
    if (!hasDepartureDateTime.depDate ||
        !hasDepartureDateTime.depTime ||
        !hasArrivalDateTime.arrDate ||
        !hasArrivalDateTime.arrTime) {
      return false;
    }
    return true;
  }

  int? durationS() {
    final value = duration[dateType];
    if (value == null) return null;

    final (hour, minute) = value;
    if (hour == null || minute == null) return null;

    return hour * 3600 + minute * 60;
  }

  (int?, int?) durationByType(DateType type) {
    return duration[type] ?? (null, null);
  }

  int? durationHourByType(type) {
    return durationByType(type).$1;
  }

  int? durationMinuteByType(type) {
    return durationByType(type).$2;
  }

  // Init
  void initState() => _hasBeenChanged = false;

  // -----------------------------
  // Validation
  // -----------------------------
  bool validateBasics() {
    basicsHasError = departureHasError || arrivalHasError;
    highlightBasicsErrors = basicsHasError;
    highlightDepartureErrors = departureHasError;
    highlightArrivalErrors = arrivalHasError;
    //highlightOperatorsErrors = operatorHasError;

    // Operator is no more an error if missing

    notifyListeners();

    return !basicsHasError;
  }

  bool validateDate() {
    switch(dateType) {
      case DateType.date:
        return departureDayDateOnly != null;
      case DateType.unknown: // Nothing is mandatory
        return true;
      case DateType.precise:
        return _checkDateAndTime();
    }
  }

  bool validateDetails() {
    return true; // All facultative and no check required
  }

  void triggerBasicsValidation() {
    highlightBasicsErrors = true;
    notifyListeners();
  }

  bool _checkDateAndTime()
  {
    if (!hasDepartureAndArrivalDates()) {
      return false;
    }

    // Check if the arrival is AFTER the depature (regarding time zone)
    return arrivalIsAfterDeparture();
  }

  // -----------------------------
  // Setters
  // -----------------------------
  void formDataChanged() => _hasBeenChanged = true;

  void setVehicleType(VehicleType type) {
    vehicleType = type;
    formDataChanged();
    notifyListeners();
  }
  
  void setDeparture({
    String? name,
    String? baseName,
    double? lat,
    double? long,
    String? address,
    bool? geoMode,
  }) {
    departureStationName = name;
    departureStationBaseName = baseName;
    departureLat = lat;
    departureLong = long;
    departureAddress = address;
    departureGeoMode = geoMode ?? false;
    formDataChanged();
    notifyListeners();
  }

  /// Renames the departure without touching its position — what the edit
  /// form's route section offers.
  void setDepartureDisplayName(String? name) {
    departureStationName = name;
    formDataChanged();
    notifyListeners();
  }

  /// Renames the arrival without touching its position.
  void setArrivalDisplayName(String? name) {
    arrivalStationName = name;
    formDataChanged();
    notifyListeners();
  }

  void updateDepartureCoords(double lat, double long) {
    departureLat = lat;
    departureLong = long;
    formDataChanged();
    notifyListeners();
  }

  void setArrival({
    String? name,
    String? baseName,
    double? lat,
    double? long,
    String? address,
    bool? geoMode,
  }) {
    arrivalStationName = name;
    arrivalStationBaseName = baseName;
    arrivalLat = lat;
    arrivalLong = long;
    arrivalAddress = address;
    arrivalGeoMode = geoMode ?? false;
    formDataChanged();
    notifyListeners();
  }

  void updateArrivalCoords(double lat, double long) {
    arrivalLat = lat;
    arrivalLong = long;
    formDataChanged();
    notifyListeners();
  }

  void switchDepartureArrival() {
    // --- swap station names ---
    final tmpName = departureStationName;
    departureStationName = arrivalStationName;
    arrivalStationName = tmpName;

    final tmpBaseName = departureStationBaseName;
    departureStationBaseName = arrivalStationBaseName;
    arrivalStationBaseName = tmpBaseName;

    // --- swap coordinates ---
    final tmpLat = departureLat;
    final tmpLong = departureLong;
    departureLat = arrivalLat;
    departureLong = arrivalLong;
    arrivalLat = tmpLat;
    arrivalLong = tmpLong;

    // --- swap addresses ---
    final tmpAddress = departureAddress;
    departureAddress = arrivalAddress;
    arrivalAddress = tmpAddress;

    // --- swap geo modes ---
    final tmpGeo = departureGeoMode;
    departureGeoMode = arrivalGeoMode;
    arrivalGeoMode = tmpGeo;

    // --- swap error highlights ---
    final tmpErr = highlightDepartureErrors;
    highlightDepartureErrors = highlightArrivalErrors;
    highlightArrivalErrors = tmpErr;

    notifyListeners();
  }

  void setOperators(List<String> ops) {
    selectedOperators = ops;
    formDataChanged();
    notifyListeners();
  }

  DateTime _setDateTimeWithTimeZone(DateTime date, TimeOfDay time, String timezone)
  {
    // get the TZ location (DST-aware)
    final location = tz.getLocation(timezone);

    // Construct local datetime inside that timezone
    final localTzDate = tz.TZDateTime(
      location,
      date.year,
      date.month,
      date.day,
      time.hour,
      time.minute,
    );

    // Convert to UTC for storage
    return localTzDate.toUtc();
  }

  DateTime _setDateTimeLocal(DateTime date, TimeOfDay time) {
    return DateTime(
      date.year,
      date.month,
      date.day,
      time.hour,
      time.minute,
    );
  }

  void setDepartureDateTime(DateTime? date, TimeOfDay? time, String timezone)
  {
     hasDepartureDateTime = (
      depDate: date != null,
      depTime: time != null,
    );

    // If missing either field, do not compute a full DateTime
    if (date == null || time == null) {
      departureDate = null;
      notifyListeners();
      return;
    }

    departureDateLocal = _setDateTimeLocal(date, time);
    departureDate = _setDateTimeWithTimeZone(date, time, timezone);
    formDataChanged();
    notifyListeners();
  }

  void initDepartureDateTime(DateTime date, TimeOfDay time, String timezone)
  {
    departureDateLocal = _setDateTimeLocal(date, time);
    departureDate = _setDateTimeWithTimeZone(date, time, timezone);
  }

  void setArrivalDateTime(DateTime? date, TimeOfDay? time, String timezone)
  {
     hasArrivalDateTime = (
      arrDate: date != null,
      arrTime: time != null,
    );

    // If missing either field, do not compute a full DateTime
    if (date == null || time == null) {
      arrivalDate = null;
      notifyListeners();
      return;
    }

    arrivalDateLocal = _setDateTimeLocal(date, time);
    arrivalDate = _setDateTimeWithTimeZone(date, time, timezone);
    formDataChanged();
    notifyListeners();
  }

  void setDuration(DateType type, int? hour, int? minute) {
    setDurationHour(type, hour);
    setDurationMinute(type, minute);
  }

  void setDurationHour(DateType type, int? hour) {
    final (_, minute) = duration[type] ?? (null, null);
    duration[type] = (hour, minute);
    formDataChanged();
    notifyListeners();
  }

  void setDurationMinute(DateType type, int? minute) {
    final (hour, _) = duration[type] ?? (null, null);
    duration[type] = (hour, minute);
    formDataChanged();
    notifyListeners();
  }

  void setDepartureDelay(bool minuteMode, DateTime? delayTime, int? delayMinute) {
    delayDepartureMinuteMode = minuteMode;
    delayDepartureTime = delayTime;
    delayDepartureMinute = delayMinute;
    formDataChanged();
  }

  void setArrivalDelay(bool minuteMode, DateTime? delayTime, int? delayMinute) {
    delayArrivalMinuteMode = minuteMode;
    delayArrivalTime = delayTime;
    delayArrivalMinute = delayMinute;
    formDataChanged();
  }

  // Page 3

  void setEnergyType(EnergyType value) {
    if (energyType == value) return; // avoids extra rebuilds
    energyType = value;
    formDataChanged();
    notifyListeners();
  }

  void setVisibility(TripVisibility value, {bool init = false}) {
    if (tripVisibility == value) return; // avoids extra rebuilds
    tripVisibility = value;
    if(!init) formDataChanged();
    notifyListeners();
  }

  // -----------------------------
  // Clear errors
  // -----------------------------
  void clearBasicsError() {
    basicsHasError = false;
    highlightBasicsErrors = false;
    notifyListeners();
  }

  void clearDepartureError() {
    highlightDepartureErrors = false;
    notifyListeners();
  }

  void clearArrivalError() {
    highlightArrivalErrors = false;
    notifyListeners();
  }

  void clearOperatorError() {
    highlightOperatorsErrors = false;
    notifyListeners();
  }

  void clearDateError() {
    dateHasError = false;
    notifyListeners();
  }


  // -----------------------------
  // JSON
  // -----------------------------
  String toJson() {
    final map = <String, dynamic>{};

    // ---- origin ----
    if (departureGeoMode) {
      map['originManualName'] = departureStationName;
      map['originManualLat']  = departureLat?.toString() ?? '';
      map['originManualLng']  = departureLong?.toString() ?? '';
    }
    map['originStation'] = [
      [departureLat, departureLong],
      departureStationBaseName ?? departureStationName,
    ];

    // ---- destination ----
    if (arrivalGeoMode) {
      map['destinationManualName'] = arrivalStationName;
      map['destinationManualLat']  = arrivalLat?.toString() ?? '';
      map['destinationManualLng']  = arrivalLong?.toString() ?? '';
    }
    map['destinationStation'] = [
      [arrivalLat, arrivalLong],
      arrivalStationBaseName ?? arrivalStationName,
    ];

    final departureDate = _when(dateType == DateType.precise, () => _isoDate(departureDateLocal));
    final departureTime = _when(dateType == DateType.precise, () => _isoTime(departureDateLocal));
    final arrivalDate = _when(dateType == DateType.precise, () => _isoDate(arrivalDateLocal));
    final arrivalTime = _when(dateType == DateType.precise, () => _isoTime(arrivalDateLocal));

    // ---- rest ----
    map.addAll({
      "operator": selectedOperators.join(","),
      "lineName": _s(line),
      "material_type": _s(material),
      "reg": _s(registration),
      "seat": _s(seat),
      "notes": _s(notes),

      "price": price?.toString() ?? "",
      "currency": _when(price != null, () => _s(currencyCode)),
      "purchasing_date": _when(price != null, () => _isoDate(purchaseDate)),

      "ticket_id": "",
      "powerType": energyType.name,

      "precision": dateType.apiName,
      "onlyDate": _when(dateType == DateType.date, () => _isoDate(departureDayDateOnly)),
      "unknownType": _when(dateType == DateType.unknown, () => _pastFutureString(isPast)),
      "manDurationHours": _when(dateType != DateType.precise, () => _duration(dateType, isHour: true)),
      "manDurationMinutes": _when(dateType != DateType.precise, () => _duration(dateType, isHour: false)),

      "newTripStartDate": departureDate,
      "newTripStartTime": departureTime,
      "newTripEndDate": arrivalDate,
      "newTripEndTime": arrivalTime,

      "onlyDateDuration": _when(dateType == DateType.date, () => _toSeconds(dateType)),
      "newTripEnd": "${arrivalDate}T$arrivalTime",
      "newTripStart": "${departureDate}T$departureTime",

      "visibility": visibilityName,
    });
    if (delayDepartureMinute != null) {
      map["departure_delay"] = delayDepartureMinute! * 60; // Trainlog uses delays in seconds
    }
    if (delayArrivalMinute != null) {
      map["arrival_delay"] = delayArrivalMinute! * 60; // Trainlog uses delays in seconds
    }

    debugPrint(jsonEncode(map));
    return jsonEncode(map);
  }
}
