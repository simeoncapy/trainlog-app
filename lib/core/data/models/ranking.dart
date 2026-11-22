import 'package:flutter/foundation.dart';
import 'package:trainlog_app/core/data/models/trips.dart';

// Ranking (leaderboard) model, shared by the provider and the views. Labels,
// icons and colours are view extensions in features/ranking/ranking_type.dart.

/// The high-level leaderboard categories shown in the selector bar.
///
/// [vehicles] is special: it is not a single pill but expands into one pill per
/// supported [VehicleType] (see [RankingSelection]). The remaining values map
/// one-to-one onto a pill.
enum RankingType {
  /// Combined distance / trips across every vehicle type.
  all,

  /// Per-vehicle distance / trips leaderboards.
  vehicles,

  /// Share of each country's rail network covered. (Built later.)
  railwayCoverage,

  /// Share of the world's squares covered.
  worldSquares,

  /// Number of distinct countries visited.
  country,

  /// Carbon-footprint leaderboard. (Built later.)
  carbon;

  /// Whether a functional view exists for this category in the current batch.
  ///
  /// Every category is implemented.
  bool get isImplemented => true;
}

/// The vehicle types that have their own ranking pill in this batch.
///
/// Note the requested `cable` and `subway` map onto the existing
/// [VehicleType.aerialway] and [VehicleType.metro] enum members.
const List<VehicleType> kRankingVehicleSubset = <VehicleType>[
  VehicleType.train,
  VehicleType.bus,
  VehicleType.plane,
  VehicleType.ferry,
  VehicleType.aerialway, // "cable"
  VehicleType.metro, // "subway"
  VehicleType.tram,
];

/// The metric a leaderboard is sorted / displayed by.
enum RankingSortUnit {
  distance,
  trips,
  totalCarbon,
  carbonPerKm;

  /// Whether a lower value ranks better (true for both carbon metrics).
  bool get lowerIsBetter =>
      this == RankingSortUnit.carbonPerKm ||
      this == RankingSortUnit.totalCarbon;
}

/// A concrete leaderboard selection: a [RankingType] plus, when the type is
/// [RankingType.vehicles], the specific [VehicleType] being ranked.
@immutable
class RankingSelection {
  final RankingType type;

  /// Only set when [type] is [RankingType.vehicles].
  final VehicleType? vehicle;

  const RankingSelection._(this.type, this.vehicle);

  const RankingSelection.all() : this._(RankingType.all, null);
  const RankingSelection.worldSquares()
    : this._(RankingType.worldSquares, null);
  const RankingSelection.vehicle(VehicleType vehicle)
    : this._(RankingType.vehicles, vehicle);

  /// A non-vehicle category (used to render the disabled pills).
  const RankingSelection.category(RankingType type) : this._(type, null);

  bool get isWorldSquares => type == RankingType.worldSquares;
  bool get isCountry => type == RankingType.country;
  bool get isVehicle => type == RankingType.vehicles && vehicle != null;

  @override
  bool operator ==(Object other) =>
      other is RankingSelection &&
      other.type == type &&
      other.vehicle == vehicle;

  @override
  int get hashCode => Object.hash(type, vehicle);
}

/// The ordered list of pills shown in the selector bar: Total, one per vehicle
/// in [kRankingVehicleSubset], then the remaining categories.
List<RankingSelection> buildRankingPills() {
  return <RankingSelection>[
    const RankingSelection.all(),
    for (final v in kRankingVehicleSubset) RankingSelection.vehicle(v),
    const RankingSelection.worldSquares(),
    const RankingSelection.category(RankingType.railwayCoverage),
    const RankingSelection.category(RankingType.country),
    const RankingSelection.category(RankingType.carbon),
  ];
}

/// A single, view-normalized leaderboard row.
///
/// All variants are flattened into this shape so the list/row widgets stay
/// agnostic of which backend endpoint produced the data. [rank] is the
/// competitive position (by the active metric, highest first) and never changes
/// when the display order is toggled.
@immutable
class RankingDisplayEntry {
  final int rank;
  final String username;

  /// Whether the user opted out of being public. Such users are still shown in
  /// the leaderboard; this flag is reserved for a later feature.
  final bool isNonPublic;

  /// Total distance in kilometres (0 when not applicable).
  final double distanceKm;

  /// Number of trips (0 when not applicable).
  final int trips;

  /// World-coverage percentage (null outside the world-squares view).
  final double? percent;

  /// Total CO2e emitted, in kilograms (0 outside the carbon view).
  final double totalCarbonKg;

  /// CO2e intensity, in grams per kilometre (0 outside the carbon view).
  final double carbonPerKmG;

  /// Number of distinct countries visited (0 outside the country view).
  final int countryCount;

  /// ISO country codes visited, in the backend order (by trip count, most
  /// visited first). Empty outside the country view.
  final List<String> countriesVisited;

  /// Last activity, when known (drives the "· Jun 2026" subtitle).
  final DateTime? lastModified;

  const RankingDisplayEntry({
    required this.rank,
    required this.username,
    this.isNonPublic = false,
    this.distanceKm = 0,
    this.trips = 0,
    this.percent,
    this.totalCarbonKg = 0,
    this.carbonPerKmG = 0,
    this.countryCount = 0,
    this.countriesVisited = const [],
    this.lastModified,
  });

  RankingDisplayEntry copyWithRank(int newRank) => RankingDisplayEntry(
    rank: newRank,
    username: username,
    isNonPublic: isNonPublic,
    distanceKm: distanceKm,
    trips: trips,
    percent: percent,
    totalCarbonKg: totalCarbonKg,
    carbonPerKmG: carbonPerKmG,
    countryCount: countryCount,
    countriesVisited: countriesVisited,
    lastModified: lastModified,
  );
}

/// Carbon intensity band of a leaderboard row (grams of CO2e per km).
enum CarbonThreshold {
  green,
  medium,
  high;

  static CarbonThreshold forValue(num value) {
    if (value < 50) return CarbonThreshold.green;
    if (value < 200) return CarbonThreshold.medium;
    return CarbonThreshold.high;
  }
}
