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
  });

  factory Trips.fromJson(Map<String, dynamic> json) {
    return Trips(
      uid: json['uid']?.toString() ?? '',
      username: json['username']?.toString() ?? '',
      originStation: json['origin_station']?.toString() ?? '',
      destinationStation: json['destination_station']?.toString() ?? '',
      startDatetime: DateTime.parse(json['start_datetime']),
      endDatetime: DateTime.parse(json['end_datetime']),
      estimatedTripDuration: _toDouble(json['estimated_trip_duration']),
      manualTripDuration: _toDoubleOrNull(json['manual_trip_duration']),
      tripLength: _toDouble(json['trip_length']),
      operatorName: json['operator']?.toString() ?? '',
      countries: json['countries']?.toString() ?? '',
      utcStartDatetime: _toDateTimeOrNull(json['utc_start_datetime']),
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

  static double _toDouble(dynamic value) {
    final str = value?.toString().trim();
    if (str == null || str.isEmpty) {
      throw FormatException('Cannot parse empty value as double');
    }
    return double.parse(str);
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
      case VehicleType.unknown:
        return 'unknown';
    }
  }
}