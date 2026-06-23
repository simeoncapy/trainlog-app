import 'package:flutter/foundation.dart';
import 'package:trainlog_app/data/models/ranking_model.dart';
import 'package:trainlog_app/data/models/trips.dart';
import 'package:trainlog_app/services/api/trainlog_http_client.dart';

/// Leaderboard / ranking domain.
///
/// Calls the backend `/getLeaderboardUsers/<type>` endpoint, where `<type>` is
/// one of a vehicle short string (`train`, `air`, …), `all`, `carbon`,
/// `country`, `train_countries` or `world_squares`.
///
/// Every response carries a `non_public_users` list; those usernames are kept
/// in the returned entries but tagged as non-public (via `isNonPublic` /
/// `RankedUser.isNonPublic`) for a later feature, rather than filtered out.
class RankingApi {
  final TrainlogHttpClient _client;

  RankingApi(this._client);

  // ----------------------------
  // Public API
  // ----------------------------

  /// Ranking for a single [VehicleType]; `<type>` is its short string.
  Future<RankingResult<LeaderboardEntry>> fetchRankingForVehicle(
    VehicleType type,
  ) {
    return _fetchLeaderboard(type.toShortString());
  }

  /// Ranking across all vehicle types combined (`<type>` = `all`).
  Future<RankingResult<LeaderboardEntry>> fetchRankingAll() {
    return _fetchLeaderboard('all');
  }

  /// Carbon-footprint ranking (`<type>` = `carbon`).
  Future<RankingResult<CarbonLeaderboardEntry>> fetchRankingForCarbonFootprint() {
    return _fetchCarbonLeaderboard('carbon');
  }

  /// Ranking by number of countries visited (`<type>` = `country_count`).
  Future<RankingResult<CountryLeaderboardEntry>> fetchRankingForCountry() {
    return _fetchCountryLeaderboard('country_count');
  }

  /// Ranking by share of rail travel per country / subdivision
  /// (`<type>` = `train_countries`).
  Future<RailPercentageResult> fetchRankingForRailPercentage() {
    return _fetchRailPercentageLeaderboard('train_countries');
  }

  /// Ranking by share of the world's squares covered
  /// (`<type>` = `world_squares`).
  Future<WorldSquaresResult> fetchRankingForWorldSquares() {
    return _fetchWorldSquaresLeaderboard('world_squares');
  }

  // ----------------------------
  // Shared private fetchers
  // ----------------------------

  /// Distance leaderboards (vehicle types and `all`) share the same shape.
  Future<RankingResult<LeaderboardEntry>> _fetchLeaderboard(String type) async {
    final (rows, nonPublic) = await _fetchRaw(type);
    final entries = rows
        .map((r) => LeaderboardEntry.fromJson(
              r,
              isNonPublic: nonPublic.contains(r['username']?.toString()),
            ))
        .toList();
    return RankingResult(entries);
  }

  /// The carbon leaderboard has extra fields but the same overall logic.
  Future<RankingResult<CarbonLeaderboardEntry>> _fetchCarbonLeaderboard(
    String type,
  ) async {
    final (rows, nonPublic) = await _fetchRaw(type);
    final entries = rows
        .map((r) => CarbonLeaderboardEntry.fromJson(
              r,
              isNonPublic: nonPublic.contains(r['username']?.toString()),
            ))
        .toList();
    return RankingResult(entries);
  }

  /// The countries-visited leaderboard: a list of country codes plus a count.
  Future<RankingResult<CountryLeaderboardEntry>> _fetchCountryLeaderboard(
    String type,
  ) async {
    final (rows, nonPublic) = await _fetchRaw(type);
    final entries = rows
        .map((r) => CountryLeaderboardEntry.fromJson(
              r,
              isNonPublic: nonPublic.contains(r['username']?.toString()),
            ))
        .toList();
    return RankingResult(entries);
  }

  /// The rail-percentage leaderboard: rows keyed by country / subdivision
  /// rather than by user. Non-public users are tagged per coverage tier (not
  /// filtered out) and country- and subdivision-level rows are kept apart.
  Future<RailPercentageResult> _fetchRailPercentageLeaderboard(
    String type,
  ) async {
    final (rows, nonPublic) = await _fetchRaw(type);
    final countries = <RailPercentageEntry>[];
    final subdivisions = <RailPercentageEntry>[];

    for (final row in rows) {
      final entry = RailPercentageEntry.fromJson(row, nonPublic: nonPublic);
      if (entry == null) continue; // no users listed for this area
      if (entry.isSubdivision) {
        subdivisions.add(entry);
      } else {
        countries.add(entry);
      }
    }

    return RailPercentageResult(
      countries: countries,
      subdivisions: subdivisions,
    );
  }

  /// The world-squares leaderboard: a single `world_squares` block of coverage
  /// tiers; non-public users are tagged, not filtered out.
  Future<WorldSquaresResult> _fetchWorldSquaresLeaderboard(String type) async {
    final (rows, nonPublic) = await _fetchRaw(type);
    return WorldSquaresResult.fromLeaderboard(rows, nonPublic);
  }

  /// Fetches and splits a `/getLeaderboardUsers/<type>` response into its
  /// `leaderboard_data` rows and the set of `non_public_users`.
  Future<(List<Map<String, dynamic>>, Set<String>)> _fetchRaw(
    String type,
  ) async {
    final path = '/getLeaderboardUsers/$type';

    try {
      final res = await _client.safeGet<Map<String, dynamic>>(path);
      final data = res.data;
      if (data == null) return (const <Map<String, dynamic>>[], const <String>{});

      final rows = (data['leaderboard_data'] as List<dynamic>? ?? [])
          .whereType<Map<String, dynamic>>()
          .toList();
      final nonPublic = (data['non_public_users'] as List<dynamic>? ?? [])
          .map((e) => e.toString())
          .toSet();

      return (rows, nonPublic);
    } catch (e) {
      debugPrint('🛑 fetchLeaderboard($type) failed: $e');
      return (const <Map<String, dynamic>>[], const <String>{});
    }
  }
}
