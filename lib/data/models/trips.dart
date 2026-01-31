import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:trainlog_app/l10n/app_localizations.dart';
import 'package:material_symbols_icons/symbols.dart';
import 'package:trainlog_app/utils/date_utils.dart';
import 'package:trainlog_app/widgets/trip_visibility_selector.dart';

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
  final TripVisibility visibility;

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
    required this.visibility,
  });

  bool get isDateOnly => startDatetime == endDatetime;
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

  factory Trips.fromJson(Map<String, dynamic> json) {
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
      path: json['path']?.toString() ?? '',
      visibility: TripVisibility.fromString(json['visibility'])
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
    };
  }


  static double? _toDoubleOrNull(dynamic value) {
    if (value == null || value.toString().trim().isEmpty) return null;
    return double.tryParse(value.toString());
  }

  static DateTime? _toDateTimeOrNull(dynamic value) {
    if (value == null || value.toString().trim().isEmpty) return null;
    return DateTime.tryParse(value.toString());
  }

  static DateTime? _toDateTimeOrCopy(dynamic value, DateTime? copy) {
    if (value == null || value.toString().trim().isEmpty) return copy;
    return DateTime.tryParse(value.toString());
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
  bus,
  car,
  ferry,
  aerialway,
  cycle,
  helicopter,
  walk,
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
      case 'helicopter':
        return VehicleType.helicopter;
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
    final appLocalizations = AppLocalizations.of(context)!;
    
    switch (type) {
      case VehicleType.train:
        return appLocalizations.typeTrain;
      case VehicleType.plane:
        return appLocalizations.typePlane;
      case VehicleType.tram:
        return appLocalizations.typeTram;
      case VehicleType.metro:
        return appLocalizations.typeMetro;
      case VehicleType.bus:
        return appLocalizations.typeBus;
      case VehicleType.car:
        return appLocalizations.typeCar;
      case VehicleType.ferry:
        return appLocalizations.typeFerry;
      case VehicleType.aerialway:
        return appLocalizations.typeAerialway;
      case VehicleType.walk:
        return appLocalizations.typeWalk;
      case VehicleType.poi:
        return appLocalizations.typePoi;
      case VehicleType.cycle:
        return appLocalizations.typeCycle;
      case VehicleType.helicopter:
        return appLocalizations.typeHelicopter;
      case VehicleType.unknown:
        return 'unknown';
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
      case VehicleType.helicopter:
        return Icon(Symbols.helicopter, fill: 1,);
      case VehicleType.unknown:
        return Icon(Icons.question_mark);
    }
  }
}