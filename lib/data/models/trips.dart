import 'dart:convert';
import 'package:google_polyline_algorithm/google_polyline_algorithm.dart';
import 'package:latlong2/latlong.dart';
import 'package:flutter/material.dart';
import 'package:trainlog_app/l10n/app_localizations.dart';
import 'package:material_symbols_icons/symbols.dart';
import 'package:trainlog_app/utils/date_utils.dart';
import 'package:trainlog_app/widgets/trip_visibility_selector.dart';
import 'package:trainlog_app/data/models/polyline_entry.dart';

class Trips {
  final String uid;
  final String username;
  final String originStation;
  final String destinationStation;
  final DateTime startDatetime;
  final DateTime endDatetime;
  final double estimatedTripDuration;
  final double? manualTripDuration;
  final double tripLength;
  final String operatorName;
  final String countries;
  final DateTime? utcStartDatetime;
  final DateTime? utcEndDatetime;
  final String lineName;
  final DateTime created;
  final DateTime lastModified;
  final VehicleType type;
  final String? materialType;
  final String? seat;
  final String? reg;
  final String? waypoints;
  final String? notes;
  final double? price;
  final String? currency;
  final DateTime? purchasingDate;
  final String path;
  final List<LatLng>? pathPoints;
  final TripVisibility visibility;
  final int? departureDelay; // in seconds
  final int? arrivalDelay; // in seconds

  Trips({
    required this.uid,
    required this.username,
    required this.originStation,
    required this.destinationStation,
    required this.startDatetime,
    required this.endDatetime,
    required this.estimatedTripDuration,
    this.manualTripDuration,
    required this.tripLength,
    required this.operatorName,
    required this.countries,
    this.utcStartDatetime,
    this.utcEndDatetime,
    required this.lineName,
    required this.created,
    required this.lastModified,
    required this.type,
    this.materialType,
    this.seat,
    this.reg,
    this.waypoints,
    this.notes,
    this.price,
    this.currency,
    this.purchasingDate,
    required this.path,
    this.pathPoints,
    required this.visibility,
    this.departureDelay,
    this.arrivalDelay,
  });

  VehicleType get vehicleType => type;
  DateTime get startDate => startDatetime;
  DateTime get endDate => endDatetime;
  DateTime? get utcStartDate => utcStartDatetime;
  DateTime? get utcEndDate => utcEndDatetime;
  DateTime get creationDate => created;

  int? get departureDelayInMinutes => Trips.formatDelayInMinutes(departureDelay);
  String? get departureDelayFormatted {
    return Trips.formatDelay(departureDelay);
  }
  int? get arrivalDelayInMinutes => Trips.formatDelayInMinutes(arrivalDelay);
  String? get arrivalDelayFormatted {
    return Trips.formatDelay(arrivalDelay);
  }

  static int? formatDelayInMinutes(int? delayInSeconds) {
    if (delayInSeconds == null) return null;
    return (delayInSeconds / 60).round();
  }

  static String? formatDelay(int? delayInSeconds) {
    final minutes = formatDelayInMinutes(delayInSeconds);
    if (minutes == null) return null;
    final sign = minutes >= 0 ? '+' : '-';
    return '$sign${minutes.abs()} min';
  }

  bool get hasDelay => departureDelay != null || arrivalDelay != null;
  bool get hasDepartureDelay => departureDelay != null;
  bool get hasArrivalDelay => arrivalDelay != null;

  // Real start and end dates getters
  DateTime? get departureDelayDate {
    if (departureDelay != null) {
      return startDatetime.add(Duration(seconds: departureDelay!));
    }
    return null;
  }

  DateTime get realStartDate {
    return departureDelayDate ?? startDatetime;
  }

  DateTime? get arrivalDelayDate {
    if (arrivalDelay != null) {
      return endDatetime.add(Duration(seconds: arrivalDelay!));
    }
    return null;
  }

  DateTime get realEndDate {
    return arrivalDelayDate ?? endDatetime;
  }

  //       hasTimeRange: trip.hasTimeRange,

  bool get isDateOnly => (startDatetime == endDatetime) && utcEndDatetime == null;
  bool get isUnknownPastFuture {
    return (startDatetime == unknownPast || startDatetime == unknownFuture) && utcEndDatetime == null;
  }

  List<String> get countryList {
    try {
      final map = jsonDecode(countries) as Map<String, dynamic>;
      return map.keys.toList();
    } catch (_) {
      return const [];
    }
  }

