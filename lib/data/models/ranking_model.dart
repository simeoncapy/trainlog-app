import 'dart:io';

import 'package:flutter/widgets.dart';
import 'package:trainlog_app/data/models/country_detail.dart';

/// Base class shared by every leaderboard entry.
///
/// The only field common to all ranking variants is the [username]; each
/// concrete subclass adds the metric-specific fields.
abstract class RankingEntry {
  final String username;

  const RankingEntry({required this.username});
}

/// Intermediate class for the trip-based leaderboards (vehicle, `all`,
/// carbon). These share a nullable [lastModified] (the backend sends `null`
/// for users who never logged anything) and a number of [trips].
abstract class TripRankingEntry extends RankingEntry {
  final DateTime? lastModified;
  final int trips;

  const TripRankingEntry({
    required super.username,
    required this.lastModified,
    required this.trips,
  });
}

/// A leaderboard row for a single vehicle type (or for `all` combined).
///
/// Matches the `leaderboard_data` rows of `/getLeaderboardUsers/<type>`:
/// ```json
/// { "last_modified": "...", "length": 35377003.27, "trips": 196, "username": "John Doe" }
/// ```
class LeaderboardEntry extends TripRankingEntry {
  /// Total travelled distance in metres.
  final double length;

  const LeaderboardEntry({
    required super.username,
    required super.lastModified,
    required super.trips,
    required this.length,
  });

  factory LeaderboardEntry.fromJson(Map<String, dynamic> json) {
    return LeaderboardEntry(
      username: json['username']?.toString() ?? '',
      lastModified: parseLeaderboardDate(json['last_modified']),
      trips: _toInt(json['trips']),
      length: _toDouble(json['length']),
    );
  }
}

/// A leaderboard row for the carbon-footprint ranking.
///
/// Matches the carbon variant of `/getLeaderboardUsers/carbon`:
/// ```json
/// { "carbon_per_km": 0.177, "last_modified": "...", "total_carbon": 507375.78,
///   "total_distance": 2856857682.75, "trips": 2202, "username": "John Doe" }
/// ```
class CarbonLeaderboardEntry extends TripRankingEntry {
  /// Average carbon emitted per kilometre (kg CO2 / km).
  final double carbonPerKm;

  /// Total carbon emitted (kg CO2).
  final double totalCarbon;

  /// Total travelled distance in metres.
  final double totalDistance;

  const CarbonLeaderboardEntry({
    required super.username,
    required super.lastModified,
    required super.trips,
    required this.carbonPerKm,
    required this.totalCarbon,
    required this.totalDistance,
  });

  factory CarbonLeaderboardEntry.fromJson(Map<String, dynamic> json) {
    return CarbonLeaderboardEntry(
      username: json['username']?.toString() ?? '',
      lastModified: parseLeaderboardDate(json['last_modified']),
      trips: _toInt(json['trips']),
      carbonPerKm: _toDouble(json['carbon_per_km']),
      totalCarbon: _toDouble(json['total_carbon']),
      totalDistance: _toDouble(json['total_distance']),
    );
  }
}

/// A leaderboard row for the countries-visited ranking
/// (`/getLeaderboardUsers/country_count`):
/// ```json
/// { "countries_visited": ["US", "JP", ...], "country_count": 101, "username": "John Doe" }
/// ```
class CountryLeaderboardEntry extends RankingEntry {
  /// Number of distinct countries visited.
  final int countryCount;

  /// ISO country codes the user has visited, kept in the backend order
  /// (by trip count per country, most visited first).
  final List<String> countriesVisited;

  const CountryLeaderboardEntry({
    required super.username,
    required this.countryCount,
    required this.countriesVisited,
  });

  factory CountryLeaderboardEntry.fromJson(Map<String, dynamic> json) {
    final visited = (json['countries_visited'] as List<dynamic>? ?? [])
        .map((e) => e.toString())
        .toList();
    return CountryLeaderboardEntry(
      username: json['username']?.toString() ?? '',
      countryCount: _toInt(json['country_count']),
      countriesVisited: visited,
    );
  }

  /// Resolves [countriesVisited] to [CountryDetail]s (code, localized name and
  /// emoji), preserving the backend order — by trip count, most visited first.
  List<CountryDetail> countryDetails(BuildContext context) {
    return countriesVisited
        .map((code) => CountryDetail.fromCode(code, context))
        .toList();
  }

  /// Same as [countryDetails] but sorted alphabetically by localized country
  /// name (according to the user's locale).
  List<CountryDetail> countryDetailsSortedByName(BuildContext context) {
    final details = countryDetails(context);
    details.sort(
      (a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()),
    );
    return details;
  }
}

