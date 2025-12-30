import 'package:trainlog_app/data/models/trips.dart';

class PreRecordModel {
  final int id;
  final String? stationName;
  final String? address;
  final double lat;
  final double long;
  final DateTime dateTime;
  final VehicleType type;

  PreRecordModel({
    required this.id,
    this.stationName,
    this.address,
    required this.lat,
    required this.long,
    required this.dateTime,
    VehicleType? type,
  }) : type = type ?? VehicleType.unknown;

  factory PreRecordModel.fromJson(Map<String, dynamic> json) {
    return PreRecordModel(
      id: json['id']?.toInt() ?? 0,
      stationName: json['station_name']?.toString(),
      address: json['address']?.toString(),
      lat: _toDouble(json['lat']),
      long: _toDouble(json['long']),
      dateTime: DateTime.parse(json['date_time']),
      type: VehicleType.fromString(json['type']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'station_name': stationName,
      'address': address,
      'lat': lat,
      'long': long,
      'date_time': dateTime.toIso8601String(),
      'type': type.toShortString(),
    };
  }

  static double _toDouble(dynamic value) {
    final str = value?.toString().trim();
    if (str == null || str.isEmpty) {
      throw FormatException('Cannot parse empty value as double');
    }
    return double.parse(str);
  }
}