import 'package:country_coder/country_coder.dart';
import 'package:flutter/foundation.dart';
import 'package:trainlog_app/data/models/trips.dart';
import 'package:trainlog_app/data/models/trips_filter.dart';
import 'package:trainlog_app/data/trips_repository.dart';

/// One suggested operator with the number of local trips backing it.
typedef OperatorSuggestion = ({String name, int tripCount});

/// Proposes operators for the trip being created by querying the local trips
/// database.
///
/// Results are filtered by the trip's [VehicleType] and, when they can be
/// determined, by the departure/arrival countries; they are ordered by the
/// total number of historical trips (most used first).
///
/// Country resolution fallback sequence, per trip end:
/// 1. Coordinate guessing — offline reverse lookup of the coordinates via
///    the country_coder package.
/// 2. Station emoji flag — the flag prefixing the station's name (station
///    search results are stored as "🇩🇪 Frankfurt (Main) Hbf").
/// 3. No country — plain manual entries carry no metadata; when neither end
///    resolves, operators are matched without any country filter.
class OperatorSuggestionService {
  const OperatorSuggestionService();

  static const int defaultLimit = 5;

  /// Loads the offline borders once, off the UI thread (takes ~1 s).
  static Future<void>? _coderLoad;
  static Future<void> _ensureCountryCoder() {
    return _coderLoad ??= compute(CountryCoder.prepareData, null)
        .then((data) => CountryCoder.instance.load(data))
        .then((_) {});
  }

  /// Maximum [limit] operators for a [vehicleType] trip between the given
  /// ends, most frequently used first.
  Future<List<OperatorSuggestion>> suggest({
    required TripsRepository repository,
    required VehicleType vehicleType,
    double? departureLat,
    double? departureLong,
    String? departureName,
    double? arrivalLat,
    double? arrivalLong,
    String? arrivalName,
    int limit = defaultLimit,
  }) async {
    final countries = <String>{
      ...await _resolveCountry(departureLat, departureLong, departureName),
      ...await _resolveCountry(arrivalLat, arrivalLong, arrivalName),
    };

    final counts = await repository.fetchOperatorsByTripPF(
      filter: TripsFilterResult(
        types: [vehicleType],
        countries: countries,
      ),
    );

    return [
      for (final entry in counts.entries.take(limit))
        (name: entry.key, tripCount: entry.value.past + entry.value.future),
    ];
  }

  /// Resolves one trip end to a country code set (empty when unknown).
  Future<Set<String>> _resolveCountry(
      double? lat, double? long, String? name) async {
    // 1) Primary: offline reverse lookup of the coordinates.
    if (lat != null && long != null) {
      try {
        await _ensureCountryCoder();
        final code = CountryCoder.instance.iso1A2Code(lat: lat, lon: long);
        if (code != null && code.isNotEmpty) return {code};
      } catch (e) {
        debugPrint('⚠️ Country lookup from coordinates failed: $e');
      }
    }

    // 2) Secondary: emoji flag prefixing the station name.
    final code = flagEmojiToCountryCode(name);
    if (code != null) return {code};

    // 3) Tertiary: no metadata at all — no country filter.
    return {};
  }

  /// Parses a leading regional-indicator flag (e.g. "🇩🇪 Frankfurt…") into an
  /// ISO 3166-1 alpha-2 code. Returns null when the text has no flag prefix.
  @visibleForTesting
  static String? flagEmojiToCountryCode(String? text) {
    final trimmed = text?.trim();
    if (trimmed == null || trimmed.isEmpty) return null;

    const int base = 0x1F1E6; // regional indicator 'A'
    final runes = trimmed.runes.take(2).toList();
    if (runes.length < 2) return null;
    if (runes.any((r) => r < base || r > base + 25)) return null;

    return String.fromCharCodes(runes.map((r) => 65 + (r - base)));
  }
}
