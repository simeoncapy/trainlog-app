import 'package:trainlog_app/data/models/trips.dart';

class PreRecordModel {
  final int id;
  final String? stationName;
  final String? address;
  final double? lat;
  final double? long;
  final DateTime dateTime;
  final DateTime dateTimeUtc;
  final VehicleType type;
  final bool loaded;

  PreRecordModel({
    required this.id,
    this.stationName,
    this.address,
    this.lat,
    this.long,
    required this.dateTime,
    DateTime? dateTimeUtc,
    this.type = VehicleType.unknown,
    this.loaded = false,
  })  : dateTimeUtc = dateTimeUtc ?? dateTime.toUtc();

  PreRecordModel copyWith({
    double? lat,
    double? long,
    String? stationName,
    String? address,
    VehicleType? type,
    bool? loaded,
  }) {
    return PreRecordModel(
      id: id,
      stationName: stationName ?? this.stationName,
      address: address ?? this.address,
      lat: lat ?? this.lat,
      long: long ?? this.long,
      dateTime: dateTime,
      dateTimeUtc: dateTimeUtc,
      type: type ?? this.type,
      loaded: loaded ?? this.loaded,
    );
  }

  factory PreRecordModel.fromJson(Map<String, dynamic> json) {
    final local = DateTime.parse(json['date_time']);
    final utc = json['date_time_utc'] != null
        ? DateTime.parse(json['date_time_utc'])
        : local.toUtc();

    return PreRecordModel(
      id: json['id']?.toInt() ?? 0,
      stationName: json['station_name']?.toString(),
      address: json['address']?.toString(),
      lat: _toDouble(json['lat']),
      long: _toDouble(json['long']),
      dateTime: local,
      dateTimeUtc: utc,
      type: VehicleType.fromString(json['type']),
      loaded: json['loaded'] ?? true,
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
      'date_time_utc': dateTimeUtc.toIso8601String(),
      'type': type.toShortString(),
      'loaded': loaded,
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
