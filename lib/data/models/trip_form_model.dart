import 'package:flutter/material.dart';
import 'package:trainlog_app/data/models/trips.dart';
import 'package:trainlog_app/utils/date_utils.dart';
import 'package:timezone/timezone.dart' as tz;
import 'package:trainlog_app/widgets/trip_visibility_selector.dart';
import 'package:trainlog_app/widgets/vehicle_energy_selector.dart';

class TripFormModel extends ChangeNotifier {
  // STEP 1 — Basic info
  bool highlightBasicsErrors = false;
  bool basicsHasError = false;
  VehicleType? vehicleType = VehicleType.train;

  String? departureStationName;
  double? departureLat;
  double? departureLong;
  String? departureAddress;
  bool departureGeoMode = false;
  bool highlightDepartureErrors = false;

  String? arrivalStationName;
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
  ({bool depDate, bool depTime}) hasDepartureDateTime = (
    depDate: false,
    depTime: false,
  );
  DateTime? arrivalDate;
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
  TripVisibility tripVisibility = TripVisibility.private;

  // -----------------------------
  // Getters
  // -----------------------------
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
  void setVehicleType(VehicleType type) {
    vehicleType = type;
    notifyListeners();
  }
  
  void setDeparture({
    String? name,
    double? lat,
    double? long,
    String? address,
    bool? geoMode,
  }) {
    departureStationName = name;
    departureLat = lat;
    departureLong = long;
    departureAddress = address;
    departureGeoMode = geoMode ?? false;
    notifyListeners();
  }

  void updateDepartureCoords(double lat, double long) {
    departureLat = lat;
    departureLong = long;
    notifyListeners();
  }

  void setArrival({
    String? name,
    double? lat,
    double? long,
    String? address,
    bool? geoMode,
  }) {
    arrivalStationName = name;
    arrivalLat = lat;
    arrivalLong = long;
    arrivalAddress = address;
    arrivalGeoMode = geoMode ?? false;
    notifyListeners();
  }

  void updateArrivalCoords(double lat, double long) {
    arrivalLat = lat;
    arrivalLong = long;
    notifyListeners();
  }

  void switchDepartureArrival() {
    // --- swap station names ---
    final tmpName = departureStationName;
    departureStationName = arrivalStationName;
    arrivalStationName = tmpName;

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

    departureDate = _setDateTimeWithTimeZone(date, time, timezone);
    notifyListeners();
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

    arrivalDate = _setDateTimeWithTimeZone(date, time, timezone);
    notifyListeners();
  }

  void setDuration(DateType type, int? hour, int? minute) {
    setDurationHour(type, hour);
    setDurationMinute(type, minute);
  }

  void setDurationHour(DateType type, int? hour) {
    final (_, minute) = duration[type] ?? (null, null);
    duration[type] = (hour, minute);
    notifyListeners();
  }

  void setDurationMinute(DateType type, int? minute) {
    final (hour, _) = duration[type] ?? (null, null);
    duration[type] = (hour, minute);
    notifyListeners();
  }

  // Page 3

  void setenergyType(EnergyType value) {
    if (energyType == value) return; // avoids extra rebuilds
    energyType = value;
    notifyListeners();
  }

  void setVisibility(TripVisibility value) {
    if (tripVisibility == value) return; // avoids extra rebuilds
    tripVisibility = value;
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
}