  factory Trips.fromJson(Map<String, dynamic> json, {bool pathAsGooglePolyline = true, bool decodePolyline = false}) {
    final start = _toDateTimeUnknownPastFuture(json['start_datetime']);
    final end = _toDateTimeUnknownPastFuture(json['end_datetime']);
    return Trips(
      uid: json['uid']?.toString() ?? '',
      username: json['username']?.toString() ?? '',
      originStation: json['origin_station']?.toString() ?? '',
      destinationStation: json['destination_station']?.toString() ?? '',
      startDatetime: start,
      endDatetime: end,
      estimatedTripDuration: _toDouble(json['estimated_trip_duration']),
      manualTripDuration: _toDoubleOrNull(json['manual_trip_duration']),
      tripLength: _toDouble(json['trip_length']),
      operatorName: json['operator']?.toString() ?? '',
      countries: json['countries']?.toString() ?? '',
      utcStartDatetime: _toDateTimeOrCopy(json['utc_start_datetime'], start),
      utcEndDatetime: _toDateTimeOrNull(json['utc_end_datetime']),
      lineName: json['line_name']?.toString() ?? '',
      created: DateTime.parse(json['created']),
      lastModified: DateTime.parse(json['last_modified']),
      type: VehicleType.fromString(json['type']),
      materialType: json['material_type']?.toString() ?? '',
      seat: json['seat']?.toString() ?? '',
      reg: json['reg']?.toString() ?? '',
      waypoints: json['waypoints']?.toString() ?? '',
      notes: json['notes']?.toString() ?? '',
      price: _toDoubleOrNull(json['price']),
      currency: json['currency']?.toString() ?? '',
      purchasingDate: _toDateTimeOrNull(json['purchasing_date']),
      path: pathAsGooglePolyline ? (json['path']?.toString() ?? '') : PolylineTools.encodePath(json['path']),
      pathPoints: pathAsGooglePolyline 
                  ? (decodePolyline ? PolylineTools.decodePath(json['path']?.toString() ?? '') : null) 
                  : PolylineTools.toLatLngList(json['path']),
      visibility: TripVisibility.fromString(json['visibility']),
      departureDelay: _toIntOrNull(json['departure_delay']),
      arrivalDelay: _toIntOrNull(json['arrival_delay']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'uid': uid,
      'username': username,
      'origin_station': originStation,
      'destination_station': destinationStation,
      'start_datetime': startDatetime.toIso8601String(),
      'end_datetime': endDatetime.toIso8601String(),
      'estimated_trip_duration': estimatedTripDuration,
      'manual_trip_duration': manualTripDuration,
      'trip_length': tripLength,
      'operator': operatorName,
      'countries': countries,
      'utc_start_datetime': utcStartDatetime?.toIso8601String(),
      'utc_end_datetime': utcEndDatetime?.toIso8601String(),
      'line_name': lineName,
      'created': created.toIso8601String(),
      'last_modified': lastModified.toIso8601String(),
      'type': type.toShortString(),
      'material_type': materialType,
      'seat': seat,
      'reg': reg,
      'waypoints': waypoints,
      'notes': notes,
      'price': price,
      'currency': currency,
      'purchasing_date': purchasingDate?.toIso8601String(),
      'path': path,
      'visibility': visibility.name,
      'departure_delay': departureDelay,
      'arrival_delay': arrivalDelay,
    };
  }


  static double? _toDoubleOrNull(dynamic value) {
    if (value == null || value.toString().trim().isEmpty) return null;
    return double.tryParse(value.toString());
  }

  static int? _toIntOrNull(dynamic value) {
    if (value == null || value.toString().trim().isEmpty) return null;
    return double.tryParse(value.toString())?.toInt();
  }

  static DateTime? _toDateTimeOrNull(dynamic value, {bool forceUtc = true}) {
    if (value == null || value.toString().trim().isEmpty) return null;
    final str = value.toString();
    final dateStr = forceUtc && !str.endsWith('Z') ? '${str}Z' : str;
    
    return DateTime.tryParse(dateStr);
  }

  static DateTime? _toDateTimeOrCopy(dynamic value, DateTime? copy, {bool forceUtc = true}) {
    if (value == null || value.toString().trim().isEmpty) {
      if (copy == null || !forceUtc || copy.isUtc) return copy;
      
      // Convert copy to UTC
      return DateTime.utc(
        copy.year,
        copy.month,
        copy.day,
        copy.hour,
        copy.minute,
        copy.second,
        copy.millisecond,
        copy.microsecond,
      );
    }
    
    final parsed = DateTime.tryParse(value.toString());
    
    if (parsed == null || !forceUtc || parsed.isUtc) return parsed;
    
    // Convert parsed to UTC
    return DateTime.utc(
      parsed.year,
      parsed.month,
      parsed.day,
      parsed.hour,
      parsed.minute,
      parsed.second,
      parsed.millisecond,
      parsed.microsecond,
    );
  }

  static double _toDouble(dynamic value) {
    final str = value?.toString().trim();
    if (str == null || str.isEmpty) {
      throw FormatException('Cannot parse empty value as double');
    }
    return double.parse(str);
  }

  static DateTime _toDateTimeUnknownPastFuture(String? value) {
    final str = value?.trim();
    if (str == null || str.isEmpty) {
      throw FormatException('Cannot parse empty value as DateTime');
    }
    if(value == "-1") return unknownPast;
    if(value == "1") return unknownFuture;
    return DateTime.parse(str);
  }
}


enum VehicleType {
  train,
  plane,
  tram,
  metro,
  rail, // for general rail trips without specific type
  funicular,
  bus,
  car,
  ferry,
  aerialway,
  cycle,
  eScooter,
  helicopter,
  walk,
  ski,
  poi, // point of interest
  unknown;

