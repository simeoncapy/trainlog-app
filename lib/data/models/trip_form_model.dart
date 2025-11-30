import 'package:flutter/material.dart';
import 'package:trainlog_app/data/models/trips.dart';

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
  DateTime? departureDate;
  DateTime? arrivalDate;

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

  // -----------------------------
  // Validation
  // -----------------------------
  bool validateBasics() {
    basicsHasError = operatorHasError || departureHasError || arrivalHasError;
    highlightBasicsErrors = basicsHasError;
    highlightDepartureErrors = departureHasError;
    highlightArrivalErrors = arrivalHasError;
    highlightOperatorsErrors = operatorHasError;

    notifyListeners();

    return !basicsHasError;
  }

  bool validateDate() {
    return departureDate != null && arrivalDate != null;
  }

  bool validateDetails() {
    return true; // Decide your required fields
  }

  void triggerBasicsValidation() {
    highlightBasicsErrors = true;
    notifyListeners();
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
