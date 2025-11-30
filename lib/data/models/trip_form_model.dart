import 'package:flutter/material.dart';
import 'package:trainlog_app/data/models/trips.dart';
import 'package:trainlog_app/utils/date_utils.dart';
import 'package:timezone/timezone.dart' as tz;

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
  int? duration; // second
  DateTime? departureDayDateOnly;

  // STEP 3 — Details
  String? notes;

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

  bool validateOperators() => selectedOperators.isNotEmpty;
  bool get operatorHasError => !validateOperators();

  bool arrivalIsAfterDeparture() {
    if (departureDate == null || arrivalDate == null) return false;
    return arrivalDate!.isAfter(departureDate!);
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
    return true; // Decide your required fields
  }

  void triggerBasicsValidation() {
    highlightBasicsErrors = true;
    notifyListeners();
  }

  bool _checkDateAndTime()
  {
    if (!hasDepartureDateTime.depDate ||
        !hasDepartureDateTime.depTime ||
        !hasArrivalDateTime.arrDate ||
        !hasArrivalDateTime.arrTime) {
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
