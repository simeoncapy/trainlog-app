import 'package:flutter/material.dart';

import 'package:trainlog_app/app/theme/app_colors.dart';
import 'package:trainlog_app/data/models/trips.dart';
import 'package:trainlog_app/l10n/app_localizations.dart';

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

  /// Number of distinct countries visited. (Built later.)
  country,

  /// Carbon-footprint leaderboard. (Built later.)
  carbon;

  /// Whether a functional view exists for this category in the current batch.
  ///
  /// Only [all], [vehicles] and [worldSquares] are implemented; the others are
  /// rendered as disabled pills.
  bool get isImplemented =>
      this == RankingType.all ||
      this == RankingType.vehicles ||
      this == RankingType.worldSquares;

  /// Localized label for the category pill (vehicle pills use the vehicle name).
  String label(BuildContext context) {
    final loc = AppLocalizations.of(context)!;
    switch (this) {
      case RankingType.all:
        return loc.rankingTypeTotal;
      case RankingType.vehicles:
        return loc.rankingTypeTotal; // not shown directly; vehicles get their own
      case RankingType.railwayCoverage:
        return loc.rankingTypeRailwayCoverage;
      case RankingType.worldSquares:
        return loc.rankingTypeWorld;
      case RankingType.country:
        return loc.rankingTypeCountries;
      case RankingType.carbon:
        return loc.rankingTypeCarbon;
    }
  }

  /// Contextually relevant icon for the non-vehicle categories.
  Icon get icon {
    switch (this) {
      case RankingType.all:
        return const Icon(Icons.emoji_events);
      case RankingType.vehicles:
        return const Icon(Icons.directions_transit);
      case RankingType.railwayCoverage:
        return const Icon(Icons.percent);
      case RankingType.worldSquares:
        return const Icon(Icons.grid_on);
      case RankingType.country:
        return const Icon(Icons.public);
      case RankingType.carbon:
        return const Icon(Icons.eco);
    }
  }
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

/// The metric a distance-based leaderboard is sorted / displayed by.
enum RankingSortUnit {
  distance,
  trips;

  String label(BuildContext context) {
    final loc = AppLocalizations.of(context)!;
    switch (this) {
      case RankingSortUnit.distance:
        return loc.rankingUnitDistance;
      case RankingSortUnit.trips:
        return loc.rankingUnitTrips;
    }
  }

  Icon get icon {
    switch (this) {
      case RankingSortUnit.distance:
        return const Icon(Icons.straighten);
      case RankingSortUnit.trips:
        return const Icon(Icons.confirmation_number_outlined);
    }
  }
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
  bool get isVehicle => type == RankingType.vehicles && vehicle != null;

  /// Pill label: the vehicle name for vehicle selections, the type label
  /// otherwise.
  String label(BuildContext context) =>
      isVehicle ? VehicleType.labelOf(vehicle!, context) : type.label(context);

  /// Pill icon: the vehicle icon for vehicle selections, the type icon
  /// otherwise.
  Icon get icon => isVehicle ? VehicleType.iconOf(vehicle!) : type.icon;

  /// Accent colour for the pill dot, matching the transport-mode palette.
  Color get accentColor {
    if (isVehicle) {
      switch (vehicle!) {
        case VehicleType.train:
          return AppColors.modeTrain;
        case VehicleType.bus:
          return AppColors.modeBus;
        case VehicleType.plane:
          return AppColors.modeAir;
        case VehicleType.ferry:
          return AppColors.modeFerry;
        case VehicleType.metro:
          return AppColors.modeMetro;
        case VehicleType.tram:
          return AppColors.modeTram;
        case VehicleType.aerialway:
          return AppColors.violet;
        default:
          return AppColors.blue;
      }
    }
    switch (type) {
      case RankingType.all:
        return AppColors.amber;
      case RankingType.worldSquares:
        return AppColors.modeFerry;
      case RankingType.railwayCoverage:
        return AppColors.modeTram;
      case RankingType.country:
        return AppColors.blue;
      case RankingType.carbon:
        return AppColors.successLight;
      case RankingType.vehicles:
        return AppColors.amber;
    }
  }

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

  /// Total distance in kilometres (0 when not applicable).
  final double distanceKm;

  /// Number of trips (0 when not applicable).
  final int trips;

  /// World-coverage percentage (null outside the world-squares view).
  final double? percent;

  /// Last activity, when known (drives the "· Jun 2026" subtitle).
  final DateTime? lastModified;

  const RankingDisplayEntry({
    required this.rank,
    required this.username,
    this.distanceKm = 0,
    this.trips = 0,
    this.percent,
    this.lastModified,
  });

  RankingDisplayEntry copyWithRank(int newRank) => RankingDisplayEntry(
        rank: newRank,
        username: username,
        distanceKm: distanceKm,
        trips: trips,
        percent: percent,
        lastModified: lastModified,
      );
}