/// The result of a leaderboard request: the public entries only (users listed
/// in `non_public_users` are already filtered out by `RankingApi`).
///
/// Sorting is intentionally not baked in — the same data is shown sorted by
/// length, trips, carbon, … depending on the screen. Use [sortedBy] with a
/// field selector, or one of the metric-specific helpers in the extensions
/// below.
class RankingResult<T extends RankingEntry> {
  final List<T> entries;

  const RankingResult(this.entries);

  bool get isEmpty => entries.isEmpty;
  bool get isNotEmpty => entries.isNotEmpty;
  int get length => entries.length;

  /// Returns a new list sorted by [selector]. Descending (highest first) by
  /// default, which is what a leaderboard usually wants.
  List<T> sortedBy(num Function(T entry) selector, {bool descending = true}) {
    final copy = List<T>.from(entries);
    copy.sort((a, b) {
      final cmp = selector(a).compareTo(selector(b));
      return descending ? -cmp : cmp;
    });
    return copy;
  }
}

/// Trip-count sorting, shared by every trip-based leaderboard.
extension TripRankingResultSorting<T extends TripRankingEntry>
    on RankingResult<T> {
  /// Sorted by number of trips.
  List<T> sortedByTrips({bool descending = true}) =>
      sortedBy((e) => e.trips, descending: descending);
}

/// Distance-based sorting for the vehicle / `all` leaderboards.
extension LeaderboardResultSorting on RankingResult<LeaderboardEntry> {
  /// Sorted by total travelled distance.
  List<LeaderboardEntry> sortedByLength({bool descending = true}) =>
      sortedBy((e) => e.length, descending: descending);
}

/// Carbon-based sorting for the carbon-footprint leaderboard.
extension CarbonResultSorting on RankingResult<CarbonLeaderboardEntry> {
  /// Sorted by total carbon emitted.
  List<CarbonLeaderboardEntry> sortedByTotalCarbon({bool descending = true}) =>
      sortedBy((e) => e.totalCarbon, descending: descending);

  /// Sorted by carbon emitted per kilometre.
  List<CarbonLeaderboardEntry> sortedByCarbonPerKm({bool descending = true}) =>
      sortedBy((e) => e.carbonPerKm, descending: descending);

  /// Sorted by total travelled distance.
  List<CarbonLeaderboardEntry> sortedByTotalDistance({bool descending = true}) =>
      sortedBy((e) => e.totalDistance, descending: descending);
}

/// Country-count sorting for the countries-visited leaderboard.
extension CountryResultSorting on RankingResult<CountryLeaderboardEntry> {
  /// Sorted by the number of distinct countries visited.
  List<CountryLeaderboardEntry> sortedByCountryCount({bool descending = true}) =>
      sortedBy((e) => e.countryCount, descending: descending);
}

/// A single coverage tier within a country/subdivision: the [percent] of the
/// rail network covered and the [usernames] of the users who reached it.
class RailCoverage {
  final double percent;
  final List<String> usernames;

  const RailCoverage({required this.percent, required this.usernames});
}

/// Rail-coverage stats for one country or subdivision, from
/// `/getLeaderboardUsers/train_countries`:
/// ```json
/// { "cc": "AT", "data": [ { "percent": 99.0, "usernames": ["John Doe"] }, ... ] }
/// ```
///
/// [code] is either a country code (`"AT"`) or an ISO 3166-2 subdivision code
/// (`"AT-1"`, `"FR-ARA"`); [RailPercentageResult] keeps the two kinds apart.
class RailPercentageEntry {
  /// Raw area code: a country code or an ISO 3166-2 subdivision code.
  final String code;

  /// Per-percentage coverage tiers (highest first, as returned by the backend).
  final List<RailCoverage> data;

  const RailPercentageEntry({required this.code, required this.data});

  /// Whether [code] denotes a subdivision (ISO 3166-2, contains a hyphen).
  bool get isSubdivision => code.contains('-');

  /// The country code: the parent for a subdivision (`"AT-1"` -> `"AT"`) or
  /// [code] itself for a country.
  String get countryCode => isSubdivision ? code.split('-').first : code;

  /// The subdivision part (`"AT-1"` -> `"1"`, `"FR-ARA"` -> `"ARA"`), or `null`
  /// for a country.
  String? get subdivisionCode =>
      isSubdivision ? code.split('-').sublist(1).join('-') : null;

  /// The highest coverage percentage reached in this area (0 when empty).
  double get highestPercent => data.isEmpty
      ? 0
      : data.map((c) => c.percent).reduce((a, b) => a > b ? a : b);

  /// The country resolved to a [CountryDetail] (code, localized name, emoji).
  CountryDetail country(BuildContext context) =>
      CountryDetail.fromCode(countryCode, context);

