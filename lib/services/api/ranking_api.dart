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
/// Every response carries a `non_public_users` list; those usernames are
/// filtered out of the returned entries so the UI never exposes private users.
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

  /// Ranking by share of rail travel (`<type>` = `train_countries`).
  ///
  /// Placeholder: dedicated result model still to be defined.
  Future<void> fetchRankingForRailPercentage() {
    throw UnimplementedError(
      'fetchRankingForRailPercentage (/getLeaderboardUsers/train_countries) is not implemented yet',
    );
  }

  /// Ranking by world squares covered (`<type>` = `world_squares`).
  ///
  /// Placeholder: dedicated result model still to be defined.
  Future<void> fetchRankingForWorldSquares() {
    throw UnimplementedError(
      'fetchRankingForWorldSquares (/getLeaderboardUsers/world_squares) is not implemented yet',
    );
  }

  // ----------------------------
  // Shared private fetchers
  // ----------------------------

  /// Distance leaderboards (vehicle types and `all`) share the same shape.
  Future<RankingResult<LeaderboardEntry>> _fetchLeaderboard(String type) async {
    final (rows, nonPublic) = await _fetchRaw(type);
    final entries = rows
        .where((r) => !nonPublic.contains(r['username']?.toString()))
        .map(LeaderboardEntry.fromJson)
        .toList();
    return RankingResult(entries);
  }

  /// The carbon leaderboard has extra fields but the same overall logic.
  Future<RankingResult<CarbonLeaderboardEntry>> _fetchCarbonLeaderboard(
    String type,
  ) async {
    final (rows, nonPublic) = await _fetchRaw(type);
    final entries = rows
        .where((r) => !nonPublic.contains(r['username']?.toString()))
        .map(CarbonLeaderboardEntry.fromJson)
        .toList();
    return RankingResult(entries);
  }

  /// The countries-visited leaderboard: a list of country codes plus a count.
  Future<RankingResult<CountryLeaderboardEntry>> _fetchCountryLeaderboard(
    String type,
  ) async {
    final (rows, nonPublic) = await _fetchRaw(type);
    final entries = rows
        .where((r) => !nonPublic.contains(r['username']?.toString()))
        .map(CountryLeaderboardEntry.fromJson)
        .toList();
    return RankingResult(entries);
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
      if (data == null) return (const [], const {});

      final rows = (data['leaderboard_data'] as List<dynamic>? ?? [])
          .whereType<Map<String, dynamic>>()
          .toList();
      final nonPublic = (data['non_public_users'] as List<dynamic>? ?? [])
          .map((e) => e.toString())
          .toSet();

      return (rows, nonPublic);
    } catch (e) {
      debugPrint('🛑 fetchLeaderboard($type) failed: $e');
      return (const [], const {});
    }
  }
}