  static VehicleType fromString(String? str) {
    switch (str?.toLowerCase()) {
      case 'train':
        return VehicleType.train;
      case 'air':
      case 'plane':
        return VehicleType.plane;
      case 'tram':
        return VehicleType.tram;
      case 'metro':
        return VehicleType.metro;
      case 'rail':
        return VehicleType.rail;
      case 'funicular':
        return VehicleType.funicular;
      case 'bus':
        return VehicleType.bus;
      case 'car':
        return VehicleType.car;
      case 'ferry':
        return VehicleType.ferry;
      case 'aerialway':
        return VehicleType.aerialway;
      case 'walk':
        return VehicleType.walk;
      case 'poi':
        return VehicleType.poi;
      case 'cycle':
        return VehicleType.cycle;
      case 'escooter': // app
      case 'e_scooter': // web
        return VehicleType.eScooter;
      case 'helicopter':
        return VehicleType.helicopter;
      case 'ski':
        return VehicleType.ski;
      default:
        return VehicleType.unknown;
    }
  }

  String toShortString() {
    switch (this) {
      case VehicleType.train:
        return 'train';
      case VehicleType.plane:
        return 'air';
      case VehicleType.tram:
        return 'tram';
      case VehicleType.metro:
        return 'metro';
      case VehicleType.rail:
        return 'rail';
      case VehicleType.funicular:
        return 'funicular';
      case VehicleType.ski:
        return 'ski';
      case VehicleType.bus:
        return 'bus';
      case VehicleType.car:
        return 'car';
      case VehicleType.ferry:
        return 'ferry';
      case VehicleType.aerialway:
        return 'aerialway';
      case VehicleType.walk:
        return 'walk';
      case VehicleType.poi:
        return 'poi';
      case VehicleType.cycle:
        return 'cycle';
      case VehicleType.eScooter:
        return 'e_scooter';
      case VehicleType.helicopter:
        return 'helicopter';
      case VehicleType.unknown:
        return 'unknown';
    }
  }

  String label(BuildContext context)
  {
    return labelOf(this, context);
  }

  static String labelOf(VehicleType type, BuildContext context)
  {
    final l10n = AppLocalizations.of(context)!;
    
    switch (type) {
      case VehicleType.train:
        return l10n.typeTrain;
      case VehicleType.plane:
        return l10n.typePlane;
      case VehicleType.tram:
        return l10n.typeTram;
      case VehicleType.metro:
        return l10n.typeMetro;
      case VehicleType.rail:
        return l10n.typeRail;
      case VehicleType.funicular:
        return l10n.typeFunicular;
      case VehicleType.ski:
        return l10n.typeSki;
      case VehicleType.eScooter:
        return l10n.typeEScooter;
      case VehicleType.bus:
        return l10n.typeBus;
      case VehicleType.car:
        return l10n.typeCar;
      case VehicleType.ferry:
        return l10n.typeFerry;
      case VehicleType.aerialway:
        return l10n.typeAerialway;
      case VehicleType.walk:
        return l10n.typeWalk;
      case VehicleType.poi:
        return l10n.typePoi;
      case VehicleType.cycle:
        return l10n.typeCycle;
      case VehicleType.helicopter:
        return l10n.typeHelicopter;
      case VehicleType.unknown:
        return 'unknown';
    }
  }

  bool isRail() {
    switch (this) {
      case VehicleType.train:
      case VehicleType.tram:
      case VehicleType.metro:
      case VehicleType.rail:
      case VehicleType.funicular:
        return true;
      default:
        return false;
    }
  }

  bool isAir() {
    switch (this) {
      case VehicleType.plane:
      case VehicleType.helicopter:
        return true;
      default:
        return false;
    }
  }

  Icon icon()
  {
    return iconOf(this);
  }

  static Icon iconOf(VehicleType type)
  {
    switch (type) {
      case VehicleType.train:
        return Icon(Icons.train);
      case VehicleType.plane:
        return Icon(Icons.flight);
      case VehicleType.tram:
        return Icon(Icons.tram);
      case VehicleType.metro:
        return Icon(Icons.subway);
      case VehicleType.rail:
        return Icon(Symbols.directions_railway_2, fill: 1,);
      case VehicleType.funicular:
        return Icon(Symbols.funicular, fill: 1,);
      case VehicleType.bus:
        return Icon(Icons.directions_bus);
      case VehicleType.car:
        return Icon(Icons.directions_car);
      case VehicleType.ferry:
        return Icon(Icons.directions_ferry);
      case VehicleType.aerialway:
        return Icon(Symbols.gondola_lift, fill: 1,);
      case VehicleType.walk:
        return Icon(Icons.directions_walk);
      case VehicleType.poi:
        return Icon(Icons.flag_circle);
      case VehicleType.cycle:
        return Icon(Icons.pedal_bike);
      case VehicleType.eScooter:
        return Icon(Icons.electric_scooter);
      case VehicleType.ski:
        return Icon(Icons.downhill_skiing);
      case VehicleType.helicopter:
        return Icon(Symbols.helicopter, fill: 1,);
      case VehicleType.unknown:
        return Icon(Icons.question_mark);
    }
  }
}