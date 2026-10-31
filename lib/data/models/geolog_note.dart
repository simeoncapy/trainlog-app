import 'package:trainlog_app/widgets/trip_visibility_selector.dart';
import 'package:trainlog_app/widgets/vehicle_energy_selector.dart';

/// Extra trip details attached to a Geolog (a Smart Prerecorder record).
///
/// Everything is optional: a field left null means "the note says nothing
/// about it". When two Geologs are combined into a trip, the departure's and
/// the arrival's notes are merged (see `PreRecordProvider.buildTripForm`).
///
/// The station itself is not part of the note: picking another station on
/// the note page updates the Geolog directly, so combining keeps using it the
/// way it always did.
class GeologNote {
  /// Replaces the time the Geolog was recorded at, in local time. The
  /// recorded time itself is kept on the Geolog.
  final DateTime? dateTime;

  /// Delay at this point, in minutes (negative when early).
  final int? delayMinutes;

  final List<String> operators;
  final String? line;
  final String? material;
  final String? registration;
  final String? seat;

  /// Free-text memo (the trip "notes" field).
  final String? memo;

  final double? price;
  final String? currency;
  final DateTime? purchaseDate;

  /// Null when the user left it on automatic.
  final EnergyType? energy;
  final TripVisibility? visibility;

  const GeologNote({
    this.dateTime,
    this.delayMinutes,
    this.operators = const [],
    this.line,
    this.material,
    this.registration,
    this.seat,
    this.memo,
    this.price,
    this.currency,
    this.purchaseDate,
    this.energy,
    this.visibility,
  });

  /// Whether the note carries anything at all. An empty note is not stored.
  bool get isEmpty =>
      dateTime == null &&
      delayMinutes == null &&
      operators.isEmpty &&
      line == null &&
      material == null &&
      registration == null &&
      seat == null &&
      memo == null &&
      price == null &&
      purchaseDate == null &&
      energy == null &&
      visibility == null;

  factory GeologNote.fromJson(Map<String, dynamic> json) {
    return GeologNote(
      dateTime: _date(json['date_time']),
      delayMinutes: (json['delay_minutes'] as num?)?.toInt(),
      operators: (json['operators'] as List? ?? const [])
          .map((e) => e.toString())
          .where((e) => e.trim().isNotEmpty)
          .toList(),
      line: _text(json['line']),
      material: _text(json['material']),
      registration: _text(json['registration']),
      seat: _text(json['seat']),
      memo: _text(json['memo']),
      price: (json['price'] as num?)?.toDouble(),
      currency: _text(json['currency']),
      purchaseDate: _date(json['purchase_date']),
      energy: json['energy'] == null
          ? null
          : EnergyType.fromString(json['energy'].toString()),
      visibility: json['visibility'] == null
          ? null
          : TripVisibility.fromString(json['visibility'].toString()),
    );
  }

  Map<String, dynamic> toJson() => {
    if (dateTime != null) 'date_time': dateTime!.toIso8601String(),
    if (delayMinutes != null) 'delay_minutes': delayMinutes,
    if (operators.isNotEmpty) 'operators': operators,
    if (line != null) 'line': line,
    if (material != null) 'material': material,
    if (registration != null) 'registration': registration,
    if (seat != null) 'seat': seat,
    if (memo != null) 'memo': memo,
    if (price != null) 'price': price,
    if (currency != null) 'currency': currency,
    if (purchaseDate != null) 'purchase_date': purchaseDate!.toIso8601String(),
    if (energy != null) 'energy': energy!.name,
    if (visibility != null) 'visibility': visibility!.name,
  };

  /// Trims [value] and turns an empty string into null, as the form fields
  /// report a cleared field as "".
  static String? clean(String? value) {
    final trimmed = value?.trim();
    return (trimmed == null || trimmed.isEmpty) ? null : trimmed;
  }

  static String? _text(dynamic value) => clean(value?.toString());

  static DateTime? _date(dynamic value) =>
      value == null ? null : DateTime.tryParse(value.toString());
}