  /// Parses one `leaderboard_data` row, dropping users in [nonPublic] (and any
  /// tier or whole entry left empty as a result). Returns `null` when no public
  /// users remain.
  static RailPercentageEntry? fromJson(
    Map<String, dynamic> json, {
    Set<String> nonPublic = const {},
  }) {
    final code = json['cc']?.toString() ?? '';
    if (code.isEmpty) return null;

    final coverages = <RailCoverage>[];
    for (final d in (json['data'] as List<dynamic>? ?? [])
        .whereType<Map<String, dynamic>>()) {
      final users = (d['usernames'] as List<dynamic>? ?? [])
          .map((e) => e.toString())
          .where((u) => !nonPublic.contains(u))
          .toList();
      if (users.isEmpty) continue;
      coverages
          .add(RailCoverage(percent: _toDouble(d['percent']), usernames: users));
    }

    if (coverages.isEmpty) return null;
    return RailPercentageEntry(code: code, data: coverages);
  }
}

/// The result of the rail-percentage leaderboard, with country-level and
/// subdivision-level entries kept apart (public users only).
class RailPercentageResult {
  /// Country-level entries (`cc` without a hyphen).
  final List<RailPercentageEntry> countries;

  /// Subdivision-level entries (`cc` in ISO 3166-2 form, with a hyphen).
  final List<RailPercentageEntry> subdivisions;

  const RailPercentageResult({
    required this.countries,
    required this.subdivisions,
  });

  bool get isEmpty => countries.isEmpty && subdivisions.isEmpty;
  bool get isNotEmpty => !isEmpty;

  /// All subdivisions belonging to [countryCode] (e.g. `"AT"` -> AT-1, AT-2…),
  /// in the order they appear.
  List<RailPercentageEntry> subdivisionsOf(String countryCode) {
    final cc = countryCode.toUpperCase();
    return subdivisions.where((e) => e.countryCode.toUpperCase() == cc).toList();
  }

  /// Countries sorted by highest coverage percentage (highest first); ties
  /// broken alphabetically by localized country name.
  List<RailPercentageEntry> countriesSortedByPercent(BuildContext context) =>
      _sortByPercent(countries, (e) => e.country(context).name);

  /// Countries sorted alphabetically by localized country name.
  List<RailPercentageEntry> countriesSortedByName(BuildContext context) =>
      _sortByName(countries, (e) => e.country(context).name);

  /// Subdivisions sorted by highest coverage percentage (highest first); ties
  /// broken alphabetically by subdivision code.
  List<RailPercentageEntry> subdivisionsSortedByPercent() =>
      _sortByPercent(subdivisions, (e) => e.code);

  /// Subdivisions sorted alphabetically by subdivision code.
  List<RailPercentageEntry> subdivisionsSortedByName() =>
      _sortByName(subdivisions, (e) => e.code);
}

/// Sorts by highest coverage percentage (descending), breaking ties
/// alphabetically (ascending) on [name].
List<RailPercentageEntry> _sortByPercent(
  List<RailPercentageEntry> list,
  String Function(RailPercentageEntry entry) name,
) {
  final copy = List<RailPercentageEntry>.of(list);
  copy.sort((a, b) {
    final cmp = b.highestPercent.compareTo(a.highestPercent);
    if (cmp != 0) return cmp;
    return name(a).toLowerCase().compareTo(name(b).toLowerCase());
  });
  return copy;
}

/// Sorts alphabetically (ascending) on [name].
List<RailPercentageEntry> _sortByName(
  List<RailPercentageEntry> list,
  String Function(RailPercentageEntry entry) name,
) {
  final copy = List<RailPercentageEntry>.of(list);
  copy.sort((a, b) => name(a).toLowerCase().compareTo(name(b).toLowerCase()));
  return copy;
}

/// Parses a leaderboard `last_modified` value into a local [DateTime].
///
/// The backend sends RFC 1123 dates (e.g. `"Wed, 01 Apr 2026 00:00:00 GMT"`)
/// or `null` for users with no activity. Returns `null` when the value is
/// missing or unparseable rather than throwing.
DateTime? parseLeaderboardDate(dynamic value) {
  if (value == null) return null;
  final str = value.toString().trim();
  if (str.isEmpty || str.toLowerCase() == 'null') return null;
  try {
    return HttpDate.parse(str).toLocal();
  } on FormatException {
    return DateTime.tryParse(str)?.toLocal();
  } on HttpException {
    return DateTime.tryParse(str)?.toLocal();
  }
}

double _toDouble(dynamic v) {
  if (v is num) return v.toDouble();
  if (v is String) return double.tryParse(v) ?? 0.0;
  return 0.0;
}

int _toInt(dynamic v) {
  if (v is int) return v;
  if (v is num) return v.toInt();
  if (v is String) return int.tryParse(v) ?? 0;
  return 0;
}
